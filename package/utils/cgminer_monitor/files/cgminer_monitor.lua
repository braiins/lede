#!/usr/bin/lua

local CJSON = require "cjson"
local SOCKET = require "socket"

local CGMINER_HOST = "127.0.0.1"
local CGMINER_PORT = 4028

local SERVER_HOST = "*"
local SERVER_PORT = 4029

local HISTORY_SIZE = 60

local CHAINS = 6
local SAMPLE_TIME = 1
local MHS = {60, 300, 900}

-- class declarations
local History = {}
History.__index = History

local RollingAverage = {}
RollingAverage.__index = RollingAverage

local CGMinerDevs = {}
CGMinerDevs.__index = CGMinerDevs

local Monitor = {}
Monitor.__index = Monitor

-- History class
function History.new(max_size)
	local self = setmetatable({}, History)
	self.max_size = max_size
	self.size = 0
	self.pos = 1
	return self
end

function History:append(value)
	if self.size < self.max_size then
		table.insert(self, value)
		self.size = self.size + 1
	else
		self[self.pos] = value
		self.pos = self.pos % self.max_size + 1
	end
end

function History:values()
	local i = 0
	return function()
		i = i + 1
		if i <= self.size then
			return self[(self.pos - i - 1) % self.size + 1]
		end
	end
end

-- RollingAverage class
function RollingAverage.new(interval)
	local self = setmetatable({}, RollingAverage)
	self.interval = interval
	self.time = 0
	self.value = 0
	return self
end

function RollingAverage:add(value, time)
	local dt = time - self.time

	if dt <= 0 then
		return
	end

	local fprop = 1 - (1 / math.exp(dt / self.interval))
	local ftotal = 1 + fprop

	self.time = time
	self.value = (self.value + (value / dt * fprop)) / ftotal
end

-- CGMiner class
function CGMinerDevs.new(response)
	local self = setmetatable({}, CGMinerDevs)
	self.data = response and CJSON.decode(response)
	return self
end

function CGMinerDevs:get(id)
	if self.data then
		for _, dev in ipairs(self.data.DEVS) do
			if dev.ID == id then
				return dev
			end
		end
	end
end

-- Monitor class
function Monitor.new(history_size)
	local self = setmetatable({}, Monitor)
	self.history = History.new(history_size)
	self.last_time = 0
	self.chains = {}
	for _ = 1,CHAINS do
		local chain = {}
		chain.temp = 0
		chain.errs_last = 0
		chain.errs = 0
		chain.accepted = 0
		chain.rejected = 0
		chain.mhs_cur = 0
		chain.mhs = {}
		for _, interval in ipairs(MHS) do
			chain.mhs[interval] = RollingAverage.new(interval)
		end
		table.insert(self.chains, chain)
	end
	return self
end

function Monitor:sample_time()
	return (os.time() - self.last_time) >= SAMPLE_TIME
end

function Monitor:add_sample(response)
	local devs = CGMinerDevs.new(response)
	local sample = {}
	self.last_time = os.time()
	sample.time = self.last_time
	sample.chains = {}

	for i, chain in ipairs(self.chains) do
		local id = i - 1
		local dev = devs:get(id)
		if dev then
			local errs = dev["Hardware Errors"]
			chain.temp = dev["TempAVG"]
			chain.errs = chain.errs + errs - chain.errs_last
			chain.errs_last = errs
			chain.accepted = dev["Accepted"]
			chain.rejected = dev["Rejected"]
			chain.mhs_cur = dev["MHS 5s"]
			for _, mhs in pairs(chain.mhs) do
				mhs:add(chain.mhs_cur, self.last_time)
			end
		else
			chain.temp = 0
			chain.errs_last = 0
			chain.accepted = 0
			chain.rejected = 0
			chain.mhs_cur = 0
			for _, mhs in pairs(chain.mhs) do
				mhs:add(0, self.last_time)
			end
		end
		-- copy current chain values to the sample
		local sample_chain = {}
		sample_chain.id = id
		sample_chain.temp = chain.temp
		sample_chain.errs = chain.errs
		sample_chain.acpt = chain.accepted
		sample_chain.rjct = chain.rejected
		sample_chain.mhs = {chain.mhs_cur }
		for _, interval in ipairs(MHS) do
			local mhs = chain.mhs[interval]
			table.insert(sample_chain.mhs, mhs.value)
		end
		-- TODO: do not insert when each value is zero
		table.insert(sample.chains, sample_chain)
	end
	self.history:append(sample)
end

function Monitor:get_response()
	if self.history.size then
		local result = {}
		for sample in self.history:values() do
			table.insert(result, sample)
		end
		return CJSON.encode(result)
	end
end

local monitor = Monitor.new(HISTORY_SIZE)
local server = assert(SOCKET.bind(SERVER_HOST, SERVER_PORT))
local result

-- server accept is interrupted every second to get new sample from cgminer
server:settimeout(SAMPLE_TIME)

-- wait forever for incomming connections
while 1 do
	local client = server:accept()
	local cgminer = assert(SOCKET.tcp())

	if monitor:sample_time() then
		cgminer:connect(CGMINER_HOST, CGMINER_PORT)
		cgminer:send('{ "command":"devs" }')
		-- read all data and close the connection
		result = cgminer:receive('*a')
		if result then
			-- remove null from string
			result = result:sub(1, -2)
		end
		monitor:add_sample(result)
	end
	if client then
		local response = monitor:get_response(history)
		if response then
			client:send(response)
		end
		client:close()
	end
end

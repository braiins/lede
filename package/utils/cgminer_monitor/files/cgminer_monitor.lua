#!/usr/bin/lua

local CJSON = require "cjson"
local SOCKET = require "socket"

local CGMINER_HOST = "127.0.0.1"
local CGMINER_PORT = 4028

local SERVER_HOST = "*"
local SERVER_PORT = 4029

local HISTORY_SIZE = 60

-- class declarations
local History = {}
History.__index = History

local Monitor = {}
Monitor.__index = Monitor

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

function Monitor.new(history_size)
	local self = setmetatable({}, Monitor)
	self.history = History.new(history_size)
	self.last_time = 0
	return self
end

function Monitor:sample_time()
	return (os.time() - self.last_time) >= 1
end

function Monitor:add_sample(devs)
	local sample = {}
	self.last_time = os.time()
	sample.time = self.last_time
	sample.chains = {}
	if devs then
		local value = CJSON.decode(devs)
		for _, dev in ipairs(value.DEVS) do
			local chain = {}
			chain.id = dev.ID
			chain.mhs = {}
			for _, unit in ipairs({"5s", "1m", "5m", "15m"}) do
				table.insert(chain.mhs, dev["MHS "..unit])
			end
			table.insert(sample.chains, chain)
		end
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
server:settimeout(1)

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

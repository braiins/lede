#!/bin/sh

cgminer -o stratum+tcp://dbg.stratum.slushpool.com:3335 -u jhorak.worker1 -p b --A1Pll1 1332 --A1Pll2 1332 --A1Pll3 1332 --A1Pll4 1332 --A1Pll5 1332 --A1Pll6 1332 --A1Vol 10 --A5-extra-debug 1 --enabled-chains 1,2 --A5-benchmark 1

bencharka
=========

Simple benchmark framework in Erlang

[![Build Status](https://secure.travis-ci.org/aleksandr-vin/bencharka.png)](http://travis-ci.org/aleksandr-vin/bencharka)


Live examples
-------------

For now you can find a benchmark project build with bencharka here: [aleksandr-vin/lager_bench](https://github.com/aleksandr-vin/lager_bench).


How it works
------------

All is simple: you actually only need to run `bencharka:start()` in
the directory with benchmark files, that have a mask
`^bench_*.erl$`. And the dragons will appear...

Those files will be:
1. enumerated
2. compiled
3. loaded
4. inited by calling Mod:init/0
5. measured the call for Mod:test/0
6. terminated with the Mod:terminate/1

Then all the produced results will be aggregated *(the benchmarking
session can repeatedly run the modules if you use
`bencharka:start/1`)* and printed.


Why not X
---------

I prefer to use smth. already being developed, but in this case I
can't figure out the task of the benchmarking using EUnit tests or
Common Tests. May be later I master them and switch from this project
but for now it simply works!


Contribution
------------

You are welcome!

-module(bencharka).

-export([start/0, start/1, stop/0]).

stop() ->
    timer:sleep(1000),
    erlang:halt(0).

start() ->
    start(1).

start([Repeats]) when is_atom(Repeats) ->
    start(list_to_integer(atom_to_list(Repeats)));
start(Repeats) ->
    io:format("% Starting benchmarks... with ~p repeats~n", [Repeats]),
    Tests0 = filelib:fold_files(".", "^bench_.*\.erl$", false,
                                fun (E,Acc) -> [E|Acc] end, []),
    Tests = lists:flatmap(fun (A) -> A end,
                          lists:duplicate(Repeats, Tests0)),
    LongResult = lists:foldl(fun perform/2, [], Tests),
    io:format("%%% Long result is: ~p~n", [LongResult]),
    Result = aggregate_result(LongResult),
    io:format("% Aggregated result is: ~p~n", [Result]),
    ok.

perform(Filename, Acc) ->
    [{Filename, perform(Filename)}|Acc].

perform([]) ->
    [];
perform(Filename) when is_list(Filename) ->
    io:format("%%% Compiling ~p~n", [Filename]),
    Mod = filename:basename(Filename, ".erl"),
    perform(compile:file(Mod));
perform({ok, Mod}) ->
    io:format("%%% Loading ~p~n", [Mod]),
    _ = code:purge(Mod),
    perform(code:load_file(Mod));
perform({module, Mod}) ->
    io:format("%% Initializing ~p~n", [Mod]),
    State = Mod:init(),
    io:format("% Running ~p:test/0~n", [Mod]),
    {Time, _} = Result = timer:tc(Mod, test, []),
    io:format("% Elapsed time: ~p s~n", [Time / 1000000]),
    io:format("%% Terminating ~p~n", [Mod]),
    ok = Mod:terminate(State),
    Result;
perform(Other) ->
    io:format("% ~p", [Other]),
    Other.

aggregate_result(LR) ->
    io:format("%%% Aggregating results...~n"),
    Keys = proplists:get_keys(LR),
    lists:map(fun (Key) ->
                      AllValues = proplists:get_all_values(Key, LR),
                      {Positives, _Negatives} =
                          lists:foldl(fun ({T, ok}, {PosAcc, NegAcc}) -> {[T|PosAcc], NegAcc};
                                          (Smth, {PosAcc, NegAcc}) -> {PosAcc, [Smth|NegAcc]}
                                      end,
                                      {[],[]},
                                      AllValues),
                      Sum = lists:sum(Positives),
                      Ratio = length(Positives) / length(AllValues),
                      Avg = Sum / length(Positives),
                      Min = lists:min(Positives),
                      Max = lists:max(Positives),
                      {Key, [{ratio, Ratio}, {avg, norm(Avg)}, {min, norm(Min)}, {max, norm(Max)}]}
              end,
              Keys).

norm(T) when is_number(T) ->
    %%norm(T, us).
    {ms, T / 1000}.

norm(T, us) when is_integer(T) and 0 =:= T rem 1000->
    norm(T div 1000, ms);
norm(T, us) when is_integer(T) ->
    norm(T / 1000, ms);
norm(T, us) when is_float(T) andalso T == ((round(T) div 1000) * 1000) ->
    norm(round(T), us);
norm(T, us) ->
    {us, T};
norm(T, ms) when is_integer(T) and 0 =:= T rem 1000 ->
    norm(T div 1000, s);
norm(T, ms) when is_integer(T) ->
    norm(T / 1000, s);
norm(T, ms) ->
    {ms, T};
norm(T, s) ->
    {seconds, T}.

-module(env).
-export([get_global_env/0, set_global_env/1, get_env/2, get_all_env/1, get_env_from_platform/1, get_all_from_platform/0]).

%% Global environment storage
-define(ENV_KEY, spaceship_helm_env).

%% Get the global environment instance
get_global_env() ->
    case erlang:get(?ENV_KEY) of
        undefined -> {error, nil};
        Env -> {ok, Env}
    end.

%% Set the global environment instance
set_global_env(Env) ->
    erlang:put(?ENV_KEY, Env),
    nil.

%% Get an environment variable from the stored environment
get_env(_Vars, Name) ->
    case os:getenv(Name) of
        false -> {error, nil};
        Value -> {ok, list_to_binary(Value)}
    end.

%% Get all environment variables from the stored environment
get_all_env(_Vars) ->
    get_all_from_platform().

%% Get an environment variable directly from the platform
get_env_from_platform(Name) ->
    case os:getenv(Name) of
        false -> {error, nil};
        Value -> {ok, list_to_binary(Value)}
    end.

%% Get all environment variables directly from the platform
get_all_from_platform() ->
    EnvList = os:env(),
    lists:map(fun({Key, Value}) -> {list_to_binary(Key), list_to_binary(Value)} end, EnvList).

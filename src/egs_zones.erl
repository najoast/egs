%% @author Lo�c Hoguin <essen@dev-extend.eu>
%% @copyright 2011 Lo�c Hoguin.
%% @doc Zone handler.
%%
%%	This file is part of EGS.
%%
%%	EGS is free software: you can redistribute it and/or modify
%%	it under the terms of the GNU Affero General Public License as
%%	published by the Free Software Foundation, either version 3 of the
%%	License, or (at your option) any later version.
%%
%%	EGS is distributed in the hope that it will be useful,
%%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%	GNU Affero General Public License for more details.
%%
%%	You should have received a copy of the GNU Affero General Public License
%%	along with EGS.  If not, see <http://www.gnu.org/licenses/>.

-module(egs_zones).
-behaviour(gen_server).

-export([start_link/4, stop/1, setid/1]). %% API.
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]). %% gen_server.

-record(state, {
	setid = 0		:: integer(),
	objects = []	:: list()
}).

%% API.

%% @spec start_link(UniID, QuestID, ZoneID, ZoneData) -> {ok,Pid::pid()}
start_link(UniID, QuestID, ZoneID, ZoneData) ->
	gen_server:start_link(?MODULE, [UniID, QuestID, ZoneID, ZoneData], []).

%% @spec stop(Pid) -> stopped
stop(Pid) ->
	gen_server:call(Pid, stop).

setid(Pid) ->
	gen_server:call(Pid, setid).

%% gen_server.

init([UniID, QuestID, ZoneID, ZoneData]) ->
	SetID = rand_setid(proplists:get_value(sets, ZoneData, [100])),
	Set = egs_quests_db:set(QuestID, ZoneID, SetID),
	Objects = create_units(Set),
	{ok, #state{setid=SetID}}.

handle_call(setid, _From, State) ->
	{reply, State#state.setid, State};

handle_call(stop, _From, State) ->
	{stop, normal, stopped, State};

handle_call(_Request, _From, State) ->
	{reply, ignored, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% Internal.

%% @doc Return a random setid from a list of chances per set.
rand_setid(Sets) ->
	N = crypto:rand_uniform(1, lists:sum(Sets)),
	rand_setid(N, Sets, 0).
rand_setid(N, [Set|_Tail], I) when N < Set ->
	I;
rand_setid(N, [Set|Tail], I) ->
	rand_setid(N - Set, Tail, I + 1).

%% @doc Create the objects for all units in a set.
create_units(Set) ->
	create_units(Set, 0, []).
create_units([], _MapNb, Acc) ->
	lists:flatten(lists:reverse(Acc));
create_units([{{map, _MapID}, Groups}|Tail], MapNb, Acc) ->
	MapObjects = create_groups(Groups, MapNb),
	create_units(Tail, MapNb + 1, [MapObjects|Acc]).

%% @doc Create the objects for all groups in a unit.
create_groups(Groups, MapNb) ->
	create_groups(Groups, MapNb, 0, []).
create_groups([], _MapNb, _GroupNb, Acc) ->
	lists:flatten(lists:reverse(Acc));
create_groups([Objects|Tail], MapNb, GroupNb, Acc) ->
	GroupObjects = create_objects(Objects, MapNb, GroupNb),
	create_groups(Tail, MapNb, GroupNb + 1, [GroupObjects|Acc]).

%% @doc Create the given objects.
create_objects(Objects, MapNb, GroupNb) ->
	create_objects(Objects, MapNb, GroupNb, 0, []).
create_objects([], _MapNb, _GroupNb, _ObjectNb, Acc) ->
	lists:reverse(Acc);
create_objects([{ObjType, ObjPos, ObjRot, ObjParams}|Tail], MapNb, GroupNb, ObjectNb, Acc) ->
	Object = create_object(ObjType, ObjPos, ObjRot, ObjParams),
	create_objects(Tail, MapNb, GroupNb, ObjectNb + 1, [{{MapNb, GroupNb, ObjectNb}, Object}|Acc]).

%% @doc Create the given object.
create_object(ObjType, ObjPos, ObjRot, ObjParams) ->
	{undefined, ObjType}.

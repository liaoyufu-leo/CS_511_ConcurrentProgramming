% Yufu Liao 10478967
% Jiyuan Xia 10468319

-module(shipping).
-compile(export_all).
-include_lib("./shipping.hrl").

get_ship(Shipping_State, Ship_ID) ->
    lists:keyfind(Ship_ID, #ship.id, Shipping_State#shipping_state.ships).

get_container(Shipping_State, Container_ID) ->
	lists:keyfind(Container_ID, #container.id, Shipping_State#shipping_state.containers).

get_port(Shipping_State, Port_ID) ->
	lists:keyfind(Port_ID, #port.id, Shipping_State#shipping_state.ports).

get_occupied_docks(Shipping_State, Port_ID) ->
	lists:filtermap(fun(X) ->
		case X of
			{Port_ID, Dock, _ship} -> {true, Dock};
			_ -> false
		end
	end, Shipping_State#shipping_state.ship_locations).	

get_ship_location(Shipping_State, Ship_ID) ->
	[List] = lists:filtermap(fun(X) ->
		case X of
			{Port_ID, Dock, Ship_ID} -> {true, {Port_ID, Dock}};
			_ -> false
		end
	end, Shipping_State#shipping_state.ship_locations),
	%% result is a tuple within a list, so return just the tuple
	List.

sum([]) ->
	0;
sum([H|T]) ->
	H+sum(T).

len([]) ->
	0;
len([_H|T]) ->
	1+len(T).

get_head_list([]) ->
	[];
get_head_list([H|_T]) ->
	H.
get_container_weight(Shipping_State, Container_IDs)  ->
	lists:foldl(fun(ID, Weight) ->
		Weight + (get_container(Shipping_State,ID))#container.weight end,
	0,
	Container_IDs).
			

get_ship_weight(Shipping_State, Ship_ID) ->
	Containers = maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory),
   	get_container_weight(Shipping_State, Containers).

load_ship_helper(Shipping_State, Ship_ID, Container_IDs) ->
	{Port_ID,_Dock} = get_ship_location(Shipping_State, Ship_ID),
	{ok,#shipping_state{
		ships = Shipping_State#shipping_state.ships,
		containers = Shipping_State#shipping_state.containers,
		ports = Shipping_State#shipping_state.ports,
		ship_locations = Shipping_State#shipping_state.ship_locations,
		ship_inventory = maps:put(Ship_ID,
			%% add containers to ship
				lists:append(maps:get(Ship_ID,Shipping_State#shipping_state.ship_inventory),Container_IDs),
				Shipping_State#shipping_state.ship_inventory),
		port_inventory = maps:put(Port_ID,
			%% remove containers from port
				lists:subtract(maps:get(Port_ID,Shipping_State#shipping_state.port_inventory),Container_IDs),
				Shipping_State#shipping_state.port_inventory)}}.

correct_port(Shipping_State, Ship_ID, Container_IDs) ->
	%% returns true if the Container_IDs match the containers at the port that the ship is at
	{Port_ID, _Dock} = get_ship_location(Shipping_State, Ship_ID),
	Port_Containers = maps:get(Port_ID, Shipping_State#shipping_state.port_inventory),
	is_sublist(Port_Containers, Container_IDs).

check_capacity(Shipping_State, Ship_ID, Container_IDs) ->
	%% returns true if adding the containers would not put the ship over capacity
	Ship_Capacity = (get_ship(Shipping_State,Ship_ID))#ship.container_cap,
	Containers_On_Ship = length(maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory)),
	Containers_Loading = length(Container_IDs),
	Difference = Ship_Capacity - Containers_On_Ship - Containers_Loading,
	Difference >= 0.

load_ship(Shipping_State, Ship_ID, Container_IDs) ->
	case correct_port(Shipping_State, Ship_ID, Container_IDs) of
		false -> error;
		true -> case check_capacity(Shipping_State, Ship_ID, Container_IDs) of
			false -> error;
			true -> load_ship_helper(Shipping_State, Ship_ID, Container_IDs)
		end
	end.
	
unload_ship_helper(Shipping_State, Ship_ID, Container_IDs) ->
	{Port_ID,_Dock} = get_ship_location(Shipping_State, Ship_ID),
	{ok,#shipping_state{
		ships = Shipping_State#shipping_state.ships,
		containers = Shipping_State#shipping_state.containers,
		ports = Shipping_State#shipping_state.ports,
		ship_locations = Shipping_State#shipping_state.ship_locations,
		ship_inventory = maps:put(Ship_ID,
			%% remove containers from ship
				lists:subtract(maps:get(Ship_ID,Shipping_State#shipping_state.ship_inventory),Container_IDs),
				Shipping_State#shipping_state.ship_inventory),
		port_inventory = maps:put(Port_ID,
			%% add containers to port
				lists:append(maps:get(Port_ID,Shipping_State#shipping_state.port_inventory),Container_IDs),
				Shipping_State#shipping_state.port_inventory)}}.
	
check_capacity_port(Shipping_State, Ship_ID, Container_IDs) ->
	%% returns true if adding the containers would not put the port over capacity
	{Port_ID,_Dock} = get_ship_location(Shipping_State, Ship_ID),
	Port_Capacity = (get_port(Shipping_State,Port_ID))#port.container_cap,
	Containers_Loading = length(Container_IDs),
	Containers_On_Port = length(maps:get(Port_ID, Shipping_State#shipping_state.port_inventory)),
	Difference = Port_Capacity - Containers_Loading - Containers_On_Port,
	Difference >= 0.

check_containers_on_ship(Shipping_State, Ship_ID, Container_IDs) ->
	Ship_Inventory = maps:get(Ship_ID,Shipping_State#shipping_state.ship_inventory),
	is_sublist(Ship_Inventory, Container_IDs).

unload_ship_all(Shipping_State, Ship_ID) ->
	case check_capacity_port(Shipping_State, Ship_ID, maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory)) of
		false -> error;
		true -> unload_ship_helper(Shipping_State, Ship_ID, maps:get(Ship_ID, Shipping_State#shipping_state.ship_inventory))
	end.

unload_ship(Shipping_State, Ship_ID, Container_IDs) ->
	case check_capacity_port(Shipping_State, Ship_ID, Container_IDs) of
		false -> error;
		true -> case check_containers_on_ship(Shipping_State, Ship_ID, Container_IDs) of
			false -> error;
			true -> unload_ship_helper(Shipping_State, Ship_ID, Container_IDs)
			end
		end.
			
get_all_locations(Shipping_State) ->
	List = lists:filtermap(fun(X) ->
		case X of
			{Port_ID, Dock, _} -> {true, {Port_ID, Dock}};
			_ -> false
		end
	end, Shipping_State#shipping_state.ship_locations),
	%% result is a tuple within a list, so return just the tuple
	List.



is_occupied(Shipping_State, {Port_ID, Dock}) ->
	%% returns true if the port is occupied and the ship is NOT able to set sail there
	Ship_Locations = get_all_locations(Shipping_State),
	is_sublist(Ship_Locations, [{Port_ID, Dock}]).

new_locations(Shipping_State, Ship_ID, {Port_ID, Dock}) ->
	Locations = Shipping_State#shipping_state.ship_locations,
	lists:foldr(fun({Cur_port,Cur_dock,Cur_ship},Temp_locations) ->
		case Cur_ship of
			Ship_ID -> [{Port_ID,Dock,Ship_ID}|Temp_locations];
			_ -> [{Cur_port,Cur_dock,Cur_ship}|Temp_locations]
		end
	end, [], Locations).

set_sail_helper(Shipping_State, Ship_ID, {Port_ID, Dock}) ->
	{ok, #shipping_state{
		ships = Shipping_State#shipping_state.ships,
		containers = Shipping_State#shipping_state.containers,
		ports = Shipping_State#shipping_state.ports,
		ship_locations = new_locations(Shipping_State, Ship_ID, {Port_ID, Dock}),
		ship_inventory = Shipping_State#shipping_state.ship_inventory,
		port_inventory = Shipping_State#shipping_state.port_inventory}}.

set_sail(Shipping_State, Ship_ID, {Port_ID, Dock}) ->
	case is_occupied(Shipping_State, {Port_ID, Dock}) of
		true -> error;
		false -> set_sail_helper(Shipping_State, Ship_ID, {Port_ID, Dock})
	end.



%% Determines whether all of the elements of Sub_List are also elements of Target_List
%% @returns true is all elements of Sub_List are members of Target_List; false otherwise
is_sublist(Target_List, Sub_List) ->
    lists:all(fun (Elem) -> lists:member(Elem, Target_List) end, Sub_List).




%% Prints out the current shipping state in a more friendly format
print_state(Shipping_State) ->
    io:format("--Ships--~n"),
    _ = print_ships(Shipping_State#shipping_state.ships, Shipping_State#shipping_state.ship_locations, Shipping_State#shipping_state.ship_inventory, Shipping_State#shipping_state.ports),
    io:format("--Ports--~n"),
    _ = print_ports(Shipping_State#shipping_state.ports, Shipping_State#shipping_state.port_inventory).


%% helper function for print_ships
get_port_helper([], _Port_ID) -> error;
get_port_helper([ Port = #port{id = Port_ID} | _ ], Port_ID) -> Port;
get_port_helper( [_ | Other_Ports ], Port_ID) -> get_port_helper(Other_Ports, Port_ID).


print_ships(Ships, Locations, Inventory, Ports) ->
    case Ships of
        [] ->
            ok;
        [Ship | Other_Ships] ->
            {Port_ID, Dock_ID, _} = lists:keyfind(Ship#ship.id, 3, Locations),
            Port = get_port_helper(Ports, Port_ID),
            {ok, Ship_Inventory} = maps:find(Ship#ship.id, Inventory),
            io:format("Name: ~s(#~w)    Location: Port ~s, Dock ~s    Inventory: ~w~n", [Ship#ship.name, Ship#ship.id, Port#port.name, Dock_ID, Ship_Inventory]),
            print_ships(Other_Ships, Locations, Inventory, Ports)
    end.

print_containers(Containers) ->
    io:format("~w~n", [Containers]).

print_ports(Ports, Inventory) ->
    case Ports of
        [] ->
            ok;
        [Port | Other_Ports] ->
            {ok, Port_Inventory} = maps:find(Port#port.id, Inventory),
            io:format("Name: ~s(#~w)    Docks: ~w    Inventory: ~w~n", [Port#port.name, Port#port.id, Port#port.docks, Port_Inventory]),
            print_ports(Other_Ports, Inventory)
    end.
%% This functions sets up an initial state for this shipping simulation. You can add, remove, or modidfy any of this content. This is provided to you to save some time.
%% @returns {ok, shipping_state} where shipping_state is a shipping_state record with all the initial content.
shipco() ->
    Ships = [#ship{id=1,name="Santa Maria",container_cap=20},
              #ship{id=2,name="Nina",container_cap=20},
              #ship{id=3,name="Pinta",container_cap=20},
              #ship{id=4,name="SS Minnow",container_cap=20},
              #ship{id=5,name="Sir Leaks-A-Lot",container_cap=20}
             ],
    Containers = [
                  #container{id=1,weight=200},
                  #container{id=2,weight=215},
                  #container{id=3,weight=131},
                  #container{id=4,weight=62},
                  #container{id=5,weight=112},
                  #container{id=6,weight=217},
                  #container{id=7,weight=61},
                  #container{id=8,weight=99},
                  #container{id=9,weight=82},
                  #container{id=10,weight=185},
                  #container{id=11,weight=282},
                  #container{id=12,weight=312},
                  #container{id=13,weight=283},
                  #container{id=14,weight=331},
                  #container{id=15,weight=136},
                  #container{id=16,weight=200},
                  #container{id=17,weight=215},
                  #container{id=18,weight=131},
                  #container{id=19,weight=62},
                  #container{id=20,weight=112},
                  #container{id=21,weight=217},
                  #container{id=22,weight=61},
                  #container{id=23,weight=99},
                  #container{id=24,weight=82},
                  #container{id=25,weight=185},
                  #container{id=26,weight=282},
                  #container{id=27,weight=312},
                  #container{id=28,weight=283},
                  #container{id=29,weight=331},
                  #container{id=30,weight=136}
                 ],
    Ports = [
             #port{
                id=1,
                name="New York",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=2,
                name="San Francisco",
                docks=['A','B','C','D'],
                container_cap=200
               },
             #port{
                id=3,
                name="Miami",
                docks=['A','B','C','D'],
                container_cap=200
               }
            ],
    %% {port, dock, ship}
    Locations = [
                 {1,'B',1},
                 {1, 'A', 3},
                 {3, 'C', 2},
                 {2, 'D', 4},
                 {2, 'B', 5}
                ],
    Ship_Inventory = #{
      1=>[14,15,9,2,6],
      2=>[1,3,4,13],
      3=>[],
      4=>[2,8,11,7],
      5=>[5,10,12]},
    Port_Inventory = #{
      1=>[16,17,18,19,20],
      2=>[21,22,23,24,25],
      3=>[26,27,28,29,30]
     },
    #shipping_state{ships = Ships, containers = Containers, ports = Ports, ship_locations = Locations, ship_inventory = Ship_Inventory, port_inventory = Port_Inventory}.

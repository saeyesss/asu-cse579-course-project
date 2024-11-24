% cabinets in use must be from the new domains
{ cabinet(C) : cabinetDomainNew(C) }.
{ room(R) : roomDomainNew(R) }.
% get things and persons from legacy config
thing(T) :- legacyConfig(thing(T)).
person(P) :- legacyConfig(person(P)).

% one thing must only be in exactly one cabinet
1 { cabinetTOthing(C,T) : cabinet(C) } 1 :- thing(T).
% one cabinet cannot have more than 5 things
:- #count{ T : cabinetTOthing(C,T) } > 5, cabinet(C).
% every cabinet in use must be in exactly one room
1 { roomTOcabinet(R,C) : room(R) } 1 :- cabinet(C).
% cabinet must be in use if it has things
:- cabinetTOthing(C,TT), not cabinet(C).
% room must be in use if it has cabinets
:- roomTOcabinet(R,CC), not room(R).
% one room cannot have more than 4 cabinets
:- #count{ C : roomTOcabinet(R,C) } > 4, room(R).

% define person P of room R as roomOwner 
roomOwner(R,P) :- room(R),
                  person(P),
                  roomTOcabinet(R,C),
                  cabinetTOthing(C,T),
                  legacyConfig(personTOthing(P,T)).

% single owner per room
:- room(R), roomOwner(R,P1), roomOwner(R,P2), P1 != P2.

% room contents belong to the room owner only
:- roomTOcabinet(R,C),
   cabinetTOthing(C,T),
   legacyConfig(personTOthing(P1,T)),
   roomOwner(R,P2),
   P1 != P2.

% cabinet is by default high unless specifically given as small
{ cabinetHigh(C) } :- cabinet(C).
cabinetSmall(C) :- cabinet(C), not cabinetHigh(C).


% costs for creating rooms and cabinets
newCabinetCost(NC) :- NC = #sum{
    HC,C : cabinet(C), not legacyConfig(cabinet(C)), cabinetHigh(C), cabinetHighCost(HC);
    SC,C : cabinet(C), not legacyConfig(cabinet(C)), cabinetSmall(C), cabinetSmallCost(SC)
}.
newRoomCost(NR) :- NR = #sum{COST,R : room(R), not legacyConfig(room(R)), roomCost(COST)}.

totalCost(NC + NR) :- newCabinetCost(NC), newRoomCost(NR).
% room slots available = 4, high cabinet uses 2, small uses 1
roomSlots(R,S) :- room(R), 
    S = #sum{ 2,C : roomTOcabinet(R,C), cabinetHigh(C);
              1,C : roomTOcabinet(R,C), cabinetSmall(C) }.
:- room(R), roomSlots(R,S), S > 4.

#minimize { COST : totalCost(COST) }.

#show cabinet/1.
#show room/1.
#show cabinetTOthing/2.
#show roomTOcabinet/2.
#show totalCost/1.
% #show person/1.
% #show thing/1.

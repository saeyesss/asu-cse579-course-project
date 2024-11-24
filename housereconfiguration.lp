% cabinet, rooms must include both new and old domains but restrict domains to reduce grounding 
{ cabinet(C) : cabinetDomainNew(C) }.{ cabinet(C) : legacyConfig(cabinet(C)) }.
{ room(R) : roomDomainNew(R) }.{ room(R) : legacyConfig(room(R)) }.
% get things and persons from legacy config
thing(T) :- legacyConfig(thing(T)).
person(P) :- legacyConfig(person(P)).


personThings(P,T) :- legacyConfig(personTOthing(P,T)).

% assignment rules
% one thing must be stored in exactly one cabinet
1 { cabinetTOthing(C,T) : cabinet(C) } 1 :- thing(T). 
% every cabinet in use must be in exactly one room
1 { roomTOcabinet(R,C) : room(R) } 1 :- cabinet(C).
% cabinet must be in use if it has things
:- cabinetTOthing(C,TT), not cabinet(C).
% room must be in use if it has cabinets
:- roomTOcabinet(R,CC), not room(R).

% cabinet size rules; it is by default high unless specifically given as small
{ cabinetHigh(C) } :- cabinet(C).
cabinetSmall(C) :- cabinet(C), not cabinetHigh(C).
% capacity constraints. less than 5 and less than 4 assignments respectively. 
:- #count{ T : cabinetTOthing(C,T) } > 5,cabinet(C).
:- #count{ C : roomTOcabinet(R,C) } > 4, room(R).
% thing length constraints, thingShort is optionally given in input so by default all things are long
thingLong(T) :- thing(T), not thingShort(T).
thingShort(T) :- thing(T), not thingLong(T).
:- cabinetTOthing(C,T), thingLong(T), not cabinetHigh(C).

% room slot constraints available = 4, high cabinet uses 2, small uses 1
:- room(R), 
   #sum{ 2,HC : roomTOcabinet(R,HC), cabinetHigh(HC);
         1,SC : roomTOcabinet(R,SC), cabinetSmall(SC) } > 4.

% define person P of room R as roomOwner  
roomOwner(R,P) :- room(R), person(P),
                  roomTOcabinet(R,C),
                  cabinetTOthing(C,T),
                  personThings(P,T). % used simplified predicate to speed up calculation
% single owner per room constraint
:- room(R), roomOwner(R,P1), roomOwner(R,P2), P1 != P2. % TODO < or !=

% things belonging to owner constraint
:- roomTOcabinet(R,C),
   cabinetTOthing(C,T),
   personThings(P1,T),
   roomOwner(R,P2),
   P1 != P2.

% cost calculations
% cost for creating new cabs
newCabHighCost(NHC) :- NHC = #sum{ HC,C : cabinet(C), not legacyConfig(cabinet(C)), 
                                        cabinetHigh(C), cabinetHighCost(HC) }.
newCabSmallCost(NSC) :- NSC = #sum{ SC,C : cabinet(C), not legacyConfig(cabinet(C)), 
                                         cabinetSmall(C), cabinetSmallCost(SC) }.
newCabinetCost(NCC) :- newCabHighCost(NHC), newCabSmallCost(NSC), NCC = NHC + NSC.
% cost for creating new rooms
newRoomCost(NRC) :- NRC = #sum{ COST,R : room(R), not legacyConfig(room(R)), roomCost(COST) }.

% costs for reusing cabs
reuseCabHighCost(RUHC) :- RUHC = #sum{ HC,C : cabinet(C), legacyConfig(cabinet(C)), 
                                         cabinetHigh(C), reuseCabinetAsHighCost(HC) }.
reuseCabSmallCost(RUSC) :- RUSC = #sum{ SC,C : cabinet(C), legacyConfig(cabinet(C)), 
                                          cabinetSmall(C), reuseCabinetAsSmallCost(SC) }.
reuseCabinetCost(RUCC) :- reuseCabHighCost(RUHC), reuseCabSmallCost(RUSC), RUCC = RUHC + RUSC.
% costs for reusing rooms
reuseRoomCost(RURC) :- RURC = #sum{ RC,R : room(R), legacyConfig(room(R)), reuseRoomCost(RC) }.

%costs for removing cabs and rooms
removeCabinetsCost(RCC) :- RCC = #sum{ RC,C : not cabinet(C), legacyConfig(cabinet(C)), removeCabinetCost(RC)}.
removeRoomsCost(RRC) :- RRC = #sum{ RC,R : not room(R), legacyConfig(room(R)), removeRoomCost(RC) }.

removeThingAssignmentCost(RTAC) :- RTAC = #sum{ RCTC,C,T : not cabinetTOthing(C,T), 
                                                    legacyConfig(cabinetTOthing(C,T)), 
                                                    removeCabinetTOthingCost(RCTC) }.
removeCabinetAssignmentCost(RCAC) :- RCAC = #sum{ RRCC,R,C : not roomTOcabinet(R,C), 
                                                      legacyConfig(roomTOcabinet(R,C)), 
                                                      removeRoomTOcabinetCost(RRCC) }.

% calculate total cost by adding up all the component costs
totalCost(TC) :- newCabinetCost(NCC), newRoomCost(NRC),
                 reuseCabinetCost(RUCC), reuseRoomCost(RURC),
                 removeCabinetsCost(RCC), removeRoomsCost(RRC),
                 removeThingAssignmentCost(RTAC), removeCabinetAssignmentCost(RCAC),
                 TC = NCC + NRC + RUCC + RURC + RCC + RRC + RTAC + RCAC.
                 
% now the optimization directive by minimizing the total cost of this reconfiguration.



#minimize { TC : totalCost(TC) }.

#show totalCost/1.
#show room/1.
#show cabinet/1.
#show cabinetHigh/1.
#show cabinetSmall/1.
#show cabinetTOthing/2.
#show roomTOcabinet/2.

--
-- Created by IntelliJ IDEA.
-- User: iThorgrim
-- Date: 18/08/2020
-- Time: 10:10
-- To change this template use File | Settings | File Templates.
--

local ArenaV1 = {};

-- Thanks Kazuma ! https://github.com/Open-Wow/forum/issues/6
ArenaV1['waiting'] = {
    player = 0,
    list = {},
};

ArenaV1['locale'] = {
    [0] = 'minute(s) restantes',
    [1] = ' seconde(s) restantes',
    [2] = 'Vous a quitté la zone, vous perdez le match par forfait.',
    [3] = ' a quitté la zone, vous gagnez le match par forfait.',
    [4] = 'Vous avez gagné le match!',
    [5] = 'Vous avez perdu le match!',
};

function ArenaV1.buildARray(pGuid)
    if(not(ArenaV1[pGuid]))then
        ArenaV1[pGuid] = {
            type = nil,
        }
    end
end

function ArenaV1.buildPhase()
    if(not(ArenaV1['phases']))then
        ArenaV1['phases'] = {};

        local count = 1;
        for i=1, 31 do
            count = count * 2;
            ArenaV1['phases'][i] = {};
            ArenaV1['phases'][i].phase = count;
            ArenaV1['phases'][i].active = 0
        end
    end
end

function ArenaV1.onGossipHello(event, player, object)
    local pGuid = player:GetGUIDLow();
    ArenaV1.buildARray(pGuid);

    player:GossipSetText("                   Arène 1v1 |-");

    if (ArenaV1[pGuid].type == 0) then
        player:GossipMenuAddItem(5, 'Se désinscrire de  l\'escamourche', 0, 99);
        player:GossipMenuAddItem(5, 'S\'inscrire en match côté', 0, 100);
    elseif (ArenaV1[pGuid].type == 1)then
        player:GossipMenuAddItem(5, 'S\'inscrire en escamourche', 0, 100);
        player:GossipMenuAddItem(5, 'Se désinscrire du match côté', 0, 99);
    else
        player:GossipMenuAddItem(5, 'S\'inscrire en escamourche', 0, 100);
        player:GossipMenuAddItem(5, 'S\'inscrire en match côté', 0, 100);
    end
    player:GossipSendMenu(0x7FFFFFFF, object);
end
RegisterCreatureGossipEvent(197, 1, ArenaV1.onGossipHello);

function ArenaV1.sendAwards(player)

    local pGuid = player:GetGUIDLow();

    local challenger = GetPlayerByGUID(ArenaV1[pGuid].challenger);
    local cGuid = challenger:GetGUIDLow();

    ArenaV1.buildARray(pGuid);
    ArenaV1.buildARray(cGuid);

    ArenaV1[cGuid].lastChallenger = pGuid;
    challenger:RemoveEvents();
    challenger:ResurrectPlayer(100);
    challenger:SetPhaseMask(ArenaV1[cGuid].position.p)
    challenger:Teleport(ArenaV1[cGuid].position.m, ArenaV1[cGuid].position.x, ArenaV1[cGuid].position.y, ArenaV1[cGuid].position.z, ArenaV1[cGuid].position.o)

    ArenaV1[pGuid].lastChallenger =  ArenaV1[pGuid].challenger;
    player:RemoveEvents();
    player:ResurrectPlayer(100);
    player:SetPhaseMask(ArenaV1[pGuid].position.p)
    player:Teleport(ArenaV1[pGuid].position.m, ArenaV1[pGuid].position.x, ArenaV1[pGuid].position.y, ArenaV1[pGuid].position.z, ArenaV1[pGuid].position.o)

    ArenaV1['phases'][ArenaV1[pGuid].phase].active = 0;

    ArenaV1[pGuid].phase = 0;
    ArenaV1[ArenaV1[pGuid].challenger].phase = 0;
end

function ArenaV1.onPlayerDeath(event, player, challenger)
    local pGuid = player:GetGUIDLow();
    local cGuid = challenger:GetGUIDLow();

    ArenaV1.buildARray(pGuid);
    ArenaV1.buildARray(cGuid);

    if(ArenaV1[pGuid].phase ~= nil or ArenaV1[pGuid] ~= 0)then
        player:SendBroadcastMessage(ArenaV1['locale'][4])
        challenger:SendBroadcastMessage(ArenaV1['locale'][5])
        ArenaV1.sendAwards(player)
    end
end
RegisterPlayerEvent(6, ArenaV1.onPlayerDeath);


function ArenaV1.getLeave(eventid, delay, repeats, player)
    if (player:GetAreaId() ~= 2177)then
        player:SendNotification(ArenaV1['locale'][2]);
        GetPlayerByGUID(ArenaV1[player:GetGUIDLow()].challenger):SendNotification(''..player:GetName()..ArenaV1['locale'][3]);
        ArenaV1.sendAwards(player);
    end
end

function ArenaV1.registerEvents(eventid, delay, repeats, player)
    local Choices = {
        [1] = function()
            local calc_1 = ((delay * repeats) /1000)/60;
            player:SendNotification(calc_1..ArenaV1['locale'][0]);
        end,

        [2] = function()
            player:SendNotification(repeats..ArenaV1['locale'][1]);
            if (ArenaV1[player:GetGUIDLow()].challenger and repeats == 1)then
                -- Player Locales
                local pGuid = player:GetGUIDLow();

                -- Challenger Locales
                local challenger = GetPlayerByGUID(ArenaV1[player:GetGUIDLow()].challenger);
                local cGuid = challenger:GetGUIDLow();
                ArenaV1[cGuid].challenger =  pGuid;

                for i=1, 31 do
                    if (ArenaV1['phases'][i].active == 0)then
                        challenger:Teleport(0, -13184.362305, 311.535217, 21.85782, 0);
                        challenger:SetPhaseMask(ArenaV1['phases'][i].phase);
                        ArenaV1[cGuid].phase = i;

                        player:Teleport(0, -13223.779297, 237.197540, 21.85782, 0);
                        player:SetPhaseMask(ArenaV1['phases'][i].phase);
                        ArenaV1[pGuid].phase = i;

                        ArenaV1['phases'][i].active = 1;

                        ArenaV1[pGuid].action = 1;
                        ArenaV1[cGuid].action = 1

                        challenger:RegisterEvent(ArenaV1.getLeave, 1000, 900000);
                        player:RegisterEvent(ArenaV1.getLeave, 1000, 900000);

                        challenger:RegisterEvent(ArenaV1.registerEvents, 30000, 2);
                        player:RegisterEvent(ArenaV1.registerEvents, 30000, 2);
                        break;
                    end
                end
            end
        end,
    };
    Choices[ArenaV1[player:GetGUIDLow()].action]();
end

-- ArenaV1.alertTimeLeft = Choices[1]();
-- ArenaV1.alertBeforeTp = Choices[2]();
-- ArenaV1.changeArea = Choices[3]();

function ArenaV1.onGossipSelect(event, player, object, sender, intid, code, menu_id)
    local pGuid = player:GetGUIDLow();

    if(intid == 100)then
        ArenaV1['waiting'].player = ArenaV1['waiting'].player + 1;
        ArenaV1['waiting'].list[player:GetGUIDLow()] = {};

        if (ArenaV1['waiting'].player == 2)then
            for k, v in pairs(ArenaV1['waiting']) do
                if (type(v) == 'table')then
                    for k, v in pairs(v) do
                        if (k ~= pGuid and ArenaV1[pGuid].lastChallenger ~= k and ArenaV1[k].lastChallenger ~= pGuid)then
                            ArenaV1['waiting'].player = ArenaV1['waiting'].player - 2;
                            ArenaV1['waiting'].list[k] = nil;
                            ArenaV1['waiting'].list[pGuid] = nil;

                            ArenaV1[k].action = 2;
                            ArenaV1[k].position = {
                                x = GetPlayerByGUID(k):GetX(), -- Position X
                                y = GetPlayerByGUID(k):GetY(), -- Position Y
                                z = GetPlayerByGUID(k):GetZ(), -- Position Z
                                o = GetPlayerByGUID(k):GetO(), -- Orientation
                                m = GetPlayerByGUID(k):GetMapId(), -- Maps
                                p = GetPlayerByGUID(k):GetPhaseMask(), -- Phase
                            };

                            ArenaV1[pGuid].challenger =  k;
                            ArenaV1[pGuid].action = 2;
                            ArenaV1[pGuid].position = {
                                x = player:GetX(), -- Position X
                                y = player:GetY(), -- Position Y
                                z = player:GetZ(), -- Position Z
                                o = player:GetO(), -- Orientation
                                m = player:GetMapId(), -- Maps
                                p = player:GetPhaseMask(), -- Phase
                            };

                            player:RegisterEvent(ArenaV1.registerEvents, 1000, 5);
                            GetPlayerByGUID(k):RegisterEvent(ArenaV1.registerEvents, 1000, 5);
                        end
                    end
                end
            end
        end
    end
end
RegisterCreatureGossipEvent(197, 2, ArenaV1.onGossipSelect);
ArenaV1.buildPhase()

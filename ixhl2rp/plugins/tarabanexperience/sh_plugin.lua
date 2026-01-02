local PLUGIN = PLUGIN

PLUGIN.name = "Taraban Experience"
PLUGIN.description = "Forces Autonomous's gamemode to be like CS"

ix.config.Add("tarabanMaxHeavy", 3, "The maximum number of heavy class.", nil, {
	data = {min = 0, max = 50},
	category = "taraban"
})

ix.config.Add("tarabanMaxMedium", 5, "The maximum number of medium class.", nil, {
	data = {min = 0, max = 50},
	category = "taraban"
})

ix.config.Add("tarabanLifesPerRound", 100, "The maximum number of lifes per side.", nil, {
	data = {min = 1, max = 1000},
	category = "taraban"
})

ix.config.Add("tarabanallowSwitchTeamPerMatch", false, "Allow switch team per match.", nil, {
	category = "taraban"
})

PLUGIN.teams = {
    combine = 1,
    resistance = 2,
}

local function trimName(str)
    if (str:utf8len() > 3) then
        return str:utf8sub(1, 4):utf8upper()
    end

    return str:utf8upper()
end

PLUGIN.equipItems = {
    light = {
        [PLUGIN.teams.combine] = {
            random = {
                "mpf_engineer",
                "mpf_medic",
                "mpf_investigator",
            },
            not_random = {
                "mp7",
                "uspmatch",
                "stunstick",
            },
            name = function(client)
                return Format("STAB-FORCE-10.i4-%s", trimName(client:SteamName()))
            end
        },
        [PLUGIN.teams.resistance] = {
            random = {
                "padded_blue_jeans",
                "padded_green_jeans",
            },
            not_random = {
                "torso_armor_tier0",
                "head_helmet_tier1",
                "mp7",
                "uspmatch",
                "crowbar",
            },
            name = function(client)
                return Format("PvT. \"%s\"", client:SteamName())
            end
        },
    },
    medium = {
        [PLUGIN.teams.combine] = {
            random = {
                {"mp7", "uspmatch"},
                {"shotgun", "magnum"},
            },
            not_random = {
                "mpf_i1",
                "stunstick",
            },
            name = function(client)
                return Format("STAB-FORCE-10.i2-%s", trimName(client:SteamName()))
            end
        },
        [PLUGIN.teams.resistance] = {
            random = {
                {"mp7", "uspmatch", "torso_armor2_tier1", "padded_green_jeans"},
                {"shotgun", "magnum", "torso_medic_tier1", "padded_blue_jeans"},
            },
            not_random = {
                "crowbar",
                "head_helmet_tier2",
            },
            name = function(client)
                return Format("SgT. \"%s\"", client:SteamName())
            end
        },
    },
    heavy = {
        [PLUGIN.teams.combine] = {
            not_random = {
                "ar2",
                "magnum",
                "mpf_support_ofc",
                "stunstick",
            },
            name = function(client)
                return Format("STAB-FORCE-10.is-%s", trimName(client:SteamName()))
            end
        },
        [PLUGIN.teams.resistance] = {
            not_random = {
                "head_helmet_tier3",
                "padded_blue_jeans",
                "torso_armor_tier3",
                "m4a4",
                "magnum",
                "crowbar",
            },
            name = function(client)
                return Format("Lt. \"%s\"", client:SteamName())
            end
        },
    },
    custom = {
        [PLUGIN.teams.combine] = {
            not_random = {
                "ar2",
                "magnum",
                "mpf_sf",
            },
            name = function(client)
                return Format("STAB-FORCE-10.sF-%s", trimName(client:SteamName()))
            end
        },
        [PLUGIN.teams.resistance] = {
            not_random = {
                "head_helmet_tier3",
                "padded_blue_jeans",
                "torso_armor_tier3",
                "m4a4",
                "magnum",
                "crowbar",
            },
            name = function(client)
                return Format("Lt. \"%s\"", client:SteamName())
            end
        },
    }
}

ix.chat.Register("killedByCombine", {
	CanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(0,110,255), text)
	end,
	noSpaceAfter = true
})

ix.chat.Register("killedByResistance", {
	CanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255,165,0), text)
	end,
	noSpaceAfter = true
})

ix.Net:AddGlobalVar("taraban.combinelifes", false, nil, ix.Net.Type.All)
ix.Net:AddGlobalVar("taraban.resistancelifes", false, nil, ix.Net.Type.All)

ix.Net:AddPlayerVar("taraban.kills", false, nil, ix.Net.Type.All)
ix.Net:AddPlayerVar("taraban.deaths", false, nil, ix.Net.Type.All)

ix.Net:AddPlayerVar("taraban.team", false, nil, ix.Net.Type.All)
ix.Net:AddPlayerVar("taraban.preset", false, nil, ix.Net.Type.All)


local function fixItemClass(itemUniqueId, newWeaponClass)
    ix.Item.stored[itemUniqueId].class = newWeaponClass
end

local toFix = {
    stunstick = "tfa_autonomous_stunstick",
    mp7 = "tfa_autonomous_ak9",
    shotgun = "tfa_autonomous_spas12",
    rpg = "tfa_autonomous_rpg",
    uspmatch = "tfa_autonomous_usp",
    magnum = "tfa_autonomous_357",
    ar2 = "tfa_hl2_ar2",
    m4a4 = "tfa_autonomous_ak103",
    frag_grenade = "tfa_autonomous_frag_m67"
}

for k,v in pairs(toFix)do
    fixItemClass(k, v)
end

function PLUGIN:GetTeamCount(teamId)
    local playersPerSide = 0

    for k,v in ipairs(player.GetAll())do
        if (v:GetNetVar("taraban.team" == teamId)) then
            playersPerSide = playersPerSide + 1
        end
    end

    return playersPerSide
end

function PLUGIN:IsTeamOverflow(teamId)
    if (!teamId) then
        return false
    end

    local curTeam = teamId == self.teams.combine && self.teams.combine || self.teams.resistance
    local enemyTeam = teamId == self.teams.combine && self.teams.resistance || self.teams.combine

    local countThisTeam = self:GetTeamCount(curTeam)
    local countEnemies = self:GetTeamCount(enemyTeam)

    if (countThisTeam > (countEnemies + 2)) then
        return false
    end

    return true
end

PLUGIN.steamIds = {}

function PLUGIN:CanSwitchTeam(client, lastTeam, newTeam)
    if ((!lastTeam && newTeam) || ix.config.Get("tarabanallowSwitchTeamPerMatch", false) || (self.steamIds[client:SteamID64()] && self.steamIds[client:SteamID64()] == newTeam)) then
        return self:IsTeamOverflow(newTeam)
    end

    if (lastTeam && newTeam) then
        if (lastTeam == newTeam) then
            return true
        end
    end

    return false
end

function PLUGIN:CountClassPlayers(class, teamId)
    local count = 0
    for k,v in ipairs(player.GetAll())do
        local teamVar = v:GetNetVar("taraban.team")
        local classVar = v:GetNetVar("taraban.preset")
        if (teamVar && teamVar == teamId) && (classVar && classVar == class) then
            count = count + 1
        end
    end

    return count
end

function PLUGIN:CanPlayerDropItem()
    return false
end

function PLUGIN:CanSwitchClass(client, lastClass, newClass, teamId)
    if (self.equipItems[newClass]) then
        if (newClass == "heavy") then
            if (self:CountClassPlayers(newClass, teamId) >= ix.config.Get("tarabanMaxHeavy", 3)) then
                return false
            end
        end

        if (newClass == "medium") then
            if (self:CountClassPlayers(newClass, teamId) >= ix.config.Get("tarabanMaxMedium", 5)) then
                return false
            end
        end

        if (newClass == "light") then
            return true
        end

        if (newClass == "custom") then
            return false
        end

        return true
    end

    return false
end

local function forceCustom(client, delayed)
    hook.Run("OnForceCustom", client, delayed)
end

ix.command.Add("TarabanPlyForceCustom", {
	description = "@cmdEvent",
	arguments = {ix.type.player, bit.bor(ix.type.bool, ix.type.optional)},
	adminOnly = true,
	OnRun = function(self, client, target, delayed)
		forceCustom(target, delayed)

        return Format("Вы успешно выставили для %s кастом класс", target:SteamName())
	end
})

ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_plugin.lua")
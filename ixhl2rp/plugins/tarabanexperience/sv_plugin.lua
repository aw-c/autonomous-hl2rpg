local PLUGIN = PLUGIN

local startSkills = {
	["athletics"] = 6,
	["acrobatics"] = 4,
	["guns"] = 5,
	["unarmed"] = 10,
	["medicine"] = 5,
	["meleeguns"] = 10,
	["impulse"] = 5,
}

local startAmmo = {
    bullets_357 = 100,
    bullets_ar2 = 600,
    bullets_buckshot = 180,
    bullets_smg = 600,
    bullets_9mm = 600,
}

local startMedicine = {
    healthkit = 1,
    bandage = 2,
    painkiller = 1,
    morphine = 4,
    epinephrine = 4,
    healthvial = 2,
    bloodbag = 2,
}

local itemsPerKill = {
    healthvial = 1,
    bandage = 1,
    bloodbag = 1,
    mat_armor_plate = 1,
}

local function matchTeamForJoin()
    
end

local function setupPlayer(client)
    local side = client:GetNetVar("taraban.team")
    local class = client:GetNetVar("taraban.preset")

    local charId = os.time() + client:EntIndex()
    local isCombine = side == PLUGIN.teams.combine
    local model = isCombine && "models/cellar/characters/metropolice/male.mdl" || "models/cellar/characters/oldcitizens/male_07.mdl"
	local faction = isCombine && "metropolice" || "citizen"

	local character = ix.char.New({
		name = client:Name(),
		faction = faction,
		model = model
	}, charId, client, client:SteamID64())
	character.isBot = true

	ix.char.loaded[charId] = character

    character:SetLevel(100)

	character:Setup()

    timer.Simple(0, function()
        client:Spawn()
    end)

    netstream.Start(client, "taraban.closeChooseClass")
end

function PLUGIN:PlayerLoadout(client)
    local char = client:GetCharacter()

    if (!char) then
        return
    end

    client.ixReceiveDamageFrom = nil

    client.carryWeapons = nil

    for k,v in ipairs(client:GetItems())do
        v:Remove()
    end
    
    local side = client:GetNetVar("taraban.team")
    local class = client:GetNetVar("taraban.preset")
    local isCombine = side == PLUGIN.teams.combine

    class = client:GetNetVar("taraban.custom") && "custom" || class

    local instance = ix.Item:Instance("bag")
    client:AddItem(instance)
    ix.Item:PerformInventoryAction(client, instance, instance.inventory_id, "equip", nil, 1)

    local preset = PLUGIN.equipItems[class][side]

    if (preset.random) then
        local randomized = math.random(1, #preset.random)
        if (istable(preset.random[randomized])) then
            for k,v in ipairs(preset.random[randomized]) do
                instance = ix.Item:Instance(v)
                client:AddItem(instance)
            end
        else
            instance = ix.Item:Instance(preset.random[randomized])
            client:AddItem(instance)
        end
    end

    if (preset.not_random) then
        for k,v in ipairs(preset.not_random) do
            instance = ix.Item:Instance(v)
            client:AddItem(instance)
        end
    end

    for k,v in ipairs(client:GetItems())do
        if (v.functions.equip) then
            ix.Item:PerformInventoryAction(client, v, v.inventory_id, "equip", nil, 1)
        end
    end
    timer.Simple(.3,function()
        for k,v in ipairs(client:GetWeapons())do
            v:SetClip1(v:GetMaxClip1())
        end

        if (class == "heavy") then
            client:Give("tfa_autonomous_frag_m67")
        end
    end)

    for i=1, 5 do
        instance = ix.Item:Instance("mat_armor_plate")
        client:AddItem(instance)
    end

    for k,v in pairs(startAmmo)do
        instance = ix.Item:Instance(k)
        instance:SetData("stack", v)

        client:AddItem(instance)
    end

    for k,v in pairs(startMedicine)do
        for i=1, v do
            instance = ix.Item:Instance(k)
            client:AddItem(instance)
        end
    end

    if (!isCombine) then
        instance = ix.Item:Instance("flashlight")
        client:AddItem(instance)
    end

    client:GetCharacter():SetName(preset.name(client))

    if (client:GetNetVar("taraban.custom", false)) then
        client:SetNetVar("taraban.custom", false)
    end

    client:SetLocalVar("stm", 300)
end

netstream.Hook("taraban.ChooseSideAndClass", function(client, side, class)
    if (PLUGIN:CanSwitchTeam(client, client:GetNetVar("taraban.team"), side)) then
        if (PLUGIN:CanSwitchClass(client, client:GetNetVar("taraban.preset"), class, side)) then
            PLUGIN.steamIds[client:SteamID64()] = side

            client:SetNetVar("taraban.team", side)
            client:SetNetVar("taraban.preset", class)

            if (client:Alive()) then
                client:Notify("В следующий раз вы возродитесь за выбранный класс и сторону.")
                client.ixShouldBeReSetup = true

                return
            end

            setupPlayer(client)

            return
        end

        return client:Notify("Вы не можете сменить класс!")
    end

    return client:Notify("Вы не можете сменить сторону!")
end)

function PLUGIN:PlayerHurt(client, attacker, health, damage)
    if (IsValid(attacker) && (attacker:IsPlayer())) then
        client.ixReceiveDamageFrom = attacker
        -- client.ixReceiveDamage = client.ixReceiveDamage or {}
        -- client.ixReceiveDamage[attacker] = (client.ixReceiveDamage[attacker] or 0) + damage
    end
end

local function restartRound(winnerTeam)
    for k,v in ipairs(player.GetAll())do
        v.ixShouldBeReSetup = nil
        setupPlayer(v)
    end

    local lifes = ix.config.Get("tarabanLifesPerRound", 100)

    ix.Net:SetVar("taraban.combinelifes", lifes)
    ix.Net:SetVar("taraban.resistancelifes", lifes)
end

function PLUGIN:PostPlayerDeath(client)
    local char = client:GetCharacter()

    if (!char) then
        return
    end

    if !IsValid(client.ixKiller) || !client.ixKiller:IsPlayer() then
        if IsValid(client.ixReceiveDamageFrom) then
            client.ixKiller = client.ixReceiveDamageFrom
        else
            return
        end
    end

    client.ixKiller:SetData("taraban.kills", client.ixKiller:GetData("taraban.kills", 0) + 1)
    client:SetData("taraban.deaths", client:GetData("taraban.deaths", 0) + 1)

    local teamId = client:GetNetVar("taraban.team")

    if (!teamId) then
        return
    end

    local isCombine = teamId == self.teams.combine
    local chatType = isCombine && "killedByResistance" or "killedByCombine"

    ix.chat.Send(nil, chatType, client.ixKiller:Name().." убивает "..client:Name())

    local teamKey = isCombine && "taraban.combinelifes" || "taraban.resistancelifes"

    local curLifes = ix.Net:GetVar(teamKey, 100) - 1
    ix.Net:SetVar(teamKey, curLifes)

    if (client.ixShouldBeReSetup) then
        client.ixShouldBeReSetup = nil
        
        timer.Simple(.3, function()
            setupPlayer(client)
        end)
    end

    if (curLifes < 0) then
        restartRound(isCombine && self.teams.resistance || self.teams.combine)
    end
end

function PLUGIN:OnForceCustom(client, delayed)
    client:SetNetVar("taraban.custom", true)

    if (!delayed) then
        setupPlayer(client)
    end
end

timer.Create("KillInCriticalState", 0.5, 0, function()
    for k,v in ipairs(player.GetAll())do
        if (v:InCriticalState()) then
            timer.Simple(0.3, function()
                v:Kill()
            end)
        end
    end
end)

restartRound()
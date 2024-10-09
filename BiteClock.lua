BiteClock = {}
BiteClock.name = "BiteClock"

local function CheckSkillLine(skillType, skillLineIndex)
    local name, rank, xp, xpForNextRank, available, leveled = GetSkillLineInfo(skillType, skillLineIndex)
    
    -- Print each value to debug
    -- d("Skill Line Name: " .. tostring(name))
    -- d("Rank: " .. tostring(rank))
    -- d("XP: " .. tostring(xp))
    -- d("XP for Next Rank: " .. tostring(xpForNextRank))
    -- d("Available: " .. tostring(available))
    -- d("Leveled: " .. tostring(leveled))
    return xp
    
end

local function GetSkillId(playerType)
    return playerType == "vampire" and 5 or 6
end

local function GetPassiveName(playerType)
    return playerType == "vampire" and "Blood Ritual" or "Blood Moon"
end

local function GetPlayerType()
    local isVampire = CheckSkillLine(SKILL_TYPE_WORLD, GetSkillId("vampire"))
    local isWerewolf = CheckSkillLine(SKILL_TYPE_WORLD, GetSkillId("werewolf"))

    if isVampire then
        return "vampire"
    elseif isWerewolf then
        return "werewolf"
    else
        return "normal"
    end
end

local function CheckBiteSkill(playerType)
    local skillId = GetSkillId(playerType)
    local skillName = GetPassiveName(playerType)
    local abilities = GetNumSkillAbilities(SKILL_TYPE_WORLD, skillId)

    d("Check Skill ID: " .. tostring(skillId))
    d("Check Skill Name: " .. skillName)

    for abilityIndex = 1, abilities do
        local name, icon, unlocksAt, passive, ult, purchased, luaind, progind, rank = GetSkillAbilityInfo(SKILL_TYPE_WORLD, skillId, abilityIndex)
        d("index: " .. tostring(abilityIndex))
        d("name: " .. tostring(name))
        d("icon: " .. tostring(icon))
        d("unlocksAt: " .. tostring(unlocksAt))
        d("passive: " .. tostring(passive))
        d("ult: " .. tostring(ult))
        d("purchased: " .. tostring(purchased))
        d("luaind: " .. tostring(luaind))
        d("progind: " .. tostring(progind))
        d("rank: " .. tostring(rank))

        if name == skillName and purchased then
            return true
        end
    end
    return false
end

local function Initialize()
    d("BiteClock Init")

    local playerType = GetPlayerType()
    d("Player Type: " .. playerType)

    if playerType == "normal" then
        BiteClockLabel:SetText("Not a Vampire or Werewolf :(")
    else
        BiteClockLabel:SetText(string.format("Player is a %s", playerType))

        local hasBiteSkill = CheckBiteSkill(playerType)

        d("Player has bite unlocked: ".. tostring(hasBiteSkill))

        -- local biteCooldown = GetCooldown(playerType)

        -- d("Cooldown: " .. tostring(biteCooldown))
    end

    -- zo_callLater(function() Initialize() end, 1000)
end

local function HideCooldown()
    BiteClockLabel:SetHidden(true)
end

local function ShowCooldown()
    BiteClockLabel:SetHidden(false)
end

function BiteClock.OnAddOnLoaded(eventCode, addonName)
    if addonName == "BiteClock" then
        EVENT_MANAGER:UnregisterForEvent("BiteClock", EVENT_ADD_ON_LOADED)
        Initialize()
    end
end

SLASH_COMMANDS["/biteclockinit"] = Initialize
SLASH_COMMANDS["/biteclockhide"] = HideCooldown
SLASH_COMMANDS["/biteclockshow"] = ShowCooldown


EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)
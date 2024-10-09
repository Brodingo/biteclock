BiteClock = {}
BiteClock.name = "BiteClock"

-- Check if the player has the given skill line unlocked
local function CheckSkillLine(skillType, skillLineIndex)
    local name, rank, xp, xpForNextRank, available, leveled = GetSkillLineInfo(skillType, skillLineIndex)
    
    -- Need to fix variable names, they appear out of order compared to example
    -- Print each value to debug
    -- d("Skill Line Name: " .. tostring(name))
    -- d("Rank: " .. tostring(rank))
    -- d("XP: " .. tostring(xp))
    -- d("XP for Next Rank: " .. tostring(xpForNextRank))
    -- d("Available: " .. tostring(available))
    -- d("Leveled: " .. tostring(leveled))
    return xp
    
end

-- ID of the skill line, assumed V/W
local function GetSkillId(playerType)
    return playerType == "vampire" and 5 or 6
end

-- Name of the bite passive skill, assumed V/W
local function GetPassiveName(playerType)
    return playerType == "vampire" and "Blood Ritual" or "Blood Moon"
end

-- Check what kind of player we're dealing with, could combine w CheckSkillLine
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

-- Check if player has the given bite passive ability unlocked and purchased
-- Could also support notifying players to get the skill if available
local function CheckBiteSkill(playerType)
    local skillId = GetSkillId(playerType)
    local skillName = GetPassiveName(playerType)
    local abilities = GetNumSkillAbilities(SKILL_TYPE_WORLD, skillId)

    d("Check Skill ID: " .. tostring(skillId))
    d("Check Skill Name: " .. skillName)

    -- Look through all the ability and check for the relevant skill info
    for abilityIndex = 1, abilities do
        local name, icon, unlocksAt, passive, ult, purchased, luaind, progind, rank = GetSkillAbilityInfo(SKILL_TYPE_WORLD, skillId, abilityIndex)
        d("index: " .. tostring(abilityIndex))
        d("name: " .. tostring(name))
        d("icon: " .. tostring(icon)) -- could be useful for showing in UI
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

    -- Determine what kind of player we're dealing with (may change during gameplay)
    local playerType = GetPlayerType()
    d("Player Type: " .. playerType)

    -- For normies, just show a message
    if playerType == "normal" then
        BiteClockLabel:SetText("Not a Vampire or Werewolf :(")
    else
        BiteClockLabel:SetText(string.format("Player is a %s", playerType))

        -- For valid players, check if they have the bite skill unlocked first
        local hasBiteSkill = CheckBiteSkill(playerType)

        d("Player has bite unlocked: ".. tostring(hasBiteSkill))

        -- If the player has the bite unlocked then check the cooldown

            -- If the cooldown is active display the countdown

            -- Else show an exciting message about bite being READY :D

    end

    -- Refresh checks, to check if player gets skill line, passive ability or when tracking cooldown
    -- zo_callLater(function() Initialize() end, 1000)
end

-- Slash command to hide UI
local function HideCooldown()
    BiteClockLabel:SetHidden(true)
end

-- Slash command to show UI
local function ShowCooldown()
    BiteClockLabel:SetHidden(false)
end

-- Slash Commands
SLASH_COMMANDS["/biteclockinit"] = Initialize
SLASH_COMMANDS["/biteclockhide"] = HideCooldown
SLASH_COMMANDS["/biteclockshow"] = ShowCooldown

-- When the addon is loaded fire the init function
function BiteClock.OnAddOnLoaded(eventCode, addonName)
    if addonName == "BiteClock" then
        -- unregister to avoid repeating init
        EVENT_MANAGER:UnregisterForEvent("BiteClock", EVENT_ADD_ON_LOADED)
        Initialize()
    end
end

-- Put me in coach, im ready to playyy
EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)

BiteClock = {}
BiteClock.name = "BiteClock"

local function CheckSkillLine(skillType, skillLineIndex)
    local name, rank, xp, xpForNextRank, available, leveled = GetSkillLineInfo(skillType, skillLineIndex)
    
    -- Print each value to debug
    d("Skill Line Name: " .. tostring(name))
    d("Rank: " .. tostring(rank))
    d("XP: " .. tostring(xp))
    d("XP for Next Rank: " .. tostring(xpForNextRank))
    d("Available: " .. tostring(available))
    d("Leveled: " .. tostring(leveled))
    
    -- Default xpForNextRank to 0 if nil
    xpForNextRank = xpForNextRank or 0
    
    d(string.format("Skill Line: %s, Rank: %d, XP: %d/%d, Available: %s, Leveled: %s", 
        name, rank, xp, xpForNextRank, tostring(available), tostring(leveled)))
end

local function GetBiteType()

    -- if isVampire
    return "none"
end

local function Initialize()

    d("BiteClock Loaded")
    local biteType = GetBiteType()
    d(biteType)

    -- Example usage for Werewolf skill line THIS IS WORKING
    CheckSkillLine(SKILL_TYPE_WORLD, 6)
    
    -- Example usage for Vampire skill line THIS IS NOT WORKING, 5 is wrong
    CheckSkillLine(SKILL_TYPE_WORLD, 5)

    if biteType == "vampire" or biteType == "werewolf" then
        BiteClockLabel:SetText(string.format("Player is a %s", biteType))
    else
        BiteClockLabel:SetText("Not a Vampire or Werewolf :(")
    end

    -- zo_callLater(function() Initialize() end, 1000)

end

local function HideCooldown()
    BiteClockLabel:SetHidden(true)
end

local function ShowCooldown()
    BiteClockLabel:SetHidden(false)
end

function BiteClock.OnAddOnLoaded(event, addonName)
    Initialize()
end

SLASH_COMMANDS["/biteclockhide"] = HideCooldown
SLASH_COMMANDS["/biteclockshow"] = ShowCooldown


EVENT_MANAGER:RegisterForEvent(BiteClock.name, EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)
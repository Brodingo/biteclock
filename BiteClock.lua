BiteClock = {}
BiteClock.name = "BiteClock"
BiteClock.defaultSettings = {
    left = 15,
    top = 15,
}
BiteClock.savedVariables = {}

local BITECLOCK_VARS = {
    vampire = {
        skillId = 5,
        passiveName = "Blood Ritual",
        icon = "/esoui/art/icons/passive_u26_vampire_05.dds"
        },
    werewolf = {
        skillId = 6,
        passiveName = "Bloodmoon",
        icon = "/esoui/art/icons/ability_werewolf_008.dds"
    }
}

-- Save window position
local function SavePosition()
    local left, top = BiteClockWindow:GetLeft(), BiteClockWindow:GetTop()
    BiteClock.savedVariables.left = left
    BiteClock.savedVariables.top = top
    -- d("Saved Position: " .. left .. ", " .. top)
end

-- Restore window position
local function RestorePosition()
    local left = BiteClock.savedVariables.left or BiteClock.defaultSettings.left
    local top = BiteClock.savedVariables.top or BiteClock.defaultSettings.top
    BiteClockWindow:ClearAnchors()
    BiteClockWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
    -- d("Restored Position: " .. left .. ", " .. top)
end

-- Reset window position
local function ResetPosition()
    BiteClock.savedVariables.left = BiteClock.defaultSettings.left
    BiteClock.savedVariables.top = BiteClock.defaultSettings.top
    RestorePosition()
    BiteClockWindow:SetHidden(false)
    -- d("Position reset to default and window shown")
end

-- Save position when moving the window
function BiteClock.OnMoveStop()
    SavePosition()
end

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

-- Check what kind of player we're dealing with
local function GetPlayerType()
    if CheckSkillLine(SKILL_TYPE_WORLD, BITECLOCK_VARS.vampire.skillId) then
        return "vampire"
    end

    if CheckSkillLine(SKILL_TYPE_WORLD, BITECLOCK_VARS.werewolf.skillId) then
        return "werewolf"
    end

    return "normal"
end

-- Check if player has the given bite passive ability unlocked and purchased
-- Could also support notifying players to get the skill if available
local function CheckBiteSkill(playerType)
    local abilities = GetNumSkillAbilities(SKILL_TYPE_WORLD, BITECLOCK_VARS[playerType].skillId)

    -- Look through all the ability and check for the relevant skill info
    for abilityIndex = 1, abilities do
        local name, icon, unlocksAt, passive, ult, purchased, luaind, progind, rank = GetSkillAbilityInfo(SKILL_TYPE_WORLD, BITECLOCK_VARS[playerType].skillId, abilityIndex)
        -- d("index: " .. tostring(abilityIndex))
        -- d("name: " .. tostring(name))
        -- d("icon: " .. tostring(icon)) -- could be useful for showing in UI
        -- d("unlocksAt: " .. tostring(unlocksAt))
        -- d("passive: " .. tostring(passive))
        -- d("ult: " .. tostring(ult))
        -- d("purchased: " .. tostring(purchased))
        -- d("luaind: " .. tostring(luaind))
        -- d("progind: " .. tostring(progind))
        -- d("rank: " .. tostring(rank))

        if name == BITECLOCK_VARS[playerType].passiveName and purchased then
            return true
        end
    end
    return false
end

-- Checks for the bite cool down and returns remaining time
local function CheckBiteCooldown(playerType)
    local numBuffs = GetNumBuffs("player")
    local cooldownName = BITECLOCK_VARS[playerType].passiveName.." Cooldown"

    for i = 1, numBuffs do
        local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo("player", i)

        -- d("buffName: " .. tostring(buffName))
        -- d("timeStarted: " .. tostring(timeStarted))
        -- d("timeEnding: " .. tostring(timeEnding))
        -- d("buffSlot: " .. tostring(buffSlot))
        -- d("stackCount: " .. tostring(stackCount))
        -- d("iconFilename: " .. tostring(iconFilename))
        -- d("buffType: " .. tostring(buffType))
        -- d("effectType: " .. tostring(effectType))
        -- d("abilityType: " .. tostring(abilityType))
        -- d("statusEffectType: " .. tostring(statusEffectType))
        -- d("canClickOff: " .. tostring(canClickOff))
        -- d("castByPlayer: " .. tostring(castByPlayer))

        if buffName == cooldownName then
            -- d(cooldownName.." Found")
            return timeEnding
        end
    end
    return false
    -- d("No Blood Ritual cooldown active.")
end

-- Make the cooldown remaining time easier to read
local function FormatTime(seconds)
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)

    local function pluralize(value, unit)
        return value == 1 and (value .. " " .. unit) or (value .. " " .. unit .. "s")
    end

    return pluralize(days, "day"), pluralize(hours, "hour"), pluralize(minutes, "minute"), pluralize(seconds, "second")
end

local function Initialize()
    -- d("BiteClock Init")

    -- d("Check buffs")
    -- CheckBuffs()

    -- Determine what kind of player we're dealing with (may change during gameplay)
    local playerType = GetPlayerType()
    -- d("Player Type: " .. playerType)

    -- For normies, just show a message
    if playerType == "normal" then
        BiteClockWindow:SetHidden(true)
    -- Player is vampire or werewolf so check for passive and cooldown
    else

        -- BiteClockWindowLabel:SetText(string.format("Player is a %s", playerType))
        
        -- Set the icon to the appropriate bite passive icon
        BiteClockWindowIcon:SetTexture(BITECLOCK_VARS[playerType].icon)

        -- For valid players, check if they have the bite skill unlocked first
        local hasBiteSkill = CheckBiteSkill(playerType)

        if not hasBiteSkill then
            BiteClockWindowLabel:SetText("Bite not unlocked")
        else
            -- d("Player has bite unlocked: ".. tostring(hasBiteSkill))

            -- If the player has the bite unlocked then check the cooldown
            local biteCooldown = CheckBiteCooldown(playerType)

            -- Bite is ready!
            if not biteCooldown then
                -- If no cooldown show an exciting message about bite being READY :D
                -- d(playerType .. " bite available!")
                BiteClockWindowLabel:SetText("Bite available!")
                -- Brighten the icon
                BiteClockWindowIcon:SetAlpha(1)
            -- Bite is not ready yet, show cooldown
            else
                -- Dim the icon
                BiteClockWindowIcon:SetAlpha(0.5)
                -- If the cooldown is active display the countdown
                local currentTime = GetFrameTimeSeconds()
                -- d("Current Time: " .. currentTime)
                local cooldownRemaining = biteCooldown - currentTime
                local days, hours, minutes, seconds = FormatTime(cooldownRemaining)

                -- Could add player setting to choose short/long format
                BiteClockWindowLabel:SetText(string.format("Bite ready in %s, %s, %s, %s", days, hours, minutes, seconds))

            end
        end
    end

    -- Refresh checks, to check if player gets skill line, passive ability or when tracking cooldown
    zo_callLater(function() Initialize() end, 1000)
end

-- Slash command to hide UI
local function HideWindow()
    BiteClockWindow:SetHidden(true)
end

-- Slash command to show UI
local function ShowWindow()
    BiteClockWindow:SetHidden(false)
end

-- Hide and show on pause/unpause
local function IsGameMenuOpen()
    return SCENE_MANAGER:IsShowing("hudui") --or SCENE_MANAGER:IsShowing("hud")
end

local function OnUICameraModeChanged(eventCode, uiMode)
    if uiMode then
        -- d("UI mode activated - hiding BiteClockWindow")
        BiteClockWindow:SetHidden(true)
    else
        -- d("UI mode deactivated - showing BiteClockWindow")
        BiteClockWindow:SetHidden(false)
    end
end

local function OnReticleHiddenUpdate(eventCode, hidden)
    if hidden and not IsGameMenuOpen() then
        -- d("Reticle hidden (not game menu) - hiding BiteClockWindow")
        BiteClockWindow:SetHidden(true)
    else
        -- d("Reticle shown or game menu - showing BiteClockWindow")
        BiteClockWindow:SetHidden(false)
    end
end

-- Slash Commands
-- SLASH_COMMANDS["/biteclockinit"] = Initialize
SLASH_COMMANDS["/biteclockhide"] = HideWindow
SLASH_COMMANDS["/biteclockshow"] = ShowWindow
SLASH_COMMANDS["/biteclockreset"] = ResetPosition

-- When the addon is loaded fire the init function
function BiteClock.OnAddOnLoaded(eventCode, addonName)
    if addonName == "BiteClock" then

        BiteClock.savedVariables = ZO_SavedVars:New("BiteClockData", 1, nil, {})

        -- Register to save position on move stop
        BiteClockWindow:SetHandler("OnMoveStop", BiteClock.OnMoveStop)

        -- Restore position when addon loads
        RestorePosition()

        -- Hide and show on pause/unpause
        EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_GAME_CAMERA_UI_MODE_CHANGED, OnUICameraModeChanged)
        EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_RETICLE_HIDDEN_UPDATE, OnReticleHiddenUpdate)

        -- Unregister to avoid repeating init
        EVENT_MANAGER:UnregisterForEvent("BiteClock", EVENT_ADD_ON_LOADED)
        Initialize()
    end
end

-- Put me in coach, im ready to playyy
EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)

BiteClock = {}
BiteClock.name = "BiteClock"
BiteClock.defaultSettings = {
    left = 15,
    top = 15,
}
BiteClock.savedVariables = {}

local PlayerType = { VAMPIRE = "vampire", WEREWOLF = "werewolf", NORMAL = "normal" }
local FormatWidth = { SHORT = "short", LONG = "long" }
local BITECLOCK_VARS = {
    [PlayerType.VAMPIRE] = {
        skillId = 5,
        passiveName = "Blood Ritual",
        icon = "/esoui/art/icons/passive_u26_vampire_05.dds",
        color = {255,45,255,1},
    },
    [PlayerType.WEREWOLF] = {
        skillId = 6,
        passiveName = "Bloodmoon",
        icon = "/esoui/art/icons/ability_werewolf_008.dds",
        color = {255,165,0,1},
    },
    formatWidth = {
        [FormatWidth.SHORT] = 220,
        [FormatWidth.LONG] = 420,
    }
}
local ShrineZones = {"Reaper's March", "Bangkorai", "The Rift"}

local function PlayerInShrineZone()
    local playerZone = GetUnitZone("player")
    for index, value in ipairs(ShrineZones) do
        if playerZone == value then
            return true
        end 
    end
    return false
end

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
    local name, rank, xp, _, _, _ = GetSkillLineInfo(skillType, skillLineIndex)
    -- d("Name: "..tostring(name))
    -- d("Level: "..tostring(level))
    -- d("XP: "..tostring(xp))

    return xp
end

-- Check what kind of player we're dealing with
local function GetPlayerType()
    -- Check if playerType is already saved in the saved variables
    if BiteClock.savedVariables.playerType and BiteClock.savedVariables.playerType ~= PlayerType.NORMAL then
        return BiteClock.savedVariables.playerType
    end

    if CheckSkillLine(SKILL_TYPE_WORLD, BITECLOCK_VARS.vampire.skillId) then
        BiteClock.savedVariables.playerType = PlayerType.VAMPIRE
    elseif CheckSkillLine(SKILL_TYPE_WORLD, BITECLOCK_VARS.werewolf.skillId) then
        BiteClock.savedVariables.playerType = PlayerType.WEREWOLF
    else
        BiteClock.savedVariables.playerType = PlayerType.NORMAL
    end

    return BiteClock.savedVariables.playerType
end

-- Check if player has the given bite passive ability unlocked and purchased
-- Could also support notifying players to get the skill if available
local function CheckBiteSkill(playerType)
    local abilities = GetNumSkillAbilities(SKILL_TYPE_WORLD, BITECLOCK_VARS[playerType].skillId)

    -- Look through all the ability and check for the relevant skill info
    for abilityIndex = 1, abilities do
        local name, icon, unlocksAt, passive, ult, purchased, luaind, progind, rank = GetSkillAbilityInfo(SKILL_TYPE_WORLD, BITECLOCK_VARS[playerType].skillId, abilityIndex)

        if name == BITECLOCK_VARS[playerType].passiveName and purchased then
            return true
        end
    end
    return false
end

-- Checks for the bite cool down and returns remaining time
local function CheckBiteCooldown(playerType)
    local lastTimeEnding = BiteClock.savedVariables.lastTimeEnding
    local currentTime = GetFrameTimeSeconds()
    
    -- Check for an existing last bite cooldown
    -- Disable for now since timeending shifts (daily?)
    -- Need to find a better way to track cooldown regardless of start
    -- Maybe determine a timestamp instead
    if false and lastTimeEnding then
        local timeRemaining = lastTimeEnding - currentTime

        -- If enough time has passed clear the last bite cooldown timer
        if timeRemaining <= 0 then
            BiteClock.savedVariables.lastTimeEnding = nil
        -- Otherwise return the last cooldown
        else
            -- d("using savedvars time")
            return timeRemaining
        end
    end

    -- If a bite is not saved check for a new one
    local numBuffs = GetNumBuffs("player")
    local cooldownName = BITECLOCK_VARS[playerType].passiveName.." Cooldown"

    for i = 1, numBuffs do
        local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff, castByPlayer = GetUnitBuffInfo("player", i)

        if buffName == cooldownName then
            -- d(cooldownName.." Found")
            -- d("Time started: "..timeStarted)
            -- d("Time ending: "..timeEnding)
            -- d("Current started: "..currentTime)
            -- Save the timeEnding
            BiteClock.savedVariables.lastTimeEnding = timeEnding - currentTime
            return timeEnding - currentTime
        end
    end

    -- d("No Blood Ritual cooldown active.")
    return nil
end

local function pluralize(value, unit)
    return value == 1 and (value .. " " .. unit) or (value .. " " .. unit .. "s")
end

-- Make the cooldown remaining time easier to read
local function FormatTime(seconds)
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)

    if BiteClock.savedVariables.timeFormat == FormatWidth.SHORT then
        return days, hours, minutes, seconds
    end

    return pluralize(days, "day"), pluralize(hours, "hour"), pluralize(minutes, "minute"), pluralize(seconds, "second")
end

local function UpdateWindow(biteCooldown)
    if BiteClock.savedVariables.windowToggle == "hide" then
        return
    end
    if biteCooldown == nil then
        BiteClockWindow:SetWidth(BITECLOCK_VARS.formatWidth.short)
        return
    end
    local format = BiteClock.savedVariables.timeFormat
    BiteClockWindow:SetWidth(BITECLOCK_VARS.formatWidth[format ~= nil and format or "long"])
end

local function Initialize()
    -- d("BiteClock Init")

    -- Show the zone so we can provide info about shrine availability later
    -- local currentZone = GetUnitZone("player")
    -- d("Current Zone: " .. currentZone)
    -- local BiteableZone = PlayerInShrineZone()
    -- d("Player is in shrine zone: " .. tostring(BiteableZone))

    -- Determine what kind of player we're dealing with (may change during gameplay)
    local playerType = GetPlayerType()
    local biteCooldown = nil
    -- d("Player Type: " .. playerType)

    -- For normies, just show a message
    if playerType == PlayerType.NORMAL then
        BiteClockWindowLabel:SetText("Not a vampire/werewolf")
        -- BiteClockWindow:SetHidden(true)
    -- Player is vampire or werewolf so check for passive and cooldown
    else
        -- Set the icon to the appropriate bite passive icon
        BiteClockWindowIcon:SetTexture(BITECLOCK_VARS[playerType].icon)
        BiteClockWindowLabel:SetColor(unpack(BITECLOCK_VARS[playerType].color))

        -- For valid players, check if they have the bite skill unlocked first
        local hasBiteSkill = CheckBiteSkill(playerType)

        if not hasBiteSkill then
            BiteClockWindowLabel:SetText("Bite skill not unlocked")
        else
            -- d("Player has bite unlocked: ".. tostring(hasBiteSkill))

            -- If the player has the bite unlocked then check the cooldown
            biteCooldown = CheckBiteCooldown(playerType)

            -- Bite is ready!
            if biteCooldown == nil then
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

                if BiteClock.savedVariables.timeFormat == FormatWidth.SHORT then
                    BiteClockWindowLabel:SetText(string.format("Ready in %dd %dh %dm %ds", days, hours, minutes, seconds))
                else
                    BiteClockWindowLabel:SetText(string.format("Bite ready in %s, %s, %s, %s", days, hours, minutes, seconds))
                end

            end
        end
    end

    -- Update window with any new settings
    UpdateWindow(biteCooldown)

    -- Refresh checks, to check if player gets skill line, passive ability or when tracking cooldown
    zo_callLater(function() Initialize() end, 1000)
end

-- Slash command to hide UI
local function HideWindow()
    BiteClock.savedVariables.windowToggle = "hide"
    BiteClockWindow:SetHidden(true)
end
-- Slash command to show UI
local function ShowWindow()
    BiteClock.savedVariables.windowToggle = "show"
    BiteClockWindow:SetHidden(false)
end

-- Slash command to change formats
local function ShortFormat()
    BiteClock.savedVariables.timeFormat = "short"
end
-- Slash command to change formats
local function LongFormat()
    BiteClock.savedVariables.timeFormat = "long"
end

-- Hide and show on pause/unpause
local function IsGameMenuOpen()
    return SCENE_MANAGER:IsShowing("hudui") --or SCENE_MANAGER:IsShowing("hud")
end

local function OnUICameraModeChanged(eventCode, uiMode)

    if BiteClock.savedVariables.windowToggle == "hide" then
        return
    end

    if uiMode then
        -- d("UI mode activated - hiding BiteClockWindow")
        BiteClockWindow:SetHidden(true)
    else
        -- d("UI mode deactivated - showing BiteClockWindow")
        BiteClockWindow:SetHidden(false)
    end
end

local function OnReticleHiddenUpdate(eventCode, hidden)

    if BiteClock.savedVariables.windowToggle == "hide" then
        return
    end

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
SLASH_COMMANDS["/biteclockshort"] = ShortFormat
SLASH_COMMANDS["/biteclocklong"] = LongFormat

-- When the addon is loaded fire the init function
function BiteClock.OnAddOnLoaded(eventCode, addonName)

    if addonName ~= "BiteClock" then return end

    BiteClock.savedVariables = ZO_SavedVars:NewCharacterIdSettings("BiteClockData", 1, nil, {})

    -- Register to save position on move stop
    BiteClockWindow:SetHandler("OnMoveStop", BiteClock.OnMoveStop)

    -- Restore position when addon loads
    RestorePosition()

    -- Restore visible toggle when addon loads
    if BiteClock.savedVariables.windowToggle == "hide" then
        BiteClockWindow:SetHidden(true)
    end

    -- Hide and show on pause/unpause
    EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_GAME_CAMERA_UI_MODE_CHANGED, OnUICameraModeChanged)
    EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_RETICLE_HIDDEN_UPDATE, OnReticleHiddenUpdate)

    -- Unregister to avoid repeating init
    EVENT_MANAGER:UnregisterForEvent("BiteClock", EVENT_ADD_ON_LOADED)
    Initialize()

end

-- Put me in coach, im ready to playyy
EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)

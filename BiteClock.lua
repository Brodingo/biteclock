BiteClock = {}
BiteClock.name = "BiteClock"
BiteClock.defaultSettings = {
    left = 15,
    top = 15,
}
BiteClock.savedVariables = {}
local gps = LibGPS3
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
    -- formatWidth = {
    --     [FormatWidth.SHORT] = 220,
    --     [FormatWidth.LONG] = 420,
    -- }
}
local FactionZones = {
    ["Aldmeri"] = {
        "Auridon",
        "Grahtwood",
        "Greenshade",
        "Malabal Tor",
        "Reaper's March",
    },
    ["Ebonheart"] = {
        "Stonefalls",
        "Deshaan",
        "Shadowfen",
        "Eastmarch",
        "The Rift",
    },
    ["Daggerfall"] = {
        "Glenumbra",
        "Stormhaven",
        "Rivenspire",
        "Alik'r Desert",
        "Bangkorai",
    }
}
local ShrineZones = {
    ["Reaper's March"] = {
        [PlayerType.VAMPIRE] = {
            x = 0.47301758463444,
            y = 0.5728352071255,
        },
        [PlayerType.WEREWOLF] = {
            x = 0.47906718510934,
            y = 0.5711256058987,
        },
    },
    ["Bangkorai"] = {
        [PlayerType.VAMPIRE] = {
            x = 0.29293640580907,
            y = 0.32498159559332,
        },
        [PlayerType.WEREWOLF] = {
            x = 0.3148992064148,
            y = 0.31686359614929,
        },
    },
    ["The Rift"] = {
        [PlayerType.VAMPIRE] = {
            x = 0.65029799679617,
            y = 0.33956479697632,
        },
        [PlayerType.WEREWOLF] = {
            x = 0.66078479961658,
            y = 0.36681839553402,
        },
    },
}

local function inTable(tbl, item)
    return tbl[item] ~= nil
end

local function GetFactionByZone(zone)
    for faction, zoneList in pairs(FactionZones) do
        if inTable({[faction] = zoneList}, zone) then
            return faction
        end
    end
    return "Unknown"
end

local function HasShrine(zone)
    return inTable(ShrineZones, zone)
end

local function CalculateDistance(x1, y1, x2, y2)
    local distance = gps:GetGlobalDistanceInMeters(x1, y1, x2, y2)
    -- local dx = x2 - x1
    -- local dy = y2 - y1
    -- 1000 is an estimate for conversion to meters...
    return math.floor(distance)
end

local function CalculateDirection(x1, y1, x2, y2)
    local shrineLocalX, shrineLocalY = gps:GlobalToLocal(x2, y2)
    local deltaX = x1 - shrineLocalX
    local deltaY = y1 - shrineLocalY
    local angle = math.atan2(deltaY, deltaX) * (180 / math.pi)
    
    if angle < 0 then
        angle = angle + 360
    end
    
    if (angle >= 337.5 and angle < 360) or (angle >= 0 and angle < 22.5) then
        return "West"
    elseif angle >= 22.5 and angle < 67.5 then
        return "Northwest"
    elseif angle >= 67.5 and angle < 112.5 then
        return "North"
    elseif angle >= 112.5 and angle < 157.5 then
        return "Northeast"
    elseif angle >= 157.5 and angle < 202.5 then
        return "East"
    elseif angle >= 202.5 and angle < 247.5 then
        return "Southeast"
    elseif angle >= 247.5 and angle < 292.5 then
        return "South"
    elseif angle >= 292.5 and angle < 337.5 then
        return "Southwest"
    end
    return "Undefined Direction"
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

-- Reset BiteClock saved variables
local function Reset()
    
    BiteClock.savedVariables.left = BiteClock.defaultSettings.left
    BiteClock.savedVariables.top = BiteClock.defaultSettings.top
    BiteClock.savedVariables.desire = nil
    BiteClock.savedVariables.playerType = nil
    BiteClock.savedVariables.windowToggle = nil
    BiteClock.savedVariables.timeFormat = nil

    d("BiteClock variables reset")
    
    RestorePosition()
    BiteClockWindow:SetHidden(false)
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

    if playerType == PlayerType.NORMAL then
        return nil
    end

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

local function UpdateWindow(biteCooldown)
    if BiteClock.savedVariables.windowToggle == "hide" then
        return
    end
    if biteCooldown == nil then
        -- BiteClockWindow:SetWidth(BITECLOCK_VARS.formatWidth.short)
        return
    end
    local format = BiteClock.savedVariables.timeFormat
    -- BiteClockWindow:SetWidth(BITECLOCK_VARS.formatWidth[format ~= nil and format or "long"])
end

local function GetShrineInfo(playerType)
    local playerLocalX, playerLocalY = GetMapPlayerPosition("player") 
    local playerX, playerY = gps:LocalToGlobal(playerLocalX, playerLocalY)
    local zone = GetUnitZone("player")
    -- d("Zone: " .. zone)

    if not HasShrine(zone) then
        return "No Shrine in " .. zone
    end

    -- Calculate distance to the shrine with global coordinates
    local distance = CalculateDistance(
        playerX,
        playerY,
        ShrineZones[zone][playerType].x,
        ShrineZones[zone][playerType].y
    )
    -- Calculate direction to the shrine with local coordinates
    local direction = CalculateDirection(
        playerLocalX,
        playerLocalY,
        ShrineZones[zone][playerType].x,
        ShrineZones[zone][playerType].y
    )
    
    return "Shrine in " .. zone .. ", " .. tostring(distance) .. "m away, " .. direction
end

local function pluralize(value, singular)
    return value .. " " .. singular .. (value == 1 and "" or "s")
end

-- Make the cooldown remaining time easier to read
local function FormatTime(seconds)
    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400
    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600
    local minutes = math.floor(seconds / 60)
    seconds = math.floor(seconds % 60)

    return days, hours, minutes, seconds
end

local function GetCooldownText(biteCooldown)
    local currentTime = GetFrameTimeSeconds()
    local cooldownRemaining = biteCooldown - currentTime
    local days, hours, minutes, seconds = FormatTime(cooldownRemaining)

    local timeStrings = {}

    if BiteClock.savedVariables.timeFormat == FormatWidth.SHORT then
        if days > 0 then table.insert(timeStrings, string.format("%dd", days)) end
        if hours > 0 then table.insert(timeStrings, string.format("%dh", hours)) end
        if minutes > 0 then table.insert(timeStrings, string.format("%dm", minutes)) end
        if seconds > 0 then table.insert(timeStrings, string.format("%ds", seconds)) end
        return "Ready in " .. table.concat(timeStrings, " ")
    else
        if days > 0 then table.insert(timeStrings, pluralize(days, "day")) end
        if hours > 0 then table.insert(timeStrings, pluralize(hours, "hour")) end
        if minutes > 0 then table.insert(timeStrings, pluralize(minutes, "minute")) end
        if seconds > 0 then table.insert(timeStrings, pluralize(seconds, "second")) end
        return "Ready in " .. table.concat(timeStrings, ", ")
    end
end

local function HandleNormalPlayer()

    local characterName = GetUnitName("player")
    local desire = BiteClock.savedVariables.desire
    
    if (desire == PlayerType.VAMPIRE) then
        BiteClockWindowStatus:SetText(characterName .. " desires to become a Vampire")
    elseif (desire == PlayerType.WEREWOLF) then    
        BiteClockWindowStatus:SetText(characterName .. " desires to become a Werewolf")
    else
        BiteClockWindowStatus:SetText(characterName .. " is not a Vampire or Werewolf")
    end

    if (desire ~= nil) then
        BiteClockWindowShrine:SetText(GetShrineInfo(desire))
    else
        BiteClockWindowShrine:SetText("Set desire with /biteclockvamp or /biteclockww")
    end

    BiteClockWindowTimer:SetText("Bite skills unlock at level 6")

end

local function HandleSupernatural(playerType, zone, playerX, playerY, playerLocalX, playerLocalY)
    -- Set appearance
    BiteClockWindowIcon:SetTexture(BITECLOCK_VARS[playerType].icon)
    BiteClockWindowStatus:SetColor(unpack(BITECLOCK_VARS[playerType].color))

    -- Check bite skill
    if not CheckBiteSkill(playerType) then
        BiteClockWindowStatus:SetText("Bite skill not unlocked")
        return
    end

    -- Get shrine info
    local shrineInfo = GetShrineInfo(playerType)
    BiteClockWindowShrine:SetText(shrineInfo)

    -- Check bite cooldown
    local biteCooldown = CheckBiteCooldown(playerType)
    if biteCooldown == nil then
        BiteClockWindowStatus:SetText(BITECLOCK_VARS[playerType].passiveName .. " ready!")
        BiteClockWindowIcon:SetAlpha(1)
    else
        BiteClockWindowStatus:SetText(BITECLOCK_VARS[playerType].passiveName .. " on cooldown")
        BiteClockWindowIcon:SetAlpha(0.5)

        biteCooldownText = GetCooldownText(biteCooldown)
        BiteClockWindowTimer:SetText(biteCooldownText)
    end
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

-- Slash command to change formats
local function DesireVampire()
    BiteClock.savedVariables.desire = PlayerType.VAMPIRE
    d("The player thirsts for the crimson elixir of life.")
end
-- Slash command to change formats
local function DesireWerewolf()
    BiteClock.savedVariables.desire = PlayerType.WEREWOLF
    d("The player yearns for the wild call of the moon.")
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
SLASH_COMMANDS["/biteclockshort"] = ShortFormat
SLASH_COMMANDS["/biteclocklong"] = LongFormat
SLASH_COMMANDS["/biteclockvamp"] = DesireVampire
SLASH_COMMANDS["/biteclockww"] = DesireWerewolf
SLASH_COMMANDS["/biteclockreset"] = Reset

local function initalizeBiteClock()
    BiteClock.savedVariables = ZO_SavedVars:NewCharacterIdSettings("BiteClockData", 1, nil, {})

    -- Register to save position on move stop
    BiteClockWindow:SetHandler("OnMoveStop", BiteClock.OnMoveStop)

    -- Restore position when addon loads
    RestorePosition()

    -- Hide and show on pause/unpause
    EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_GAME_CAMERA_UI_MODE_CHANGED, OnUICameraModeChanged)
    EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_RETICLE_HIDDEN_UPDATE, OnReticleHiddenUpdate)

    -- Restore visible toggle when addon loads
    if BiteClock.savedVariables.windowToggle == "hide" then
        BiteClockWindow:SetHidden(true)
    end
end

-- Main function to check for bite updates
local function biteClock()
    local playerType = GetPlayerType()

    if playerType == PlayerType.NORMAL then
        HandleNormalPlayer()
    end

    if playerType == PlayerType.VAMPIRE or playerType == PlayerType.WEREWOLF then
        HandleSupernatural(playerType)
    end

    UpdateWindow(CheckBiteCooldown(playerType))
    zo_callLater(function() biteClock() end, 1000)
end

-- When the addon is loaded fire the init function
function BiteClock.OnAddOnLoaded(eventCode, addonName)
    if addonName ~= "BiteClock" then return end
    
    -- Unregister to avoid repeating init
    EVENT_MANAGER:UnregisterForEvent("BiteClock", EVENT_ADD_ON_LOADED)

    initalizeBiteClock()
    biteClock()
end

-- Put me in coach, im ready to playyy
EVENT_MANAGER:RegisterForEvent("BiteClock", EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)

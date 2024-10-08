BiteClock = {}
BiteClock.name = "BiteClock"

local function updateCooldown()
    d("BiteClock Loaded")

    BiteClockLabel:SetText("Bite ready in: ...loading...")

    zo_callLater(function() updateClock() end, 1000)

end

local function HideCooldown()
    BiteClockLabel:SetHidden(true)
end

local function ShowCooldown()
    BiteClockLabel:SetHidden(false)
end

function BiteClock.OnAddOnLoaded()
    updateCooldown()
end

SLASH_COMMANDS["/biteclockhide"] = HideCooldown
SLASH_COMMANDS["/biteclockshow"] = ShowCooldown


EVENT_MANAGER:RegisterForEvent(BiteClock.name, EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)
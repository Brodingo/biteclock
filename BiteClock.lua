BiteClock = {}
BiteClock.name = "BiteClock"

local function updateCooldown()
    d("BiteClock Loaded")

    BiteClockLabel:SetText("Bite ready in: ...loading...")

end

function BiteClock.OnAddOnLoaded()
    updateCooldown()
end


EVENT_MANAGER:RegisterForEvent(BiteClock.name, EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)
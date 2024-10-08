BiteClock = {}
BiteClock.name = "BiteClock"

local function updateClock()
    d("bite clock!")
end

function BiteClock.OnAddOnLoaded()
    updateClock()
end

EVENT_MANAGER:RegisterForEvent(BiteClock.name, EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)
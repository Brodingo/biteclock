BiteClock = {}
BiteClock.name = "BiteClock"

function BiteClock.OnAddOnLoaded()
    if addonName == BiteClock.name then
        BiteClock:Initialize()
    end
end

function BiteClock:Initialize()
    d("BiteClock Loaded")
end

EVENT_MANAGER:RegisterForEvent(BiteClock.name, EVENT_ADD_ON_LOADED, BiteClock.OnAddOnLoaded)
CBTSData = {}
local DebugPrefix = "[CBTSData] "

function CBTSData.SetPhase(stringArg)
    if type(stringArg) == "string" then

        print(DebugPrefix, "Phase has been set to '", stringArg, "'")

        if stringArg == "cooldown" then
            CBTSData.Data.Counter = 0
        elseif stringArg == "calm" then
            CBTSData.Data.Counter = (SandboxVars.CBTS.CooldownPhaseDuration * 60)
        elseif stringArg == "storm" then
            CBTSData.Data.Counter = (SandboxVars.CBTS.CooldownPhaseDuration * 60) + (SandboxVars.CBTS.CalmPhaseDuration * 60)
        else
            print(DebugPrefix, "Invalid input. Phase name not found.")
        end
    else
        print(DebugPrefix, "Invalid input. Must be a string value.")
    end
end

function CBTSData.SetCounter(intArg)
    if type(intArg) == "number" then
        if intArg < (SandboxVars.CBTS.CooldownPhaseDuration * 60) + (SandboxVars.CBTS.CalmPhaseDuration * 60) + (SandboxVars.CBTS.MaxStormPhaseDuration * 60) then
            CBTSData.Data.Counter = intArg
            print(DebugPrefix, "Cycle Counter set to ", intArg)
        else
            CBTSData.Data.Counter = 0 -- If input is greater than the total event cycle time, set to zero.
        end
    else
        print(DebugPrefix, "Invalid input. Must be an integer value.")
    end
end

function CBTSData.SetCounterInHours(intArg)
    if type(intArg) == "number" then
        if intArg < SandboxVars.CBTS.CooldownPhaseDuration + SandboxVars.CBTS.CalmPhaseDuration + SandboxVars.CBTS.StormPhaseDuration then
            CBTSData.Data.Counter = intArg * 60
            print(DebugPrefix, "Cycle set to ", intArg, " hours")
        else
            CBTSData.Data.Counter = 0 -- If input is greater than the total event cycle time, set to zero.
        end
    else
        print(DebugPrefix, "Invalid input. Must be an integer value.")
    end
end

function CBTSData.SetPaused(boolArg)
    if type(boolArg) == "boolean" then
        CBTSData.Data.Paused = boolArg
        print(DebugPrefix, "Cycle counter has been paused.")
    else
        print(DebugPrefix, "Invalid input. Must be a boolean value (true/false).")
    end
end

function CBTSData.Initialise()
    CBTSData.Data = ModData.getOrCreate("CBTS_Data")
    if CBTSData.Data.Counter == nil then
        CBTSData.Data.Counter = 0
    end
    if CBTSData.Data.Paused == nil then
        CBTSData.Data.Paused = false
    end
    CBTSData.UpdateToRandomDurations()
end

function CBTSData.UpdateToRandomDurations()
    if CBTSData.Data.Counter == 0 then
        CBTSData.Data.RandomCooldownPhaseDuration = ZombRand(SandboxVars.CBTS.MinCooldownPhaseDuration * 60 + 0.0, SandboxVars.CBTS.MaxCooldownPhaseDuration * 60 + 0.0)
        CBTSData.Data.RandomCalmPhaseDuration = ZombRand(SandboxVars.CBTS.MinCalmPhaseDuration * 60 + 0.0, SandboxVars.CBTS.MaxCalmPhaseDuration * 60 + 0.0)
        CBTSData.Data.RandomStormPhaseDuration = ZombRand(SandboxVars.CBTS.MinStormPhaseDuration * 60 + 0.0, SandboxVars.CBTS.MaxStormPhaseDuration * 60 + 0.0)
    end
end

function CBTSData.Count()
    if not CBTSData.Data.Paused then
        CBTSData.Data.Counter = CBTSData.Data.Counter + 1
    end
    --print(DebugPrefix, "CBTSData.Data.Counter: " .. CBTSData.Data.Counter)
end

function CBTSData.Reset()
    CBTSData.Data.Counter = 0
    CBTSData.UpdateToRandomDurations()
end

Events.OnInitGlobalModData.Add(CBTSData.Initialise)
Events.EveryOneMinute.Add(CBTSData.Count)
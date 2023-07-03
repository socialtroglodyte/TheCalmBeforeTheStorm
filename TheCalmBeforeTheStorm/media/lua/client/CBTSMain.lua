local Utils = require("Utils")
local DebugPrefix = "[CBTS] " -- This will show at the start of the debug message to help identify mod outputs more easily

local WorldSoundManager = getWorldSoundManager()
local BaseSoundManager = getSoundManager()
local HordeRadius = SandboxVars.CBTS.HordeRadius
local HordeDistance = SandboxVars.CBTS.HordeDistance
local CooldownPhaseDuration = SandboxVars.CBTS.CooldownPhaseDuration * 60 + 0.0
local CalmPhaseDuration = SandboxVars.CBTS.CalmPhaseDuration * 60 + 0.0
local StormPhaseDuration = SandboxVars.CBTS.StormPhaseDuration * 60 + 0.0
local MinutesBetweenZombieCalls = SandboxVars.CBTS.MinutesBetweenZombieCalls
local MaxNumChasingZombies = SandboxVars.CBTS.MaxNumChasingZombies
local PlayerPositionOffset = SandboxVars.CBTS.PlayerPositionOffset
local EnableLogging = SandboxVars.CBTS.EnableLogging
local DebugMinutesToUpdateConsole = SandboxVars.CBTS.DebugMinutesToUpdateConsole
local SoundType = SandboxVars.CBTS.SoundType
local CycleCounter  -- Cycle counter variable

local MigrationDirection = {
    North = SandboxVars.CBTS.MigrateToNorth,
    East = SandboxVars.CBTS.MigrateToEast,
    South = SandboxVars.CBTS.MigrateToSouth,
    West = SandboxVars.CBTS.MigrateToWest,
    NorthEast = SandboxVars.CBTS.MigrateToNorthEast,
    NorthWest = SandboxVars.CBTS.MigrateToNorthWest,
    SouthEast = SandboxVars.CBTS.MigrateToSouthEast,
    SouthWest = SandboxVars.CBTS.MigrateToSouthWest
}

local function UpdateSandboxVars()
    CallZombiesOnce = SandboxVars.CBTS.CallZombiesOnce
    HordeRadius = SandboxVars.CBTS.HordeRadius
    HordeDistance = SandboxVars.CBTS.HordeDistance
    MinutesBetweenZombieCalls = SandboxVars.CBTS.MinutesBetweenZombieCalls
	EnableLogging = SandboxVars.CBTS.EnableLogging
    DebugMinutesToUpdateConsole = SandboxVars.CBTS.DebugMinutesToUpdateConsole
    MaxNumChasingZombies = SandboxVars.CBTS.MaxNumChasingZombies
    PlayerPositionOffset = SandboxVars.CBTS.PlayerPositionOffset
    SoundType = SandboxVars.CBTS.SoundType

    MigrationDirection.North = SandboxVars.CBTS.MigrateToNorth
    MigrationDirection.East = SandboxVars.CBTS.MigrateToEast
    MigrationDirection.South = SandboxVars.CBTS.MigrateToSouth
    MigrationDirection.West = SandboxVars.CBTS.MigrateToWest
    MigrationDirection.NorthEast = SandboxVars.CBTS.MigrateToNorthEast
    MigrationDirection.NorthWest = SandboxVars.CBTS.MigrateToNorthWest
    MigrationDirection.SouthEast = SandboxVars.CBTS.MigrateToSouthEast
    MigrationDirection.SouthWest = SandboxVars.CBTS.MigrateToSouthWest

    if SandboxVars.CBTS.RandomDurationFlag then
        CooldownPhaseDuration = CBTSData.Data.RandomCooldownPhaseDuration + 0.0
        CalmPhaseDuration = CBTSData.Data.RandomCalmPhaseDuration + 0.0
        StormPhaseDuration = CBTSData.Data.RandomStormPhaseDuration + 0.0
    else
        CooldownPhaseDuration = SandboxVars.CBTS.CooldownPhaseDuration * 60 + 0.0
        CalmPhaseDuration = SandboxVars.CBTS.CalmPhaseDuration * 60 + 0.0
        StormPhaseDuration = SandboxVars.CBTS.StormPhaseDuration * 60 + 0.0
    end
end

local function MakeNoise(x, y, radius)
    local Player = getPlayer()
    if Player ~= nil then
        WorldSoundManager:addSound(Player, x, y, 0, radius, radius * 5000)
    end -- getWorldSoundManager():addSound(getPlayer(), getPlayer():getCurrentSquare():getX()+3000, getPlayer():getCurrentSquare():getY()+3000, 0, 100, 100)
end

local function CalmPhase()
    if not getPlayer() then return end

    if getPlayer():isAlive() and getPlayer() ~= nil then

        local CurrentSquare = getPlayer():getCurrentSquare()

        if CurrentSquare then

            local x1 = CurrentSquare:getX() + HordeDistance
            local y1 = CurrentSquare:getY() + HordeDistance
            local x2 = CurrentSquare:getX() - HordeDistance
            local y2 = CurrentSquare:getY() - HordeDistance

            if MigrationDirection.North then
                MakeNoise(CurrentSquare:getX(), y2, HordeRadius)
            end

            if MigrationDirection.South then
                MakeNoise(CurrentSquare:getX(), y1, HordeRadius)
            end

            if MigrationDirection.East then
                MakeNoise(x1, CurrentSquare:getY(), HordeRadius)
            end

            if MigrationDirection.West then
                MakeNoise(x2, CurrentSquare:getY(), HordeRadius)
            end

            if MigrationDirection.NorthEast then
                MakeNoise(x1, y2, HordeRadius)
            end

            if MigrationDirection.SouthEast then
                MakeNoise(x1, y1, HordeRadius)
            end

            if MigrationDirection.NorthWest then
                MakeNoise(x2, y2, HordeRadius)
            end

            if MigrationDirection.SouthWest then
                MakeNoise(x2, y1, HordeRadius)
            end

        else
            if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
                print(DebugPrefix, "Player CurrentSquare not found. Cancelled calm phase update.")
            end
        end

        if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
            print(DebugPrefix, "The calm phase is in progress. Migrating zombies away from player(s).")
        end
    else
        if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
            print(DebugPrefix, "Player not found. Cancelled calm phase update.")
        end
    end
end

local function StormPhase()
    if not getPlayer() then return end
    if getPlayer():isAlive() and getPlayer() ~= nil then
        local CurrentSquare = getPlayer():getCurrentSquare() or 0

        if CurrentSquare then
            if MaxNumChasingZombies > 0 then
                if getPlayer():getStats():getNumChasingZombies() < MaxNumChasingZombies then
                    MakeNoise(CurrentSquare:getX(), CurrentSquare:getY(), HordeDistance * 1.5)
                else
                    if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
                        print(DebugPrefix, "MaxNumChasingZombies value reached. Cancelled storm phase update.")
                    end
                end
            else
                MakeNoise(CurrentSquare:getX() + ZombRand(-PlayerPositionOffset, PlayerPositionOffset), CurrentSquare:getY() + ZombRand(-PlayerPositionOffset, PlayerPositionOffset), HordeDistance * 1.5)
            end
        else
            if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
                print(DebugPrefix, "Player CurrentSquare not found. Cancelled storm phase update.")
            end
        end

        if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
            print(DebugPrefix, "The storm phase is in progress. Sending horde to player(s).")
        end
    else
        if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
            print(DebugPrefix, "Player not found. Cancelled storm phase update.")
        end
    end
end

local function PlayStormSounds()
    local Player = getPlayer()
    if Player:isAlive() and Player ~= nil then

        if SoundType == 3 then

            local CurrentSquare = Player:getCurrentSquare()
            BaseSoundManager:PlaySound("Rumble", false, 0.01)

            if CurrentSquare then
                local x1 = CurrentSquare:getX() + HordeDistance
                local y1 = CurrentSquare:getY() + HordeDistance
                local x2 = CurrentSquare:getX() - HordeDistance
                local y2 = CurrentSquare:getY() - HordeDistance

                local WindIntensity = Utils.RoundFloat(getClimateManager():getWindIntensity(), 2)
                local Sound = getWorld():getFreeEmitter()
                Sound:setVolume(WindIntensity, 1.0)
                Sound:setPos(x1, y1, 0)
                --Sound:playSoundImpl("Wind" .. ZombRand(1, 4), false, nil)
                Sound:playSoundImpl("Zombies" .. ZombRand(1, 4), false, nil)
                Sound:setPos(x2, y1, 0)
                --Sound:playSoundImpl("Wind" .. ZombRand(1, 4), false, nil)
                Sound:playSoundImpl("Zombies" .. ZombRand(1, 4), false, nil)
                Sound:setPos(x1, y2, 0)
                --Sound:playSoundImpl("Wind" .. ZombRand(1, 4), false, nil)
                Sound:playSoundImpl("Zombies" .. ZombRand(1, 4), false, nil)
                Sound:setPos(x2, y2, 0)
                --Sound:playSoundImpl("Wind" .. ZombRand(1, 4), false, nil)
                Sound:playSoundImpl("Zombies" .. ZombRand(1, 4), false, nil)
            else
                print(DebugPrefix, "Player CurrentSquare not found. Cancelled PlayStormSounds().")
            end
        elseif SoundType == 2 then
            BaseSoundManager:PlaySound("Hunt" .. ZombRand(1, 4), false, 0.1)
        elseif SoundType == 1 then
            return
        end
    end
end

local function CyclePhases()
	CycleCounter = CBTSData.Data.Counter 

    UpdateSandboxVars()

    if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
        print("-----------------------------------------------------------")
    end

    if CycleCounter < CooldownPhaseDuration then
        if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
            print(DebugPrefix, "The calm phase begins in: ", CooldownPhaseDuration - CycleCounter, " in-game minute(s).")
        end
    end

    if (CycleCounter > CooldownPhaseDuration) and (CycleCounter < CooldownPhaseDuration + CalmPhaseDuration) then
        CalmPhase()
        if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0  and EnableLogging  then
            print(DebugPrefix, "The storm phase begins in ",  ((CooldownPhaseDuration + CalmPhaseDuration) - CycleCounter), " in-game minute(s).")
        end
    end

    if CycleCounter == CooldownPhaseDuration + CalmPhaseDuration then
        if StormPhaseDuration > 0.0 then
            --BaseSoundManager:PlaySound("Hunt" .. ZombRand(1, 4), false, 0.1)
            PlayStormSounds()
        end
    end

    if CycleCounter % MinutesBetweenZombieCalls == 0 then
        if (CycleCounter > CooldownPhaseDuration + CalmPhaseDuration) and (CycleCounter < CooldownPhaseDuration + CalmPhaseDuration + StormPhaseDuration) then
            StormPhase()
        end
    end

    --[[if not CallZombiesOnce then
        if (CycleCounter > CooldownPhaseDuration + CalmPhaseDuration) and (CycleCounter < CooldownPhaseDuration + CalmPhaseDuration + StormPhaseDuration) then
            StormPhase()
        end
    else
        if CycleCounter == CooldownPhaseDuration + CalmPhaseDuration then
            StormPhase()
        end
    end

    Old code using the now-retired 'call zombies once' option

    ]]

    if CycleCounter == CooldownPhaseDuration + CalmPhaseDuration then
        if getPlayer():isAsleep() then
            getPlayer():forceAwake()
        end
    end

    if CycleCounter > CooldownPhaseDuration + CalmPhaseDuration + StormPhaseDuration then
        CBTSData.Reset()
    end

    if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
        print(DebugPrefix, "Full Event Cycle Counter: ", CycleCounter, "/", CooldownPhaseDuration + CalmPhaseDuration + StormPhaseDuration)
    end

    if (CycleCounter)%(DebugMinutesToUpdateConsole) == 0 and EnableLogging then
        print("-----------------------------------------------------------")
    end

end

Events.EveryOneMinute.Add(CyclePhases)
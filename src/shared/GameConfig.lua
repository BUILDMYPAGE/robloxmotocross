--[[
    GameConfig.lua - Shared Game Configuration
    
    This module contains shared configuration values for the motocross game.
    It can be used by both client and server scripts to maintain consistency.
    
    Usage: Place in ReplicatedStorage or require from shared folder
--]]

local GameConfig = {}

-- Bike Physics Configuration
GameConfig.Bike = {
    MaxSpeed = 100,              -- Maximum bike speed
    Acceleration = 50,           -- Acceleration rate
    BrakeForce = 80,            -- Braking force
    TurnSpeed = 50,             -- Steering sensitivity
    SuspensionForce = 5000,     -- Suspension spring force
    SuspensionDamping = 500,    -- Suspension damping
    BalanceForce = 2000,        -- Balance control force
    AntiFlipForce = 1500,       -- Anti-flip assistance force
    WheelFriction = 1.5,        -- Wheel friction coefficient
    
    -- Bike dimensions
    FrameSize = Vector3.new(6, 2, 2),
    WheelSize = Vector3.new(0.5, 3, 3),
    SeatSize = Vector3.new(2, 0.5, 2),
    HandlebarSize = Vector3.new(3, 0.2, 0.2)
}

-- Track Configuration
GameConfig.Track = {
    TrackWidth = 20,            -- Width of track segments
    CheckpointCount = 10,       -- Number of checkpoints per lap
    LapCount = 3,               -- Number of laps in a race
    RampHeight = 8,             -- Maximum ramp height
    ObstacleFrequency = 0.3,    -- Probability of obstacles (0-1)
    
    -- Track piece dimensions
    SegmentLength = 10,         -- Length of each track segment
    RampAngle = 15,            -- Maximum ramp angle in degrees
    BankingAngle = 10          -- Maximum banking angle for turns
}

-- Race Configuration
GameConfig.Race = {
    MaxPlayers = 8,             -- Maximum players in a race
    MinPlayersToStart = 2,      -- Minimum players to auto-start
    CountdownTime = 10,         -- Race countdown in seconds
    RaceTimeLimit = 600,        -- Maximum race time (10 minutes)
    
    -- Position calculation
    CheckpointRadius = 15,      -- Detection radius for checkpoints
    PositionUpdateRate = 0.5,   -- How often to update positions (seconds)
    
    -- Anti-spam protection
    SpawnCooldown = 5,          -- Seconds between bike spawns
    MinBikeDistance = 10        -- Minimum distance between bikes
}

-- Input Configuration
GameConfig.Input = {
    -- Keyboard controls
    ThrottleKeys = {"W", "Up"},
    BrakeKeys = {"S", "Down"},
    SteerLeftKeys = {"A", "Left"},
    SteerRightKeys = {"D", "Right"},
    SpawnBikeKey = "R",
    ResetBikeKey = "T",
    
    -- Input processing
    InputSmoothing = 0.1,       -- Input smoothing factor
    DeadZone = 0.05,           -- Input dead zone
    MaxInputRate = 60          -- Maximum input updates per second
}

-- UI Configuration
GameConfig.UI = {
    -- Colors
    PrimaryColor = Color3.fromRGB(255, 215, 0),      -- Gold
    SecondaryColor = Color3.fromRGB(0, 100, 200),    -- Blue
    BackgroundColor = Color3.fromRGB(30, 30, 30),    -- Dark gray
    TextColor = Color3.fromRGB(255, 255, 255),       -- White
    
    -- Position colors
    FirstPlaceColor = Color3.fromRGB(255, 215, 0),   -- Gold
    SecondPlaceColor = Color3.fromRGB(192, 192, 192), -- Silver
    ThirdPlaceColor = Color3.fromRGB(205, 127, 50),  -- Bronze
    
    -- Animation settings
    TweenTime = 0.3,           -- Default tween duration
    CountdownScale = 2.0,      -- Scale factor for countdown text
    
    -- Mobile controls
    MobileButtonSize = UDim2.new(0, 80, 0, 80),
    MobileButtonSpacing = 10
}

-- Audio Configuration
GameConfig.Audio = {
    EngineVolume = 0.8,        -- Engine sound volume
    EffectsVolume = 0.6,       -- Sound effects volume
    MusicVolume = 0.4,         -- Background music volume
    
    -- Engine sound configuration
    IdleRPM = 1000,           -- Engine idle RPM
    MaxRPM = 8000,            -- Maximum engine RPM
    RPMToPitch = 0.0002       -- RPM to pitch conversion factor
}

-- Reward Configuration
GameConfig.Rewards = {
    -- Points for finishing positions
    PositionPoints = {
        [1] = 100,  -- 1st place
        [2] = 80,   -- 2nd place
        [3] = 60,   -- 3rd place
        [4] = 40,   -- 4th place
        [5] = 20,   -- 5th place
        [6] = 10,   -- 6th place
        [7] = 5,    -- 7th place
        [8] = 1     -- 8th place
    },
    
    -- Bonus points
    FastestLapBonus = 25,     -- Bonus for fastest lap
    ConsistencyBonus = 15,    -- Bonus for consistent lap times
    ParticipationPoints = 5   -- Points just for participating
}

-- Physics Constants
GameConfig.Physics = {
    Gravity = 196.2,          -- Roblox gravity (studs/s²)
    AirDensity = 1.225,       -- Air density for drag calculations
    DragCoefficient = 0.3,    -- Bike drag coefficient
    RollingResistance = 0.02, -- Rolling resistance coefficient
    
    -- Collision detection
    RaycastDistance = 10,     -- Distance for ground detection
    CollisionLayers = {       -- Collision layer configuration
        Bike = 1,
        Track = 2,
        Checkpoint = 3,
        Obstacle = 4
    }
}

-- Network Configuration
GameConfig.Network = {
    InputSendRate = 30,       -- Input updates per second to server
    PositionSyncRate = 10,    -- Position syncs per second
    MaxPacketSize = 1024,     -- Maximum packet size in bytes
    CompressionEnabled = true, -- Enable data compression
    
    -- Remote event throttling
    BikeControlThrottle = 0.033,  -- ~30 FPS
    PositionUpdateThrottle = 0.1,  -- 10 FPS
    UIUpdateThrottle = 0.2        -- 5 FPS
}

-- Development Configuration
GameConfig.Debug = {
    ShowPhysicsDebug = false,    -- Show physics debug visuals
    ShowCheckpointDebug = false, -- Show checkpoint debug info
    ShowNetworkDebug = false,    -- Show network debug info
    LogLevel = "INFO",           -- DEBUG, INFO, WARN, ERROR
    
    -- Performance monitoring
    EnableProfiler = false,      -- Enable performance profiler
    MaxMemoryUsage = 512,       -- Max memory usage in MB
    TargetFPS = 60              -- Target frame rate
}

-- Asset Configuration
GameConfig.Assets = {
    -- Required models and assets
    BikeModelId = nil,          -- Custom bike model ID (optional)
    TrackTextureId = nil,       -- Custom track texture ID (optional)
    
    -- Sound IDs
    EngineSound = nil,          -- Engine sound ID
    CrashSound = nil,           -- Crash sound ID
    CheckpointSound = nil,      -- Checkpoint sound ID
    FinishSound = nil,          -- Finish line sound ID
    
    -- Particle effects
    ExhaustParticles = true,    -- Enable exhaust particles
    DustParticles = true,       -- Enable dust particles
    SparkParticles = true       -- Enable spark particles on contact
}

-- Validation functions
function GameConfig.validateBikeConfig(config)
    assert(config.MaxSpeed > 0, "MaxSpeed must be positive")
    assert(config.Acceleration > 0, "Acceleration must be positive")
    assert(config.BrakeForce > 0, "BrakeForce must be positive")
    assert(config.SuspensionForce > 0, "SuspensionForce must be positive")
    assert(config.BalanceForce > 0, "BalanceForce must be positive")
end

function GameConfig.validateTrackConfig(config)
    assert(config.TrackWidth > 0, "TrackWidth must be positive")
    assert(config.CheckpointCount > 0, "CheckpointCount must be positive")
    assert(config.LapCount > 0, "LapCount must be positive")
    assert(config.ObstacleFrequency >= 0 and config.ObstacleFrequency <= 1, 
           "ObstacleFrequency must be between 0 and 1")
end

function GameConfig.validateRaceConfig(config)
    assert(config.MaxPlayers > 0, "MaxPlayers must be positive")
    assert(config.MinPlayersToStart > 0, "MinPlayersToStart must be positive")
    assert(config.MinPlayersToStart <= config.MaxPlayers, 
           "MinPlayersToStart cannot exceed MaxPlayers")
    assert(config.CountdownTime > 0, "CountdownTime must be positive")
end

-- Utility functions
function GameConfig.getPositionSuffix(position)
    if position == 1 then return "st"
    elseif position == 2 then return "nd"
    elseif position == 3 then return "rd"
    else return "th" end
end

function GameConfig.formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    return string.format("%d:%05.2f", minutes, remainingSeconds)
end

function GameConfig.interpolate(a, b, t)
    return a + (b - a) * math.max(0, math.min(1, t))
end

function GameConfig.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Validate all configurations on module load
GameConfig.validateBikeConfig(GameConfig.Bike)
GameConfig.validateTrackConfig(GameConfig.Track)
GameConfig.validateRaceConfig(GameConfig.Race)

return GameConfig

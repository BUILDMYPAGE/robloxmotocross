--[[
    Main.server.lua - Main Server Initialization Script
    
    This script should be placed in ServerScriptService and will initialize
    the entire motocross racing game system.
    
    It handles:
    - Loading all game modules
    - Setting up RemoteEvents
    - Initializing the game manager
    - Error handling and logging
    
    Usage: Place in ServerScriptService as the main entry point
--]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Create RemoteEvents folder if it doesn't exist
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

-- Create required RemoteEvents
local function createRemoteEvent(name)
    local existing = remoteEvents:FindFirstChild(name)
    if not existing then
        local remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = remoteEvents
        return remoteEvent
    end
    return existing
end

local function createRemoteFunction(name)
    local existing = remoteEvents:FindFirstChild(name)
    if not existing then
        local remoteFunction = Instance.new("RemoteFunction")
        remoteFunction.Name = name
        remoteFunction.Parent = remoteEvents
        return remoteFunction
    end
    return existing
end

-- Create all required remote events
local bikeControlEvent = createRemoteEvent("BikeControl")
local raceUpdateEvent = createRemoteEvent("RaceUpdate")
local spawnBikeEvent = createRemoteEvent("SpawnBike")
local gameStateEvent = createRemoteEvent("GameState")
local playerDataEvent = createRemoteEvent("PlayerData")

-- Create remote functions for client queries
local getGameDataFunction = createRemoteFunction("GetGameData")
local getPlayerStatsFunction = createRemoteFunction("GetPlayerStats")

print("🏁 Motocross Racing Game - Server Starting...")

-- Wait for the source folder to be available
local sourceFolder = script.Parent:WaitForChild("src", 5)
if not sourceFolder then
    -- If src folder doesn't exist in expected location, create a fallback
    print("⚠️ Source folder not found in expected location. Using script.Parent...")
    sourceFolder = script.Parent
end

-- Load shared configuration
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = nil

-- Try to load GameConfig from ReplicatedStorage (where shared modules should be)
local success, result = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("GameConfig"))
end)

if success then
    GameConfig = result
    print("✅ Game configuration loaded from ReplicatedStorage")
else
    -- Fallback configuration if shared module not found
    print("⚠️ Using fallback GameConfig - shared module not found")
    GameConfig = {
        -- Basic fallback config
        SPAWN_LOCATIONS = {
            Vector3.new(0, 10, 0)
        },
        BIKE_CONFIG = {
            MAX_SPEED = 100,
            ACCELERATION = 50
        }
    }
end

-- Load server modules with error handling
local function safeRequire(module, moduleName)
    local success, result = pcall(require, module)
    if success then
        print("✅ " .. moduleName .. " loaded successfully")
        return result
    else
        warn("❌ Failed to load " .. moduleName .. ": " .. tostring(result))
        return nil
    end
end

-- Try to load modules from the expected structure
local DirtBike = safeRequire(script.Parent.server.DirtBike, "DirtBike")
local RaceTrack = safeRequire(script.Parent.server.RaceTrack, "RaceTrack")
local GameManager = safeRequire(script.Parent.server.GameManager, "GameManager")

-- If modules didn't load, provide fallback functionality
if not DirtBike or not RaceTrack or not GameManager then
    warn("⚠️ Some modules failed to load. Game may not function properly.")
    warn("📁 Please ensure the following file structure exists:")
    warn("   ServerScriptService/")
    warn("   ├── Main.server.lua (this file)")
    warn("   ├── server/")
    warn("   │   ├── DirtBike.lua")
    warn("   │   ├── RaceTrack.lua")
    warn("   │   └── GameManager.lua")
    warn("   ├── client/")
    warn("   │   ├── InputController.lua")
    warn("   │   └── UIManager.lua")
    warn("   └── shared/")
    warn("       └── GameConfig.lua")
end

-- Initialize game systems
local gameManager = nil
local gameInitialized = false

local function initializeGame()
    if gameInitialized then return end
    
    print("🎮 Initializing Motocross Racing Game...")
    
    -- Setup basic workspace environment
    local function setupWorkspace()
        -- Ensure proper lighting for outdoor racing
        local lighting = game:GetService("Lighting")
        lighting.Brightness = 2
        lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
        lighting.TimeOfDay = "14:00:00" -- Afternoon lighting
        lighting.FogEnd = 1000
        lighting.FogStart = 500
        
        -- Add basic sky if none exists
        if not lighting:FindFirstChildOfClass("Sky") then
            local sky = Instance.new("Sky")
            sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.jpg"
            sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.jpg"
            sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.jpg"
            sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.jpg"
            sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.jpg"
            sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.jpg"
            sky.Parent = lighting
        end
        
        -- Set spawn location
        local spawnLocation = workspace:FindFirstChild("SpawnLocation")
        if not spawnLocation then
            spawnLocation = Instance.new("SpawnLocation")
            spawnLocation.Name = "SpawnLocation"
            spawnLocation.Size = Vector3.new(20, 2, 20)
            spawnLocation.Position = Vector3.new(0, 5, -30)
            spawnLocation.BrickColor = BrickColor.new("Bright green")
            spawnLocation.Material = Enum.Material.Neon
            spawnLocation.CanCollide = true
            spawnLocation.Anchored = true
            spawnLocation.Parent = workspace
            
            -- Add spawn location label
            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Face = Enum.NormalId.Top
            surfaceGui.Parent = spawnLocation
            
            local spawnLabel = Instance.new("TextLabel")
            spawnLabel.Size = UDim2.new(1, 0, 1, 0)
            spawnLabel.BackgroundTransparency = 1
            spawnLabel.Text = "PLAYER SPAWN"
            spawnLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
            spawnLabel.TextScaled = true
            spawnLabel.Font = Enum.Font.HighwayGothic
            spawnLabel.Parent = surfaceGui
        end
        
        print("✅ Workspace environment configured")
    end
    
    -- Setup remote event handlers
    local function setupRemoteEvents()
        -- Basic bike control handler (fallback if GameManager doesn't load)
        bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
            -- This will be overridden by GameManager if it loads properly
            print(player.Name .. " sent input: " .. inputType .. " = " .. tostring(inputValue))
        end)
        
        spawnBikeEvent.OnServerEvent:Connect(function(player)
            print("⚠️ Main server bike spawning disabled - TestServer handles spawning")
            -- Disabled to prevent conflicts with TestServer
            -- This will be overridden by GameManager if it loads properly
        end)
        
        -- Handle client data requests
        getGameDataFunction.OnServerInvoke = function(player)
            return {
                gameState = "waiting",
                playerCount = #Players:GetPlayers(),
                trackLoaded = true,
                serverTime = tick()
            }
        end
        
        print("✅ Remote events configured")
    end
    
    -- Initialize game components
    setupWorkspace()
    setupRemoteEvents()
    
    -- Try to initialize GameManager if available
    if GameManager then
        local success, result = pcall(function()
            gameManager = GameManager.new()
            return gameManager
        end)
        
        if success and result then
            print("✅ Game Manager initialized successfully")
            gameInitialized = true
        else
            warn("❌ Failed to initialize Game Manager: " .. tostring(result))
            gameInitialized = false
        end
    else
        print("⚠️ GameManager not available - running in basic mode")
        gameInitialized = false
    end
    
    print("🏁 Motocross Racing Game initialization complete!")
    print("📋 Players can join and press R to spawn bikes")
    
    -- Broadcast server ready state
    for _, player in pairs(Players:GetPlayers()) do
        gameStateEvent:FireClient(player, {
            type = "serverReady",
            gameInitialized = gameInitialized,
            hasGameManager = gameManager ~= nil
        })
    end
end

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
    print("🏍️ " .. player.Name .. " joined the motocross server!")
    
    -- Give player basic instructions
    player.Chatted:Connect(function(message)
        local lowerMessage = message:lower()
        if lowerMessage == "/help" or lowerMessage == "help" then
            -- Send help information
            gameStateEvent:FireClient(player, {
                type = "help",
                message = "Welcome to Motocross Racing!\n" ..
                         "• Press R to spawn your bike\n" ..
                         "• Use WASD or Arrow Keys to control\n" ..
                         "• Race through checkpoints to win!\n" ..
                         "• Type /status for server info"
            })
        elseif lowerMessage == "/status" or lowerMessage == "status" then
            gameStateEvent:FireClient(player, {
                type = "status",
                message = "Server Status:\n" ..
                         "• Players: " .. #Players:GetPlayers() .. "/" .. GameConfig.Race.MaxPlayers .. "\n" ..
                         "• Game Manager: " .. (gameManager and "Active" or "Inactive") .. "\n" ..
                         "• Game State: " .. (gameManager and gameManager.gameState or "Unknown")
            })
        end
    end)
    
    -- Send welcome message after a short delay
    wait(2)
    if player.Parent then -- Check if player is still connected
        gameStateEvent:FireClient(player, {
            type = "welcome",
            message = "Welcome to Motocross Racing! Press R to spawn your bike and start racing!"
        })
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 " .. player.Name .. " left the motocross server")
end)

-- Start game initialization
spawn(function()
    wait(1) -- Small delay to ensure everything is loaded
    initializeGame()
end)

-- Performance monitoring
local lastMemoryCheck = tick()
local function monitorPerformance()
    local currentTime = tick()
    
    -- Check memory usage every 30 seconds
    if currentTime - lastMemoryCheck > 30 then
        lastMemoryCheck = currentTime
        
        local memoryUsage = gcinfo() / 1024 -- Convert to MB
        if memoryUsage > GameConfig.Debug.MaxMemoryUsage then
            warn("⚠️ High memory usage detected: " .. math.floor(memoryUsage) .. "MB")
        end
        
        -- Log server status
        if GameConfig.Debug.LogLevel == "DEBUG" then
            print("📊 Server Status - Players: " .. #Players:GetPlayers() .. 
                  ", Memory: " .. math.floor(memoryUsage) .. "MB")
        end
    end
end

-- Performance monitoring loop
RunService.Heartbeat:Connect(monitorPerformance)

print("🚀 Motocross Racing Server is ready for players!")
print("📚 Available commands: /help, /status")

-- Export global reference for debugging
_G.MotocrossServer = {
    gameManager = gameManager,
    config = GameConfig,
    version = "1.0.0"
}

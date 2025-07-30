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
        },
        Race = {
            MaxPlayers = 10
        },
        Debug = {
            MaxMemoryUsage = 500,
            LogLevel = "INFO"
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
local playerBikes = {} -- Store player bikes for input handling
local playerInputs = {} -- Store player input states

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
            -- Find the player's bike
            local bike = nil
            for _, obj in pairs(workspace:GetChildren()) do
                if obj.Name == player.Name .. "_MainBike" and obj:IsA("Model") then
                    bike = obj
                    break
                end
            end
            
            if not bike then
                return -- No bike found, silently ignore
            end
            
            -- Initialize input state if needed
            if not playerInputs[player.Name] then
                playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
            end
            
            -- Update the specific input
            if inputType == "throttle" then
                playerInputs[player.Name].throttle = inputValue
            elseif inputType == "brake" then
                playerInputs[player.Name].brake = inputValue
            elseif inputType == "steer" then
                playerInputs[player.Name].steer = inputValue
            end
            
            -- Apply controls to the bike
            local seat = bike:FindFirstChild("VehicleSeat")
            if seat and seat:IsA("VehicleSeat") then
                local throttleValue = playerInputs[player.Name].throttle - playerInputs[player.Name].brake
                seat.Throttle = throttleValue
                seat.Steer = playerInputs[player.Name].steer
                
                -- Debug significant movements only
                if math.abs(throttleValue) > 0.3 or math.abs(playerInputs[player.Name].steer) > 0.3 then
                    print("🏍️ " .. player.Name .. " controlling motocross bike: Throttle=" .. string.format("%.1f", throttleValue) .. ", Steer=" .. string.format("%.1f", playerInputs[player.Name].steer))
                end
            end
        end)
        
        spawnBikeEvent.OnServerEvent:Connect(function(player)
            print("🏍️ " .. player.Name .. " requested bike spawn via Main server")
            
            -- Basic bike spawning functionality
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                print("❌ " .. player.Name .. " - Character not ready")
                return
            end
            
            -- Remove any existing bikes for this player
            for _, obj in pairs(workspace:GetChildren()) do
                if string.find(obj.Name, player.Name .. "_") and string.find(obj.Name, "Bike") then
                    print("🗑️ Removing existing bike: " .. obj.Name)
                    obj:Destroy()
                end
            end
            
            -- Create new motocross bike model
            local bike = Instance.new("Model")
            bike.Name = player.Name .. "_MainBike"
            bike.Parent = workspace
            
            local spawnPos = player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 10)
            
            -- Create main frame (chassis)
            local frame = Instance.new("Part")
            frame.Name = "Frame"
            frame.Size = Vector3.new(6, 0.5, 1.5)
            frame.Position = spawnPos
            frame.BrickColor = BrickColor.new("Really black")
            frame.Material = Enum.Material.Metal
            frame.CanCollide = false
            frame.Parent = bike
            
            -- Create vehicle seat (rider position) - positioned for straddling
            local seat = Instance.new("VehicleSeat")
            seat.Name = "VehicleSeat"
            seat.Size = Vector3.new(2, 0.8, 1.8)  -- Made wider for straddling
            seat.Position = spawnPos + Vector3.new(-0.5, 1.2, 0)  -- Raised higher
            seat.BrickColor = BrickColor.new("Bright red")
            seat.Material = Enum.Material.SmoothPlastic
            seat.CanCollide = false
            seat.Anchored = false
            
            -- Rotate seat slightly forward for motocross position
            seat.CFrame = CFrame.new(seat.Position) * CFrame.Angles(math.rad(-5), 0, 0)
            
            -- Motocross bike physics settings
            seat.MaxSpeed = 100
            seat.Torque = 15000
            seat.TurnSpeed = 35
            seat.HeadsUpDisplay = false
            seat.Parent = bike
            
            -- Create engine block
            local engine = Instance.new("Part")
            engine.Name = "Engine"
            engine.Size = Vector3.new(1.5, 1.5, 1)
            engine.Position = spawnPos + Vector3.new(0, 0.5, 0)
            engine.BrickColor = BrickColor.new("Dark stone grey")
            engine.Material = Enum.Material.Metal
            engine.CanCollide = false
            engine.Parent = bike
            
            -- Create gas tank
            local tank = Instance.new("Part")
            tank.Name = "GasTank"
            tank.Size = Vector3.new(2, 1, 1.2)
            tank.Position = spawnPos + Vector3.new(-1, 1.2, 0)
            tank.BrickColor = BrickColor.new("Bright red")
            tank.Material = Enum.Material.SmoothPlastic
            tank.CanCollide = false
            tank.Parent = bike
            
            -- Create handlebars (positioned for rider reach)
            local handlebars = Instance.new("Part")
            handlebars.Name = "Handlebars"
            handlebars.Size = Vector3.new(0.2, 0.2, 3)
            handlebars.Position = spawnPos + Vector3.new(2.5, 2.2, 0)  -- Raised to rider height
            handlebars.BrickColor = BrickColor.new("Really black")
            handlebars.Material = Enum.Material.Metal
            handlebars.CanCollide = false
            handlebars.Parent = bike
            
            -- Create foot pegs for realistic rider position
            local leftFootPeg = Instance.new("Part")
            leftFootPeg.Name = "LeftFootPeg"
            leftFootPeg.Size = Vector3.new(0.8, 0.1, 0.3)
            leftFootPeg.Position = spawnPos + Vector3.new(0.5, 0.2, -1.2)  -- Left side
            leftFootPeg.BrickColor = BrickColor.new("Dark stone grey")
            leftFootPeg.Material = Enum.Material.Metal
            leftFootPeg.CanCollide = false
            leftFootPeg.Parent = bike
            
            local rightFootPeg = Instance.new("Part")
            rightFootPeg.Name = "RightFootPeg"
            rightFootPeg.Size = Vector3.new(0.8, 0.1, 0.3)
            rightFootPeg.Position = spawnPos + Vector3.new(0.5, 0.2, 1.2)  -- Right side
            rightFootPeg.BrickColor = BrickColor.new("Dark stone grey")
            rightFootPeg.Material = Enum.Material.Metal
            rightFootPeg.CanCollide = false
            rightFootPeg.Parent = bike
            
            -- Create front fork
            local frontFork = Instance.new("Part")
            frontFork.Name = "FrontFork"
            frontFork.Size = Vector3.new(0.3, 2, 0.3)
            frontFork.Position = spawnPos + Vector3.new(2.5, 0, 0)
            frontFork.BrickColor = BrickColor.new("Mid gray")
            frontFork.Material = Enum.Material.Metal
            frontFork.CanCollide = false
            frontFork.Parent = bike
            
            -- Create rear shock
            local rearShock = Instance.new("Part")
            rearShock.Name = "RearShock"
            rearShock.Size = Vector3.new(0.2, 1.5, 0.2)
            rearShock.Position = spawnPos + Vector3.new(-2.5, 0.5, 0)
            rearShock.BrickColor = BrickColor.new("Bright yellow")
            rearShock.Material = Enum.Material.Neon
            rearShock.CanCollide = false
            rearShock.Parent = bike
            
            -- Create exhaust pipe
            local exhaust = Instance.new("Part")
            exhaust.Name = "Exhaust"
            exhaust.Size = Vector3.new(0.3, 0.3, 2)
            exhaust.Position = spawnPos + Vector3.new(-1, -0.5, 1.5)
            exhaust.BrickColor = BrickColor.new("Dark stone grey")
            exhaust.Material = Enum.Material.Metal
            exhaust.CanCollide = false
            exhaust.Parent = bike
            
            -- Create realistic wheels with better proportions
            local function createMotocrossWheel(name, position, size, isFront)
                -- Main wheel (tire)
                local wheel = Instance.new("Part")
                wheel.Name = name
                wheel.Shape = Enum.PartType.Cylinder
                wheel.Size = size
                wheel.Position = position
                wheel.BrickColor = BrickColor.new("Really black")
                wheel.Material = Enum.Material.Rubber
                wheel.CanCollide = true
                wheel.Parent = bike
                
                -- Rim
                local rim = Instance.new("Part")
                rim.Name = name .. "Rim"
                rim.Shape = Enum.PartType.Cylinder
                rim.Size = Vector3.new(size.X * 0.3, size.Y * 0.7, size.Z * 0.7)
                rim.Position = position
                rim.BrickColor = BrickColor.new("Aluminum")
                rim.Material = Enum.Material.Metal
                rim.CanCollide = false
                rim.Parent = bike
                
                -- Spokes effect
                local spokes = Instance.new("Part")
                spokes.Name = name .. "Spokes"
                spokes.Shape = Enum.PartType.Cylinder
                spokes.Size = Vector3.new(size.X * 0.1, size.Y * 0.5, size.Z * 0.5)
                spokes.Position = position
                spokes.BrickColor = BrickColor.new("Light stone grey")
                spokes.Material = Enum.Material.Metal
                spokes.CanCollide = false
                spokes.Parent = bike
                
                -- Weld wheel components together
                local rimWeld = Instance.new("WeldConstraint")
                rimWeld.Part0 = wheel
                rimWeld.Part1 = rim
                rimWeld.Parent = bike
                
                local spokesWeld = Instance.new("WeldConstraint")
                spokesWeld.Part0 = wheel
                spokesWeld.Part1 = spokes
                spokesWeld.Parent = bike
                
                -- Weld wheel to frame
                local frameWeld = Instance.new("WeldConstraint")
                frameWeld.Part0 = frame
                frameWeld.Part1 = wheel
                frameWeld.Parent = bike
                
                return wheel
            end
            
            -- Create front wheel (smaller, for steering)
            local frontWheel = createMotocrossWheel(
                "FrontWheel", 
                spawnPos + Vector3.new(2.5, -1.5, 0), 
                Vector3.new(0.5, 2.2, 2.2), 
                true
            )
            
            -- Create rear wheel (larger, for power)
            local rearWheel = createMotocrossWheel(
                "BackWheel", 
                spawnPos + Vector3.new(-2.5, -1.5, 0), 
                Vector3.new(0.6, 2.8, 2.8), 
                false
            )
            
            -- Weld all parts to the frame
            local parts = {seat, engine, tank, handlebars, frontFork, rearShock, exhaust, leftFootPeg, rightFootPeg}
            for _, part in pairs(parts) do
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = frame
                weld.Part1 = part
                weld.Parent = bike
            end
            
            -- Set primary part to the frame for better physics
            bike.PrimaryPart = frame
            
            print("✅ Created realistic motocross bike for " .. player.Name .. " via Main server")
            
            -- Auto-sit the player on the realistic motocross bike
            spawn(function()
                wait(1)
                if player.Character and player.Character:FindFirstChild("Humanoid") and bike.Parent then
                    local vehicleSeat = bike:FindFirstChild("VehicleSeat")
                    if vehicleSeat then
                        -- Ensure the seat is properly positioned for straddling
                        vehicleSeat.Disabled = false
                        
                        -- Force the player to sit on the bike
                        vehicleSeat:Sit(player.Character.Humanoid)
                        
                        print("✅ " .. player.Name .. " is now straddling the motocross bike! Use WASD!")
                        
                        -- Additional check to ensure proper seating
                        wait(0.5)
                        if not player.Character.Humanoid.Sit then
                            print("🔄 Retrying seat positioning for " .. player.Name)
                            vehicleSeat:Sit(player.Character.Humanoid)
                        end
                    end
                end
            end)
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
            local maxPlayers = (GameConfig.Race and GameConfig.Race.MaxPlayers) or "Unknown"
            gameStateEvent:FireClient(player, {
                type = "status",
                message = "Server Status:\n" ..
                         "• Players: " .. #Players:GetPlayers() .. "/" .. maxPlayers .. "\n" ..
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
    
    -- Clean up player's bike
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, player.Name .. "_") and string.find(obj.Name, "Bike") then
            print("🧹 Cleaning up bike: " .. obj.Name)
            obj:Destroy()
        end
    end
    
    -- Clean up player data
    playerInputs[player.Name] = nil
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
        if GameConfig.Debug and GameConfig.Debug.MaxMemoryUsage and memoryUsage > GameConfig.Debug.MaxMemoryUsage then
            warn("⚠️ High memory usage detected: " .. math.floor(memoryUsage) .. "MB")
        end
        
        -- Log server status
        if GameConfig.Debug and GameConfig.Debug.LogLevel == "DEBUG" then
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

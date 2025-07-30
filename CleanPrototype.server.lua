--[[
    CleanPrototype.server.lua - Working Motocross Bike Prototype
    
    This is a clean, simple implementation that focuses on getting the basics working:
    - Press R to spawn a bike
    - Use WASD to control the bike
    - Proper physics and movement
    
    Place this in ServerScriptService and delete other server scripts to avoid conflicts.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

print("🏁 CLEAN MOTOCROSS PROTOTYPE STARTING...")

-- AGGRESSIVE CLEANUP - Disable conflicting scripts immediately
local ServerScriptService = game:GetService("ServerScriptService")
local scriptsToDisable = {"Main", "TestServer", "SimpleServer", "GameManager", "RemoteEventsSetup"}

for _, scriptName in pairs(scriptsToDisable) do
    local script = ServerScriptService:FindFirstChild(scriptName)
    if script and script:IsA("Script") then
        script.Disabled = true
        print("🚫 DISABLED CONFLICTING SCRIPT: " .. scriptName)
    end
end

-- Wait a moment for other scripts to stop
wait(0.5)

-- Clean up any existing RemoteEvents to start fresh
local existingRemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if existingRemoteEvents then
    existingRemoteEvents:Destroy()
    print("🧹 Removed existing RemoteEvents")
    wait(0.1) -- Brief pause to ensure cleanup
end

-- Create fresh RemoteEvents with unique names to avoid conflicts
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

-- Use unique names to prevent conflicts with old scripts
local spawnBikeEvent = Instance.new("RemoteEvent")
spawnBikeEvent.Name = "CleanSpawnBike"  -- Unique name
spawnBikeEvent.Parent = remoteEvents

local bikeControlEvent = Instance.new("RemoteEvent")
bikeControlEvent.Name = "CleanBikeControl"  -- Unique name
bikeControlEvent.Parent = remoteEvents

-- Also create the old names for compatibility but immediately take control
local oldSpawnBike = Instance.new("RemoteEvent")
oldSpawnBike.Name = "SpawnBike"
oldSpawnBike.Parent = remoteEvents

local oldBikeControl = Instance.new("RemoteEvent")
oldBikeControl.Name = "BikeControl"
oldBikeControl.Parent = remoteEvents

print("✅ Created fresh RemoteEvents with unique names")

-- Connect to BOTH old and new event names to ensure we capture all requests
local function handleSpawnRequest(player)
    print("🏍️ CLEANPROTOTYPE: Spawn request from " .. player.Name)
    
    local spawnPosition = Vector3.new(0, 10, -20)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        spawnPosition = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-5, 5), 5, 10)
    end
    
    createBike(player, spawnPosition)
end

local function handleControlInput(player, inputType, inputValue)
    if not playerInputs[player.Name] then
        playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
    end
    
    if inputType == "throttle" then
        playerInputs[player.Name].throttle = inputValue
    elseif inputType == "brake" then
        playerInputs[player.Name].brake = inputValue
    elseif inputType == "steer" then
        playerInputs[player.Name].steer = inputValue
    end
    
    if inputValue > 0 then
        print("🎮 CLEANPROTOTYPE: " .. player.Name .. " input: " .. inputType .. " = " .. inputValue)
    end
end

-- Store player bikes and input states
local playerBikes = {}
local playerInputs = {}

-- Bike configuration
local BIKE_CONFIG = {
    MaxSpeed = 80,
    Acceleration = 30,
    BrakeForce = 40,
    TurnSpeed = 25,
    BodyVelocityForce = 50000,
    BodyAngularVelocityForce = 50000
}

-- Create a simple but effective bike
local function createBike(player, spawnPosition)
    print("🏗️ Creating bike for " .. player.Name)
    
    -- Clean up any existing bike first
    if playerBikes[player.Name] then
        playerBikes[player.Name]:Destroy()
        playerBikes[player.Name] = nil
    end
    
    -- Create bike model
    local bike = Instance.new("Model")
    bike.Name = player.Name .. "_Bike"
    bike.Parent = workspace
    
    -- Main bike frame
    local frame = Instance.new("Part")
    frame.Name = "Frame"
    frame.Size = Vector3.new(6, 2, 2)
    frame.Position = spawnPosition
    frame.Material = Enum.Material.Metal
    frame.BrickColor = BrickColor.new("Bright red")
    frame.CanCollide = true
    frame.Shape = Enum.PartType.Block
    frame.Parent = bike
    
    -- Add some mass for stability
    frame.AssemblyMass = 20
    
    -- Create seat
    local seat = Instance.new("Seat")
    seat.Name = "BikeSeat"
    seat.Size = Vector3.new(2, 0.5, 2)
    seat.Position = spawnPosition + Vector3.new(0, 1.5, 0)
    seat.Material = Enum.Material.Fabric
    seat.BrickColor = BrickColor.new("Black")
    seat.CanCollide = false
    seat.Parent = bike
    
    -- Weld seat to frame
    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = frame
    seatWeld.Part1 = seat
    seatWeld.Parent = bike
    
    -- Create wheels
    local function createWheel(name, offset, size)
        local wheel = Instance.new("Part")
        wheel.Name = name
        wheel.Size = size or Vector3.new(0.5, 3, 3)
        wheel.Shape = Enum.PartType.Cylinder
        wheel.Position = spawnPosition + offset
        wheel.Material = Enum.Material.Rubber
        wheel.BrickColor = BrickColor.new("Really black")
        wheel.CanCollide = true
        wheel.Parent = bike
        
        -- Create attachment points
        local frameAttachment = Instance.new("Attachment")
        frameAttachment.Position = offset
        frameAttachment.Parent = frame
        
        local wheelAttachment = Instance.new("Attachment")
        wheelAttachment.Parent = wheel
        
        -- Create spring constraint for suspension
        local spring = Instance.new("SpringConstraint")
        spring.Attachment0 = frameAttachment
        spring.Attachment1 = wheelAttachment
        spring.Stiffness = 3000
        spring.Damping = 300
        spring.FreeLength = 1
        spring.Parent = bike
        
        -- Create hinge for wheel rotation
        local hinge = Instance.new("HingeConstraint")
        hinge.Attachment0 = frameAttachment
        hinge.Attachment1 = wheelAttachment
        hinge.ActuatorType = Enum.ActuatorType.Motor
        hinge.MotorMaxTorque = 10000
        hinge.AngularVelocity = 0
        hinge.Parent = bike
        
        return wheel, hinge
    end
    
    -- Create wheels with hinges
    local frontWheel, frontHinge = createWheel("FrontWheel", Vector3.new(0, -2, -2.5))
    local rearWheel, rearHinge = createWheel("RearWheel", Vector3.new(0, -2, 2.5))
    
    -- Add BodyVelocity and BodyAngularVelocity for movement control
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(BIKE_CONFIG.BodyVelocityForce, 0, BIKE_CONFIG.BodyVelocityForce)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = frame
    
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.MaxTorque = Vector3.new(0, BIKE_CONFIG.BodyAngularVelocityForce, 0)
    bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    bodyAngularVelocity.Parent = frame
    
    -- Store bike data
    local bikeData = {
        model = bike,
        frame = frame,
        seat = seat,
        frontWheel = frontWheel,
        rearWheel = rearWheel,
        frontHinge = frontHinge,
        rearHinge = rearHinge,
        bodyVelocity = bodyVelocity,
        bodyAngularVelocity = bodyAngularVelocity,
        currentSpeed = 0,
        targetSpeed = 0
    }
    
    playerBikes[player.Name] = bikeData
    playerInputs[player.Name] = {
        throttle = 0,
        brake = 0,
        steer = 0
    }
    
    -- Auto-sit the player after a short delay
    spawn(function()
        wait(0.5)
        if player.Character and player.Character:FindFirstChild("Humanoid") and seat.Parent then
            seat:Sit(player.Character.Humanoid)
            print("✅ " .. player.Name .. " is seated on the bike")
        end
    end)
    
    print("✅ Bike created for " .. player.Name)
    return bikeData
end

-- Update bike physics
local function updateBikePhysics(playerName, deltaTime)
    local bikeData = playerBikes[playerName]
    local inputs = playerInputs[playerName]
    
    if not bikeData or not bikeData.frame or not bikeData.frame.Parent then
        return
    end
    
    if not inputs then
        return
    end
    
    local frame = bikeData.frame
    local bodyVelocity = bikeData.bodyVelocity
    local bodyAngularVelocity = bikeData.bodyAngularVelocity
    local frontHinge = bikeData.frontHinge
    local rearHinge = bikeData.rearHinge
    
    -- Calculate target speed based on input
    local throttle = inputs.throttle or 0
    local brake = inputs.brake or 0
    local steer = inputs.steer or 0
    
    -- Update target speed
    if throttle > 0 then
        bikeData.targetSpeed = math.min(bikeData.targetSpeed + BIKE_CONFIG.Acceleration * deltaTime, BIKE_CONFIG.MaxSpeed)
    elseif brake > 0 then
        bikeData.targetSpeed = math.max(bikeData.targetSpeed - BIKE_CONFIG.BrakeForce * deltaTime, 0)
    else
        -- Natural deceleration
        bikeData.targetSpeed = math.max(bikeData.targetSpeed - 15 * deltaTime, 0)
    end
    
    -- Smooth speed transition
    bikeData.currentSpeed = bikeData.currentSpeed + (bikeData.targetSpeed - bikeData.currentSpeed) * deltaTime * 5
    
    -- Apply movement
    local forwardDirection = frame.CFrame.LookVector
    local velocity = forwardDirection * bikeData.currentSpeed
    
    if bodyVelocity then
        bodyVelocity.Velocity = velocity
    end
    
    -- Apply steering
    if math.abs(steer) > 0.1 and bikeData.currentSpeed > 5 then
        local turnRate = BIKE_CONFIG.TurnSpeed * steer * (bikeData.currentSpeed / BIKE_CONFIG.MaxSpeed)
        if bodyAngularVelocity then
            bodyAngularVelocity.AngularVelocity = Vector3.new(0, math.rad(turnRate), 0)
        end
    else
        if bodyAngularVelocity then
            bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        end
    end
    
    -- Update wheel rotation
    local wheelSpeed = bikeData.currentSpeed / 5 -- Convert to angular velocity
    if frontHinge then
        frontHinge.AngularVelocity = wheelSpeed
    end
    if rearHinge then
        rearHinge.AngularVelocity = wheelSpeed
    end
end

-- Create race track
local function createTrack()
    print("🏗️ Creating race track...")
    
    -- Ground
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(500, 2, 500)
    ground.Position = Vector3.new(0, -1, 0)
    ground.Material = Enum.Material.Grass
    ground.BrickColor = BrickColor.new("Bright green")
    ground.Anchored = true
    ground.CanCollide = true
    ground.Parent = workspace
    
    -- Starting line
    local startLine = Instance.new("Part")
    startLine.Name = "StartLine"
    startLine.Size = Vector3.new(20, 0.2, 2)
    startLine.Position = Vector3.new(0, 1, -30)
    startLine.Material = Enum.Material.Neon
    startLine.BrickColor = BrickColor.new("Bright yellow")
    startLine.Anchored = true
    startLine.CanCollide = false
    startLine.Parent = workspace
    
    -- Spawn location for players
    local spawnLocation = workspace:FindFirstChild("SpawnLocation")
    if not spawnLocation then
        spawnLocation = Instance.new("SpawnLocation")
        spawnLocation.Name = "SpawnLocation"
        spawnLocation.Size = Vector3.new(20, 2, 20)
        spawnLocation.Position = Vector3.new(0, 5, -50)
        spawnLocation.BrickColor = BrickColor.new("Bright blue")
        spawnLocation.Material = Enum.Material.Neon
        spawnLocation.CanCollide = true
        spawnLocation.Anchored = true
        spawnLocation.Parent = workspace
    end
    
    -- Create some ramps and obstacles
    local function createRamp(position, size, rotation)
        local ramp = Instance.new("Part")
        ramp.Name = "Ramp"
        ramp.Size = size
        ramp.Position = position
        ramp.Material = Enum.Material.Concrete
        ramp.BrickColor = BrickColor.new("Dark stone grey")
        ramp.Anchored = true
        ramp.CanCollide = true
        if rotation then
            ramp.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
        end
        ramp.Parent = workspace
    end
    
    -- Add some ramps
    createRamp(Vector3.new(-50, 5, 50), Vector3.new(20, 2, 30), {X = 15, Y = 0, Z = 0})
    createRamp(Vector3.new(50, 8, 100), Vector3.new(15, 2, 25), {X = 20, Y = 45, Z = 0})
    createRamp(Vector3.new(0, 3, 150), Vector3.new(30, 2, 20), {X = 10, Y = 0, Z = 0})
    
    print("✅ Race track created")
end

-- Handle bike spawning - FORCE OVERRIDE any existing handlers
-- Connect to both new and old event names
spawnBikeEvent.OnServerEvent:Connect(handleSpawnRequest)
oldSpawnBike.OnServerEvent:Connect(handleSpawnRequest)

-- Handle bike controls - Connect to both event names
bikeControlEvent.OnServerEvent:Connect(handleControlInput)
oldBikeControl.OnServerEvent:Connect(handleControlInput)

print("🔄 CLEANPROTOTYPE: Connected to both old and new RemoteEvent names")

-- Also try to disconnect any existing connections (aggressive override)
spawn(function()
    wait(1)
    -- Clear all existing connections on the spawn event
    pcall(function()
        for connection in pairs(getconnections(spawnBikeEvent.OnServerEvent)) do
            connection:Disconnect()
        end
    end)
    
    -- Reconnect our handler
    spawnBikeEvent.OnServerEvent:Connect(function(player)
        print("🏍️ CLEANPROTOTYPE (OVERRIDE): Spawn request from " .. player.Name)
        
        local spawnPosition = Vector3.new(0, 10, -20)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            spawnPosition = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-5, 5), 5, 10)
        end
        
        createBike(player, spawnPosition)
    end)
    print("🔄 CLEANPROTOTYPE: Event handlers reset and reconnected")
end)

-- Handle bike controls
bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
    if not playerInputs[player.Name] then
        playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
    end
    
    -- Update input value
    if inputType == "throttle" then
        playerInputs[player.Name].throttle = inputValue
    elseif inputType == "brake" then
        playerInputs[player.Name].brake = inputValue
    elseif inputType == "steer" then
        playerInputs[player.Name].steer = inputValue
    end
    
    -- Debug output for input
    if inputValue > 0 then
        print("🎮 " .. player.Name .. " input: " .. inputType .. " = " .. inputValue)
    end
end)

-- Main physics update loop
local lastUpdate = tick()
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    local deltaTime = currentTime - lastUpdate
    lastUpdate = currentTime
    
    -- Update all player bikes
    for playerName, _ in pairs(playerBikes) do
        updateBikePhysics(playerName, deltaTime)
    end
end)

-- Handle player events
Players.PlayerAdded:Connect(function(player)
    print("👋 " .. player.Name .. " joined the motocross server!")
    
    -- Give instructions
    wait(2)
    if player.Parent then
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "🏍️ Welcome " .. player.Name .. "! Press R to spawn your bike, then use WASD to drive!";
            Color = Color3.fromRGB(255, 215, 0);
            Font = Enum.Font.HighwayGothic;
            FontSize = Enum.FontSize.Size18;
        })
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 " .. player.Name .. " left the server")
    
    -- Clean up player data
    if playerBikes[player.Name] then
        playerBikes[player.Name].model:Destroy()
        playerBikes[player.Name] = nil
    end
    playerInputs[player.Name] = nil
end)

-- Create the track
createTrack()

print("🚀 CLEAN MOTOCROSS PROTOTYPE READY!")
print("📋 Players can press R to spawn bikes and use WASD to drive!")

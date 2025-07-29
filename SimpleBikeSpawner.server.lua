-- SimpleBikeSpawner.server.lua
-- Simple, clean bike spawning system
-- Place this in ServerScriptService instead of TestServer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🏍️ Simple Bike Spawner Starting...")

-- Create RemoteEvents if they don't exist
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
end

local spawnBikeEvent = remoteEvents:FindFirstChild("SpawnBike")
if not spawnBikeEvent then
    spawnBikeEvent = Instance.new("RemoteEvent")
    spawnBikeEvent.Name = "SpawnBike"
    spawnBikeEvent.Parent = remoteEvents
end

local bikeControlEvent = remoteEvents:FindFirstChild("BikeControl")
if not bikeControlEvent then
    bikeControlEvent = Instance.new("RemoteEvent")
    bikeControlEvent.Name = "BikeControl"
    bikeControlEvent.Parent = remoteEvents
end

-- Player bike storage
local playerBikes = {}
local playerInputs = {}

-- Handle bike spawning
spawnBikeEvent.OnServerEvent:Connect(function(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        print("❌ " .. player.Name .. " - Character not ready")
        return
    end
    
    print("🏍️ Spawning bike for " .. player.Name)
    
    -- Remove existing bike
    if playerBikes[player.Name] and playerBikes[player.Name].Parent then
        playerBikes[player.Name]:Destroy()
    end
    
    -- Clean up any leftover bikes
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == player.Name .. "_Bike" then
            obj:Destroy()
        end
    end
    
    -- Create new bike
    local bike = Instance.new("Model")
    bike.Name = player.Name .. "_Bike"
    bike.Parent = workspace
    
    -- Create main seat (bright orange for visibility)
    local seat = Instance.new("VehicleSeat")
    seat.Name = "VehicleSeat"
    seat.Size = Vector3.new(6, 1.5, 3)
    seat.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 4, 8)
    seat.BrickColor = BrickColor.new("Bright orange")
    seat.Material = Enum.Material.SmoothPlastic
    seat.CanCollide = true
    seat.Anchored = false
    
    -- Vehicle settings for motocross feel
    seat.MaxSpeed = 80
    seat.Torque = 10000
    seat.TurnSpeed = 20
    seat.HeadsUpDisplay = false
    seat.Parent = bike
    
    -- Create front wheel
    local frontWheel = Instance.new("Part")
    frontWheel.Name = "FrontWheel"
    frontWheel.Shape = Enum.PartType.Cylinder
    frontWheel.Size = Vector3.new(0.8, 2.5, 2.5)
    frontWheel.Position = seat.Position + Vector3.new(2.5, -1, 0)
    frontWheel.BrickColor = BrickColor.new("Really black")
    frontWheel.Material = Enum.Material.Rubber
    frontWheel.CanCollide = true
    frontWheel.Parent = bike
    
    -- Create back wheel
    local backWheel = Instance.new("Part")
    backWheel.Name = "BackWheel"
    backWheel.Shape = Enum.PartType.Cylinder
    backWheel.Size = Vector3.new(0.8, 2.5, 2.5)
    backWheel.Position = seat.Position + Vector3.new(-2.5, -1, 0)
    backWheel.BrickColor = BrickColor.new("Really black")
    backWheel.Material = Enum.Material.Rubber
    backWheel.CanCollide = true
    backWheel.Parent = bike
    
    -- Weld wheels to seat
    local frontWeld = Instance.new("WeldConstraint")
    frontWeld.Part0 = seat
    frontWeld.Part1 = frontWheel
    frontWeld.Parent = bike
    
    local backWeld = Instance.new("WeldConstraint")
    backWeld.Part0 = seat
    backWeld.Part1 = backWheel
    backWeld.Parent = bike
    
    -- Set primary part
    bike.PrimaryPart = seat
    
    -- Store bike
    playerBikes[player.Name] = bike
    playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
    
    -- Auto-sit player
    wait(0.5)
    if player.Character and player.Character:FindFirstChild("Humanoid") and bike.Parent then
        seat:Sit(player.Character.Humanoid)
        print("✅ " .. player.Name .. " is now on the orange motocross bike!")
    end
end)

-- Handle bike controls
bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
    local bike = playerBikes[player.Name]
    
    -- Only process if bike exists
    if not bike or not bike.Parent then
        return
    end
    
    if not playerInputs[player.Name] then
        playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
    end
    
    -- Update input
    playerInputs[player.Name][inputType] = inputValue
    
    -- Apply to bike
    local seat = bike:FindFirstChild("VehicleSeat")
    if seat then
        local throttleValue = playerInputs[player.Name].throttle - playerInputs[player.Name].brake
        seat.Throttle = throttleValue
        seat.Steer = playerInputs[player.Name].steer
        
        -- Only show debug for significant movement
        if math.abs(throttleValue) > 0.5 or math.abs(playerInputs[player.Name].steer) > 0.5 then
            print("🏍️ " .. player.Name .. " riding: T=" .. string.format("%.1f", throttleValue) .. " S=" .. string.format("%.1f", playerInputs[player.Name].steer))
        end
    end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    if playerBikes[player.Name] and playerBikes[player.Name].Parent then
        playerBikes[player.Name]:Destroy()
    end
    playerBikes[player.Name] = nil
    playerInputs[player.Name] = nil
    print("🧹 Cleaned up bike for " .. player.Name)
end)

print("✅ Simple Bike Spawner Ready! Players can press R to get orange motocross bikes!")

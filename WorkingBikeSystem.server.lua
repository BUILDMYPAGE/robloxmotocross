-- DISABLED - Main.server.lua now handles bike spawning
-- print("🚫 WorkingBikeSystem DISABLED - Main.server.lua handles spawning now")
return

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🚀 Working Bike System Starting...")

-- Step 1: Create RemoteEvents
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
    print("✅ Created RemoteEvents folder")
end

local spawnBikeEvent = remoteEvents:FindFirstChild("SpawnBike")
if not spawnBikeEvent then
    spawnBikeEvent = Instance.new("RemoteEvent")
    spawnBikeEvent.Name = "SpawnBike"
    spawnBikeEvent.Parent = remoteEvents
    print("✅ Created SpawnBike event")
end

local bikeControlEvent = remoteEvents:FindFirstChild("BikeControl")
if not bikeControlEvent then
    bikeControlEvent = Instance.new("RemoteEvent")
    bikeControlEvent.Name = "BikeControl"
    bikeControlEvent.Parent = remoteEvents
    print("✅ Created BikeControl event")
end

-- Step 2: Bike management
local playerBikes = {}
local playerInputs = {}

-- Step 3: Bike spawning function
local function createBike(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        print("❌ " .. player.Name .. " - Character not ready")
        return false
    end
    
    -- Clean up any existing bike
    if playerBikes[player.Name] and playerBikes[player.Name].Parent then
        playerBikes[player.Name]:Destroy()
        print("🗑️ Removed old bike for " .. player.Name)
    end
    
    -- Remove any leftover bikes
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, player.Name .. "_") and string.find(obj.Name, "Bike") then
            obj:Destroy()
        end
    end
    
    -- Create bike model
    local bike = Instance.new("Model")
    bike.Name = player.Name .. "_Bike"
    bike.Parent = workspace
    
    -- Create vehicle seat (bright blue for visibility)
    local seat = Instance.new("VehicleSeat")
    seat.Name = "VehicleSeat"
    seat.Size = Vector3.new(7, 2, 4)
    seat.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 10)
    seat.BrickColor = BrickColor.new("Bright blue")
    seat.Material = Enum.Material.ForceField
    seat.CanCollide = true
    seat.Anchored = false
    
    -- Vehicle physics settings
    seat.MaxSpeed = 50
    seat.Torque = 8000
    seat.TurnSpeed = 15
    seat.HeadsUpDisplay = false
    seat.Parent = bike
    
    -- Create front wheel
    local frontWheel = Instance.new("Part")
    frontWheel.Name = "FrontWheel"
    frontWheel.Shape = Enum.PartType.Cylinder
    frontWheel.Size = Vector3.new(1, 3, 3)
    frontWheel.Position = seat.Position + Vector3.new(3, -2, 0)
    frontWheel.BrickColor = BrickColor.new("Really black")
    frontWheel.Material = Enum.Material.Rubber
    frontWheel.CanCollide = true
    frontWheel.Parent = bike
    
    -- Create back wheel  
    local backWheel = Instance.new("Part")
    backWheel.Name = "BackWheel"
    backWheel.Shape = Enum.PartType.Cylinder
    backWheel.Size = Vector3.new(1, 3, 3)
    backWheel.Position = seat.Position + Vector3.new(-3, -2, 0)
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
    
    print("🏍️ Created BLUE bike for " .. player.Name)
    
    -- Auto-sit the player after a short delay
    spawn(function()
        wait(1)
        if player.Character and player.Character:FindFirstChild("Humanoid") and bike.Parent then
            seat:Sit(player.Character.Humanoid)
            print("✅ " .. player.Name .. " is now riding the blue bike! Use WASD!")
        end
    end)
    
    return true
end

-- Step 4: Handle bike spawning requests
spawnBikeEvent.OnServerEvent:Connect(function(player)
    print("🏍️ " .. player.Name .. " requested bike spawn")
    local success = createBike(player)
    if success then
        print("✅ Bike spawned successfully for " .. player.Name)
    else
        print("❌ Failed to spawn bike for " .. player.Name)
    end
end)

-- Step 5: Handle bike controls
bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
    local bike = playerBikes[player.Name]
    
    -- Check if bike exists
    if not bike or not bike.Parent then
        return -- Silently ignore if no bike
    end
    
    -- Initialize input if needed
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
            print("🚗 " .. player.Name .. " riding: Throttle=" .. string.format("%.1f", throttleValue) .. ", Steer=" .. string.format("%.1f", playerInputs[player.Name].steer))
        end
    end
end)

-- Step 6: Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    if playerBikes[player.Name] and playerBikes[player.Name].Parent then
        playerBikes[player.Name]:Destroy()
        print("🧹 Cleaned up bike for " .. player.Name)
    end
    playerBikes[player.Name] = nil
    playerInputs[player.Name] = nil
end)

print("✅ Working Bike System Ready!")
print("📋 Players can press R to spawn BLUE motocross bikes!")
print("🎮 Use WASD to control the bikes!")

-- BIKE_SPAWNING_FIX.server.lua
-- Complete fix for bike spawning issues

print("🔧 BIKE SPAWNING FIX - Starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Step 1: Ensure RemoteEvents exist
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
    remoteEvents = Instance.new("Folder")
    remoteEvents.Name = "RemoteEvents"
    remoteEvents.Parent = ReplicatedStorage
    print("✅ Created RemoteEvents folder")
else
    print("✅ RemoteEvents folder found")
end

-- Step 2: Ensure SpawnBike event exists
local spawnBikeEvent = remoteEvents:FindFirstChild("SpawnBike")
if not spawnBikeEvent then
    spawnBikeEvent = Instance.new("RemoteEvent")
    spawnBikeEvent.Name = "SpawnBike"
    spawnBikeEvent.Parent = remoteEvents
    print("✅ Created SpawnBike event")
else
    print("✅ SpawnBike event found")
end

-- Step 3: Ensure BikeControl event exists
local bikeControlEvent = remoteEvents:FindFirstChild("BikeControl")
if not bikeControlEvent then
    bikeControlEvent = Instance.new("RemoteEvent")
    bikeControlEvent.Name = "BikeControl"
    bikeControlEvent.Parent = remoteEvents
    print("✅ Created BikeControl event")
else
    print("✅ BikeControl event found")
end

-- Step 4: Create backup bike spawning (in case Main.server.lua isn't working)
local playerBikes = {}
local playerInputs = {}

local function createBackupBike(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        print("❌ " .. player.Name .. " - Character not ready")
        return false
    end
    
    -- Clean up any existing bikes
    for _, obj in pairs(workspace:GetChildren()) do
        if string.find(obj.Name, player.Name .. "_") and string.find(obj.Name, "Bike") then
            print("🗑️ Removing existing bike: " .. obj.Name)
            obj:Destroy()
        end
    end
    
    -- Create realistic motocross bike model
    local bike = Instance.new("Model")
    bike.Name = player.Name .. "_FixBike"
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
    seat.BrickColor = BrickColor.new("Bright yellow") -- Yellow for backup bikes
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
    tank.BrickColor = BrickColor.new("Bright yellow") -- Yellow for backup
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
    
    -- Store bike
    playerBikes[player.Name] = bike
    playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
    
    print("✅ Created YELLOW realistic motocross bike for " .. player.Name)
    
    -- Auto-sit the player
    spawn(function()
        wait(1)
        if player.Character and player.Character:FindFirstChild("Humanoid") and bike.Parent then
            -- Ensure the seat is properly positioned for straddling
            seat.Disabled = false
            
            -- Force the player to sit on the bike
            seat:Sit(player.Character.Humanoid)
            
            print("✅ " .. player.Name .. " is now straddling the YELLOW motocross bike! Use WASD!")
            
            -- Additional check to ensure proper seating
            wait(0.5)
            if not player.Character.Humanoid.Sit then
                print("🔄 Retrying seat positioning for " .. player.Name)
                seat:Sit(player.Character.Humanoid)
            end
        end
    end)
    
    return true
end

-- Step 5: Monitor spawn requests and provide backup
spawn(function()
    wait(5) -- Give Main.server.lua time to initialize
    
    spawnBikeEvent.OnServerEvent:Connect(function(player)
        print("🔥 BACKUP: Received spawn request from " .. player.Name)
        
        -- Wait a moment to see if Main.server.lua handles it
        wait(1)
        
        -- Check if Main.server.lua created a bike
        local mainBikeExists = false
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name == player.Name .. "_MainBike" then
                mainBikeExists = true
                print("✅ Main.server.lua created bike - backup not needed")
                break
            end
        end
        
        -- If no main bike exists, create backup
        if not mainBikeExists then
            print("⚠️ Main.server.lua didn't create bike - creating backup YELLOW bike")
            createBackupBike(player)
        end
    end)
end)

-- Step 6: Handle backup bike controls
bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
    local bike = playerBikes[player.Name]
    
    if not bike or not bike.Parent then
        return -- No backup bike
    end
    
    -- Initialize input if needed
    if not playerInputs[player.Name] then
        playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
    end
    
    -- Handle combined input format (new) or individual inputs (legacy)
    if inputType == "allInputs" and type(inputValue) == "table" then
        -- New combined format - more efficient
        playerInputs[player.Name].throttle = inputValue.throttle or 0
        playerInputs[player.Name].brake = inputValue.brake or 0
        playerInputs[player.Name].steer = inputValue.steer or 0
    else
        -- Legacy individual input format
        if inputType == "throttle" then
            playerInputs[player.Name].throttle = inputValue
        elseif inputType == "brake" then
            playerInputs[player.Name].brake = inputValue
        elseif inputType == "steer" then
            playerInputs[player.Name].steer = inputValue
        end
    end
    
    -- Apply controls to the bike
    local seat = bike:FindFirstChild("VehicleSeat")
    if seat and seat:IsA("VehicleSeat") then
        local throttleValue = playerInputs[player.Name].throttle - playerInputs[player.Name].brake
        seat.Throttle = throttleValue
        seat.Steer = playerInputs[player.Name].steer
        
        -- Debug significant movements only (and only for combined inputs to reduce spam)
        if inputType == "allInputs" and (math.abs(throttleValue) > 0.3 or math.abs(playerInputs[player.Name].steer) > 0.3) then
            print("🏍️ " .. player.Name .. " controlling YELLOW backup bike")
        end
    end
end)

-- Step 7: Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    if playerBikes[player.Name] and playerBikes[player.Name].Parent then
        playerBikes[player.Name]:Destroy()
        print("🧹 Cleaned up backup bike for " .. player.Name)
    end
    playerBikes[player.Name] = nil
    playerInputs[player.Name] = nil
end)

-- Step 8: Test message for players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(3)
        print("📢 " .. player.Name .. " - Press R to spawn a bike! Should be RED (Main) or YELLOW (Backup)")
    end)
end)

print("✅ REALISTIC MOTOCROSS BIKE SPAWNING FIX COMPLETE!")
print("📋 Now you should get either:")
print("   🔴 RED motocross bike from Main.server.lua")
print("   🟡 YELLOW motocross bike from this backup script")
print("🏍️ Both bikes now look like real motocross bikes with:")
print("   • Detailed frame and engine")
print("   • Realistic wheels with rims and spokes")
print("   • Gas tank, handlebars, and exhaust")
print("   • Front fork and rear shock suspension")
print("🎮 Press R to test the new motocross bike spawning!")

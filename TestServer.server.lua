-- EMERGENCY DEBUG SERVER
-- This will help us figure out why nothing is spawning

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🚨 EMERGENCY DEBUG SERVER STARTED")

-- Player bike storage for input handling
local playerBikes = {}
local playerInputs = {}

-- Test the table immediately
playerBikes["TEST"] = "TEST_BIKE"
print("🧪 TEST: Added test entry to playerBikes table")
for k, v in pairs(playerBikes) do
    print("🧪 TEST: " .. k .. " = " .. tostring(v))
end

-- Check if RemoteEvents exist, create them if needed
spawn(function()
    wait(1) -- Give other scripts time to run
    
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteEvents then
        print("⚠️ RemoteEvents folder not found, creating...")
        remoteEvents = Instance.new("Folder")
        remoteEvents.Name = "RemoteEvents"
        remoteEvents.Parent = ReplicatedStorage
    end
    
    -- Ensure SpawnBike event exists
    local spawnBike = remoteEvents:FindFirstChild("SpawnBike")
    if not spawnBike then
        print("⚠️ SpawnBike event not found, creating...")
        spawnBike = Instance.new("RemoteEvent")
        spawnBike.Name = "SpawnBike"
        spawnBike.Parent = remoteEvents
    end
    
    -- Ensure BikeControl event exists
    local bikeControl = remoteEvents:FindFirstChild("BikeControl")
    if not bikeControl then
        print("⚠️ BikeControl event not found, creating...")
        bikeControl = Instance.new("RemoteEvent")
        bikeControl.Name = "BikeControl"
        bikeControl.Parent = remoteEvents
    end
    
    print("✅ All RemoteEvents verified/created")
end)

-- Listen for any RemoteEvent calls
spawn(function()
    wait(3)
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
    if remoteEvents then
        local spawnBike = remoteEvents:WaitForChild("SpawnBike", 5)
        local bikeControl = remoteEvents:WaitForChild("BikeControl", 5)
        
        -- Handle bike spawning
        if spawnBike then
            print("🔗 SpawnBike event connected - waiting for spawn requests...")
            spawnBike.OnServerEvent:Connect(function(player)
                print("🔥 RECEIVED SPAWN REQUEST FROM: " .. player.Name)
                
                -- Remove any existing bikes - but be more careful about what we destroy
                local existingBike = playerBikes[player.Name]
                if existingBike and existingBike.Parent then
                    print("🗑️ Removing existing bike: " .. existingBike.Name)
                    existingBike:Destroy()
                    playerBikes[player.Name] = nil
                end
                
                -- Also check workspace for any leftover bikes
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj.Name == player.Name .. "_TestBike" then
                        print("🗑️ Removing leftover bike from workspace: " .. obj.Name)
                        obj:Destroy()
                    end
                end
                
                -- Create a working VehicleSeat bike
                local bike = Instance.new("Model")
                bike.Name = player.Name .. "_TestBike"
                bike.Parent = workspace
                
                local seat = Instance.new("VehicleSeat")
                seat.Name = "VehicleSeat"
                seat.Size = Vector3.new(8, 2, 4)
                seat.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 10)
                seat.BrickColor = BrickColor.new("Bright green")
                seat.Material = Enum.Material.Neon
                seat.CanCollide = false  -- Disable collision to prevent getting stuck
                seat.MaxSpeed = 100
                seat.Torque = 50000
                seat.TurnSpeed = 30
                seat.HeadsUpDisplay = false
                seat.Parent = bike
                
                -- Add wheels for physics
                local function createWheel(name, offset)
                    local wheel = Instance.new("Part")
                    wheel.Name = name
                    wheel.Shape = Enum.PartType.Cylinder
                    wheel.Size = Vector3.new(0.5, 2, 2)
                    wheel.Position = seat.Position + offset
                    wheel.BrickColor = BrickColor.new("Really black")
                    wheel.CanCollide = true
                    wheel.Material = Enum.Material.Plastic
                    wheel.Parent = bike
                    
                    -- Weld wheel to seat
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = seat
                    weld.Part1 = wheel
                    weld.Parent = bike
                    
                    return wheel
                end
                
                -- Create 4 wheels
                createWheel("FrontLeft", Vector3.new(-3, -1, 1.5))
                createWheel("FrontRight", Vector3.new(-3, -1, -1.5))
                createWheel("BackLeft", Vector3.new(3, -1, 1.5))
                createWheel("BackRight", Vector3.new(3, -1, -1.5))
                
                -- Set the VehicleSeat as the PrimaryPart
                bike.PrimaryPart = seat
                
                -- Store bike for input handling
                playerBikes[player.Name] = bike
                playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
                
                -- Monitor if bike gets destroyed
                bike.AncestryChanged:Connect(function()
                    if not bike.Parent then
                        print("⚠️ BIKE DESTROYED: " .. player.Name .. "'s bike was removed from workspace!")
                        playerBikes[player.Name] = nil
                    end
                end)
                
                print("🎯 CREATED GREEN BIKE FOR " .. player.Name)
                print("🔍 STORED BIKE: playerBikes[" .. player.Name .. "] = " .. bike.Name)
                
                -- Count bikes in table
                local bikeCount = 0
                for _ in pairs(playerBikes) do bikeCount = bikeCount + 1 end
                print("🔍 TOTAL BIKES IN TABLE: " .. tostring(bikeCount))
                
                -- Wait a moment and check if bike still exists
                wait(0.1)
                if bike and bike.Parent then
                    print("✅ Bike still exists after 0.1 seconds")
                else
                    print("❌ BIKE DISAPPEARED after 0.1 seconds!")
                end
                
                -- Auto-sit the player
                spawn(function()
                    wait(1)
                    if player.Character and player.Character:FindFirstChild("Humanoid") and seat.Parent then
                        seat:Sit(player.Character.Humanoid)
                        print("✅ " .. player.Name .. " is now on the green bike - use WASD!")
                        
                        -- Test automatic movement to see if VehicleSeat works at all
                        wait(2)
                        print("🔧 Testing automatic movement...")
                        seat.Throttle = 1
                        wait(3)
                        seat.Throttle = 0
                        print("🔧 Automatic test complete - did the bike move?")
                    end
                end)
            end)
        end
        
        -- Handle bike controls (WASD input)
        if bikeControl then
            bikeControl.OnServerEvent:Connect(function(player, inputType, inputValue)
                -- Reduce debug spam - only show when needed
                local bike = playerBikes[player.Name]
                
                if not bike or not bike.Parent then
                    -- Bike doesn't exist - clean up and return silently
                    if playerBikes[player.Name] then
                        playerBikes[player.Name] = nil
                        print("🧹 Cleaned up missing bike for " .. player.Name)
                    end
                    return
                end
                
                if not playerInputs[player.Name] then
                    playerInputs[player.Name] = {throttle = 0, brake = 0, steer = 0}
                end
                
                -- Update input values
                if inputType == "throttle" then
                    playerInputs[player.Name].throttle = inputValue
                elseif inputType == "brake" then
                    playerInputs[player.Name].brake = inputValue
                elseif inputType == "steer" then
                    playerInputs[player.Name].steer = inputValue
                end
                
                -- Apply inputs to bike
                local seat = bike:FindFirstChild("VehicleSeat")
                if seat and seat:IsA("VehicleSeat") then
                        local throttleValue = playerInputs[player.Name].throttle - playerInputs[player.Name].brake
                        seat.Throttle = throttleValue
                        seat.Steer = playerInputs[player.Name].steer
                        
                        -- Debug movement - always show when applying values
                        print("🚗 APPLYING TO SEAT: Throttle = " .. throttleValue .. ", Steer = " .. playerInputs[player.Name].steer)
                        print("� Seat properties: MaxSpeed=" .. seat.MaxSpeed .. ", Torque=" .. seat.Torque .. ", TurnSpeed=" .. seat.TurnSpeed)
                    else
                        print("❌ No VehicleSeat found in bike!")
                    end
                else
                    print("❌ No bike found for " .. player.Name)
                end
            end)
        else
            print("❌ BikeControl event not found!")
        end
    end
end)

-- Test player events
Players.PlayerAdded:Connect(function(player)
    print("👋 DEBUG: Player joined: " .. player.Name)
    
    player.CharacterAdded:Connect(function(character)
        print("🏃 DEBUG: Character loaded for: " .. player.Name)
    end)
end)

print("🔍 DEBUG SERVER READY - Press R to see if events work")
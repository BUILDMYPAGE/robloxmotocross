-- SimpleServer.server.lua - DISABLED FOR TESTING
-- Using TestServer.server.lua instead

print("🚫 SimpleServer DISABLED - Using TestServer instead")

--[[ DISABLED CODE
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("🏍️ Simple Motocross Server Starting...")

-- Create RemoteEvents
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

print("✅ RemoteEvents created")

-- Player bike storage
local playerBikes = {}
local playerInputs = {}

-- ULTRA SIMPLE bike that WILL work
local function createSimpleBike(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local character = player.Character
    local rootPart = character.HumanoidRootPart
    
    -- Remove any existing bikes
    local existingBike = workspace:FindFirstChild(player.Name .. "_Bike")
    if existingBike then
        existingBike:Destroy()
    end
    
    -- Create bike model
    local bike = Instance.new("Model")
    bike.Name = player.Name .. "_Bike"
    bike.Parent = workspace
    
    -- Create ONLY a VehicleSeat - nothing else!
    local seat = Instance.new("VehicleSeat")
    seat.Name = "VehicleSeat"
    seat.Size = Vector3.new(6, 2, 4)  -- Big enough to be stable
    seat.Position = rootPart.Position + Vector3.new(0, 5, 10)  -- High enough to not clip
    seat.BrickColor = BrickColor.new("Bright red")
    seat.Material = Enum.Material.Metal
    seat.CanCollide = true
    seat.Shape = Enum.PartType.Block
    -- VehicleSeat settings
    seat.MaxSpeed = 50
    seat.Torque = 20000
    seat.TurnSpeed = 16
    seat.HeadsUpDisplay = false
    seat.Parent = bike
    
    -- Store bike reference and initialize input
    bike:SetAttribute("Owner", player.Name)
    playerBikes[player.Name] = bike
    playerInputs[player.Name] = {
        throttle = 0,
        brake = 0,
        steer = 0
    }
    
    -- Auto-sit player immediately
    spawn(function()
        wait(0.5)
        if player.Character and player.Character:FindFirstChild("Humanoid") and seat.Parent then
            seat:Sit(player.Character.Humanoid)
            print("✅ " .. player.Name .. " is sitting on basic vehicle")
        end
    end)
    
    print("✅ BASIC VEHICLE created for " .. player.Name .. " - should move with WASD!")
    
    return bike
end

-- Handle bike control input from clients
bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
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
    
    -- Apply inputs directly to VehicleSeat
    local bike = playerBikes[player.Name]
    if bike and bike.Parent then
        local seat = bike:FindFirstChild("VehicleSeat")
        
        if seat and seat:IsA("VehicleSeat") then
            -- Direct control - this MUST work!
            local throttleValue = playerInputs[player.Name].throttle - playerInputs[player.Name].brake
            seat.Throttle = throttleValue
            seat.Steer = playerInputs[player.Name].steer
            
            -- Debug output to confirm inputs are working
            if math.abs(throttleValue) > 0 or math.abs(playerInputs[player.Name].steer) > 0 then
                print("🏍️ " .. player.Name .. " - Throttle: " .. throttleValue .. ", Steer: " .. playerInputs[player.Name].steer)
            end
        end
    end
end)

-- Handle bike spawn requests
spawnBikeEvent.OnServerEvent:Connect(function(player)
    print("🏍️ " .. player.Name .. " requested bike spawn")
    createSimpleBike(player)
end)

-- AUTO-SPAWN bikes when players join (for testing)
Players.PlayerAdded:Connect(function(player)
    print("👋 " .. player.Name .. " joined! Auto-spawning bike in 3 seconds...")
    
    player.CharacterAdded:Connect(function(character)
        wait(3) -- Give time for character to load
        if player.Parent then
            print("🔧 Auto-spawning bike for " .. player.Name)
            createSimpleBike(player)
        end
    end)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
    if playerBikes[player.Name] then
        playerBikes[player.Name]:Destroy()
        playerBikes[player.Name] = nil
    end
    playerInputs[player.Name] = nil
end)

-- Welcome players
Players.PlayerAdded:Connect(function(player)
    print("👋 " .. player.Name .. " joined! They can press R to spawn a bike.")
    
    player.CharacterAdded:Connect(function(character)
        wait(2) -- Give time for character to load
        if player.Parent then
            -- Send welcome message in chat
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "Welcome " .. player.Name .. "! Press R to spawn your bike!";
                Color = Color3.fromRGB(255, 215, 0);
                Font = Enum.Font.HighwayGothic;
                FontSize = Enum.FontSize.Size18;
            })
        end
    end)
end)

print("🚀 Simple Motocross Server Ready! Players can press R to spawn bikes!")
--]]

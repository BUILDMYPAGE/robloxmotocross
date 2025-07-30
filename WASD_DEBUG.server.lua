-- WASD CONTROL DEBUG SCRIPT
-- Place this in ServerScriptService to test bike controls

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🚀 WASD DEBUG SCRIPT LOADED")

-- Find RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local bikeControlEvent = remoteEvents:WaitForChild("BikeControl")

-- Test function to manually check bike controls
local function testBikeControls(player)
    -- Find player's bike
    local bike = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == player.Name .. "_MainBike" and obj:IsA("Model") then
            bike = obj
            break
        end
    end
    
    if not bike then
        print("❌ No bike found for " .. player.Name)
        return
    end
    
    local seat = bike:FindFirstChild("VehicleSeat")
    if not seat then
        print("❌ No VehicleSeat found in bike")
        return
    end
    
    print("🔍 BIKE DEBUG for " .. player.Name .. ":")
    print("   - Bike exists: ✅")
    print("   - VehicleSeat exists: ✅")
    print("   - VehicleSeat.Disabled: " .. tostring(seat.Disabled))
    print("   - VehicleSeat.Occupant: " .. tostring(seat.Occupant))
    print("   - VehicleSeat.MaxSpeed: " .. seat.MaxSpeed)
    print("   - VehicleSeat.Torque: " .. seat.Torque)
    print("   - VehicleSeat.TurnSpeed: " .. seat.TurnSpeed)
    
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        local humanoid = player.Character.Humanoid
        print("   - Humanoid.Sit: " .. tostring(humanoid.Sit))
        print("   - Humanoid.PlatformStand: " .. tostring(humanoid.PlatformStand))
        
        if seat.Occupant ~= humanoid then
            print("🔧 Attempting to sit player...")
            seat:Sit(humanoid)
            wait(0.5)
            print("   - After sit attempt - Occupant: " .. tostring(seat.Occupant))
        end
    end
end

-- Chat command to debug bike
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        if message:lower() == "/debug" or message:lower() == "/test" then
            testBikeControls(player)
        elseif message:lower() == "/sit" then
            -- Force sit on bike with proper validation
            local bike = nil
            for _, obj in pairs(workspace:GetChildren()) do
                if obj.Name == player.Name .. "_MainBike" and obj:IsA("Model") then
                    bike = obj
                    break
                end
            end
            
            if not bike or not bike.Parent then
                print("❌ No bike found for " .. player.Name)
                return
            end
            
            local vehicleSeat = bike:FindFirstChild("VehicleSeat")
            if not vehicleSeat or not vehicleSeat.Parent then
                print("❌ VehicleSeat not found or not in workspace")
                return
            end
            
            if not player.Character or not player.Character.Parent then
                print("❌ Player character not in workspace")
                return
            end
            
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if not humanoid or not humanoid.Parent then
                print("❌ Humanoid not found or not in workspace")
                return
            end
            
            -- Ensure seat is ready
            vehicleSeat.Disabled = false
            
            -- Try to sit with error handling
            local success, errorMessage = pcall(function()
                vehicleSeat:Sit(humanoid)
            end)
            
            if success then
                print("🪑 Force-sitting " .. player.Name .. " - attempt successful")
                wait(0.3)
                if vehicleSeat.Occupant == humanoid then
                    print("✅ " .. player.Name .. " is now sitting!")
                else
                    print("❌ Sitting command succeeded but player not occupying seat")
                end
            else
                print("❌ Force-sit failed: " .. tostring(errorMessage))
                
                -- Try moving player closer first
                if player.Character:FindFirstChild("HumanoidRootPart") then
                    print("🔄 Moving player closer to seat...")
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(vehicleSeat.Position + Vector3.new(0, 3, 0))
                    wait(0.2)
                    
                    local success2, errorMessage2 = pcall(function()
                        vehicleSeat:Sit(humanoid)
                    end)
                    
                    if success2 then
                        print("✅ Successfully sat player after repositioning")
                    else
                        print("❌ Still failed after repositioning: " .. tostring(errorMessage2))
                    end
                end
            end
        end
    end)
end)

-- Listen for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player.Character then
        player.Chatted:Connect(function(message)
            if message:lower() == "/debug" or message:lower() == "/test" then
                testBikeControls(player)
            elseif message:lower() == "/sit" then
                local bike = nil
                for _, obj in pairs(workspace:GetChildren()) do
                    if obj.Name == player.Name .. "_MainBike" and obj:IsA("Model") then
                        bike = obj
                        break
                    end
                end
                
                if bike and bike:FindFirstChild("VehicleSeat") and player.Character and player.Character:FindFirstChild("Humanoid") then
                    bike.VehicleSeat:Sit(player.Character.Humanoid)
                    print("🪑 Force-sitting " .. player.Name)
                end
            end
        end)
    end
end

print("💬 Chat commands available:")
print("   /debug - Check bike status")
print("   /sit - Force sit on bike")

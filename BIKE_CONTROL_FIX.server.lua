-- QUICK BIKE CONTROL FIX
-- Place in ServerScriptService to override bike controls

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🔧 BIKE CONTROL FIX LOADED")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local bikeControlEvent = remoteEvents:WaitForChild("BikeControl")

-- Override bike control with simplified system
bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
    print("🎮 CONTROL FIX - Input from " .. player.Name .. ": " .. tostring(inputType))
    
    -- Find bike
    local bike = nil
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == player.Name .. "_MainBike" and obj:IsA("Model") then
            bike = obj
            break
        end
    end
    
    if not bike then
        print("❌ No bike found")
        return
    end
    
    -- Get current inputs
    local throttle = 0
    local brake = 0
    local steer = 0
    
    if inputType == "allInputs" and type(inputValue) == "table" then
        throttle = inputValue.throttle or 0
        brake = inputValue.brake or 0
        steer = inputValue.steer or 0
    end
    
    local throttleValue = throttle - brake
    
    -- Skip if no input
    if math.abs(throttleValue) < 0.1 and math.abs(steer) < 0.1 then
        return
    end
    
    print("🎯 CONTROL FIX - Applying: T=" .. throttleValue .. ", S=" .. steer)
    
    -- Try VehicleSeat first
    local seat = bike:FindFirstChild("VehicleSeat")
    if seat then
        seat.Throttle = throttleValue
        seat.Steer = steer
        
        if seat.Occupant then
            print("✅ Using VehicleSeat controls (player seated)")
            return
        else
            print("⚠️ VehicleSeat available but player not seated")
        end
    end
    
    -- Backup: Direct physics control
    local frame = bike:FindFirstChild("Frame")
    if frame then
        local bodyVelocity = frame:FindFirstChild("BodyVelocity")
        local bodyAngularVelocity = frame:FindFirstChild("BodyAngularVelocity")
        
        if bodyVelocity and bodyAngularVelocity then
            print("🔄 Using backup physics controls")
            
            -- Apply movement
            local forwardDirection = frame.CFrame.LookVector
            local speed = math.abs(throttleValue) * 60
            
            if math.abs(throttleValue) > 0.1 then
                bodyVelocity.Velocity = forwardDirection * speed * (throttleValue > 0 and 1 or -1) + Vector3.new(0, bodyVelocity.Velocity.Y, 0)
            else
                bodyVelocity.Velocity = Vector3.new(0, bodyVelocity.Velocity.Y, 0)
            end
            
            -- Apply steering
            if math.abs(steer) > 0.1 then
                bodyAngularVelocity.AngularVelocity = Vector3.new(0, steer * 4, 0)
            else
                bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
            end
            
            print("✅ Physics controls applied successfully")
        else
            print("❌ No backup physics objects found")
        end
    else
        print("❌ No frame found")
    end
end)

print("🚀 Bike control fix ready - WASD should work now!")

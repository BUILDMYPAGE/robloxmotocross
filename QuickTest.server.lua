-- QuickTest.server.lua
-- Simple test to make sure RemoteEvents work
-- Place this in ServerScriptService temporarily for testing

local ReplicatedStorage = game:GetService("ReplicatedStorage")

wait(2) -- Wait for other scripts to set up

print("🔍 QUICK TEST: Checking RemoteEvents setup...")

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
    print("✅ RemoteEvents folder found")
    
    local spawnBike = remoteEvents:FindFirstChild("SpawnBike")
    local bikeControl = remoteEvents:FindFirstChild("BikeControl")
    
    if spawnBike then
        print("✅ SpawnBike event found")
    else
        print("❌ SpawnBike event missing")
    end
    
    if bikeControl then
        print("✅ BikeControl event found")
    else
        print("❌ BikeControl event missing")
    end
else
    print("❌ RemoteEvents folder missing")
end

print("🔍 QUICK TEST: Complete - Check console for any missing components")

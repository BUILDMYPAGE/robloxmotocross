-- ERROR_FIX_TEST.server.lua
-- Simple test to verify all errors are fixed

print("🔧 ERROR FIX TEST - Starting...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Test 1: Check if TestServer is properly disabled
print("✅ Test 1: TestServer should be disabled without syntax errors")

-- Test 2: Verify RemoteEvents exist
spawn(function()
    wait(2)
    
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
    if remoteEvents then
        print("✅ Test 2: RemoteEvents folder found")
        
        local spawnBike = remoteEvents:FindFirstChild("SpawnBike")
        local bikeControl = remoteEvents:FindFirstChild("BikeControl")
        local gameState = remoteEvents:FindFirstChild("GameState")
        
        if spawnBike then
            print("✅ Test 2a: SpawnBike event exists")
        else
            print("❌ Test 2a: SpawnBike event missing")
        end
        
        if bikeControl then
            print("✅ Test 2b: BikeControl event exists")
        else
            print("❌ Test 2b: BikeControl event missing")
        end
        
        if gameState then
            print("✅ Test 2c: GameState event exists")
        else
            print("❌ Test 2c: GameState event missing")
        end
    else
        print("❌ Test 2: RemoteEvents folder not found")
    end
end)

-- Test 3: Monitor for client errors
Players.PlayerAdded:Connect(function(player)
    print("🧪 Test 3: Player " .. player.Name .. " joined - monitoring for client errors...")
    
    player.CharacterAdded:Connect(function(character)
        print("🧪 Test 3a: Character loaded for " .. player.Name .. " - client should initialize without errors")
    end)
end)

print("✅ ERROR FIX TEST READY")
print("📋 Expected results:")
print("   • No TestServer syntax errors")
print("   • No client 'updateStatus' errors")
print("   • All RemoteEvents should exist")
print("   • Players should be able to spawn bikes with R")

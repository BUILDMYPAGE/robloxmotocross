-- TestBikeSpawning.server.lua
-- Simple test to verify bike spawning works

print("🧪 Testing bike spawning system...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for RemoteEvents to be set up
spawn(function()
    wait(3) -- Give Main.server.lua time to initialize
    
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
    if not remoteEvents then
        print("❌ RemoteEvents not found!")
        return
    end
    
    local spawnBikeEvent = remoteEvents:WaitForChild("SpawnBike", 5)
    if not spawnBikeEvent then
        print("❌ SpawnBike event not found!")
        return
    end
    
    print("✅ RemoteEvents found - bike spawning should work!")
    print("📋 Players should be able to press R to spawn RED bikes")
    
    -- Monitor for players pressing R
    spawnBikeEvent.OnServerEvent:Connect(function(player)
        print("🔥 BIKE SPAWN REQUEST from " .. player.Name .. " - Main.server.lua should handle this")
    end)
end)

-- Test when a player joins
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        wait(2)
        print("📢 " .. player.Name .. " - You can now press R to spawn a RED motocross bike!")
    end)
end)

print("✅ Bike spawning test script ready")

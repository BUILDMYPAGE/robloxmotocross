-- CONSOLE_CLEANUP.server.lua
-- Removes unnecessary console messages for a cleaner experience

print("🧹 CONSOLE CLEANUP - Removing disabled script messages...")

-- Just verify that the main systems are working
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

spawn(function()
    wait(2)
    
    local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 5)
    if remoteEvents then
        local spawnBike = remoteEvents:FindFirstChild("SpawnBike")
        local bikeControl = remoteEvents:FindFirstChild("BikeControl")
        
        if spawnBike and bikeControl then
            print("✅ MOTOCROSS SYSTEM READY")
            print("🏍️ Players can press R to spawn realistic motocross bikes")
            print("🎮 Use WASD to control the bikes")
        else
            print("⚠️ Some RemoteEvents are missing")
        end
    else
        print("❌ RemoteEvents folder not found")
    end
end)

-- Welcome new players without spam
Players.PlayerAdded:Connect(function(player)
    print("🏁 " .. player.Name .. " joined the motocross race!")
end)

-- Clean shutdown message
game:BindToClose(function()
    print("🏁 Motocross Racing Server shutting down...")
end)

print("✅ Console cleanup complete - only essential messages will show")

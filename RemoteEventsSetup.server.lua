-- RemoteEventsSetup.server.lua
-- Simple script to create the RemoteEvents folder and events
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvents folder if it doesn't exist
local remoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEventsFolder then
    remoteEventsFolder = Instance.new("Folder")
    remoteEventsFolder.Name = "RemoteEvents"
    remoteEventsFolder.Parent = ReplicatedStorage
    print("✅ Created RemoteEvents folder")
end

-- Create SpawnBike event if it doesn't exist
local spawnBikeEvent = remoteEventsFolder:FindFirstChild("SpawnBike")
if not spawnBikeEvent then
    spawnBikeEvent = Instance.new("RemoteEvent")
    spawnBikeEvent.Name = "SpawnBike"
    spawnBikeEvent.Parent = remoteEventsFolder
    print("✅ Created SpawnBike RemoteEvent")
end

-- Create BikeControl event if it doesn't exist
local bikeControlEvent = remoteEventsFolder:FindFirstChild("BikeControl")
if not bikeControlEvent then
    bikeControlEvent = Instance.new("RemoteEvent")
    bikeControlEvent.Name = "BikeControl"
    bikeControlEvent.Parent = remoteEventsFolder
    print("✅ Created BikeControl RemoteEvent")
end

print("🔗 RemoteEvents setup complete!")

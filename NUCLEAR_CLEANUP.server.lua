-- NUCLEAR_CLEANUP.server.lua
-- This will aggressively remove ALL conflicting scripts and ensure CleanPrototype runs
-- Place this in ServerScriptService, run it once, then remove it

print("🚨 NUCLEAR CLEANUP - REMOVING ALL CONFLICTING SCRIPTS...")

local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. COMPLETELY REMOVE (not just disable) conflicting server scripts
local serverScriptsToRemove = {
    "TestServer", "Main", "SimpleServer", "GameManager", "DirtBike", "RaceTrack",
    "RemoteEventsSetup", "WorkingBikeSystem", "QuickTest", "SimpleBikeSpawner"
}

for _, scriptName in pairs(serverScriptsToRemove) do
    local script = ServerScriptService:FindFirstChild(scriptName)
    if script then
        script:Destroy()
        print("🗑️ REMOVED: " .. scriptName)
    end
end

-- 2. Remove conflicting folders
local foldersToRemove = {"server", "src"}
for _, folderName in pairs(foldersToRemove) do
    local folder = ServerScriptService:FindFirstChild(folderName)
    if folder then
        folder:Destroy()
        print("🗑️ REMOVED FOLDER: " .. folderName)
    end
end

-- 3. COMPLETELY REMOVE conflicting client scripts
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if starterPlayerScripts then
    local clientScriptsToRemove = {"Main", "SimpleClient", "InputController", "UIManager"}
    
    for _, scriptName in pairs(clientScriptsToRemove) do
        local script = starterPlayerScripts:FindFirstChild(scriptName)
        if script then
            script:Destroy()
            print("🗑️ REMOVED CLIENT: " .. scriptName)
        end
    end
    
    -- Remove client folders
    local clientFoldersToRemove = {"client", "src"}
    for _, folderName in pairs(clientFoldersToRemove) do
        local folder = starterPlayerScripts:FindFirstChild(folderName)
        if folder then
            folder:Destroy()
            print("🗑️ REMOVED CLIENT FOLDER: " .. folderName)
        end
    end
end

-- 4. Clear ReplicatedStorage
local itemsToRemove = {"RemoteEvents", "shared", "src"}
for _, itemName in pairs(itemsToRemove) do
    local item = ReplicatedStorage:FindFirstChild(itemName)
    if item then
        item:Destroy()
        print("🗑️ REMOVED FROM REPLICATEDSTORAGE: " .. itemName)
    end
end

-- 5. Clear workspace of old bikes
for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name:find("Bike") or obj.Name:find("bike") or obj.Name:find("TestBike") then
        obj:Destroy()
        print("🗑️ REMOVED OLD BIKE: " .. obj.Name)
    end
end

print("")
print("🧨 NUCLEAR CLEANUP COMPLETE!")
print("📋 NOW DO THIS:")
print("   1. STOP the game")
print("   2. Make sure CleanPrototype.server.lua is in ServerScriptService")
print("   3. Make sure CleanPrototype.client.lua is in StarterPlayerScripts")
print("   4. Remove this NUCLEAR_CLEANUP script")
print("   5. START the game - you should ONLY see CleanPrototype messages")
print("")
print("✅ After cleanup, you should see:")
print("   '🏁 CLEAN MOTOCROSS PROTOTYPE STARTING...'")
print("   and NO 'Main', 'TestServer', or 'SimpleClient' messages")

-- Wait 5 seconds then self-destruct
wait(5)
print("💥 NUCLEAR_CLEANUP self-destructing...")
script:Destroy()

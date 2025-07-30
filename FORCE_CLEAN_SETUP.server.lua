-- FORCE_CLEAN_SETUP.server.lua
-- This will aggressively clean up and ensure only CleanPrototype runs
-- Place this in ServerScriptService and run it

print("🚨 FORCE CLEANING MOTOCROSS SETUP...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

-- 1. DISABLE ALL OTHER SERVER SCRIPTS IMMEDIATELY
print("🧹 Step 1: Disabling conflicting server scripts...")
local scriptsToDisable = {
    "TestServer", "Main", "SimpleServer", "GameManager", "DirtBike", "RaceTrack",
    "RemoteEventsSetup", "WorkingBikeSystem", "QuickTest", "server"
}

for _, child in pairs(ServerScriptService:GetChildren()) do
    if child:IsA("Script") and child.Name ~= "FORCE_CLEAN_SETUP" and child.Name ~= "CleanPrototype" then
        child.Disabled = true
        child.Name = child.Name .. "_DISABLED"
        print("🚫 Disabled server script: " .. child.Name)
    elseif child:IsA("Folder") and child.Name == "server" then
        -- Disable scripts in server folder
        for _, subScript in pairs(child:GetChildren()) do
            if subScript:IsA("Script") then
                subScript.Disabled = true
                print("🚫 Disabled: " .. child.Name .. "/" .. subScript.Name)
            end
        end
    end
end

-- 2. DISABLE ALL OTHER CLIENT SCRIPTS
print("🧹 Step 2: Disabling conflicting client scripts...")
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if starterPlayerScripts then
    for _, child in pairs(starterPlayerScripts:GetChildren()) do
        if child:IsA("LocalScript") and child.Name ~= "CleanPrototype" then
            child.Disabled = true
            child.Name = child.Name .. "_DISABLED"
            print("🚫 Disabled client script: " .. child.Name)
        elseif child:IsA("Folder") and child.Name == "client" then
            -- Disable scripts in client folder
            for _, subScript in pairs(child:GetChildren()) do
                if subScript:IsA("LocalScript") then
                    subScript.Disabled = true
                    print("🚫 Disabled: " .. child.Name .. "/" .. subScript.Name)
                end
            end
        end
    end
end

-- 3. CLEAR ALL REMOTEEVENTS
print("🧹 Step 3: Clearing old RemoteEvents...")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
    remoteEvents:Destroy()
    print("🗑️ Deleted old RemoteEvents")
end

-- 4. CLEAR ALL EXISTING BIKES
print("🧹 Step 4: Clearing old bikes...")
for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name:find("Bike") or obj.Name:find("bike") or obj.Name == "BikeFrame" then
        obj:Destroy()
        print("🗑️ Removed old bike: " .. obj.Name)
    end
end

-- 5. CLEAR SHARED FOLDERS THAT MIGHT CONFLICT
local sharedFolder = ReplicatedStorage:FindFirstChild("shared")
if sharedFolder then
    sharedFolder:Destroy()
    print("🗑️ Removed conflicting shared folder")
end

-- 6. CHECK IF CLEANPROTOTYPE EXISTS AND ENABLE IT
print("🔍 Step 5: Checking for CleanPrototype scripts...")
local cleanServer = ServerScriptService:FindFirstChild("CleanPrototype")
if cleanServer then
    cleanServer.Disabled = false
    print("✅ CleanPrototype server script is ready")
else
    print("❌ CleanPrototype.server.lua NOT FOUND!")
    print("   👉 You need to add CleanPrototype.server.lua to ServerScriptService")
end

local cleanClient = nil
if starterPlayerScripts then
    cleanClient = starterPlayerScripts:FindFirstChild("CleanPrototype")
end
if cleanClient then
    cleanClient.Disabled = false
    print("✅ CleanPrototype client script is ready")
else
    print("❌ CleanPrototype.client.lua NOT FOUND!")
    print("   👉 You need to add CleanPrototype.client.lua to StarterPlayerScripts")
end

-- 7. FINAL STATUS
print("")
print("🏁 CLEANUP COMPLETE!")
if cleanServer and cleanClient then
    print("✅ CleanPrototype scripts are ready")
    print("🚀 Stop the game and restart it now!")
    print("   You should see: '🏁 CLEAN MOTOCROSS PROTOTYPE STARTING...'")
else
    print("❌ CleanPrototype scripts missing!")
    print("📋 TO FIX:")
    print("   1. Add CleanPrototype.server.lua to ServerScriptService")
    print("   2. Add CleanPrototype.client.lua to StarterPlayerScripts") 
    print("   3. Make sure they're named exactly 'CleanPrototype' (no .server.lua extension)")
end

print("")
print("🔧 WHAT TO DO NEXT:")
print("   1. STOP the current game")
print("   2. Make sure CleanPrototype scripts are added")
print("   3. START the game again")
print("   4. Look for '🏁 CLEAN MOTOCROSS PROTOTYPE STARTING...' message")
print("   5. Press R to spawn bike")

-- Self-destruct after 5 seconds
wait(5)
script:Destroy()

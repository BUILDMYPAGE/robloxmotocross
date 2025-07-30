-- TestCleanPrototype.server.lua
-- Quick test to verify CleanPrototype is working
-- Place this in ServerScriptService temporarily for testing

wait(2) -- Wait for other scripts to load

print("🧪 TESTING CLEANPROTOTYPE SETUP...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")

if remoteEvents then
    print("✅ RemoteEvents folder found")
    
    local cleanSpawn = remoteEvents:FindFirstChild("CleanSpawnBike")
    local regularSpawn = remoteEvents:FindFirstChild("SpawnBike")
    local cleanControl = remoteEvents:FindFirstChild("CleanBikeControl")
    local regularControl = remoteEvents:FindFirstChild("BikeControl")
    
    if cleanSpawn then
        print("✅ CleanSpawnBike event found")
    end
    if regularSpawn then
        print("✅ SpawnBike event found")
    end
    if cleanControl then
        print("✅ CleanBikeControl event found")
    end
    if regularControl then
        print("✅ BikeControl event found")
    end
    
    -- Test if CleanPrototype's message appeared
    local foundCleanPrototype = false
    spawn(function()
        -- This is a simple check - in a real scenario you'd monitor the output differently
        print("🔍 Looking for CleanPrototype startup message...")
        wait(1)
        print("📋 If you see 'CLEAN MOTOCROSS PROTOTYPE STARTING' above, CleanPrototype is running!")
    end)
    
else
    print("❌ RemoteEvents folder not found - CleanPrototype may not be running")
end

-- Check for conflicting scripts
local ServerScriptService = game:GetService("ServerScriptService")
local conflictingScripts = {"Main", "TestServer", "SimpleServer"}
local foundConflicts = {}

for _, scriptName in pairs(conflictingScripts) do
    local script = ServerScriptService:FindFirstChild(scriptName)
    if script and not script.Disabled then
        table.insert(foundConflicts, scriptName)
    end
end

if #foundConflicts > 0 then
    print("⚠️ CONFLICTING SCRIPTS STILL ACTIVE:")
    for _, name in pairs(foundConflicts) do
        print("   • " .. name .. " (should be disabled)")
    end
    print("💡 This explains why you're still seeing the 'Main server bike spawning disabled' message!")
else
    print("✅ No conflicting scripts found")
end

print("🧪 Test complete!")

-- Self-destruct after test
wait(5)
script:Destroy()

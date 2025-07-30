-- VERIFY_CLEAN.server.lua
-- Run this after NUCLEAR_CLEANUP to verify everything is clean
-- Place in ServerScriptService temporarily

wait(2) -- Wait for other scripts to load

print("🔍 VERIFYING CLEAN SETUP...")

local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Check for remaining conflicting scripts
local foundConflicts = {}
for _, child in pairs(ServerScriptService:GetChildren()) do
    if child:IsA("Script") and child.Name ~= "VERIFY_CLEAN" and child.Name ~= "CleanPrototype" then
        table.insert(foundConflicts, "SERVER: " .. child.Name)
    end
end

local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if starterPlayerScripts then
    for _, child in pairs(starterPlayerScripts:GetChildren()) do
        if child:IsA("LocalScript") and child.Name ~= "CleanPrototype" then
            table.insert(foundConflicts, "CLIENT: " .. child.Name)
        end
    end
end

-- Report results
if #foundConflicts > 0 then
    print("❌ STILL HAVE CONFLICTS:")
    for _, conflict in pairs(foundConflicts) do
        print("   • " .. conflict)
    end
    print("💡 Run NUCLEAR_CLEANUP again!")
else
    print("✅ NO CONFLICTS FOUND!")
end

-- Check for CleanPrototype
local cleanServer = ServerScriptService:FindFirstChild("CleanPrototype")
local cleanClient = starterPlayerScripts and starterPlayerScripts:FindFirstChild("CleanPrototype")

if cleanServer then
    print("✅ CleanPrototype.server.lua found")
else
    print("❌ CleanPrototype.server.lua MISSING - add it to ServerScriptService")
end

if cleanClient then
    print("✅ CleanPrototype.client.lua found")
else
    print("❌ CleanPrototype.client.lua MISSING - add it to StarterPlayerScripts")
end

-- Final verdict
if #foundConflicts == 0 and cleanServer and cleanClient then
    print("")
    print("🎉 SETUP IS CLEAN AND READY!")
    print("🚀 Start the game - you should see:")
    print("   '🏁 CLEAN MOTOCROSS PROTOTYPE STARTING...'")
    print("   and NOTHING about Main, TestServer, or SimpleClient")
else
    print("")
    print("❌ SETUP NEEDS MORE WORK")
    print("📋 Fix the issues above before testing")
end

-- Self-destruct
wait(5)
script:Destroy()

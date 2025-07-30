-- VerifySetup.server.lua
-- Run this script to verify your setup is correct
-- Place in ServerScriptService temporarily

print("🔍 VERIFYING MOTOCROSS SETUP...")

local serverScriptService = game:GetService("ServerScriptService")
local starterPlayer = game:GetService("StarterPlayer")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Check for conflicting server scripts
local conflictingScripts = {}
for _, child in pairs(serverScriptService:GetChildren()) do
    if child:IsA("Script") and child.Name ~= "VerifySetup" and child.Name ~= "CleanPrototype" then
        if not child.Disabled then
            table.insert(conflictingScripts, child.Name)
        end
    end
end

if #conflictingScripts > 0 then
    print("⚠️ CONFLICTING SERVER SCRIPTS FOUND:")
    for _, name in pairs(conflictingScripts) do
        print("   • " .. name .. " (should be disabled)")
    end
    print("   👉 Use DisableOldScripts.server.lua to fix this")
else
    print("✅ No conflicting server scripts found")
end

-- Check for clean prototype server script
local cleanServer = serverScriptService:FindFirstChild("CleanPrototype")
if cleanServer and not cleanServer.Disabled then
    print("✅ CleanPrototype.server.lua is present and enabled")
else
    print("❌ CleanPrototype.server.lua is missing or disabled")
    print("   👉 Add CleanPrototype.server.lua to ServerScriptService")
end

-- Check for clean prototype client script
local starterPlayerScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
local cleanClient = nil
if starterPlayerScripts then
    cleanClient = starterPlayerScripts:FindFirstChild("CleanPrototype")
end

if cleanClient and not cleanClient.Disabled then
    print("✅ CleanPrototype.client.lua is present and enabled")
else
    print("❌ CleanPrototype.client.lua is missing or disabled")
    print("   👉 Add CleanPrototype.client.lua to StarterPlayerScripts")
end

-- Check for old RemoteEvents
local remoteEvents = replicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
    print("ℹ️ RemoteEvents folder exists (this is normal)")
else
    print("ℹ️ No RemoteEvents folder (will be created by CleanPrototype)")
end

-- Summary
print("")
print("📋 SETUP SUMMARY:")
if #conflictingScripts == 0 and cleanServer and cleanClient then
    print("🎉 SETUP LOOKS GOOD!")
    print("   • No conflicting scripts")
    print("   • CleanPrototype server script ready")
    print("   • CleanPrototype client script ready")
    print("")
    print("🚀 Ready to test! Press Play and then R to spawn bike!")
else
    print("❌ SETUP NEEDS FIXING:")
    if #conflictingScripts > 0 then
        print("   • Disable conflicting server scripts")
    end
    if not cleanServer then
        print("   • Add CleanPrototype.server.lua to ServerScriptService")
    end
    if not cleanClient then
        print("   • Add CleanPrototype.client.lua to StarterPlayerScripts")
    end
end

-- Self-destruct after verification
wait(3)
script:Destroy()

-- DisableOldScripts.server.lua
-- This script will disable the conflicting scripts so the clean prototype can work
-- Place this in ServerScriptService and run it once to clean up

print("🧹 DISABLING CONFLICTING SCRIPTS...")

-- Disable existing scripts by renaming them
local serverScriptService = game:GetService("ServerScriptService")

-- List of scripts to disable
local scriptsToDisable = {
    "TestServer",
    "Main", 
    "SimpleServer",
    "GameManager",
    "RemoteEventsSetup",
    "WorkingBikeSystem",
    "QuickTest"
}

for _, scriptName in pairs(scriptsToDisable) do
    local script = serverScriptService:FindFirstChild(scriptName)
    if script then
        script.Disabled = true
        script.Name = script.Name .. "_DISABLED"
        print("🚫 Disabled: " .. scriptName)
    end
end

-- Clean up ReplicatedStorage
local replicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = replicatedStorage:FindFirstChild("RemoteEvents")
if remoteEvents then
    remoteEvents:Destroy()
    print("🧹 Cleared old RemoteEvents")
end

-- Clean up any existing bikes in workspace
for _, obj in pairs(workspace:GetChildren()) do
    if obj.Name:find("_Bike") or obj.Name:find("TestBike") then
        obj:Destroy()
        print("🧹 Removed old bike: " .. obj.Name)
    end
end

print("✅ Cleanup complete! Now add CleanPrototype.server.lua to ServerScriptService")
print("📋 Also add CleanPrototype.client.lua to StarterPlayerScripts")

-- Self-destruct after cleanup
wait(2)
script:Destroy()

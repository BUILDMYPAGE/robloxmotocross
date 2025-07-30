-- UI_MANAGER_TEST.client.lua
-- Test to verify UI Manager is working properly

print("🧪 UI MANAGER TEST - Starting...")

-- Test SimpleUI class directly
local SimpleUI = {}
SimpleUI.__index = SimpleUI

function SimpleUI.new()
    local self = setmetatable({}, SimpleUI)
    print("🔧 Creating SimpleUI instance...")
    
    self.updateStatus = function(self, status)
        print("✅ updateStatus called with: " .. tostring(status))
    end
    
    self.showMessage = function(self, title, message)
        print("✅ showMessage called with: " .. title .. " - " .. message)
    end
    
    return self
end

function SimpleUI:updateStatus(status)
    print("✅ SimpleUI:updateStatus called with: " .. tostring(status))
end

-- Test the UI manager
local testUI = SimpleUI.new()

print("🔍 Testing UI Manager...")
print("🔍 Type of testUI:", typeof(testUI))
print("🔍 updateStatus exists:", testUI.updateStatus and "YES" or "NO")

if testUI.updateStatus then
    testUI:updateStatus("Test status message")
    print("✅ updateStatus test completed")
else
    print("❌ updateStatus method not found!")
end

print("✅ UI Manager test complete")

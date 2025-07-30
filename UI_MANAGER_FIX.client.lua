-- UI_MANAGER_FIX.client.lua
-- Comprehensive fix for UI Manager issues

print("🔧 UI MANAGER FIX - Ensuring updateStatus method works...")

-- Wait for the main client to load
wait(2)

-- Check if there's a global reference we can access
if _G.MotocrossClient and _G.MotocrossClient.state then
    local clientState = _G.MotocrossClient.state
    
    if clientState.uiManager then
        print("✅ Found existing UI Manager")
        
        -- Check if updateStatus exists
        if not clientState.uiManager.updateStatus then
            print("🔧 Adding missing updateStatus method...")
            
            clientState.uiManager.updateStatus = function(self, status)
                print("📢 STATUS: " .. tostring(status))
                
                -- Try to update status label if it exists
                if self.statusLabel then
                    self.statusLabel.Text = "🏁 GAME STATUS\n" .. status
                else
                    print("⚠️ Status label not found, status: " .. status)
                end
            end
            
            print("✅ updateStatus method added successfully")
        else
            print("✅ updateStatus method already exists")
        end
        
        -- Test the method
        clientState.uiManager:updateStatus("UI Manager Fix Applied!")
        
    else
        print("❌ No UI Manager found in client state")
    end
else
    print("❌ MotocrossClient global not found")
end

print("✅ UI Manager fix complete")

#!/bin/bash

# Clean Motocross Prototype Setup Instructions
# This will help you set up the working prototype in Roblox Studio

echo "🏍️ MOTOCROSS CLEAN PROTOTYPE SETUP"
echo "=================================="
echo ""
echo "To set up this working prototype in Roblox Studio:"
echo ""
echo "1. CLEAR EXISTING SCRIPTS (to avoid conflicts):"
echo "   - Remove any existing server scripts in ServerScriptService"
echo "   - Remove any existing client scripts in StarterPlayerScripts"
echo "   - Remove any RemoteEvents from ReplicatedStorage"
echo ""
echo "2. ADD SERVER SCRIPT:"
echo "   - Copy CleanPrototype.server.lua"
echo "   - Place it directly in ServerScriptService"
echo "   - Name it 'CleanPrototype' (remove .server.lua extension)"
echo ""
echo "3. ADD CLIENT SCRIPT:"
echo "   - Copy CleanPrototype.client.lua"
echo "   - Place it in StarterPlayer > StarterPlayerScripts"
echo "   - Name it 'CleanPrototype' (remove .client.lua extension)"
echo ""
echo "4. TEST THE GAME:"
echo "   - Click 'Play' in Roblox Studio"
echo "   - Wait for the track to load"
echo "   - Press R to spawn your bike"
echo "   - Use WASD to drive around!"
echo ""
echo "🎮 CONTROLS:"
echo "   • R - Spawn Bike"
echo "   • W - Throttle (go forward)"
echo "   • S - Brake"
echo "   • A - Turn Left"
echo "   • D - Turn Right"
echo ""
echo "🔧 TROUBLESHOOTING:"
echo "   - If the bike doesn't spawn, check the Output window for errors"
echo "   - Make sure only these two scripts are running (no conflicting scripts)"
echo "   - Try spawning in an empty baseplate for best results"
echo ""
echo "✅ This prototype focuses on working bike physics!"
echo "   Once this works, we can add more features like multiplayer racing."

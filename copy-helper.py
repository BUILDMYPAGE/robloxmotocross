#!/usr/bin/env python3
"""
Roblox Studio Copy Helper
Generates formatted output for easy copying to Roblox Studio
"""

import os

def read_file(filepath):
    """Read file content safely"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return f"❌ File not found: {filepath}"

def print_section(title, filepath, script_type="Script"):
    """Print a formatted section for copying"""
    print(f"\n{'='*60}")
    print(f"📄 {title}")
    print(f"   Type: {script_type}")
    print(f"   File: {filepath}")
    print(f"{'='*60}")
    print("\n--- COPY FROM HERE ---")
    print(read_file(filepath))
    print("--- END COPY ---\n")

def main():
    print("🏍️ ROBLOX MOTOCROSS RACING - COPY HELPER")
    print("=" * 60)
    print("\n📋 Copy each section below into Roblox Studio:")
    print("\n🔧 STRUCTURE SETUP:")
    print("   ServerScriptService/")
    print("   ├── Main (Script)")
    print("   └── server/ (Folder)")
    print("       ├── GameManager (ModuleScript)")
    print("       ├── DirtBike (ModuleScript)")
    print("       └── RaceTrack (ModuleScript)")
    print("   StarterPlayer/StarterPlayerScripts/")
    print("   ├── Main (LocalScript)")
    print("   └── client/ (Folder)")
    print("       ├── InputController (ModuleScript)")
    print("       └── UIManager (ModuleScript)")
    print("   ReplicatedStorage/")
    print("   └── shared/ (Folder)")
    print("       └── GameConfig (ModuleScript)")

    # Server Scripts
    print_section("Main Server Script", "src/server/Main.server.lua", "Script")
    print_section("Game Manager Module", "src/server/GameManager.lua", "ModuleScript")
    print_section("Dirt Bike Module", "src/server/DirtBike.lua", "ModuleScript")
    print_section("Race Track Module", "src/server/RaceTrack.lua", "ModuleScript")
    
    # Client Scripts
    print_section("Main Client Script", "src/client/Main.client.lua", "LocalScript")
    print_section("Input Controller Module", "src/client/InputController.lua", "ModuleScript")
    print_section("UI Manager Module", "src/client/UIManager.lua", "ModuleScript")
    
    # Shared Scripts
    print_section("Game Config Module", "src/shared/GameConfig.lua", "ModuleScript")
    
    print("\n🎮 TESTING INSTRUCTIONS:")
    print("1. Click ▶️ Play in Roblox Studio")
    print("2. Press R to spawn your dirt bike")
    print("3. Use WASD or Arrow Keys to control")
    print("4. Use 'Start Server' for multiplayer testing")
    print("\n✅ Setup complete! Happy racing! 🏁")

if __name__ == "__main__":
    main()

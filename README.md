# 🏍️ Roblox Motocross Racing Game

A comprehensive motocross racing game built for Roblox using Lua, featuring realistic bike physics, multiplayer racing, checkpoint systems, and professional game mechanics.

## 🎮 Features

### 🏍️ Realistic Dirt Bike Physics
- **Detailed bike model** with frame, wheels, handlebars, and seat
- **Advanced suspension system** using HingeConstraints and SpringConstraints
- **Balance control** with AlignOrientation and PID controllers
- **Anti-flip mechanics** to prevent bikes from flipping on ramps
- **Realistic wheel rotation** and suspension dampening
- **Speed-based steering** and momentum physics

### 🏁 Race Track System
- **Procedural track generation** with various track pieces
- **Multiple track types**: straight sections, ramps, turns, and obstacles
- **Checkpoint system** for tracking race progress
- **Lap counting** and race timing
- **Starting line** and finish line with proper markings
- **Track decorations** including banners and spectator areas

### 🎯 Game Mechanics
- **Multiplayer support** for up to 8 players
- **Real-time position tracking** and leaderboard
- **Lap counter** and race timer
- **Player spawn management** with anti-spam protection
- **Bike distance checking** to prevent clustering
- **Race state management** (waiting, countdown, racing, finished)

### 🖥️ User Interface
- **Race information panel** showing lap, time, and position
- **Real-time leaderboard** with player rankings
- **Speedometer** with color-coded speed indicators
- **Game state display** for race status
- **Mobile touch controls** for mobile players
- **Instructions panel** with control information

### 🎛️ Controls
- **Keyboard Controls**:
  - `W` / `↑` - Throttle
  - `S` / `↓` - Brake
  - `A` / `←` - Steer Left
  - `D` / `→` - Steer Right
  - `R` - Spawn Bike
- **Mobile Controls**: Touch buttons for all functions
- **Input smoothing** and dead zone support

## 📁 Project Structure

```
RobloxMotocross/
├── src/
│   ├── server/                 # Server-side scripts
│   │   ├── Main.server.lua     # Main server initialization
│   │   ├── GameManager.lua     # Game state and player management
│   │   ├── DirtBike.lua        # Bike physics and controls
│   │   └── RaceTrack.lua       # Track generation and checkpoints
│   ├── client/                 # Client-side scripts
│   │   ├── Main.client.lua     # Main client initialization
│   │   ├── InputController.lua # Input handling and controls
│   │   └── UIManager.lua       # User interface management
│   └── shared/                 # Shared modules
│       └── GameConfig.lua      # Game configuration settings
├── .github/
│   └── copilot-instructions.md # Copilot development guidelines
├── .vscode/
│   └── tasks.json             # VS Code build tasks
└── README.md                  # This file
```

## 🚀 Installation & Setup

### Prerequisites
- Roblox Studio
- Visual Studio Code (recommended)
- Basic knowledge of Lua scripting

### Step 1: Download the Scripts

1. Clone or download this repository
2. Extract all files to your development folder

### Step 2: Setup in Roblox Studio

1. **Open Roblox Studio** and create a new place
2. **Configure the workspace structure**:

#### Server Scripts (ServerScriptService)
Place these scripts in `ServerScriptService`:
- `src/server/Main.server.lua` → `ServerScriptService/Main.server.lua`
- Create folder `ServerScriptService/server/`
- `src/server/GameManager.lua` → `ServerScriptService/server/GameManager.lua`
- `src/server/DirtBike.lua` → `ServerScriptService/server/DirtBike.lua`
- `src/server/RaceTrack.lua` → `ServerScriptService/server/RaceTrack.lua`

#### Client Scripts (StarterPlayer)
Place these scripts in `StarterPlayer/StarterPlayerScripts`:
- `src/client/Main.client.lua` → `StarterPlayerScripts/Main.client.lua`
- Create folder `StarterPlayerScripts/client/`
- `src/client/InputController.lua` → `StarterPlayerScripts/client/InputController.lua`
- `src/client/UIManager.lua` → `StarterPlayerScripts/client/UIManager.lua`

#### Shared Scripts (ReplicatedStorage)
Place these scripts in `ReplicatedStorage`:
- Create folder `ReplicatedStorage/shared/`
- `src/shared/GameConfig.lua` → `ReplicatedStorage/shared/GameConfig.lua`

### Step 3: Configure the Game

1. **Run the main server script** by starting the game in Roblox Studio
2. **Test with multiple players** using the "Start Server" option in Studio
3. **Customize settings** by editing `GameConfig.lua`

## 🎮 How to Play

### For Players
1. **Join the game** and wait for it to load
2. **Press R** to spawn your dirt bike
3. **Use WASD or Arrow Keys** to control your bike:
   - W/↑: Accelerate
   - S/↓: Brake
   - A/←: Turn left
   - D/→: Turn right
4. **Race through checkpoints** in order to complete laps
5. **Complete 3 laps** to finish the race
6. **Check the leaderboard** to see your position

### For Mobile Players
- Use the **on-screen touch controls**
- **Throttle/Brake buttons** on the right side
- **Steering buttons** on the left side
- **Spawn Bike button** at the top center

## ⚙️ Configuration

Edit `src/shared/GameConfig.lua` to customize game settings:

```lua
-- Example configurations
GameConfig.Race.MaxPlayers = 8          -- Maximum players
GameConfig.Race.LapCount = 3            -- Number of laps
GameConfig.Bike.MaxSpeed = 100          -- Top speed
GameConfig.Track.CheckpointCount = 10   -- Checkpoints per lap
```

## 🔧 Advanced Features

### Custom Bike Models
1. Create your own bike model in Roblox Studio
2. Replace the bike creation code in `DirtBike.lua`
3. Ensure proper physics constraints are maintained

### Track Customization
1. Modify track points in `RaceTrack.lua`
2. Add new track segment types
3. Customize ramp heights and obstacle placement

### UI Themes
1. Edit color schemes in `GameConfig.lua`
2. Modify UI layouts in `UIManager.lua`
3. Add custom graphics and animations

## 🐛 Troubleshooting

### Common Issues

**"RemoteEvents not found" Error**
- Ensure all scripts are placed in the correct locations
- Run the server script first to create RemoteEvents
- Check that ReplicatedStorage is accessible

**Bikes not spawning**
- Verify the spawn positions are valid
- Check that the bike creation code runs without errors
- Ensure workspace permissions allow script-created parts

**Controls not working**
- Confirm InputController is running on the client
- Check that RemoteEvents are properly connected
- Verify UserInputService is accessible

**Physics issues**
- Ensure all bike parts are properly welded/constrained
- Check that suspension values are reasonable
- Verify workspace gravity and physics settings

### Debug Commands
Type these in chat for debugging:
- `/help` - Show help information
- `/status` - Display server status
- `/debug` - Enable debug mode (if implemented)

## 🛠️ Development

### VS Code Setup
1. Install the Roblox LSP extension
2. Use the provided `.vscode/tasks.json` for build tasks
3. Follow the coding guidelines in `.github/copilot-instructions.md`

### Testing
1. Use "Start Server" in Roblox Studio for multiplayer testing
2. Test on both desktop and mobile devices
3. Verify all game states (waiting, countdown, racing, finished)

### Performance Tips
- Monitor memory usage with the built-in performance monitoring
- Use efficient networking to reduce lag
- Implement proper cleanup for disconnected players
- Optimize physics calculations for better performance

## 📋 Asset Requirements

### Models (Optional)
- Custom dirt bike model (replace default geometry)
- Track decoration models
- Checkpoint and finish line models

### Sounds (Optional)
- Engine sound effects
- Crash and impact sounds
- Checkpoint notification sounds
- Background music

### Textures (Optional)
- Track surface textures
- Bike paint schemes
- UI background images
- Particle effects

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the coding guidelines
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and development purposes. Feel free to modify and use in your own Roblox games.

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section
2. Review the console output for errors
3. Ensure all scripts are properly placed
4. Test with a fresh Roblox Studio place

## 🎯 Future Features

- [ ] Custom bike customization system
- [ ] Multiple track layouts
- [ ] Tournament and ranking systems
- [ ] Spectator mode
- [ ] Replay system
- [ ] Advanced physics tuning
- [ ] Weather and time-of-day systems
- [ ] Achievement system

---

**Happy Racing! 🏍️💨**

*Built with ❤️ for the Roblox community*

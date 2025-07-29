-- build.lua - Remodel script to build the Roblox place
local remodel = require(remodel)

-- Create the place
local game = remodel.createInstance("DataModel")

-- Create ServerScriptService structure
local serverScriptService = game:FindFirstChild("ServerScriptService") or remodel.createInstance("ServerScriptService", game)

-- Main server script
local mainServer = remodel.createInstance("Script", serverScriptService)
mainServer.Name = "Main"
mainServer.Source = remodel.readFile("src/server/Main.server.lua")

-- Server folder
local serverFolder = remodel.createInstance("Folder", serverScriptService)
serverFolder.Name = "server"

-- Server modules
local gameManager = remodel.createInstance("ModuleScript", serverFolder)
gameManager.Name = "GameManager"
gameManager.Source = remodel.readFile("src/server/GameManager.lua")

local dirtBike = remodel.createInstance("ModuleScript", serverFolder)
dirtBike.Name = "DirtBike"
dirtBike.Source = remodel.readFile("src/server/DirtBike.lua")

local raceTrack = remodel.createInstance("ModuleScript", serverFolder)
raceTrack.Name = "RaceTrack"
raceTrack.Source = remodel.readFile("src/server/RaceTrack.lua")

-- Create StarterPlayer structure
local starterPlayer = game:FindFirstChild("StarterPlayer") or remodel.createInstance("StarterPlayer", game)
local starterPlayerScripts = starterPlayer:FindFirstChild("StarterPlayerScripts") or remodel.createInstance("StarterPlayerScripts", starterPlayer)

-- Main client script
local mainClient = remodel.createInstance("LocalScript", starterPlayerScripts)
mainClient.Name = "Main"
mainClient.Source = remodel.readFile("src/client/Main.client.lua")

-- Client folder
local clientFolder = remodel.createInstance("Folder", starterPlayerScripts)
clientFolder.Name = "client"

-- Client modules
local inputController = remodel.createInstance("ModuleScript", clientFolder)
inputController.Name = "InputController"
inputController.Source = remodel.readFile("src/client/InputController.lua")

local uiManager = remodel.createInstance("ModuleScript", clientFolder)
uiManager.Name = "UIManager"
uiManager.Source = remodel.readFile("src/client/UIManager.lua")

-- Create ReplicatedStorage structure
local replicatedStorage = game:FindFirstChild("ReplicatedStorage") or remodel.createInstance("ReplicatedStorage", game)
local sharedFolder = remodel.createInstance("Folder", replicatedStorage)
sharedFolder.Name = "shared"

-- Shared modules
local gameConfig = remodel.createInstance("ModuleScript", sharedFolder)
gameConfig.Name = "GameConfig"
gameConfig.Source = remodel.readFile("src/shared/GameConfig.lua")

-- Save the place
remodel.writePlace(game, "MotocrossRacing.rbxl")
print("✅ Roblox place file created: MotocrossRacing.rbxl")

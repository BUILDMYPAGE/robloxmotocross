--[[
    GameManager.lua - Main Game Controller
    
    This script handles:
    - Player spawning and bike management
    - Multiplayer race coordination
    - Anti-spam bike spawning protection
    - Game state management
    
    Usage: Place in ServerScriptService
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Import other modules
local DirtBike = require(script.Parent.DirtBike)
local RaceTrack = require(script.Parent.RaceTrack)

-- RemoteEvents setup
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

local bikeControlEvent = Instance.new("RemoteEvent")
bikeControlEvent.Name = "BikeControl"
bikeControlEvent.Parent = remoteEvents

local raceUpdateEvent = Instance.new("RemoteEvent")
raceUpdateEvent.Name = "RaceUpdate"
raceUpdateEvent.Parent = remoteEvents

local spawnBikeEvent = Instance.new("RemoteEvent")
spawnBikeEvent.Name = "SpawnBike"
spawnBikeEvent.Parent = remoteEvents

local GameManager = {}
GameManager.__index = GameManager

-- Game configuration
local GAME_CONFIG = {
    MaxPlayers = 8,
    MinimumBikeDistance = 10, -- Minimum distance between bikes
    SpawnCooldown = 5, -- Seconds before player can spawn another bike
    RaceCountdown = 10, -- Countdown before race starts
    AutoStartPlayers = 2 -- Minimum players to auto-start race
}

function GameManager.new()
    local self = setmetatable({}, GameManager)
    
    self.playerBikes = {} -- Track player bikes
    self.playerSpawnTimes = {} -- Track when players last spawned
    self.playerPositions = {} -- Track player spawn positions
    self.gameState = "waiting" -- waiting, countdown, racing, finished
    self.raceTrack = nil
    self.countdownTime = 0
    
    self:initialize()
    
    return self
end

function GameManager:initialize()
    -- Create race track
    self.raceTrack = RaceTrack.new()
    
    -- Connect player events
    Players.PlayerAdded:Connect(function(player)
        self:onPlayerJoined(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:onPlayerLeft(player)
    end)
    
    -- Connect remote events
    spawnBikeEvent.OnServerEvent:Connect(function(player)
        self:onSpawnBikeRequest(player)
    end)
    
    -- Start game loop
    self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:update(deltaTime)
    end)
    
    print("Motocross Game Manager initialized!")
end

function GameManager:onPlayerJoined(player)
    print(player.Name .. " joined the motocross race!")
    
    -- Initialize player data
    self.playerBikes[player] = nil
    self.playerSpawnTimes[player] = 0
    self.playerPositions[player] = nil
    
    -- Auto-assign spawn position
    self:assignSpawnPosition(player)
    
    -- Check if we should start countdown
    self:checkAutoStart()
    
    -- Send initial game state to player
    self:sendGameStateToPlayer(player)
end

function GameManager:onPlayerLeft(player)
    print(player.Name .. " left the motocross race!")
    
    -- Clean up player's bike
    if self.playerBikes[player] then
        self.playerBikes[player]:destroy()
        self.playerBikes[player] = nil
    end
    
    -- Clean up player data
    self.playerSpawnTimes[player] = nil
    self.playerPositions[player] = nil
    
    -- Remove from race track progress
    if self.raceTrack and self.raceTrack.playerProgress[player] then
        self.raceTrack.playerProgress[player] = nil
    end
end

function GameManager:assignSpawnPosition(player)
    -- Find an available spawn position
    local spawnIndex = self:getNextAvailableSpawnIndex()
    if spawnIndex then
        self.playerPositions[player] = spawnIndex
        local spawnPos = self.raceTrack:getSpawnPosition(spawnIndex)
        
        -- Teleport player to spawn area
        if player.Character and player.Character.HumanoidRootPart then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(spawnPos + Vector3.new(0, 5, 0))
        end
    end
end

function GameManager:getNextAvailableSpawnIndex()
    -- Find the next available spawn position
    for i = 1, GAME_CONFIG.MaxPlayers do
        local positionTaken = false
        for _, spawnIndex in pairs(self.playerPositions) do
            if spawnIndex == i then
                positionTaken = true
                break
            end
        end
        if not positionTaken then
            return i
        end
    end
    return nil -- All positions taken
end

function GameManager:onSpawnBikeRequest(player)
    -- Check if player can spawn a bike
    if not self:canPlayerSpawnBike(player) then
        return
    end
    
    -- Get spawn position
    local spawnIndex = self.playerPositions[player]
    if not spawnIndex then
        print("No spawn position available for " .. player.Name)
        return
    end
    
    local spawnPos = self.raceTrack:getSpawnPosition(spawnIndex)
    
    -- Check for nearby bikes to prevent clustering
    if self:isBikeTooClose(spawnPos) then
        print("Cannot spawn bike for " .. player.Name .. " - too close to another bike")
        return
    end
    
    -- Destroy existing bike if any
    if self.playerBikes[player] then
        self.playerBikes[player]:destroy()
    end
    
    -- Create new bike
    local bike = DirtBike.new(player, spawnPos)
    self.playerBikes[player] = bike
    self.playerSpawnTimes[player] = tick()
    
    -- Store bike reference in race track for collision detection
    if self.raceTrack.playerProgress[player] then
        self.raceTrack.playerProgress[player].bike = bike.frame
    else
        self.raceTrack.playerProgress[player] = {bike = bike.frame}
    end
    
    print("Spawned bike for " .. player.Name)
end

function GameManager:canPlayerSpawnBike(player)
    -- Check spawn cooldown
    local lastSpawnTime = self.playerSpawnTimes[player] or 0
    if tick() - lastSpawnTime < GAME_CONFIG.SpawnCooldown then
        return false
    end
    
    -- Check if game allows spawning
    if self.gameState == "racing" then
        -- Only allow spawning if player doesn't have a bike
        return self.playerBikes[player] == nil
    end
    
    return true
end

function GameManager:isBikeTooClose(spawnPos)
    -- Check if any existing bike is too close to the spawn position
    for _, bike in pairs(self.playerBikes) do
        if bike and bike.frame and bike.frame.Parent then
            local distance = (bike.frame.Position - spawnPos).Magnitude
            if distance < GAME_CONFIG.MinimumBikeDistance then
                return true
            end
        end
    end
    return false
end

function GameManager:checkAutoStart()
    if self.gameState == "waiting" then
        local readyPlayers = 0
        for player, bike in pairs(self.playerBikes) do
            if bike and bike.frame and bike.frame.Parent then
                readyPlayers = readyPlayers + 1
            end
        end
        
        if readyPlayers >= GAME_CONFIG.AutoStartPlayers then
            self:startCountdown()
        end
    end
end

function GameManager:startCountdown()
    if self.gameState ~= "waiting" then
        return
    end
    
    self.gameState = "countdown"
    self.countdownTime = GAME_CONFIG.RaceCountdown
    
    print("Race countdown started!")
    self:broadcastGameState()
end

function GameManager:startRace()
    if self.gameState ~= "countdown" then
        return
    end
    
    self.gameState = "racing"
    
    -- Start race on track
    if self.raceTrack then
        self.raceTrack:startRace()
    end
    
    print("Race started!")
    self:broadcastGameState()
end

function GameManager:endRace()
    if self.gameState ~= "racing" then
        return
    end
    
    self.gameState = "finished"
    
    -- End race on track
    if self.raceTrack then
        self.raceTrack:endRace()
    end
    
    print("Race finished!")
    self:broadcastGameState()
    
    -- Wait a bit then reset to waiting
    wait(10)
    self:resetGame()
end

function GameManager:resetGame()
    self.gameState = "waiting"
    
    -- Reset race track
    if self.raceTrack then
        self.raceTrack.playerProgress = {}
    end
    
    print("Game reset - waiting for players")
    self:broadcastGameState()
end

function GameManager:update(deltaTime)
    -- Handle countdown
    if self.gameState == "countdown" then
        self.countdownTime = self.countdownTime - deltaTime
        
        if self.countdownTime <= 0 then
            self:startRace()
        elseif math.ceil(self.countdownTime) ~= math.ceil(self.countdownTime + deltaTime) then
            -- Countdown number changed, broadcast update
            self:broadcastGameState()
        end
    end
    
    -- Check race completion
    if self.gameState == "racing" and self.raceTrack then
        local allFinished = true
        local anyPlayers = false
        
        for player, progress in pairs(self.raceTrack.playerProgress) do
            anyPlayers = true
            if not progress.finished then
                allFinished = false
            end
        end
        
        if anyPlayers and allFinished then
            self:endRace()
        end
    end
    
    -- Clean up disconnected bikes
    self:cleanupDisconnectedBikes()
end

function GameManager:cleanupDisconnectedBikes()
    for player, bike in pairs(self.playerBikes) do
        if bike and (not bike.frame or not bike.frame.Parent) then
            -- Bike was destroyed, clean up reference
            self.playerBikes[player] = nil
        end
    end
end

function GameManager:broadcastGameState()
    local gameData = {
        gameState = self.gameState,
        countdownTime = math.ceil(self.countdownTime),
        playerCount = self:getActivePlayerCount()
    }
    
    -- Broadcast to all players
    for _, player in pairs(Players:GetPlayers()) do
        self:sendGameStateToPlayer(player, gameData)
    end
end

function GameManager:sendGameStateToPlayer(player, gameData)
    if not gameData then
        gameData = {
            gameState = self.gameState,
            countdownTime = math.ceil(self.countdownTime),
            playerCount = self:getActivePlayerCount()
        }
    end
    
    -- You would typically use a RemoteEvent here to send to client
    -- For now, we'll just print the game state
    print("Game state for " .. player.Name .. ": " .. gameData.gameState)
end

function GameManager:getActivePlayerCount()
    local count = 0
    for _, bike in pairs(self.playerBikes) do
        if bike and bike.frame and bike.frame.Parent then
            count = count + 1
        end
    end
    return count
end

-- Manual race control functions (for admin commands)
function GameManager:forceStartRace()
    if self.gameState == "waiting" then
        self:startCountdown()
    elseif self.gameState == "countdown" then
        self.countdownTime = 0
    end
end

function GameManager:forceEndRace()
    if self.gameState == "racing" then
        self:endRace()
    end
end

function GameManager:forceResetGame()
    self:resetGame()
end

-- Initialize the game manager when the script runs
local gameManager = GameManager.new()

-- Export functions for external access
_G.MotocrossGameManager = gameManager

return GameManager

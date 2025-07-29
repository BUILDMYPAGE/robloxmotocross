--[[
    UIManager.lua - Client-side UI Manager
    
    This script handles:
    - Race UI display (lap counter, timer, positions)
    - Player leaderboard
    - Game state indicators
    - Instructions and help text
    
    Usage: Place in StarterGui or StarterPlayerScripts
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local raceUpdateEvent = remoteEvents:FindFirstChild("RaceUpdate") -- Make this optional

local UIManager = {}
UIManager.__index = UIManager

function UIManager.new()
    local self = setmetatable({}, UIManager)
    
    self.mainGui = nil
    self.raceData = {}
    self.lastUpdateTime = 0
    
    self:createMainUI()
    self:setupEventConnections()
    self:startUpdateLoop()
    
    return self
end

function UIManager:createMainUI()
    -- Create main GUI
    self.mainGui = Instance.new("ScreenGui")
    self.mainGui.Name = "MotocrossRaceUI"
    self.mainGui.ResetOnSpawn = false
    self.mainGui.Parent = playerGui
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = self.mainGui
    
    -- Create race info panel (top-left)
    self:createRaceInfoPanel(mainFrame)
    
    -- Create leaderboard (top-right)
    self:createLeaderboard(mainFrame)
    
    -- Create speedometer (bottom-center)
    self:createSpeedometer(mainFrame)
    
    -- Create game state display (center)
    self:createGameStateDisplay(mainFrame)
    
    -- Create instructions panel
    self:createInstructionsPanel(mainFrame)
end

function UIManager:createRaceInfoPanel(parent)
    -- Race info frame
    local raceInfoFrame = Instance.new("Frame")
    raceInfoFrame.Name = "RaceInfoFrame"
    raceInfoFrame.Size = UDim2.new(0, 250, 0, 120)
    raceInfoFrame.Position = UDim2.new(0, 20, 0, 20)
    raceInfoFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    raceInfoFrame.BackgroundTransparency = 0.3
    raceInfoFrame.BorderSizePixel = 0
    raceInfoFrame.Parent = parent
    
    local raceInfoCorner = Instance.new("UICorner")
    raceInfoCorner.CornerRadius = UDim.new(0, 12)
    raceInfoCorner.Parent = raceInfoFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "RACE INFO"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = raceInfoFrame
    
    -- Current lap
    local lapLabel = Instance.new("TextLabel")
    lapLabel.Name = "LapLabel"
    lapLabel.Size = UDim2.new(1, -20, 0, 20)
    lapLabel.Position = UDim2.new(0, 10, 0, 30)
    lapLabel.BackgroundTransparency = 1
    lapLabel.Text = "Lap: 1 / 3"
    lapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    lapLabel.TextScaled = true
    lapLabel.Font = Enum.Font.Gotham
    lapLabel.TextXAlignment = Enum.TextXAlignment.Left
    lapLabel.Parent = raceInfoFrame
    
    -- Race time
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(1, -20, 0, 20)
    timeLabel.Position = UDim2.new(0, 10, 0, 55)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "Time: 0:00"
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.TextScaled = true
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = raceInfoFrame
    
    -- Position
    local positionLabel = Instance.new("TextLabel")
    positionLabel.Name = "PositionLabel"
    positionLabel.Size = UDim2.new(1, -20, 0, 20)
    positionLabel.Position = UDim2.new(0, 10, 0, 80)
    positionLabel.BackgroundTransparency = 1
    positionLabel.Text = "Position: 1st"
    positionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    positionLabel.TextScaled = true
    positionLabel.Font = Enum.Font.Gotham
    positionLabel.TextXAlignment = Enum.TextXAlignment.Left
    positionLabel.Parent = raceInfoFrame
    
    self.raceInfoFrame = raceInfoFrame
end

function UIManager:createLeaderboard(parent)
    -- Leaderboard frame
    local leaderboardFrame = Instance.new("Frame")
    leaderboardFrame.Name = "LeaderboardFrame"
    leaderboardFrame.Size = UDim2.new(0, 200, 0, 300)
    leaderboardFrame.Position = UDim2.new(1, -220, 0, 20)
    leaderboardFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    leaderboardFrame.BackgroundTransparency = 0.3
    leaderboardFrame.BorderSizePixel = 0
    leaderboardFrame.Parent = parent
    
    local leaderboardCorner = Instance.new("UICorner")
    leaderboardCorner.CornerRadius = UDim.new(0, 12)
    leaderboardCorner.Parent = leaderboardFrame
    
    -- Title
    local leaderboardTitle = Instance.new("TextLabel")
    leaderboardTitle.Name = "LeaderboardTitle"
    leaderboardTitle.Size = UDim2.new(1, -20, 0, 30)
    leaderboardTitle.Position = UDim2.new(0, 10, 0, 5)
    leaderboardTitle.BackgroundTransparency = 1
    leaderboardTitle.Text = "LEADERBOARD"
    leaderboardTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    leaderboardTitle.TextScaled = true
    leaderboardTitle.Font = Enum.Font.GothamBold
    leaderboardTitle.Parent = leaderboardFrame
    
    -- Scrolling frame for player list
    local playerListFrame = Instance.new("ScrollingFrame")
    playerListFrame.Name = "PlayerListFrame"
    playerListFrame.Size = UDim2.new(1, -20, 1, -45)
    playerListFrame.Position = UDim2.new(0, 10, 0, 40)
    playerListFrame.BackgroundTransparency = 1
    playerListFrame.BorderSizePixel = 0
    playerListFrame.ScrollBarThickness = 4
    playerListFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    playerListFrame.Parent = leaderboardFrame
    
    -- UI List Layout
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = playerListFrame
    
    self.leaderboardFrame = leaderboardFrame
    self.playerListFrame = playerListFrame
end

function UIManager:createSpeedometer(parent)
    -- Speedometer frame
    local speedometerFrame = Instance.new("Frame")
    speedometerFrame.Name = "SpeedometerFrame"
    speedometerFrame.Size = UDim2.new(0, 150, 0, 80)
    speedometerFrame.Position = UDim2.new(0.5, -75, 1, -100)
    speedometerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    speedometerFrame.BackgroundTransparency = 0.3
    speedometerFrame.BorderSizePixel = 0
    speedometerFrame.Parent = parent
    
    local speedometerCorner = Instance.new("UICorner")
    speedometerCorner.CornerRadius = UDim.new(0, 12)
    speedometerCorner.Parent = speedometerFrame
    
    -- Speed label
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, -10, 0, 40)
    speedLabel.Position = UDim2.new(0, 5, 0, 5)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = "0"
    speedLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.GothamBold
    speedLabel.Parent = speedometerFrame
    
    -- Speed unit label
    local speedUnitLabel = Instance.new("TextLabel")
    speedUnitLabel.Name = "SpeedUnitLabel"
    speedUnitLabel.Size = UDim2.new(1, -10, 0, 20)
    speedUnitLabel.Position = UDim2.new(0, 5, 0, 50)
    speedUnitLabel.BackgroundTransparency = 1
    speedUnitLabel.Text = "MPH"
    speedUnitLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedUnitLabel.TextScaled = true
    speedUnitLabel.Font = Enum.Font.Gotham
    speedUnitLabel.Parent = speedometerFrame
    
    self.speedometerFrame = speedometerFrame
end

function UIManager:createGameStateDisplay(parent)
    -- Game state display (center screen)
    local gameStateFrame = Instance.new("Frame")
    gameStateFrame.Name = "GameStateFrame"
    gameStateFrame.Size = UDim2.new(0, 400, 0, 150)
    gameStateFrame.Position = UDim2.new(0.5, -200, 0.5, -75)
    gameStateFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    gameStateFrame.BackgroundTransparency = 0.5
    gameStateFrame.BorderSizePixel = 0
    gameStateFrame.Visible = false
    gameStateFrame.Parent = parent
    
    local gameStateCorner = Instance.new("UICorner")
    gameStateCorner.CornerRadius = UDim.new(0, 20)
    gameStateCorner.Parent = gameStateFrame
    
    -- Main message
    local gameStateLabel = Instance.new("TextLabel")
    gameStateLabel.Name = "GameStateLabel"
    gameStateLabel.Size = UDim2.new(1, -20, 0, 80)
    gameStateLabel.Position = UDim2.new(0, 10, 0, 10)
    gameStateLabel.BackgroundTransparency = 1
    gameStateLabel.Text = "WAITING FOR PLAYERS"
    gameStateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    gameStateLabel.TextScaled = true
    gameStateLabel.Font = Enum.Font.GothamBold
    gameStateLabel.Parent = gameStateFrame
    
    -- Sub message
    local gameStateSubLabel = Instance.new("TextLabel")
    gameStateSubLabel.Name = "GameStateSubLabel"
    gameStateSubLabel.Size = UDim2.new(1, -20, 0, 40)
    gameStateSubLabel.Position = UDim2.new(0, 10, 0, 90)
    gameStateSubLabel.BackgroundTransparency = 1
    gameStateSubLabel.Text = "Press R to spawn your bike"
    gameStateSubLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    gameStateSubLabel.TextScaled = true
    gameStateSubLabel.Font = Enum.Font.Gotham
    gameStateSubLabel.Parent = gameStateFrame
    
    self.gameStateFrame = gameStateFrame
end

function UIManager:createInstructionsPanel(parent)
    -- Instructions panel (bottom-left)
    local instructionsFrame = Instance.new("Frame")
    instructionsFrame.Name = "InstructionsFrame"
    instructionsFrame.Size = UDim2.new(0, 280, 0, 100)
    instructionsFrame.Position = UDim2.new(0, 20, 1, -120)
    instructionsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    instructionsFrame.BackgroundTransparency = 0.3
    instructionsFrame.BorderSizePixel = 0
    instructionsFrame.Parent = parent
    
    local instructionsCorner = Instance.new("UICorner")
    instructionsCorner.CornerRadius = UDim.new(0, 12)
    instructionsCorner.Parent = instructionsFrame
    
    -- Title
    local instructionsTitle = Instance.new("TextLabel")
    instructionsTitle.Name = "InstructionsTitle"
    instructionsTitle.Size = UDim2.new(1, -20, 0, 20)
    instructionsTitle.Position = UDim2.new(0, 10, 0, 5)
    instructionsTitle.BackgroundTransparency = 1
    instructionsTitle.Text = "CONTROLS"
    instructionsTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    instructionsTitle.TextScaled = true
    instructionsTitle.Font = Enum.Font.GothamBold
    instructionsTitle.TextXAlignment = Enum.TextXAlignment.Left
    instructionsTitle.Parent = instructionsFrame
    
    -- Instructions text
    local instructionsText = Instance.new("TextLabel")
    instructionsText.Name = "InstructionsText"
    instructionsText.Size = UDim2.new(1, -20, 0, 70)
    instructionsText.Position = UDim2.new(0, 10, 0, 25)
    instructionsText.BackgroundTransparency = 1
    instructionsText.Text = "W/↑ - Throttle\nS/↓ - Brake\nA/← D/→ - Steer\nR - Spawn Bike"
    instructionsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    instructionsText.TextSize = 14
    instructionsText.Font = Enum.Font.Gotham
    instructionsText.TextXAlignment = Enum.TextXAlignment.Left
    instructionsText.TextYAlignment = Enum.TextYAlignment.Top
    instructionsText.Parent = instructionsFrame
    
    self.instructionsFrame = instructionsFrame
end

function UIManager:setupEventConnections()
    -- Connect to race update events (if available)
    if raceUpdateEvent then
        raceUpdateEvent.OnClientEvent:Connect(function(raceData)
            self:updateRaceData(raceData)
        end)
    else
        print("⚠️ RaceUpdate event not found - some UI features disabled")
    end
end

function UIManager:startUpdateLoop()
    -- Start UI update loop
    self.updateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updateUI(deltaTime)
    end)
end

function UIManager:updateRaceData(raceData)
    self.raceData = raceData
    self.lastUpdateTime = tick()
end

function UIManager:updateUI(deltaTime)
    -- Update race info panel
    self:updateRaceInfo()
    
    -- Update leaderboard
    self:updateLeaderboard()
    
    -- Update speedometer
    self:updateSpeedometer()
    
    -- Update game state display
    self:updateGameStateDisplay()
end

function UIManager:updateRaceInfo()
    if not self.raceInfoFrame then return end
    
    local lapLabel = self.raceInfoFrame:FindFirstChild("LapLabel")
    local timeLabel = self.raceInfoFrame:FindFirstChild("TimeLabel")
    local positionLabel = self.raceInfoFrame:FindFirstChild("PositionLabel")
    
    if self.raceData.playerProgress and self.raceData.playerProgress[player.Name] then
        local playerProgress = self.raceData.playerProgress[player.Name]
        
        -- Update lap
        if lapLabel then
            lapLabel.Text = "Lap: " .. playerProgress.currentLap .. " / 3"
        end
        
        -- Update position
        if positionLabel then
            local positionText = self:getPositionText(playerProgress.position)
            positionLabel.Text = "Position: " .. positionText
            
            -- Color based on position
            if playerProgress.position == 1 then
                positionLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
            elseif playerProgress.position == 2 then
                positionLabel.TextColor3 = Color3.fromRGB(192, 192, 192) -- Silver
            elseif playerProgress.position == 3 then
                positionLabel.TextColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
            else
                positionLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
            end
        end
    end
    
    -- Update race time
    if timeLabel and self.raceData.raceActive then
        local raceTime = self.raceData.raceTime or 0
        local minutes = math.floor(raceTime / 60)
        local seconds = math.floor(raceTime % 60)
        timeLabel.Text = string.format("Time: %d:%02d", minutes, seconds)
    end
end

function UIManager:updateLeaderboard()
    if not self.playerListFrame then return end
    
    -- Clear existing player entries
    for _, child in pairs(self.playerListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    if not self.raceData.playerProgress then return end
    
    -- Create sorted player list
    local playerList = {}
    for playerName, progress in pairs(self.raceData.playerProgress) do
        table.insert(playerList, {name = playerName, progress = progress})
    end
    
    -- Sort by position
    table.sort(playerList, function(a, b)
        return a.progress.position < b.progress.position
    end)
    
    -- Create UI entries for each player
    for i, playerData in ipairs(playerList) do
        self:createPlayerLeaderboardEntry(playerData, i)
    end
    
    -- Update canvas size
    self.playerListFrame.CanvasSize = UDim2.new(0, 0, 0, #playerList * 30 + 10)
end

function UIManager:createPlayerLeaderboardEntry(playerData, index)
    local playerFrame = Instance.new("Frame")
    playerFrame.Name = "Player_" .. index
    playerFrame.Size = UDim2.new(1, -10, 0, 25)
    playerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playerFrame.BackgroundTransparency = 0.5
    playerFrame.BorderSizePixel = 0
    playerFrame.LayoutOrder = index
    playerFrame.Parent = self.playerListFrame
    
    local playerCorner = Instance.new("UICorner")
    playerCorner.CornerRadius = UDim.new(0, 4)
    playerCorner.Parent = playerFrame
    
    -- Position label
    local positionLabel = Instance.new("TextLabel")
    positionLabel.Size = UDim2.new(0, 30, 1, 0)
    positionLabel.Position = UDim2.new(0, 5, 0, 0)
    positionLabel.BackgroundTransparency = 1
    positionLabel.Text = playerData.progress.position
    positionLabel.TextColor3 = self:getPositionColor(playerData.progress.position)
    positionLabel.TextScaled = true
    positionLabel.Font = Enum.Font.HighwayGothic
    positionLabel.Parent = playerFrame
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -40, 1, 0)
    nameLabel.Position = UDim2.new(0, 35, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerData.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = playerFrame
    
    -- Highlight local player
    if playerData.name == player.Name then
        playerFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
        playerFrame.BackgroundTransparency = 0.3
    end
end

function UIManager:updateSpeedometer()
    if not self.speedometerFrame then return end
    
    local speedLabel = self.speedometerFrame:FindFirstChild("SpeedLabel")
    if not speedLabel then return end
    
    -- Calculate speed based on player's bike (simplified)
    local speed = 0
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local velocity = player.Character.HumanoidRootPart.Velocity
        speed = math.floor(velocity.Magnitude * 2.237) -- Convert to MPH approximation
    end
    
    speedLabel.Text = tostring(speed)
    
    -- Color based on speed
    if speed > 80 then
        speedLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red for high speed
    elseif speed > 50 then
        speedLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow for medium speed
    else
        speedLabel.TextColor3 = Color3.fromRGB(0, 255, 100) -- Green for low speed
    end
end

function UIManager:updateGameStateDisplay()
    if not self.gameStateFrame then return end
    
    local gameStateLabel = self.gameStateFrame:FindFirstChild("GameStateLabel")
    local gameStateSubLabel = self.gameStateFrame:FindFirstChild("GameStateSubLabel")
    
    if not gameStateLabel or not gameStateSubLabel then return end
    
    local shouldShow = false
    
    if self.raceData.gameState == "waiting" then
        gameStateLabel.Text = "WAITING FOR PLAYERS"
        gameStateSubLabel.Text = "Press R to spawn your bike"
        shouldShow = true
    elseif self.raceData.gameState == "countdown" then
        local countdownTime = self.raceData.countdownTime or 0
        gameStateLabel.Text = "RACE STARTING IN"
        gameStateSubLabel.Text = tostring(countdownTime)
        gameStateSubLabel.TextColor3 = countdownTime <= 3 and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
        shouldShow = true
    elseif self.raceData.gameState == "racing" then
        shouldShow = false
    elseif self.raceData.gameState == "finished" then
        gameStateLabel.Text = "RACE FINISHED!"
        gameStateSubLabel.Text = "Waiting for next race..."
        shouldShow = true
    end
    
    -- Show/hide with animation
    if shouldShow and not self.gameStateFrame.Visible then
        self.gameStateFrame.Visible = true
        self.gameStateFrame.Size = UDim2.new(0, 0, 0, 0)
        local showTween = TweenService:Create(
            self.gameStateFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 400, 0, 150)}
        )
        showTween:Play()
    elseif not shouldShow and self.gameStateFrame.Visible then
        local hideTween = TweenService:Create(
            self.gameStateFrame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size = UDim2.new(0, 0, 0, 0)}
        )
        hideTween:Play()
        hideTween.Completed:Connect(function()
            self.gameStateFrame.Visible = false
        end)
    end
end

function UIManager:getPositionText(position)
    if position == 1 then
        return "1st"
    elseif position == 2 then
        return "2nd"
    elseif position == 3 then
        return "3rd"
    else
        return position .. "th"
    end
end

function UIManager:getPositionColor(position)
    if position == 1 then
        return Color3.fromRGB(255, 215, 0) -- Gold
    elseif position == 2 then
        return Color3.fromRGB(192, 192, 192) -- Silver
    elseif position == 3 then
        return Color3.fromRGB(205, 127, 50) -- Bronze
    else
        return Color3.fromRGB(255, 255, 255) -- White
    end
end

function UIManager:destroy()
    -- Clean up connections
    if self.updateConnection then
        self.updateConnection:Disconnect()
    end
    
    -- Remove GUI
    if self.mainGui then
        self.mainGui:Destroy()
    end
end

-- Initialize the UI manager
local uiManager = UIManager.new()

return UIManager

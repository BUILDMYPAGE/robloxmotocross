--[[
    RaceTrack.lua - Race Track and Checkpoint System
    
    This script handles:
    - Track generation with ramps and obstacles
    - Checkpoint system for tracking player progress
    - Lap counting and race progression
    - Player position determination
    
    Usage: Place in ServerScriptService
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local raceUpdateEvent = remoteEvents:WaitForChild("RaceUpdate")

local RaceTrack = {}
RaceTrack.__index = RaceTrack

-- Track configuration
local TRACK_CONFIG = {
    TrackWidth = 20,
    CheckpointCount = 10,
    LapCount = 3,
    RampHeight = 8,
    ObstacleFrequency = 0.3
}

function RaceTrack.new()
    local self = setmetatable({}, RaceTrack)
    
    self.checkpoints = {}
    self.playerProgress = {}
    self.raceActive = false
    self.startTime = 0
    
    -- Track pieces for procedural generation
    self.trackPieces = {}
    
    self:generateTrack()
    self:setupCheckpoints()
    
    return self
end

function RaceTrack:generateTrack()
    -- Create starting line
    self:createStartingLine()
    
    -- Track layout points (you can modify these for different track shapes)
    local trackPoints = {
        Vector3.new(0, 0, 0),      -- Start
        Vector3.new(50, 0, 0),     -- Straight section
        Vector3.new(80, 0, 30),    -- Right turn
        Vector3.new(100, 0, 80),   -- Straight with ramp
        Vector3.new(80, 0, 120),   -- Left turn
        Vector3.new(30, 0, 140),   -- S-curve start
        Vector3.new(-20, 0, 120),  -- S-curve middle
        Vector3.new(-50, 0, 80),   -- S-curve end
        Vector3.new(-60, 0, 30),   -- Back straight
        Vector3.new(-30, 0, -20),  -- Final turn
        Vector3.new(0, 0, 0)       -- Back to start
    }
    
    -- Generate track segments
    for i = 1, #trackPoints - 1 do
        local startPoint = trackPoints[i]
        local endPoint = trackPoints[i + 1]
        local segmentType = self:determineSegmentType(i, #trackPoints - 1)
        
        self:createTrackSegment(startPoint, endPoint, segmentType, i)
    end
    
    -- Add decorative elements
    self:addTrackDecorations()
end

function RaceTrack:determineSegmentType(segmentIndex, totalSegments)
    -- Determine what type of track segment to create
    local segmentTypes = {"straight", "ramp", "turn", "obstacle"}
    
    -- Force certain segments to be ramps
    if segmentIndex == 4 or segmentIndex == 8 then
        return "ramp"
    end
    
    -- Add obstacles randomly
    if math.random() < TRACK_CONFIG.ObstacleFrequency then
        return "obstacle"
    end
    
    -- Default to straight or turn based on position
    if segmentIndex % 3 == 0 then
        return "turn"
    else
        return "straight"
    end
end

function RaceTrack:createTrackSegment(startPoint, endPoint, segmentType, segmentIndex)
    local direction = (endPoint - startPoint).Unit
    local distance = (endPoint - startPoint).Magnitude
    local segmentParts = {}
    
    -- Create base track surface
    local segments = math.ceil(distance / 10) -- 10 stud segments
    
    for i = 1, segments do
        local position = startPoint + direction * (i - 1) * 10
        local trackPart = self:createTrackPart(position, segmentType, segmentIndex, i)
        table.insert(segmentParts, trackPart)
    end
    
    -- Store segment for reference
    self.trackPieces[segmentIndex] = {
        startPoint = startPoint,
        endPoint = endPoint,
        segmentType = segmentType,
        parts = segmentParts
    }
end

function RaceTrack:createTrackPart(position, segmentType, segmentIndex, partIndex)
    local trackPart = Instance.new("Part")
    trackPart.Name = "TrackSegment_" .. segmentIndex .. "_" .. partIndex
    trackPart.Size = Vector3.new(TRACK_CONFIG.TrackWidth, 2, 10)
    trackPart.Material = Enum.Material.Asphalt
    trackPart.BrickColor = BrickColor.new("Dark stone grey")
    trackPart.Anchored = true
    trackPart.CanCollide = true
    
    -- Adjust position and properties based on segment type
    if segmentType == "ramp" then
        -- Create ramp
        local rampHeight = TRACK_CONFIG.RampHeight * (partIndex / 3) -- Gradual ramp
        trackPart.Position = position + Vector3.new(0, rampHeight, 0)
        trackPart.Rotation = Vector3.new(math.deg(math.atan(rampHeight / 10)), 0, 0)
        trackPart.BrickColor = BrickColor.new("Bright yellow") -- Different color for ramps
    elseif segmentType == "obstacle" then
        -- Add small bumps or barriers
        if partIndex % 2 == 0 then
            trackPart.Size = Vector3.new(TRACK_CONFIG.TrackWidth, 4, 10)
            trackPart.Position = position + Vector3.new(0, 1, 0)
            trackPart.BrickColor = BrickColor.new("Bright red")
        else
            trackPart.Position = position
        end
    else
        trackPart.Position = position
    end
    
    trackPart.Parent = workspace
    
    -- Add track markings
    self:addTrackMarkings(trackPart, segmentType)
    
    return trackPart
end

function RaceTrack:addTrackMarkings(trackPart, segmentType)
    -- Add lane markings
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.Parent = trackPart
    
    -- Center line
    local centerLine = Instance.new("Frame")
    centerLine.Size = UDim2.new(0, 2, 1, 0)
    centerLine.Position = UDim2.new(0.5, -1, 0, 0)
    centerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    centerLine.BorderSizePixel = 0
    centerLine.Parent = surfaceGui
    
    -- Side markings for ramps and special sections
    if segmentType == "ramp" then
        local rampMarking = Instance.new("TextLabel")
        rampMarking.Size = UDim2.new(1, 0, 1, 0)
        rampMarking.Position = UDim2.new(0, 0, 0, 0)
        rampMarking.BackgroundTransparency = 1
        rampMarking.Text = "RAMP"
        rampMarking.TextColor3 = Color3.fromRGB(255, 255, 255)
        rampMarking.TextScaled = true
        rampMarking.Font = Enum.Font.GothamBold
        rampMarking.Parent = surfaceGui
    end
end

function RaceTrack:createStartingLine()
    -- Create starting line platform
    local startingLine = Instance.new("Part")
    startingLine.Name = "StartingLine"
    startingLine.Size = Vector3.new(TRACK_CONFIG.TrackWidth + 10, 2, 20)
    startingLine.Material = Enum.Material.Concrete
    startingLine.BrickColor = BrickColor.new("White")
    startingLine.Position = Vector3.new(0, 0, -10)
    startingLine.Anchored = true
    startingLine.CanCollide = true
    startingLine.Parent = workspace
    
    -- Add starting line markings
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.Parent = startingLine
    
    local startText = Instance.new("TextLabel")
    startText.Size = UDim2.new(1, 0, 1, 0)
    startText.Position = UDim2.new(0, 0, 0, 0)
    startText.BackgroundTransparency = 1
    startText.Text = "START / FINISH"
    startText.TextColor3 = Color3.fromRGB(0, 0, 0)
    startText.TextScaled = true
    startText.Font = Enum.Font.GothamBold
    startText.Parent = surfaceGui
    
    -- Create spawn positions
    self.spawnPositions = {}
    local spawnCount = 8 -- Support up to 8 players
    for i = 1, spawnCount do
        local xOffset = ((i - 1) % 4 - 1.5) * 4 -- 4 players per row
        local zOffset = math.floor((i - 1) / 4) * -5 -- Multiple rows
        local spawnPos = Vector3.new(xOffset, 3, -15 + zOffset)
        table.insert(self.spawnPositions, spawnPos)
    end
end

function RaceTrack:setupCheckpoints()
    -- Calculate checkpoint positions along the track
    local totalCheckpoints = TRACK_CONFIG.CheckpointCount
    
    for i = 1, totalCheckpoints do
        local checkpointIndex = i
        local segmentIndex = math.ceil((i / totalCheckpoints) * #self.trackPieces)
        segmentIndex = math.min(segmentIndex, #self.trackPieces)
        
        if self.trackPieces[segmentIndex] then
            local segment = self.trackPieces[segmentIndex]
            local checkpointPos = segment.startPoint + (segment.endPoint - segment.startPoint) * 0.5
            
            self:createCheckpoint(checkpointIndex, checkpointPos)
        end
    end
    
    -- Create finish line checkpoint
    self:createCheckpoint(totalCheckpoints + 1, Vector3.new(0, 2, 0), true)
end

function RaceTrack:createCheckpoint(index, position, isFinishLine)
    local checkpoint = Instance.new("Part")
    checkpoint.Name = isFinishLine and "FinishLine" or ("Checkpoint_" .. index)
    checkpoint.Size = Vector3.new(TRACK_CONFIG.TrackWidth + 5, 10, 2)
    checkpoint.Material = Enum.Material.ForceField
    checkpoint.BrickColor = isFinishLine and BrickColor.new("Bright green") or BrickColor.new("Bright blue")
    checkpoint.Position = position + Vector3.new(0, 5, 0)
    checkpoint.Anchored = true
    checkpoint.CanCollide = false
    checkpoint.Transparency = 0.7
    checkpoint.Parent = workspace
    
    -- Add checkpoint number display
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(4, 0, 2, 0)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0)
    billboardGui.Parent = checkpoint
    
    local checkpointLabel = Instance.new("TextLabel")
    checkpointLabel.Size = UDim2.new(1, 0, 1, 0)
    checkpointLabel.BackgroundTransparency = 1
    checkpointLabel.Text = isFinishLine and "FINISH" or ("CHECKPOINT " .. index)
    checkpointLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkpointLabel.TextScaled = true
    checkpointLabel.Font = Enum.Font.GothamBold
    checkpointLabel.TextStrokeTransparency = 0
    checkpointLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    checkpointLabel.Parent = billboardGui
    
    -- Store checkpoint data
    self.checkpoints[index] = {
        part = checkpoint,
        position = position,
        index = index,
        isFinishLine = isFinishLine or false
    }
    
    -- Connect touch detection
    checkpoint.Touched:Connect(function(hit)
        self:onCheckpointTouched(index, hit)
    end)
end

function RaceTrack:onCheckpointTouched(checkpointIndex, hit)
    -- Find the player who touched the checkpoint
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if not player then
        -- Check if it's a bike part
        local bike = hit.Parent
        if bike.Name == "BikeFrame" or bike.Parent.Name == "BikeFrame" then
            -- Find player by bike ownership (you'll need to track this)
            player = self:getPlayerFromBike(bike)
        end
    end
    
    if player and self.raceActive then
        self:updatePlayerProgress(player, checkpointIndex)
    end
end

function RaceTrack:getPlayerFromBike(bike)
    -- This function should return the player who owns the bike
    -- You'll need to implement bike ownership tracking
    for _, player in pairs(Players:GetPlayers()) do
        if self.playerProgress[player] and self.playerProgress[player].bike == bike then
            return player
        end
    end
    return nil
end

function RaceTrack:updatePlayerProgress(player, checkpointIndex)
    if not self.playerProgress[player] then
        self.playerProgress[player] = {
            currentCheckpoint = 0,
            currentLap = 1,
            totalDistance = 0,
            raceTime = 0,
            position = 1,
            finished = false
        }
    end
    
    local progress = self.playerProgress[player]
    
    -- Check if this is the next expected checkpoint
    local expectedCheckpoint = progress.currentCheckpoint + 1
    if expectedCheckpoint > TRACK_CONFIG.CheckpointCount then
        expectedCheckpoint = TRACK_CONFIG.CheckpointCount + 1 -- Finish line
    end
    
    if checkpointIndex == expectedCheckpoint then
        progress.currentCheckpoint = checkpointIndex
        progress.totalDistance = progress.totalDistance + 1
        
        -- Check for lap completion
        if checkpointIndex == TRACK_CONFIG.CheckpointCount + 1 then -- Finish line
            progress.currentLap = progress.currentLap + 1
            progress.currentCheckpoint = 0
            
            -- Check for race completion
            if progress.currentLap > TRACK_CONFIG.LapCount then
                progress.finished = true
                progress.raceTime = tick() - self.startTime
                self:onPlayerFinished(player)
            end
        end
        
        -- Update player positions
        self:updatePlayerPositions()
        
        -- Send update to clients
        self:broadcastRaceUpdate()
    end
end

function RaceTrack:updatePlayerPositions()
    -- Sort players by progress (lap, checkpoint, distance)
    local playerList = {}
    for player, progress in pairs(self.playerProgress) do
        table.insert(playerList, {player = player, progress = progress})
    end
    
    table.sort(playerList, function(a, b)
        local progressA = a.progress
        local progressB = b.progress
        
        -- First, compare by lap
        if progressA.currentLap ~= progressB.currentLap then
            return progressA.currentLap > progressB.currentLap
        end
        
        -- Then by checkpoint
        if progressA.currentCheckpoint ~= progressB.currentCheckpoint then
            return progressA.currentCheckpoint > progressB.currentCheckpoint
        end
        
        -- Finally by total distance
        return progressA.totalDistance > progressB.totalDistance
    end)
    
    -- Assign positions
    for i, playerData in ipairs(playerList) do
        playerData.progress.position = i
    end
end

function RaceTrack:onPlayerFinished(player)
    local progress = self.playerProgress[player]
    print(player.Name .. " finished the race in position " .. progress.position .. " with time: " .. progress.raceTime)
    
    -- Award points or rewards based on finishing position
    self:awardRaceRewards(player, progress.position, progress.raceTime)
end

function RaceTrack:awardRaceRewards(player, position, raceTime)
    -- Implement reward system here
    local points = math.max(100 - (position - 1) * 20, 10) -- First place gets 100 points, etc.
    
    -- You can expand this to include currency, items, etc.
    print(player.Name .. " earned " .. points .. " points!")
end

function RaceTrack:broadcastRaceUpdate()
    -- Send race update to all clients
    local raceData = {
        playerProgress = {},
        raceActive = self.raceActive,
        raceTime = self.raceActive and (tick() - self.startTime) or 0
    }
    
    for player, progress in pairs(self.playerProgress) do
        raceData.playerProgress[player.Name] = {
            position = progress.position,
            currentLap = progress.currentLap,
            currentCheckpoint = progress.currentCheckpoint,
            finished = progress.finished,
            raceTime = progress.raceTime
        }
    end
    
    raceUpdateEvent:FireAllClients(raceData)
end

function RaceTrack:startRace()
    self.raceActive = true
    self.startTime = tick()
    
    -- Reset all player progress
    for player, _ in pairs(self.playerProgress) do
        self.playerProgress[player] = {
            currentCheckpoint = 0,
            currentLap = 1,
            totalDistance = 0,
            raceTime = 0,
            position = 1,
            finished = false
        }
    end
    
    print("Race started!")
    self:broadcastRaceUpdate()
end

function RaceTrack:endRace()
    self.raceActive = false
    print("Race ended!")
    self:broadcastRaceUpdate()
end

function RaceTrack:getSpawnPosition(playerIndex)
    if self.spawnPositions and self.spawnPositions[playerIndex] then
        return self.spawnPositions[playerIndex]
    else
        -- Return default spawn position
        return Vector3.new(0, 3, -15)
    end
end

function RaceTrack:addTrackDecorations()
    -- Add some decorative elements around the track
    local decorations = {
        {name = "Start Banner", position = Vector3.new(0, 8, -10), size = Vector3.new(25, 5, 1)},
        {name = "Spectator Stand", position = Vector3.new(-15, 5, -20), size = Vector3.new(10, 10, 15)},
        {name = "Pit Area", position = Vector3.new(15, 2, -25), size = Vector3.new(20, 4, 10)}
    }
    
    for _, decoration in ipairs(decorations) do
        local part = Instance.new("Part")
        part.Name = decoration.name
        part.Size = decoration.size
        part.Position = decoration.position
        part.Material = Enum.Material.Concrete
        part.BrickColor = BrickColor.new("Medium stone grey")
        part.Anchored = true
        part.CanCollide = true
        part.Parent = workspace
        
        -- Add text label for some decorations
        if decoration.name == "Start Banner" then
            local surfaceGui = Instance.new("SurfaceGui")
            surfaceGui.Face = Enum.NormalId.Front
            surfaceGui.Parent = part
            
            local bannerText = Instance.new("TextLabel")
            bannerText.Size = UDim2.new(1, 0, 1, 0)
            bannerText.BackgroundTransparency = 1
            bannerText.Text = "MOTOCROSS RACING"
            bannerText.TextColor3 = Color3.fromRGB(255, 215, 0)
            bannerText.TextScaled = true
            bannerText.Font = Enum.Font.GothamBold
            bannerText.Parent = surfaceGui
        end
    end
end

return RaceTrack

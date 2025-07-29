--[[
    DirtBike.lua - Main Dirt Bike Controller
    
    This script handles the dirt bike physics, controls, and behavior.
    Features:
    - Realistic suspension using HingeConstraints
    - Balance control with AlignOrientation
    - Acceleration, braking, and steering
    - Anti-flip mechanics for ramps
    
    Usage: Place in ServerScriptService
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- RemoteEvents for client-server communication
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local bikeControlEvent = remoteEvents:WaitForChild("BikeControl")

local DirtBike = {}
DirtBike.__index = DirtBike

-- Bike configuration
local BIKE_CONFIG = {
    MaxSpeed = 100,
    Acceleration = 50,
    BrakeForce = 80,
    TurnSpeed = 50,
    SuspensionForce = 5000,
    SuspensionDamping = 500,
    BalanceForce = 2000,
    AntiFlipForce = 1500,
    WheelFriction = 1.5
}

function DirtBike.new(player, spawnPosition)
    local self = setmetatable({}, DirtBike)
    
    self.player = player
    self.isActive = false
    self.currentSpeed = 0
    self.inputValues = {
        throttle = 0,
        brake = 0,
        steer = 0
    }
    
    -- Create the bike model
    self:createBikeModel(spawnPosition)
    self:setupPhysics()
    self:setupControls()
    
    return self
end

function DirtBike:createBikeModel(spawnPosition)
    -- Create main bike frame
    self.frame = Instance.new("Part")
    self.frame.Name = "BikeFrame"
    self.frame.Size = Vector3.new(6, 2, 2)
    self.frame.Material = Enum.Material.Metal
    self.frame.BrickColor = BrickColor.new("Bright red")
    self.frame.Position = spawnPosition
    self.frame.CanCollide = true
    self.frame.Parent = workspace
    
    -- Add seat for player
    self.seat = Instance.new("Seat")
    self.seat.Name = "BikeSeat"
    self.seat.Size = Vector3.new(2, 0.5, 2)
    self.seat.Material = Enum.Material.Fabric
    self.seat.BrickColor = BrickColor.new("Black")
    self.seat.Position = spawnPosition + Vector3.new(0, 1.5, 0)
    self.seat.CanCollide = false
    self.seat.Parent = self.frame
    
    -- Weld seat to frame
    local seatWeld = Instance.new("WeldConstraint")
    seatWeld.Part0 = self.frame
    seatWeld.Part1 = self.seat
    seatWeld.Parent = self.frame
    
    -- Create wheels
    self:createWheels()
    
    -- Create handlebar
    self.handlebar = Instance.new("Part")
    self.handlebar.Name = "Handlebar"
    self.handlebar.Size = Vector3.new(3, 0.2, 0.2)
    self.handlebar.Material = Enum.Material.Metal
    self.handlebar.BrickColor = BrickColor.new("Dark stone grey")
    self.handlebar.Position = spawnPosition + Vector3.new(0, 2, -1)
    self.handlebar.CanCollide = false
    self.handlebar.Parent = self.frame
    
    -- Weld handlebar
    local handlebarWeld = Instance.new("WeldConstraint")
    handlebarWeld.Part0 = self.frame
    handlebarWeld.Part1 = self.handlebar
    handlebarWeld.Parent = self.frame
    
    -- Add BodyVelocity for movement
    self.bodyVelocity = Instance.new("BodyVelocity")
    self.bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
    self.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    self.bodyVelocity.Parent = self.frame
    
    -- Add BodyAngularVelocity for rotation
    self.bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    self.bodyAngularVelocity.MaxTorque = Vector3.new(0, 50000, 0)
    self.bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    self.bodyAngularVelocity.Parent = self.frame
end

function DirtBike:createWheels()
    -- Front wheel
    self.frontWheel = Instance.new("Part")
    self.frontWheel.Name = "FrontWheel"
    self.frontWheel.Size = Vector3.new(0.5, 3, 3)
    self.frontWheel.Shape = Enum.PartType.Cylinder
    self.frontWheel.Material = Enum.Material.Rubber
    self.frontWheel.BrickColor = BrickColor.new("Really black")
    self.frontWheel.Position = self.frame.Position + Vector3.new(0, -2, -2.5)
    self.frontWheel.CanCollide = true
    self.frontWheel.Parent = workspace
    
    -- Rear wheel
    self.rearWheel = Instance.new("Part")
    self.rearWheel.Name = "RearWheel"
    self.rearWheel.Size = Vector3.new(0.5, 3, 3)
    self.rearWheel.Shape = Enum.PartType.Cylinder
    self.rearWheel.Material = Enum.Material.Rubber
    self.rearWheel.BrickColor = BrickColor.new("Really black")
    self.rearWheel.Position = self.frame.Position + Vector3.new(0, -2, 2.5)
    self.rearWheel.CanCollide = true
    self.rearWheel.Parent = workspace
    
    -- Set wheel friction
    local frontWheelSurface = Instance.new("SurfaceGui")
    frontWheelSurface.Parent = self.frontWheel
    
    local rearWheelSurface = Instance.new("SurfaceGui")
    rearWheelSurface.Parent = self.rearWheel
end

function DirtBike:setupPhysics()
    -- Create suspension for front wheel
    self.frontSuspension = Instance.new("SpringConstraint")
    
    -- Create attachments for front suspension
    local frontAttachment0 = Instance.new("Attachment")
    frontAttachment0.Position = Vector3.new(0, -1, -2.5)
    frontAttachment0.Parent = self.frame
    
    local frontAttachment1 = Instance.new("Attachment")
    frontAttachment1.Position = Vector3.new(0, 1, 0)
    frontAttachment1.Parent = self.frontWheel
    
    self.frontSuspension.Attachment0 = frontAttachment0
    self.frontSuspension.Attachment1 = frontAttachment1
    self.frontSuspension.Stiffness = BIKE_CONFIG.SuspensionForce
    self.frontSuspension.Damping = BIKE_CONFIG.SuspensionDamping
    self.frontSuspension.FreeLength = 1
    self.frontSuspension.Parent = self.frame
    
    -- Create suspension for rear wheel
    self.rearSuspension = Instance.new("SpringConstraint")
    
    local rearAttachment0 = Instance.new("Attachment")
    rearAttachment0.Position = Vector3.new(0, -1, 2.5)
    rearAttachment0.Parent = self.frame
    
    local rearAttachment1 = Instance.new("Attachment")
    rearAttachment1.Position = Vector3.new(0, 1, 0)
    rearAttachment1.Parent = self.rearWheel
    
    self.rearSuspension.Attachment0 = rearAttachment0
    self.rearSuspension.Attachment1 = rearAttachment1
    self.rearSuspension.Stiffness = BIKE_CONFIG.SuspensionForce
    self.rearSuspension.Damping = BIKE_CONFIG.SuspensionDamping
    self.rearSuspension.FreeLength = 1
    self.rearSuspension.Parent = self.frame
    
    -- Create wheel rotation hinges
    self:createWheelHinges()
    
    -- Create balance system
    self:createBalanceSystem()
end

function DirtBike:createWheelHinges()
    -- Front wheel hinge
    self.frontHinge = Instance.new("HingeConstraint")
    
    local frontHingeAttachment0 = Instance.new("Attachment")
    frontHingeAttachment0.Position = Vector3.new(0, -2, -2.5)
    frontHingeAttachment0.Orientation = Vector3.new(0, 0, 90)
    frontHingeAttachment0.Parent = self.frame
    
    local frontHingeAttachment1 = Instance.new("Attachment")
    frontHingeAttachment1.Position = Vector3.new(0, 0, 0)
    frontHingeAttachment1.Orientation = Vector3.new(0, 0, 90)
    frontHingeAttachment1.Parent = self.frontWheel
    
    self.frontHinge.Attachment0 = frontHingeAttachment0
    self.frontHinge.Attachment1 = frontHingeAttachment1
    self.frontHinge.ActuatorType = Enum.ActuatorType.Motor
    self.frontHinge.MotorMaxTorque = 10000
    self.frontHinge.AngularVelocity = 0
    self.frontHinge.Parent = self.frame
    
    -- Rear wheel hinge
    self.rearHinge = Instance.new("HingeConstraint")
    
    local rearHingeAttachment0 = Instance.new("Attachment")
    rearHingeAttachment0.Position = Vector3.new(0, -2, 2.5)
    rearHingeAttachment0.Orientation = Vector3.new(0, 0, 90)
    rearHingeAttachment0.Parent = self.frame
    
    local rearHingeAttachment1 = Instance.new("Attachment")
    rearHingeAttachment1.Position = Vector3.new(0, 0, 0)
    rearHingeAttachment1.Orientation = Vector3.new(0, 0, 90)
    rearHingeAttachment1.Parent = self.rearWheel
    
    self.rearHinge.Attachment0 = rearHingeAttachment0
    self.rearHinge.Attachment1 = rearHingeAttachment1
    self.rearHinge.ActuatorType = Enum.ActuatorType.Motor
    self.rearHinge.MotorMaxTorque = 10000
    self.rearHinge.AngularVelocity = 0
    self.rearHinge.Parent = self.frame
end

function DirtBike:createBalanceSystem()
    -- AlignOrientation for balance control
    self.alignOrientation = Instance.new("AlignOrientation")
    
    local balanceAttachment = Instance.new("Attachment")
    balanceAttachment.Name = "BalanceAttachment"
    balanceAttachment.Parent = self.frame
    
    self.alignOrientation.Attachment0 = balanceAttachment
    self.alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    self.alignOrientation.MaxTorque = BIKE_CONFIG.BalanceForce
    self.alignOrientation.Responsiveness = 20
    self.alignOrientation.Parent = self.frame
    
    -- Set target orientation to keep bike upright
    self.targetCFrame = self.frame.CFrame
end

function DirtBike:setupControls()
    -- Connect to remote event for input
    bikeControlEvent.OnServerEvent:Connect(function(player, inputType, inputValue)
        if player == self.player then
            self:handleInput(inputType, inputValue)
        end
    end)
    
    -- Start physics update loop
    self.heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
        self:updatePhysics(deltaTime)
    end)
end

function DirtBike:handleInput(inputType, inputValue)
    if inputType == "throttle" then
        self.inputValues.throttle = inputValue
    elseif inputType == "brake" then
        self.inputValues.brake = inputValue
    elseif inputType == "steer" then
        self.inputValues.steer = inputValue
    end
end

function DirtBike:updatePhysics(deltaTime)
    if not self.frame or not self.frame.Parent then
        return
    end
    
    -- Calculate movement
    local throttle = self.inputValues.throttle
    local brake = self.inputValues.brake
    local steer = self.inputValues.steer
    
    -- Update speed
    if throttle > 0 then
        self.currentSpeed = math.min(self.currentSpeed + BIKE_CONFIG.Acceleration * deltaTime, BIKE_CONFIG.MaxSpeed)
    elseif brake > 0 then
        self.currentSpeed = math.max(self.currentSpeed - BIKE_CONFIG.BrakeForce * deltaTime, 0)
    else
        -- Natural deceleration
        self.currentSpeed = math.max(self.currentSpeed - 20 * deltaTime, 0)
    end
    
    -- Apply movement
    local forwardDirection = self.frame.CFrame.LookVector
    local velocity = forwardDirection * self.currentSpeed
    
    if self.bodyVelocity then
        self.bodyVelocity.Velocity = velocity
    end
    
    -- Apply steering
    if math.abs(steer) > 0.1 and self.currentSpeed > 5 then
        local turnRate = BIKE_CONFIG.TurnSpeed * steer * (self.currentSpeed / BIKE_CONFIG.MaxSpeed)
        if self.bodyAngularVelocity then
            self.bodyAngularVelocity.AngularVelocity = Vector3.new(0, math.rad(turnRate), 0)
        end
        
        -- Tilt bike when turning
        local tiltAngle = math.rad(steer * 15) -- Max 15 degree tilt
        local currentCFrame = self.frame.CFrame
        local tiltedCFrame = currentCFrame * CFrame.Angles(0, 0, tiltAngle)
        self.targetCFrame = tiltedCFrame
    else
        if self.bodyAngularVelocity then
            self.bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
        end
        
        -- Return to upright position
        local currentCFrame = self.frame.CFrame
        local uprightCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + currentCFrame.LookVector)
        self.targetCFrame = uprightCFrame
    end
    
    -- Update balance system
    if self.alignOrientation then
        self.alignOrientation.CFrame = self.targetCFrame
    end
    
    -- Update wheel rotation
    local wheelSpeed = self.currentSpeed / 10 -- Convert to angular velocity
    if self.frontHinge then
        self.frontHinge.AngularVelocity = wheelSpeed
    end
    if self.rearHinge then
        self.rearHinge.AngularVelocity = wheelSpeed
    end
    
    -- Anti-flip system for ramps
    self:updateAntiFlip()
end

function DirtBike:updateAntiFlip()
    if not self.frame then return end
    
    local upVector = self.frame.CFrame.UpVector
    local worldUp = Vector3.new(0, 1, 0)
    
    -- Check if bike is tilted too much
    local dot = upVector:Dot(worldUp)
    if dot < 0.3 then -- If tilted more than ~70 degrees
        -- Apply corrective force
        local correctionForce = worldUp * BIKE_CONFIG.AntiFlipForce
        local bodyVelocity = self.frame:FindFirstChild("BodyVelocity")
        if bodyVelocity then
            bodyVelocity.Velocity = bodyVelocity.Velocity + correctionForce * 0.1
        end
        
        -- Apply corrective torque
        local rightVector = self.frame.CFrame.RightVector
        local correctionTorque = rightVector:Cross(worldUp) * BIKE_CONFIG.AntiFlipForce
        
        if self.alignOrientation then
            -- Increase responsiveness temporarily for quick recovery
            self.alignOrientation.Responsiveness = 50
        end
    else
        if self.alignOrientation then
            -- Return to normal responsiveness
            self.alignOrientation.Responsiveness = 20
        end
    end
end

function DirtBike:destroy()
    -- Clean up connections
    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
    end
    
    -- Clean up bike model
    if self.frame and self.frame.Parent then
        self.frame:Destroy()
    end
    if self.frontWheel and self.frontWheel.Parent then
        self.frontWheel:Destroy()
    end
    if self.rearWheel and self.rearWheel.Parent then
        self.rearWheel:Destroy()
    end
    
    self.isActive = false
end

return DirtBike

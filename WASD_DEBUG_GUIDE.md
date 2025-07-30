# 🐛 WASD CONTROL DEBUGGING GUIDE

## Problem Analysis
The bike spawns and is stabilized, but WASD controls don't work. This is likely due to **VehicleSeat occupancy issues**.

## Key Insight: VehicleSeat Controls
⚠️ **CRITICAL**: VehicleSeat.Throttle and VehicleSeat.Steer only work when a Humanoid is sitting in the VehicleSeat!

## Debug Steps Added

### 1. Client-Side Debug (Main.client.lua)
- ✅ Added WASD key press detection logging
- ✅ Added input value logging (throttle, brake, steer)
- ✅ Added network send confirmation logging

### 2. Server-Side Debug (Main.server.lua)  
- ✅ Added input reception logging
- ✅ Added bike finding verification
- ✅ Added VehicleSeat property logging
- ✅ Added occupancy checking (seat.Occupant)
- ✅ Enhanced auto-sit functionality with retries

### 3. Debug Script (WASD_DEBUG.server.lua)
- ✅ Manual bike status checking (/debug command)
- ✅ Force-sit functionality (/sit command)
- ✅ Comprehensive VehicleSeat diagnostics

## Testing Protocol

### Step 1: Spawn Bike
```
Press R → Check console for bike creation messages
```

### Step 2: Check Debug Output
```
Press WASD → Look for these messages:
🎯 WASD INPUT - W PRESSED
📡 SENDING INPUTS: T=1, B=0, S=0
🎮 SERVER RECEIVED INPUT from [Player]: allInputs = table
🎯 APPLYING TO BIKE [Player]: Throttle=1.00, Steer=0.00
```

### Step 3: Check Occupancy
```
Type /debug in chat → Look for:
✅ VehicleSeat.Occupant: [Humanoid]
OR
❌ VehicleSeat.Occupant: nil
```

### Step 4: Force Sit (if needed)
```
Type /sit in chat → Forces player into VehicleSeat
```

## Common Issues & Solutions

### Issue 1: Player Not Sitting
**Symptoms**: 
- Inputs sent but bike doesn't move
- Console shows "❌ PROBLEM: Player is NOT sitting in VehicleSeat!"

**Solution**: 
- Type `/sit` to force-sit
- Auto-sit should retry automatically

### Issue 2: VehicleSeat Disabled
**Symptoms**: 
- VehicleSeat.Disabled = true
- Seat appears non-functional

**Solution**: 
- Auto-fix: Server sets Disabled = false
- Manual check with `/debug`

### Issue 3: Network Issues
**Symptoms**: 
- Client shows input but server doesn't receive
- Missing network messages

**Solution**: 
- Check RemoteEvent connections
- Verify bikeControlEvent exists

## Expected Console Output (Working)

### Client:
```
🎯 WASD INPUT - W PRESSED
🎯 Current values: Throttle=1, Brake=0, Steer=0
📡 SENDING INPUTS: T=1, B=0, S=0
```

### Server:
```
🎮 SERVER RECEIVED INPUT from Player1: allInputs = table
🎯 APPLYING TO BIKE Player1: Throttle=1.00, Steer=0.00
🔧 VehicleSeat properties: MaxSpeed=80, Torque=25000, TurnSpeed=25
✅ Player is sitting in VehicleSeat
```

## If Still Not Working

1. **Check bike physics**: Bike might be stuck/anchored
2. **Verify Humanoid**: Player character might be broken
3. **Test manually**: Use VehicleSeat GUI to test basic movement
4. **Respawn bike**: Press R again to get fresh bike

## Quick Fix Commands
- `/debug` - Full bike diagnostics
- `/sit` - Force player to sit in bike
- Press `R` - Respawn fresh bike

The debug output will show exactly where the problem is occurring! 🔍

function widget:GetInfo()
	return {
		name = "Developer Debug Menu",
		desc = "Simple developer controls",
		author = "Justin H.",
		version = "3.1",
		date = "2025-03-30",
		license = "GNU GPL, v2 or later",
		layer = 10000,
		enabled = true,
	}
end

-- Add a sign function if not already available
math.sign = math.sign or function(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
end

-- Configuration
local debugSpawnUnit = "armcomlvl10"
local secondSpawnUnit = "armacv"
local circleRadius = 200  -- Default radius for circle formation
local pizzaRadius = 200   -- Default radius for pizza formation
local pizzaAngle = 150    -- Default angle spread for pizza formation (in degrees) - increased from 120
local pizzaFillSides = true -- Fill the sides of the pizza slice
local pizzaDirection = 0  -- Direction of pizza slice in degrees (0 = east, 90 = north, etc.)
local wFormationActive = false -- For W formation placement
local wFormationWidth = 250  -- Width of the W formation
local wFormationDepth = 150  -- Depth/height of the W formation
local wDirection = 0       -- Direction of W formation in degrees
local diamondFormationActive = false -- For diamond formation placement
local diamondWidth = 200   -- Width of the diamond formation
local diamondLength = 300  -- Length of the diamond formation
local diamondTopRatio = 0.5 -- Top half is shorter than bottom half
local diamondDirection = 0 -- Direction of diamond formation in degrees

-- Button states
local cheatEnabled = false
local nocostEnabled = false
local godmodeEnabled = false
local nofogEnabled = false
local spawnModeActive = false
local spawnModeUnit = debugSpawnUnit -- Which unit to spawn
local circleModeActive = false -- For circle formation placement
local pizzaModeActive = false -- For pizza formation placement

-- Menu positioning
local menuX = 0
local menuY = 0
local menuWidth = 200
local buttonHeight = 30
local buttonSpacing = 5
local buttonPadding = 10
local menuVisible = true

-- Screen dimensions
local screenWidth = 1024
local screenHeight = 768

-- Import Spring functions
local GetMouseState = Spring.GetMouseState
local TraceScreenRay = Spring.TraceScreenRay
local SendCommands = Spring.SendCommands
local GetViewGeometry = Spring.GetViewGeometry
local IsCheatingEnabled = Spring.IsCheatingEnabled
local Echo = Spring.Echo
-- Import ValidUnitID correctly
local ValidUnitID = Spring.ValidUnitID

-- Import Spring command constants directly
local CMD_MOVE = 10      -- Explicit command ID for move (Spring.CMD.MOVE)
local CMD_STOP = 0       -- Stop command (Spring.CMD.STOP)
local CMD_OPT_SHIFT = 1  -- Shift key option (add to queue instead of replacing) - essential for waypoints
local CMD_OPT_ALT = 4    -- Alt key option for commands
local CMD_OPT_CTRL = 8   -- Control key option for commands
local CMD_OPT_RIGHT = 16 -- Right mouse button option
local CMD_OPT_META = 32  -- Meta key option
local CMD_OPT_INTERNAL = 2048 -- Internal command option (engine use)
local CMD_MOVE_ID = 10   -- More explicit command ID for move

-- For diamond formation - command tracking
local diamondPendingCommands = {}    -- Store waypoint commands to issue
local diamondFinalTarget = {x=0, y=0, z=0} -- Final target for all units

-- Safe click position storage
local safeClickX = 0
local safeClickY = 0
local safeClickZ = 0
local hasValidTarget = false
local selectedUnits = {}  -- Store selected units for circle formation

-- Activate spawn mode
local function activateSpawnMode(unitType)
    circleModeActive = false
    spawnModeActive = true
    spawnModeUnit = unitType
    Echo("Spawn mode active - click on map to place " .. unitType)
end

-- Deactivate spawn mode
local function deactivateSpawnMode()
    spawnModeActive = false
    Echo("Spawn mode deactivated")
end

-- Activate circle formation mode
local function activateCircleMode()
    spawnModeActive = false
    circleModeActive = true
    
    -- Store currently selected units
    local tempUnits = Spring.GetSelectedUnits() or {}
    selectedUnits = {}
    
    -- Copy the units into our array to ensure we have valid units
    for i, unitID in ipairs(tempUnits) do
        if unitID and unitID > 0 and ValidUnitID(unitID) then
            table.insert(selectedUnits, unitID)
        end
    end
    
    local count = #selectedUnits
    
    if count > 0 then
        Echo("Circle formation mode active - click on map to place " .. count .. " units in a circle")
        Echo("Selected units: " .. count)
        
        -- Print each selected unit ID for debugging
        for i, unitID in ipairs(selectedUnits) do
            Echo("Selected unit " .. i .. ": ID " .. unitID)
        end
    else
        Echo("No units selected - please select units first")
        circleModeActive = false
    end
end

-- Deactivate circle formation mode
local function deactivateCircleMode()
    circleModeActive = false
    selectedUnits = {}
    Echo("Circle formation mode deactivated")
end

-- Activate pizza formation mode
local function activatePizzaMode()
    spawnModeActive = false
    circleModeActive = false
    pizzaModeActive = true
    
    -- Store currently selected units
    local tempUnits = Spring.GetSelectedUnits() or {}
    selectedUnits = {}
    
    -- Copy the units into our array to ensure we have valid units
    for i, unitID in ipairs(tempUnits) do
        if unitID and unitID > 0 and ValidUnitID(unitID) then
            table.insert(selectedUnits, unitID)
        end
    end
    
    local count = #selectedUnits
    
    if count > 0 then
        Echo("Pizza formation mode active - click on map to place " .. count .. " units in a pizza shape")
        Echo("Selected units: " .. count)
        Echo("Controls:")
        Echo("  Q/E - Rotate pizza slice left/right")
        Echo("  F - Toggle filling the sides of the slice")
        Echo("  ESC - Cancel formation")
        
        -- Print each selected unit ID for debugging
        for i, unitID in ipairs(selectedUnits) do
            Echo("Selected unit " .. i .. ": ID " .. unitID)
        end
    else
        Echo("No units selected - please select units first")
        pizzaModeActive = false
    end
end

-- Deactivate pizza formation mode
local function deactivatePizzaMode()
    pizzaModeActive = false
    selectedUnits = {}
    Echo("Pizza formation mode deactivated")
end

-- Activate W formation mode
local function activateWFormation()
    spawnModeActive = false
    circleModeActive = false
    pizzaModeActive = false
    wFormationActive = true
    
    -- Store currently selected units
    local tempUnits = Spring.GetSelectedUnits() or {}
    selectedUnits = {}
    
    -- Copy the units into our array to ensure we have valid units
    for i, unitID in ipairs(tempUnits) do
        if unitID and unitID > 0 and ValidUnitID(unitID) then
            table.insert(selectedUnits, unitID)
        end
    end
    
    local count = #selectedUnits
    
    if count > 0 then
        Echo("W formation mode active - click on map to place " .. count .. " units in a W shape")
        Echo("Selected units: " .. count)
        Echo("Controls:")
        Echo("  Q/E - Rotate W formation left/right")
        Echo("  ESC - Cancel formation")
        
        -- Print each selected unit ID for debugging
        for i, unitID in ipairs(selectedUnits) do
            Echo("Selected unit " .. i .. ": ID " .. unitID)
        end
    else
        Echo("No units selected - please select units first")
        wFormationActive = false
    end
end

-- Deactivate W formation mode
local function deactivateWFormation()
    wFormationActive = false
    selectedUnits = {}
    Echo("W formation mode deactivated")
end

-- Activate Diamond formation mode
local function activateDiamondFormation()
    spawnModeActive = false
    circleModeActive = false
    pizzaModeActive = false
    wFormationActive = false
    diamondFormationActive = true
    
    -- Store currently selected units
    local tempUnits = Spring.GetSelectedUnits() or {}
    selectedUnits = {}
    
    -- Copy the units into our array to ensure we have valid units
    for i, unitID in ipairs(tempUnits) do
        if unitID and unitID > 0 and ValidUnitID(unitID) then
            table.insert(selectedUnits, unitID)
        end
    end
    
    local count = #selectedUnits
    
    if count > 0 then
        Echo("Diamond formation mode active - click on map to place " .. count .. " units in a flanking diamond attack")
        Echo("Controls:")
        Echo("  - Click where you want units to attack/converge (the target point)")
        Echo("  - Units will split into left and right groups")
        Echo("  - Each group will move to a flank position first")
        Echo("  - Then both groups will converge on the target in a pincer movement")
        Echo("  - ESC - Cancel formation")
        Echo("  - Q/E - Rotate formation (to be implemented)")
    else
        Echo("No units selected - please select units first")
        diamondFormationActive = false
    end
end

-- Deactivate Diamond formation mode
local function deactivateDiamondFormation()
    diamondFormationActive = false
    selectedUnits = {}
    Echo("Diamond formation mode deactivated")
    
    -- Clear any pending commands to avoid leftover operations
    if #diamondPendingCommands > 0 then
        Echo("[DIAMOND FORMATION] Cleared " .. #diamondPendingCommands .. " pending commands")
        diamondPendingCommands = {}
    end
end

-- Execute spawn at safe position
local function executeSafeSpawn()
    if not hasValidTarget then
        Echo("No valid target position")
        return
    end
    
    -- Make sure cheats are enabled
    if not IsCheatingEnabled() then
        SendCommands("cheat 1")
        cheatEnabled = true
    end
    
    -- Send the give command with proper format
    -- Round coordinates to integers to avoid floating point issues
    local x = math.floor(safeClickX)
    local z = math.floor(safeClickZ)
    SendCommands("give " .. spawnModeUnit)
    Echo("Attempting to spawn " .. spawnModeUnit .. " at " .. x .. "," .. z)
    
    -- Also try direct unit creation as fallback
    pcall(function()
        if Spring.CreateUnit then
            local unitID = Spring.CreateUnit(spawnModeUnit, x, safeClickY, z, 0, Spring.GetMyTeamID())
            if unitID then
                Echo("Successfully spawned " .. spawnModeUnit .. " (ID: " .. unitID .. ")")
            end
        end
    end)
    
    -- Reset state
    hasValidTarget = false
    deactivateSpawnMode()
end

-- Place units in circle formation at target position
local function executeCircleFormation()
    if not hasValidTarget then
        Echo("No valid target position")
        return
    end
    
    -- Re-get the currently selected units in case the selection has changed
    selectedUnits = Spring.GetSelectedUnits() or {}
    local count = #selectedUnits
    
    -- Get positions and counts
    local centerX = safeClickX
    local centerZ = safeClickZ
    
    if count == 0 then
        Echo("No units selected for circle formation")
        deactivateCircleMode()
        return
    end
    
    -- Position units in a circle
    Echo("Placing " .. count .. " units in circle formation at " .. centerX .. "," .. centerZ)
    
    -- Use both methods for added reliability
    
    -- Method 1: Direct command to each unit
    for i, unitID in ipairs(selectedUnits) do
        -- Calculate position on circle
        local angle = (i - 1) * (2 * math.pi / count)
        local x = centerX + circleRadius * math.cos(angle)
        local z = centerZ + circleRadius * math.sin(angle)
        local y = Spring.GetGroundHeight(x, z) or 0
        
        Echo("Moving unit ID " .. unitID .. " to position " .. x .. "," .. z)
        
        -- First stop the unit to clear previous orders
        pcall(function()
            Spring.GiveOrderToUnit(unitID, CMD_STOP, {}, {})
        end)
        
        -- Then issue the move command with a small delay
        Spring.Echo("Issuing move command")
        pcall(function()
            Spring.GiveOrderToUnit(unitID, CMD_MOVE, {x, y, z}, {})
        end)
    end
    
    -- Method 2: Send a formation command for all units at once
    -- Only as a backup in case the individual commands don't work
    pcall(function()
        -- First stop all units to clear previous orders
        local cmdParams = {}
        Spring.GiveOrderToUnitArray(selectedUnits, CMD_STOP, cmdParams, {})
        
        -- For each unit, add a move command to its position on the circle
        for i, unitID in ipairs(selectedUnits) do
            -- Calculate position on circle
            local angle = (i - 1) * (2 * math.pi / count)
            local x = centerX + circleRadius * math.cos(angle)
            local z = centerZ + circleRadius * math.sin(angle)
            local y = Spring.GetGroundHeight(x, z) or 0
            
            cmdParams = {x, y, z}
            Spring.GiveOrderToUnit(unitID, CMD_MOVE, cmdParams, {})
        end
    end)
    
    -- Reset state
    hasValidTarget = false
    deactivateCircleMode()
end

-- Place units in pizza formation at target position
local function executePizzaFormation()
    if not hasValidTarget then
        Echo("No valid target position")
        return
    end
    
    -- Re-get the currently selected units in case the selection has changed
    selectedUnits = Spring.GetSelectedUnits() or {}
    local count = #selectedUnits
    
    -- Get positions and counts
    local centerX = safeClickX
    local centerZ = safeClickZ
    
    if count == 0 then
        Echo("No units selected for pizza formation")
        deactivatePizzaMode()
        return
    end
    
    -- Position units in a pizza shape (wedge/slice)
    Echo("Placing " .. count .. " units in pizza formation at " .. centerX .. "," .. centerZ)
    Echo("Direction: " .. pizzaDirection .. " degrees, Fill sides: " .. (pizzaFillSides and "Yes" or "No"))
    
    -- Convert angles from degrees to radians
    local pizzaAngleRad = math.rad(pizzaAngle)
    local directionRad = math.rad(pizzaDirection)
    
    -- Calculate start angle based on direction
    local startAngle = directionRad - (pizzaAngleRad / 2)
    
    -- Calculate unit positions and store them
    local unitPositions = {}
    
    -- First unit always at the center (tip of the pizza)
    table.insert(unitPositions, {
        x = centerX,
        y = Spring.GetGroundHeight(centerX, centerZ) or 0,
        z = centerZ
    })
    
    -- Determine how to place the remaining units
    local remainingUnits = count - 1
    if remainingUnits <= 0 then
        -- If only one unit, just place it at the center
    elseif pizzaFillSides then
        -- Fill the entire pizza slice with units
        -- Calculate how many rings we need
        local maxUnitsOnOuterRing = math.max(2, math.floor(pizzaAngleRad * 3))
        
        -- Distribute units across multiple rings
        local remainingToPlace = remainingUnits
        local ringRadius = pizzaRadius
        local minRadius = pizzaRadius * 0.2  -- Start at 20% of max radius
        local ringSpacing = (pizzaRadius - minRadius) / 5  -- Space between rings
        
        -- Place units along multiple rings
        for ring = 1, 5 do
            ringRadius = pizzaRadius - ((ring - 1) * ringSpacing)
            local unitsInThisRing = math.min(remainingToPlace, math.max(2, math.ceil(maxUnitsOnOuterRing * (ringRadius / pizzaRadius))))
            
            if unitsInThisRing <= 0 or ringRadius < minRadius then break end
            
            local ringAngleStep = pizzaAngleRad / (unitsInThisRing - 1)
            if unitsInThisRing <= 1 then
                ringAngleStep = 0
            end
            
            -- Place units along this ring
            for i = 0, unitsInThisRing - 1 do
                local angle = startAngle + i * ringAngleStep
                local x = centerX + ringRadius * math.cos(angle)
                local z = centerZ + ringRadius * math.sin(angle)
                local y = Spring.GetGroundHeight(x, z) or 0
                
                table.insert(unitPositions, {
                    x = x,
                    y = y,
                    z = z
                })
            end
            
            remainingToPlace = remainingToPlace - unitsInThisRing
            if remainingToPlace <= 0 then break end
        end
    else
        -- Just place units along the outer arc
        local angleStep = pizzaAngleRad / (remainingUnits - 1)
        if remainingUnits <= 1 then
            angleStep = 0
        end
        
        for i = 0, remainingUnits - 1 do
            local angle = startAngle + i * angleStep
            local x = centerX + pizzaRadius * math.cos(angle)
            local z = centerZ + pizzaRadius * math.sin(angle)
            local y = Spring.GetGroundHeight(x, z) or 0
            
            table.insert(unitPositions, {
                x = x,
                y = y,
                z = z
            })
        end
    end
    
    -- Make sure we have the right number of positions
    if #unitPositions < count then
        -- If we don't have enough positions, add more at the center
        for i = #unitPositions + 1, count do
            table.insert(unitPositions, {
                x = centerX,
                y = Spring.GetGroundHeight(centerX, centerZ) or 0,
                z = centerZ
            })
        end
    elseif #unitPositions > count then
        -- If we have too many positions, trim the extras
        while #unitPositions > count do
            table.remove(unitPositions)
        end
    end
    
    -- Method 1: Direct command to each unit
    for i, unitID in ipairs(selectedUnits) do
        -- Get the position for this unit
        local pos = unitPositions[i]
        if not pos then
            Echo("Error: Missing position for unit " .. i)
            break
        end
        
        Echo("Moving unit ID " .. unitID .. " to position " .. pos.x .. "," .. pos.z)
        
        -- First stop the unit to clear previous orders
        pcall(function()
            Spring.GiveOrderToUnit(unitID, CMD_STOP, {}, {})
        end)
        
        -- Then issue the move command
        pcall(function()
            Spring.GiveOrderToUnit(unitID, CMD_MOVE, {pos.x, pos.y, pos.z}, {})
        end)
    end
    
    -- Method 2: Send a formation command for all units at once
    -- Only as a backup in case the individual commands don't work
    pcall(function()
        -- First stop all units to clear previous orders
        local cmdParams = {}
        Spring.GiveOrderToUnitArray(selectedUnits, CMD_STOP, cmdParams, {})
        
        -- For each unit, add a move command to its position in the pizza
        for i, unitID in ipairs(selectedUnits) do
            -- Get the position for this unit
            local pos = unitPositions[i]
            if not pos then
                Echo("Error: Missing position for unit " .. i)
                break
            end
            
            cmdParams = {pos.x, pos.y, pos.z}
            Spring.GiveOrderToUnit(unitID, CMD_MOVE, cmdParams, {})
        end
    end)
    
    -- Reset state
    hasValidTarget = false
    deactivatePizzaMode()
end

-- Place units in W formation at target position
local function executeWFormation()
    if not hasValidTarget then
        Echo("No valid target position")
        return
    end
    
    -- Re-get the currently selected units in case the selection has changed
    selectedUnits = Spring.GetSelectedUnits() or {}
    local count = #selectedUnits
    
    -- Get positions and counts
    local centerX = safeClickX
    local centerZ = safeClickZ
    
    if count == 0 then
        Echo("No units selected for W formation")
        deactivateWFormation()
        return
    end
    
    -- Position units in a W shape
    Echo("Placing " .. count .. " units in W formation at " .. centerX .. "," .. centerZ)
    Echo("Direction: " .. wDirection .. " degrees")
    
    -- Convert angles from degrees to radians
    local directionRad = math.rad(wDirection)
    
    -- Calculate unit positions and store them
    local unitPositions = {}
    
    -- Define the base W shape points (unrotated, centered at origin)
    local baseW = {
        {x = -wFormationWidth/2, z = wFormationDepth/2},  -- Top left
        {x = -wFormationWidth/4, z = -wFormationDepth/2}, -- Bottom left middle
        {x = 0, z = wFormationDepth/2},                   -- Top middle
        {x = wFormationWidth/4, z = -wFormationDepth/2},  -- Bottom right middle
        {x = wFormationWidth/2, z = wFormationDepth/2}    -- Top right
    }
    
    -- Calculate how to distribute units across the W
    local totalPoints = 5  -- 5 points in a W
    local unitsPerSegment
    
    -- If we have more than 5 units, distribute additional units along the segments
    if count <= totalPoints then
        -- Just place units at the key points, starting from left
        for i = 1, count do
            local pointIndex = i
            local point = baseW[pointIndex]
            
            -- Rotate the point based on direction
            local rotX = point.x * math.cos(directionRad) - point.z * math.sin(directionRad)
            local rotZ = point.x * math.sin(directionRad) + point.z * math.cos(directionRad)
            
            -- Add to center point for final position
            local x = centerX + rotX
            local z = centerZ + rotZ
            local y = Spring.GetGroundHeight(x, z) or 0
            
            table.insert(unitPositions, {
                x = x,
                y = y,
                z = z
            })
        end
    else
        -- We have more units than key points, so distribute along line segments
        -- Calculate how many units to place on each segment
        local segmentCount = 4  -- 4 segments in a W (5 points)
        local extraUnits = count - 5
        local unitsPerSegment = math.floor(extraUnits / segmentCount)
        local remainingUnits = extraUnits % segmentCount
        
        -- First place units at the 5 key points
        for i = 1, 5 do
            local point = baseW[i]
            
            -- Rotate the point based on direction
            local rotX = point.x * math.cos(directionRad) - point.z * math.sin(directionRad)
            local rotZ = point.x * math.sin(directionRad) + point.z * math.cos(directionRad)
            
            -- Add to center point for final position
            local x = centerX + rotX
            local z = centerZ + rotZ
            local y = Spring.GetGroundHeight(x, z) or 0
            
            table.insert(unitPositions, {
                x = x,
                y = y,
                z = z
            })
        end
        
        -- Then distribute remaining units along the four segments
        for segment = 1, 4 do
            local startPoint = baseW[segment]
            local endPoint = baseW[segment+1]
            local segmentUnits = unitsPerSegment + (segment <= remainingUnits and 1 or 0)
            
            for i = 1, segmentUnits do
                -- Calculate position along the segment (excluding endpoints)
                local t = i / (segmentUnits + 1)
                local x = startPoint.x + t * (endPoint.x - startPoint.x)
                local z = startPoint.z + t * (endPoint.z - startPoint.z)
                
                -- Rotate the point based on direction
                local rotX = x * math.cos(directionRad) - z * math.sin(directionRad)
                local rotZ = x * math.sin(directionRad) + z * math.cos(directionRad)
                
                -- Add to center point for final position
                local finalX = centerX + rotX
                local finalZ = centerZ + rotZ
                local finalY = Spring.GetGroundHeight(finalX, finalZ) or 0
                
                table.insert(unitPositions, {
                    x = finalX,
                    y = finalY,
                    z = finalZ
                })
            end
        end
    end
    
    -- Make sure we have the right number of positions
    if #unitPositions < count then
        -- If we don't have enough positions, add more at the center
        for i = #unitPositions + 1, count do
            table.insert(unitPositions, {
                x = centerX,
                y = Spring.GetGroundHeight(centerX, centerZ) or 0,
                z = centerZ
            })
        end
    elseif #unitPositions > count then
        -- If we have too many positions, trim the extras
        while #unitPositions > count do
            table.remove(unitPositions)
        end
    end
    
    -- Method 1: Direct command to each unit
    for i, unitID in ipairs(selectedUnits) do
        -- Get the position for this unit
        local pos = unitPositions[i]
        if not pos then
            Echo("Error: Missing position for unit " .. i)
            break
        end
        
        Echo("Moving unit ID " .. unitID .. " to position " .. pos.x .. "," .. pos.z)
        
        -- First stop the unit to clear previous orders
        pcall(function()
            Spring.GiveOrderToUnit(unitID, CMD_STOP, {}, {})
        end)
        
        -- Then issue the move command
        pcall(function()
            Spring.GiveOrderToUnit(unitID, CMD_MOVE, {pos.x, pos.y, pos.z}, {})
        end)
    end
    
    -- Method 2: Send a formation command for all units at once
    -- Only as a backup in case the individual commands don't work
    pcall(function()
        -- First stop all units to clear previous orders
        local cmdParams = {}
        Spring.GiveOrderToUnitArray(selectedUnits, CMD_STOP, cmdParams, {})
        
        -- For each unit, add a move command to its position
        for i, unitID in ipairs(selectedUnits) do
            -- Get the position for this unit
            local pos = unitPositions[i]
            if not pos then
                Echo("Error: Missing position for unit " .. i)
                break
            end
            
            cmdParams = {pos.x, pos.y, pos.z}
            Spring.GiveOrderToUnit(unitID, CMD_MOVE, cmdParams, {})
        end
    end)
    
    -- Reset state
    hasValidTarget = false
    deactivateWFormation()
end

-- Prepare diamond formation and add pending commands to be executed over time
local function executeDiamondFormation()
    if not hasValidTarget then
        Echo("No valid target position")
        return
    end
    
    -- Validate target position
    if not safeClickX or not safeClickZ then
        Echo("Diamond Formation: Invalid target coordinates")
        hasValidTarget = false
        deactivateDiamondFormation()
        return
    end
    
    -- Get the selected units
    local selectedUnits = Spring.GetSelectedUnits() or {}
    
    local count = #selectedUnits
    
    if count == 0 then
        Echo("No units selected for diamond formation")
        deactivateDiamondFormation()
        return
    end
    
    -- Target position (where the diamond point will be)
    local topX = safeClickX
    local topZ = safeClickZ
    local topY = Spring.GetGroundHeight(topX, topZ)
    
    -- Handle possible nil value
    if not topY then
        Echo("Diamond Formation: Could not get ground height at target position, using default")
        topY = 0
    end
    
    -- Store final target for all units
    diamondFinalTarget = {x = topX, y = topY, z = topZ}
    
    -- Get current unit positions to calculate the starting point (center of unit group)
    local unitPositions = {}
    local avgX, avgZ = 0, 0
    local validPosCount = 0
    
    for _, unitID in ipairs(selectedUnits) do
        if Spring.ValidUnitID(unitID) then
            local x, y, z = Spring.GetUnitPosition(unitID)
            if x and z then
                unitPositions[unitID] = {x = x, y = y, z = z}
                avgX = avgX + x
                avgZ = avgZ + z
                validPosCount = validPosCount + 1
            end
        end
    end
    
    -- If we have valid positions, calculate the average position
    if validPosCount > 0 then
        avgX = avgX / validPosCount
        avgZ = avgZ / validPosCount
    else
        -- Fallback if we can't get unit positions
        avgX = topX
        avgZ = topZ + 300  -- Default to 300 units south of target
        Echo("[DIAMOND FORMATION] Warning: Could not determine unit positions, using fallback")
    end
    
    -- Make the diamond's bottom point be at the current unit position (average)
    local bottomX = avgX
    local bottomZ = avgZ
    local bottomY = Spring.GetGroundHeight(bottomX, bottomZ) or 0
    
    -- Calculate the distance from current position to target
    local distX = topX - bottomX
    local distZ = topZ - bottomZ
    local totalDist = math.sqrt(distX * distX + distZ * distZ)
    
    -- If the distance is too small, ensure a minimum distance
    if totalDist < 100 then
        -- Target is too close, adjust to ensure reasonable diamond size
        Echo("[DIAMOND FORMATION] Target is very close to units, adjusting formation size")
        totalDist = 450  -- Minimum diamond length
        
        -- Use the direction from units to target, but extend it
        local dirX, dirZ = 0, -1  -- Default north direction
        if distX ~= 0 or distZ ~= 0 then
            dirX = distX / math.sqrt(distX * distX + distZ * distZ)
            dirZ = distZ / math.sqrt(distX * distX + distZ * distZ)
        end
        
        -- Recalculate top point based on this minimum distance
        topX = bottomX + dirX * totalDist
        topZ = bottomZ + dirZ * totalDist
        topY = Spring.GetGroundHeight(topX, topZ) or 0
    end
    
    -- Calculate diamond width based on distance (wider for longer distances)
    -- Increased width factor from 0.8 to 1.2 to make flanks wider
    local diamondWidth = math.min(totalDist * 1.2, 600)  -- Width scales with length, max 600 (up from 400)
    
    -- Calculate direction vector from bottom to top FIRST
    local pathX = topX - bottomX
    local pathZ = topZ - bottomZ
    
    -- Calculate the flank point positions - move them closer to the target
    -- Instead of midpoint (0.5), use 0.65 to place flanks 65% of the way from start to target
    local flankRatio = 0.65  -- Higher value puts flanks closer to target (was 0.5 for midpoint)
    
    -- Safety check to prevent null values
    if not bottomX or not bottomZ or not pathX or not pathZ then
        Echo("[DIAMOND FORMATION] ERROR: Missing position data for flank calculation")
        Echo("[DIAMOND FORMATION] Bottom: " .. tostring(bottomX) .. ", " .. tostring(bottomZ))
        Echo("[DIAMOND FORMATION] Path: " .. tostring(pathX) .. ", " .. tostring(pathZ))
        
        -- Use default values if we have missing data
        bottomX = bottomX or 0
        bottomZ = bottomZ or 0
        pathX = pathX or 0
        pathZ = pathZ or -1  -- Default north direction
    end
    
    local flankX = bottomX + pathX * flankRatio
    local flankZ = bottomZ + pathZ * flankRatio
    
    -- Normalize the path vector
    local pathLength = math.sqrt(pathX * pathX + pathZ * pathZ)
    if pathLength > 0 then
        pathX = pathX / pathLength
        pathZ = pathZ / pathLength
    else
        pathX, pathZ = 0, -1  -- Default north direction
    end
    
    -- Calculate perpendicular vector to the path (for flank points) with safety check
    local perpX, perpZ
    if pathX and pathZ then
        perpX = -pathZ  -- Perpendicular is (-z, x)
        perpZ = pathX
    else
        -- Use default values if path vector is invalid
        Echo("[DIAMOND FORMATION] ERROR: Invalid path vector for perpendicular calculation")
        perpX, perpZ = 1, 0  -- Default perpendicular (east)
    end
    
    -- Safety check for flank coordinates
    if not flankX or not flankZ then
        Echo("[DIAMOND FORMATION] ERROR: Invalid flank coordinates")
        flankX = bottomX or 0
        flankZ = bottomZ or 0
    end
    
    -- Safety check for perpendicular vector and diamond width
    if not perpX or not perpZ or not diamondWidth then
        Echo("[DIAMOND FORMATION] ERROR: Invalid perpendicular vector or width")
        perpX = perpX or 1
        perpZ = perpZ or 0
        diamondWidth = diamondWidth or 400
    end
    
    -- Left and right flanking points, placed at the calculated flank position
    local leftX = flankX + perpX * diamondWidth/2
    local leftZ = flankZ + perpZ * diamondWidth/2
    local leftY = Spring.GetGroundHeight(leftX, leftZ) or 0
    
    local rightX = flankX - perpX * diamondWidth/2
    local rightZ = flankZ - perpZ * diamondWidth/2
    local rightY = Spring.GetGroundHeight(rightX, rightZ) or 0
    
    Echo("[DIAMOND FORMATION] Path details:")
    Echo(string.format("  - Bottom (start): (%.1f, %.1f)", bottomX, bottomZ))
    Echo(string.format("  - Left flank: (%.1f, %.1f)", leftX, leftZ))
    Echo(string.format("  - Right flank: (%.1f, %.1f)", rightX, rightZ))
    Echo(string.format("  - Top (target): (%.1f, %.1f)", topX, topZ))
    Echo(string.format("  - Path length: %.1f, Width: %.1f", pathLength, diamondWidth))
    
    -- Split units into left and right groups
    local leftGroup = {}
    local rightGroup = {}
    
    for i, unitID in ipairs(selectedUnits) do
        if i % 2 == 1 then  -- Odd units go to left group
            table.insert(leftGroup, unitID)
        else  -- Even units go to right group
            table.insert(rightGroup, unitID)
        end
    end
    
    -- Clear any old pending commands
    diamondPendingCommands = {}
    
    -- STEP 1: First, we'll stop all units to clear their command queues
    local currentFrame = Spring.GetGameFrame()
    
    for _, unitID in ipairs(selectedUnits) do
        if Spring.ValidUnitID(unitID) then
            -- Add a stop command to be executed immediately
            table.insert(diamondPendingCommands, {
                frame = currentFrame,
                unitID = unitID,
                cmdID = CMD_STOP,
                params = {},
                options = 0,
                description = "Stop to clear queue"
            })
        end
    end
    
    -- STEP 2: After a brief delay, send each unit to its flank point
    -- We'll use a delay of 15 frames to ensure stop commands have been processed
    local flankFrame = currentFrame + 15
    
    -- Left group - send to left flank with offsets
    for i, unitID in ipairs(leftGroup) do
        if Spring.ValidUnitID(unitID) then
            -- Get current unit position
            local ux, uy, uz = Spring.GetUnitPosition(unitID)
            
            -- Calculate slight offsets to prevent stacking
            local offsetX = 0
            local offsetZ = 0
            
            if i > 1 then
                local row = math.floor((i-1) / 4)
                local col = (i-1) % 4
                offsetX = (col - 1.5) * 20
                offsetZ = row * 20
            end
            
            -- Calculate a unique position at the flank point to prevent stacking
            local flankX = leftX + offsetX
            local flankZ = leftZ + offsetZ
            local flankY = Spring.GetGroundHeight(flankX, flankZ) or leftY
            
            -- Report displacement for debugging
            if ux and uz then
                local moveDistX = flankX - ux
                local moveDistZ = flankZ - uz
                local moveDist = math.sqrt(moveDistX * moveDistX + moveDistZ * moveDistZ)
                Echo(string.format("[DIAMOND] Unit %d will move %.1f units to left flank", unitID, moveDist))
            end
            
            -- Add move to flank command
            table.insert(diamondPendingCommands, {
                frame = flankFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {flankX, flankY, flankZ},
                options = 0,  -- Start fresh queue
                description = "Move to left flank",
                isFlankPoint = true
            })
        end
    end
    
    -- Right group - send to right flank with offsets
    for i, unitID in ipairs(rightGroup) do
        if Spring.ValidUnitID(unitID) then
            -- Get current unit position
            local ux, uy, uz = Spring.GetUnitPosition(unitID)
            
            -- Calculate slight offsets to prevent stacking
            local offsetX = 0
            local offsetZ = 0
            
            if i > 1 then
                local row = math.floor((i-1) / 4)
                local col = (i-1) % 4
                offsetX = (col - 1.5) * 20
                offsetZ = row * 20
            end
            
            -- Calculate a unique position at the flank point to prevent stacking
            local flankX = rightX + offsetX
            local flankZ = rightZ + offsetZ
            local flankY = Spring.GetGroundHeight(flankX, flankZ) or rightY
            
            -- Report displacement for debugging
            if ux and uz then
                local moveDistX = flankX - ux
                local moveDistZ = flankZ - uz
                local moveDist = math.sqrt(moveDistX * moveDistX + moveDistZ * moveDistZ)
                Echo(string.format("[DIAMOND] Unit %d will move %.1f units to right flank", unitID, moveDist))
            end
            
            -- Add move to flank command
            table.insert(diamondPendingCommands, {
                frame = flankFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {flankX, flankY, flankZ},
                options = 0,  -- Start fresh queue
                description = "Move to right flank",
                isFlankPoint = true
            })
        end
    end
    
    -- STEP 3: Complete redesign of the command sequence
    -- Instead of a fixed delay with shift queuing, we'll use a two-phase approach
    
    -- Phase 1: Move to flanks (executed immediately)
    -- Phase 2: Move to target (separate commands)
    
    -- Track unit positions and waypoints for phase 2
    local unitWaypoints = {}
    
    -- First, issue ONLY the flank movement commands
    Echo("[DIAMOND FORMATION] PHASE 1: Issuing flank movement commands")
    
    -- Process left group to move to left flank
    Echo("[DIAMOND FORMATION] Sending left group to left flank point")
    for i, unitID in ipairs(leftGroup) do
        if Spring.ValidUnitID(unitID) then
            -- Get current position for debugging
            local ux, uy, uz = Spring.GetUnitPosition(unitID)
            
            -- Calculate slight offsets to prevent stacking
            local offsetX = 0
            local offsetZ = 0
            if i > 1 then
                local row = math.floor((i-1) / 4)
                local col = (i-1) % 4
                offsetX = (col - 1.5) * 20
                offsetZ = row * 20
            end
            
            -- Calculate flank position with offset
            local flankX = leftX + offsetX
            local flankZ = leftZ + offsetZ
            local flankY = Spring.GetGroundHeight(flankX, flankZ) or leftY
            
            -- Calculate target position with smaller offset
            local targetX = topX + offsetX/4
            local targetZ = topZ + offsetZ/4
            local targetY = Spring.GetGroundHeight(targetX, targetZ) or topY
            
            -- Report movement info
            if ux and uz then
                local distX = flankX - ux
                local distZ = flankZ - uz
                local distance = math.sqrt(distX * distX + distZ * distZ)
                Echo(string.format("[DIAMOND FORMATION] Unit %d moving %.1f units to left flank", unitID, distance))
            end
            
            -- Clear queue with stop command first
            table.insert(diamondPendingCommands, {
                frame = flankFrame - 10, -- Execute a bit before the move command
                unitID = unitID,
                cmdID = CMD_STOP,
                params = {},
                options = 0,
                description = "Clear command queue",
                isStopCommand = true
            })
            
            -- Add flank move command (executed immediately)
            table.insert(diamondPendingCommands, {
                frame = flankFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {flankX, flankY, flankZ},
                options = 0, -- Fresh queue
                description = "Move to left flank",
                isFlankPoint = true
            })
            
            -- Store target waypoint for phase 2
            unitWaypoints[unitID] = {
                targetX = targetX,
                targetY = targetY,
                targetZ = targetZ,
                flankX = flankX,
                flankY = flankY,
                flankZ = flankZ
            }
        end
    end
    
    -- Process right group to move to right flank
    Echo("[DIAMOND FORMATION] Sending right group to right flank point")
    for i, unitID in ipairs(rightGroup) do
        if Spring.ValidUnitID(unitID) then
            -- Get current position for debugging
            local ux, uy, uz = Spring.GetUnitPosition(unitID)
            
            -- Calculate slight offsets to prevent stacking
            local offsetX = 0
            local offsetZ = 0
            if i > 1 then
                local row = math.floor((i-1) / 4)
                local col = (i-1) % 4
                offsetX = (col - 1.5) * 20
                offsetZ = row * 20
            end
            
            -- Calculate flank position with offset
            local flankX = rightX + offsetX
            local flankZ = rightZ + offsetZ
            local flankY = Spring.GetGroundHeight(flankX, flankZ) or rightY
            
            -- Calculate target position with smaller offset
            local targetX = topX + offsetX/4
            local targetZ = topZ + offsetZ/4
            local targetY = Spring.GetGroundHeight(targetX, targetZ) or topY
            
            -- Report movement info
            if ux and uz then
                local distX = flankX - ux
                local distZ = flankZ - uz
                local distance = math.sqrt(distX * distX + distZ * distZ)
                Echo(string.format("[DIAMOND FORMATION] Unit %d moving %.1f units to right flank", unitID, distance))
            end
            
            -- Clear queue with stop command first
            table.insert(diamondPendingCommands, {
                frame = flankFrame - 10, -- Execute a bit before the move command
                unitID = unitID,
                cmdID = CMD_STOP,
                params = {},
                options = 0,
                description = "Clear command queue",
                isStopCommand = true
            })
            
            -- Add flank move command (executed immediately)
            table.insert(diamondPendingCommands, {
                frame = flankFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {flankX, flankY, flankZ},
                options = 0, -- Fresh queue
                description = "Move to right flank",
                isFlankPoint = true
            })
            
            -- Store target waypoint for phase 2
            unitWaypoints[unitID] = {
                targetX = targetX,
                targetY = targetY,
                targetZ = targetZ,
                flankX = flankX,
                flankY = flankY,
                flankZ = flankZ
            }
        end
    end
    
    -- PHASE 2: Simply schedule direct move commands after a fixed delay
    Echo("[DIAMOND FORMATION] PHASE 2: Setting up direct convergence commands")
    
    -- Calculate time needed for units to reach flanks
    -- Use a fixed time of 4 seconds (120 frames) for simplicity
    local timeToFlanks = 120
    
    -- Schedule convergence commands to execute after timeToFlanks
    local convergeFrame = flankFrame + timeToFlanks
    
    Echo("[DIAMOND FORMATION] Scheduling convergence for frame " .. convergeFrame)
    
    -- Process left group for convergence
    for i, unitID in ipairs(leftGroup) do
        if Spring.ValidUnitID(unitID) then
            -- Small offset at target to prevent perfect stacking
            local offsetX = ((i % 8) - 3.5) * 15
            local offsetZ = math.floor(i / 8) * 15
            
            -- Add direct convergence command after delay
            table.insert(diamondPendingCommands, {
                frame = convergeFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {topX + offsetX, topY, topZ + offsetZ},
                options = 0, -- Fresh command (no SHIFT)
                description = "Converge on target from left flank",
                isConvergeCommand = true
            })
        end
    end
    
    -- Process right group for convergence
    for i, unitID in ipairs(rightGroup) do
        if Spring.ValidUnitID(unitID) then
            -- Small offset at target to prevent perfect stacking
            local offsetX = ((i % 8) - 3.5) * 15
            local offsetZ = math.floor(i / 8) * 15
            
            -- Add direct convergence command after delay
            table.insert(diamondPendingCommands, {
                frame = convergeFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {topX + offsetX, topY, topZ + offsetZ},
                options = 0, -- Fresh command (no SHIFT)
                description = "Converge on target from right flank",
                isConvergeCommand = true
            })
        end
    end
    
    Echo(string.format("[DIAMOND FORMATION] Scheduled %d direct convergence commands", 
        #leftGroup + #rightGroup))
    Echo(string.format("[DIAMOND FORMATION] Convergence will happen %.1f seconds after flanking movement", 
        timeToFlanks/30))
    
    -- NOTE: We no longer add the convergence commands here
    for i, unitID in ipairs(selectedUnits) do
        if Spring.ValidUnitID(unitID) then
            -- Small offsets at target to prevent perfect stacking
            local offsetX = ((i % 8) - 3.5) * 15
            local offsetZ = math.floor(i / 8) * 15
            
            -- Add converge command - CRITICAL: Use CMD_OPT_SHIFT to queue after flank movement
            table.insert(diamondPendingCommands, {
                frame = convergeFrame,
                unitID = unitID,
                cmdID = CMD_MOVE,
                params = {topX + offsetX, topY, topZ + offsetZ},
                options = CMD_OPT_SHIFT,  -- IMPORTANT: Use shift flag to queue AFTER flank movement
                description = "Converge on target",
                isTargetPoint = true
            })
        end
    end
    
    -- Print out a diagnostic summary
    Echo("[DIAMOND FORMATION] Created " .. #diamondPendingCommands .. " staged commands")
    Echo("[DIAMOND FORMATION] Units will first move to flank positions")
    Echo("  - Left flank: " .. #leftGroup .. " units to position " .. string.format("%.1f, %.1f", leftX, leftZ))
    Echo("  - Right flank: " .. #rightGroup .. " units to position " .. string.format("%.1f, %.1f", rightX, rightZ))
    Echo("[DIAMOND FORMATION] Then units will CONVERGE on target: " .. string.format("%.1f, %.1f", topX, topZ))
    Echo("[DIAMOND FORMATION] NEW SYSTEM: Units will FIRST reach flanks, THEN receive commands to move to the target")
    Echo("[DIAMOND FORMATION] A checkpoint will be triggered after " .. math.floor(timeToFlanks/30) .. " seconds to detect units at flanks")
    Echo("[DIAMOND FORMATION] Execution will be sequenced across multiple frames for reliability")
    
    -- Reset target flag but keep diamondFormationActive true so we can process commands
    hasValidTarget = false
end

-- Execute a cheat command
local function executeCommand(command)
    if command == "cheat" then
        -- Toggle cheat mode
        cheatEnabled = not cheatEnabled
        SendCommands("cheat " .. (cheatEnabled and "1" or "0"))
        Echo("Cheat mode: " .. (cheatEnabled and "ON" or "OFF"))
        
        -- If we're disabling cheats, all other cheat states should be reset
        if not cheatEnabled then
            nocostEnabled = false
            godmodeEnabled = false
            nofogEnabled = false
            Echo("All cheat states reset due to disabling cheat mode")
        end
    elseif command == "nocost" then
        -- Ensure cheats are enabled first
        if not cheatEnabled then
            cheatEnabled = true
            SendCommands("cheat 1")
            Echo("Cheat mode enabled for nocost")
        end
        
        -- Toggle nocost
        nocostEnabled = not nocostEnabled
        SendCommands("nocost")
        Echo("No cost: " .. (nocostEnabled and "ON" or "OFF"))
    elseif command == "godmode" then
        -- Ensure cheats are enabled first
        if not cheatEnabled then
            cheatEnabled = true
            SendCommands("cheat 1")
            Echo("Cheat mode enabled for godmode")
        end
        
        -- Toggle godmode
        godmodeEnabled = not godmodeEnabled
        SendCommands("godmode")
        Echo("God mode: " .. (godmodeEnabled and "ON" or "OFF"))
    elseif command == "nofog" then
        -- Ensure cheats are enabled first
        if not cheatEnabled then
            cheatEnabled = true
            SendCommands("cheat 1")
            Echo("Cheat mode enabled for nofog")
        end
        
        -- Toggle nofog
        nofogEnabled = not nofogEnabled
        SendCommands("nofog")
        Echo("No fog: " .. (nofogEnabled and "ON" or "OFF"))
    elseif command == "spawn_comm" then
        if spawnModeActive then
            deactivateSpawnMode()
        else
            activateSpawnMode(debugSpawnUnit)
        end
    elseif command == "spawn_acv" then
        if spawnModeActive then
            deactivateSpawnMode()
        else
            activateSpawnMode(secondSpawnUnit)
        end
    elseif command == "circle_formation" then
        if circleModeActive then
            deactivateCircleMode()
        else
            activateCircleMode()
        end
    elseif command == "pizza_formation" then
        if pizzaModeActive then
            deactivatePizzaMode()
        else
            activatePizzaMode()
        end
    elseif command == "w_formation" then
        if wFormationActive then
            deactivateWFormation()
        else
            activateWFormation()
        end
    elseif command == "diamond_formation" then
        if diamondFormationActive then
            deactivateDiamondFormation()
        else
            activateDiamondFormation()
        end
    end
end

-- Calculate exact button positions
local buttonPositions = {}

-- Update button positions
local function updateButtonPositions()
    buttonPositions = {}
    
    for i = 1, 10 do  -- Increased to 10 buttons to include diamond formation
        local buttonY
        if i == 1 then
            buttonY = menuY - buttonPadding - buttonHeight
        else
            -- For buttons 2-10, calculate position with correct spacing
            buttonY = menuY - buttonPadding - i * (buttonHeight + buttonSpacing) + (i-1) * buttonSpacing
        end
        
        buttonPositions[i] = {
            x1 = menuX + buttonPadding,
            y1 = buttonY - buttonHeight,
            x2 = menuX + menuWidth - buttonPadding,
            y2 = buttonY
        }
    end
end

-- Check if mouse is over a button
local function isMouseOverButton(index)
    local mx, my = GetMouseState()
    
    -- Make sure button positions are initialized
    if #buttonPositions == 0 then
        updateButtonPositions()
    end
    
    -- Get button position from cache
    local button = buttonPositions[index]
    if not button then return false end
    
    -- Simple bounds check
    return mx >= button.x1 and 
           mx <= button.x2 and
           my >= button.y1 and
           my <= button.y2
end

-- Draw screen elements
function widget:DrawScreen()
    -- Update screen dimensions occasionally
    local vsx, vsy = GetViewGeometry()
    if vsx and vsy and vsx > 0 and vsy > 0 then
        screenWidth = vsx
        screenHeight = vsy
    end
    
    -- Calculate menu position (top right)
    menuX = screenWidth - menuWidth - 10
    menuY = screenHeight - 10
    
    -- Update button positions whenever the menu moves
    updateButtonPositions()
    
    -- Only draw if menu is visible
    if not menuVisible then return end
    
    -- Draw menu background (increase height for extra button)
    gl.Color(0.1, 0.1, 0.2, 0.85)
    gl.Rect(menuX, menuY - 10 * (buttonHeight + buttonSpacing) - 2 * buttonPadding, 
            menuX + menuWidth, menuY)
    
    -- Draw menu border
    gl.Color(0.4, 0.4, 0.8, 0.9)
    gl.LineWidth(1.0)
    gl.Rect(menuX, menuY - 10 * (buttonHeight + buttonSpacing) - 2 * buttonPadding, 
            menuX + menuWidth, menuY)
    
    -- Draw title
    gl.Color(1, 1, 0, 1)
    gl.Text("Developer Controls", menuX + menuWidth/2, menuY - buttonPadding, 14, "oc")
    
    -- Draw cheat button
    if cheatEnabled then
        gl.Color(0.2, 0.8, 0.2, 0.8)  -- Green when active
    else
        gl.Color(0.8, 0.2, 0.2, 0.8)  -- Red when inactive
    end
    if isMouseOverButton(1) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[1]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    -- Debug: draw button index
    gl.Color(1, 1, 1, 1)
    gl.Text("Cheat: " .. (cheatEnabled and "ON" or "OFF"), 
            (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    
    -- Draw nocost button
    if nocostEnabled then
        gl.Color(0.2, 0.8, 0.2, 0.8)  -- Green when active
    else
        gl.Color(0.8, 0.2, 0.2, 0.8)  -- Red when inactive
    end
    if isMouseOverButton(2) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[2]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    gl.Text("No Cost: " .. (nocostEnabled and "ON" or "OFF"), 
            (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    
    -- Draw godmode button
    if godmodeEnabled then
        gl.Color(0.2, 0.8, 0.2, 0.8)  -- Green when active
    else
        gl.Color(0.8, 0.2, 0.2, 0.8)  -- Red when inactive
    end
    if isMouseOverButton(3) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[3]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    gl.Text("God Mode: " .. (godmodeEnabled and "ON" or "OFF"), 
            (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    
    -- Draw nofog button
    if nofogEnabled then
        gl.Color(0.2, 0.8, 0.2, 0.8)  -- Green when active
    else
        gl.Color(0.8, 0.2, 0.2, 0.8)  -- Red when inactive
    end
    if isMouseOverButton(4) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[4]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    gl.Text("No Fog: " .. (nofogEnabled and "ON" or "OFF"), 
            (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    
    -- Draw spawn Commander button
    if spawnModeActive and spawnModeUnit == debugSpawnUnit then
        gl.Color(0.9, 0.9, 0.2, 0.9)  -- Yellow in spawn mode
    else
        gl.Color(0.2, 0.6, 0.8, 0.8)  -- Blue normally
    end
    if isMouseOverButton(5) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[5]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    if spawnModeActive and spawnModeUnit == debugSpawnUnit then
        gl.Text("Click Map to Spawn", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    else
        gl.Text("Spawn Level 10 Commander", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    end
    
    -- Draw spawn ACV button
    if spawnModeActive and spawnModeUnit == secondSpawnUnit then
        gl.Color(0.9, 0.9, 0.2, 0.9)  -- Yellow in spawn mode
    else
        gl.Color(0.2, 0.6, 0.8, 0.8)  -- Blue normally
    end
    if isMouseOverButton(6) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[6]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    if spawnModeActive and spawnModeUnit == secondSpawnUnit then
        gl.Text("Click Map to Spawn", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    else
        gl.Text("Spawn Advanced Construction", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    end
    
    -- Draw Circle Formation button
    if circleModeActive then
        gl.Color(0.9, 0.9, 0.2, 0.9)  -- Yellow in circle mode
    else
        gl.Color(0.2, 0.8, 0.4, 0.8)  -- Green normally
    end
    if isMouseOverButton(7) then
        gl.Color(0.4, 0.9, 0.4, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[7]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    if circleModeActive then
        gl.Text("Click Map for Circle Center", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    else
        gl.Text("Place Selected Units in Circle", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    end
    
    -- Draw Pizza Formation button
    if pizzaModeActive then
        gl.Color(0.9, 0.5, 0.2, 0.9)  -- Orange in pizza mode
    else
        gl.Color(1.0, 0.6, 0.2, 0.8)  -- Light orange normally
    end
    if isMouseOverButton(8) then
        gl.Color(1.0, 0.7, 0.3, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[8]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    if pizzaModeActive then
        gl.Text("Click Map for Pizza Tip", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    else
        gl.Text("Place Selected Units in Pizza", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    end
    
    -- Draw W Formation button
    if wFormationActive then
        gl.Color(0.2, 0.5, 1.0, 0.9)  -- Blue in W mode
    else
        gl.Color(0.3, 0.6, 1.0, 0.8)  -- Light blue normally
    end
    if isMouseOverButton(9) then
        gl.Color(0.4, 0.7, 1.0, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[9]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    if wFormationActive then
        gl.Text("Click Map for W Formation", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    else
        gl.Text("Place Selected Units in W", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    end
    
    -- Draw Diamond Formation button
    if diamondFormationActive then
        gl.Color(0.5, 0.0, 1.0, 0.9)  -- Purple in diamond mode
    else
        gl.Color(0.7, 0.3, 1.0, 0.8)  -- Light purple normally
    end
    if isMouseOverButton(10) then
        gl.Color(0.8, 0.4, 1.0, 0.9)  -- Highlight on hover
    end
    
    -- Get button position from cache
    local button = buttonPositions[10]
    gl.Rect(button.x1, button.y1, button.x2, button.y2)
    
    gl.Color(1, 1, 1, 1)
    if diamondFormationActive then
        gl.Text("Click for Flanking Diamond Attack", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    else
        gl.Text("Flanking Diamond Attack Formation", (button.x1 + button.x2)/2, (button.y1 + button.y2)/2, 12, "oc")
    end
    
    -- Diamond formation visualization is now in DrawWorld function
    
    -- Draw crosshair in spawn/circle/pizza/w/diamond mode
    if spawnModeActive or circleModeActive or pizzaModeActive or wFormationActive or diamondFormationActive then
        local mx, my = GetMouseState()
        gl.Color(1, 1, 0, 0.8)
        gl.LineWidth(1.0)
        
        -- Simple crosshair
        gl.BeginEnd(GL.LINES, function()
            gl.Vertex(mx - 10, my)
            gl.Vertex(mx + 10, my)
            gl.Vertex(mx, my - 10)
            gl.Vertex(mx, my + 10)
        end)
    end
end

-- Draw indicators in world
function widget:DrawWorld()
    -- Common variables
    local mx, my = GetMouseState()
    local _, pos = TraceScreenRay(mx, my, true)
    
    -- Draw indicators only if we have a valid position
    if not pos then return end
    
    -- Draw spawn indicator
    if spawnModeActive then
        gl.LineWidth(2.0)
        gl.Color(1.0, 1.0, 0.0, 0.7)
        
        -- Draw a circle on the ground
        gl.BeginEnd(GL.LINE_LOOP, function()
            for i = 1, 16 do
                local angle = i * 2 * math.pi / 16
                local px = pos[1] + 20 * math.cos(angle)
                local pz = pos[3] + 20 * math.sin(angle)
                local py = Spring.GetGroundHeight(px, pz) or 0
                gl.Vertex(px, py, pz)
            end
        end)
    end
    
    -- Draw circle formation indicator
    if circleModeActive then
        gl.LineWidth(2.0)
        gl.Color(0.2, 1.0, 0.2, 0.7)
        
        -- Draw the circle that units will form
        gl.BeginEnd(GL.LINE_LOOP, function()
            for i = 1, 32 do
                local angle = i * 2 * math.pi / 32
                local px = pos[1] + circleRadius * math.cos(angle)
                local pz = pos[3] + circleRadius * math.sin(angle)
                local py = Spring.GetGroundHeight(px, pz) or 0
                gl.Vertex(px, py, pz)
            end
        end)
        
        -- Draw dots for each unit position
        local count = #selectedUnits
        if count > 0 then
            gl.PointSize(5.0)
            gl.BeginEnd(GL.POINTS, function()
                for i = 1, count do
                    local angle = (i - 1) * (2 * math.pi / count)
                    local px = pos[1] + circleRadius * math.cos(angle)
                    local pz = pos[3] + circleRadius * math.sin(angle)
                    local py = Spring.GetGroundHeight(px, pz) or 0
                    gl.Vertex(px, py, pz)
                end
            end)
        end
    end
    
    -- Draw pizza formation indicator
    if pizzaModeActive then
        gl.LineWidth(2.0)
        gl.Color(1.0, 0.5, 0.0, 0.7)  -- Orange for pizza
        
        -- Convert angles from degrees to radians
        local pizzaAngleRad = math.rad(pizzaAngle)
        local directionRad = math.rad(pizzaDirection)
        
        -- Calculate start angle and end angle based on direction
        local startAngle = directionRad - (pizzaAngleRad / 2)
        local endAngle = directionRad + (pizzaAngleRad / 2)
        
        -- Draw the pizza wedge outline
        gl.BeginEnd(GL.LINE_STRIP, function()
            -- Start at center point
            gl.Vertex(pos[1], pos[2], pos[3])
            
            -- Draw the arc
            for i = 0, 20 do
                local angle = startAngle + (i / 20) * pizzaAngleRad
                local px = pos[1] + pizzaRadius * math.cos(angle)
                local pz = pos[3] + pizzaRadius * math.sin(angle)
                local py = Spring.GetGroundHeight(px, pz) or 0
                gl.Vertex(px, py, pz)
            end
            
            -- Return to center to complete the wedge
            gl.Vertex(pos[1], pos[2], pos[3])
        end)
        
        -- Draw filled pizza slice if enabled
        if pizzaFillSides then
            gl.Color(1.0, 0.5, 0.0, 0.3)  -- Transparent orange fill
            
            -- Draw the pizza wedge as a filled polygon
            gl.BeginEnd(GL.TRIANGLE_FAN, function()
                -- Start at center point
                gl.Vertex(pos[1], pos[2], pos[3])
                
                -- Draw the arc
                for i = 0, 20 do
                    local angle = startAngle + (i / 20) * pizzaAngleRad
                    local px = pos[1] + pizzaRadius * math.cos(angle)
                    local pz = pos[3] + pizzaRadius * math.sin(angle)
                    local py = Spring.GetGroundHeight(px, pz) or 0
                    gl.Vertex(px, py, pz)
                end
            end)
        end
        
        -- Draw dots for each unit position
        local count = #selectedUnits
        if count > 0 then
            gl.PointSize(5.0)
            gl.Color(1, 1, 0, 0.8)  -- Yellow dots for unit positions
            
            gl.BeginEnd(GL.POINTS, function()
                -- First unit at the tip (center)
                gl.Vertex(pos[1], pos[2], pos[3])
                
                -- Determine how to place the units
                local remainingUnits = count - 1
                
                if pizzaFillSides and remainingUnits > 0 then
                    -- Fill the entire pizza slice with units
                    -- Calculate how many rings we need
                    local unitsPerRing = 0
                    local rings = 0
                    local ringUnits = {}
                    local maxUnitsOnOuterRing = math.max(2, math.floor(pizzaAngleRad * 3))
                    
                    -- Distribute units across multiple rings
                    local remainingToPlace = remainingUnits
                    local ringRadius = pizzaRadius
                    local minRadius = pizzaRadius * 0.2  -- Start at 20% of max radius
                    local ringSpacing = (pizzaRadius - minRadius) / 5  -- Space between rings
                    
                    -- Place units along multiple rings
                    for ring = 1, 5 do
                        ringRadius = pizzaRadius - ((ring - 1) * ringSpacing)
                        local unitsInThisRing = math.min(remainingToPlace, math.max(2, math.ceil(maxUnitsOnOuterRing * (ringRadius / pizzaRadius))))
                        
                        if unitsInThisRing <= 0 or ringRadius < minRadius then break end
                        
                        local ringAngleStep = pizzaAngleRad / (unitsInThisRing - 1)
                        
                        -- Place units along this ring
                        for i = 0, unitsInThisRing - 1 do
                            local angle = startAngle + i * ringAngleStep
                            local px = pos[1] + ringRadius * math.cos(angle)
                            local pz = pos[3] + ringRadius * math.sin(angle)
                            local py = Spring.GetGroundHeight(px, pz) or 0
                            gl.Vertex(px, py, pz)
                        end
                        
                        remainingToPlace = remainingToPlace - unitsInThisRing
                        if remainingToPlace <= 0 then break end
                    end
                else
                    -- Just place units along the outer arc
                    local angleStep = pizzaAngleRad / (count - 1)
                    if count <= 1 then
                        angleStep = 0
                    end
                    
                    for i = 1, remainingUnits do
                        local angle = startAngle + (i - 1) * angleStep
                        local px = pos[1] + pizzaRadius * math.cos(angle)
                        local pz = pos[3] + pizzaRadius * math.sin(angle)
                        local py = Spring.GetGroundHeight(px, pz) or 0
                        gl.Vertex(px, py, pz)
                    end
                end
            end)
        end
        
        -- Draw direction indicator
        gl.Color(0.0, 1.0, 1.0, 0.8)  -- Cyan for direction
        gl.LineWidth(2.0)
        gl.BeginEnd(GL.LINES, function()
            -- Draw a line from center in the direction of the pizza
            local dirX = pos[1] + pizzaRadius * 0.5 * math.cos(directionRad)
            local dirZ = pos[3] + pizzaRadius * 0.5 * math.sin(directionRad)
            local dirY = Spring.GetGroundHeight(dirX, dirZ) or 0
            gl.Vertex(pos[1], pos[2], pos[3])
            gl.Vertex(dirX, dirY, dirZ)
        end)
    end
    
    -- Draw W formation indicator
    if wFormationActive then
        -- Convert direction from degrees to radians
        local directionRad = math.rad(wDirection)
        
        -- Define the base W shape points (unrotated, centered at origin)
        local baseW = {
            {x = -wFormationWidth/2, z = wFormationDepth/2},  -- Top left
            {x = -wFormationWidth/4, z = -wFormationDepth/2}, -- Bottom left middle
            {x = 0, z = wFormationDepth/2},                   -- Top middle
            {x = wFormationWidth/4, z = -wFormationDepth/2},  -- Bottom right middle
            {x = wFormationWidth/2, z = wFormationDepth/2}    -- Top right
        }
        
        -- Draw the W shape outline
        gl.LineWidth(2.0)
        gl.Color(0.2, 0.5, 1.0, 0.8)  -- Blue for W formation
        
        gl.BeginEnd(GL.LINE_STRIP, function()
            for i = 1, 5 do
                local point = baseW[i]
                
                -- Rotate the point based on direction
                local rotX = point.x * math.cos(directionRad) - point.z * math.sin(directionRad)
                local rotZ = point.x * math.sin(directionRad) + point.z * math.cos(directionRad)
                
                -- Add to center point for final position
                local x = pos[1] + rotX
                local z = pos[3] + rotZ
                local y = Spring.GetGroundHeight(x, z) or 0
                
                gl.Vertex(x, y, z)
            end
        end)
        
        -- Draw dots for each unit position based on how many units we have
        local count = #selectedUnits
        if count > 0 then
            gl.PointSize(5.0)
            gl.Color(1, 1, 0, 0.9)  -- Yellow dots for unit positions
            
            gl.BeginEnd(GL.POINTS, function()
                if count <= 5 then
                    -- Just place dots at the key points
                    for i = 1, count do
                        local point = baseW[i]
                        
                        -- Rotate the point based on direction
                        local rotX = point.x * math.cos(directionRad) - point.z * math.sin(directionRad)
                        local rotZ = point.x * math.sin(directionRad) + point.z * math.cos(directionRad)
                        
                        -- Add to center point for final position
                        local x = pos[1] + rotX
                        local z = pos[3] + rotZ
                        local y = Spring.GetGroundHeight(x, z) or 0
                        
                        gl.Vertex(x, y, z)
                    end
                else
                    -- Place dots at all 5 key points
                    for i = 1, 5 do
                        local point = baseW[i]
                        
                        -- Rotate the point based on direction
                        local rotX = point.x * math.cos(directionRad) - point.z * math.sin(directionRad)
                        local rotZ = point.x * math.sin(directionRad) + point.z * math.cos(directionRad)
                        
                        -- Add to center point for final position
                        local x = pos[1] + rotX
                        local z = pos[3] + rotZ
                        local y = Spring.GetGroundHeight(x, z) or 0
                        
                        gl.Vertex(x, y, z)
                    end
                    
                    -- Calculate how many units to place on each segment
                    local segmentCount = 4  -- 4 segments in a W (5 points)
                    local extraUnits = count - 5
                    local unitsPerSegment = math.floor(extraUnits / segmentCount)
                    local remainingUnits = extraUnits % segmentCount
                    
                    -- Distribute remaining units along the four segments
                    for segment = 1, 4 do
                        local startPoint = baseW[segment]
                        local endPoint = baseW[segment+1]
                        local segmentUnits = unitsPerSegment + (segment <= remainingUnits and 1 or 0)
                        
                        for i = 1, segmentUnits do
                            -- Calculate position along the segment (excluding endpoints)
                            local t = i / (segmentUnits + 1)
                            local x = startPoint.x + t * (endPoint.x - startPoint.x)
                            local z = startPoint.z + t * (endPoint.z - startPoint.z)
                            
                            -- Rotate the point based on direction
                            local rotX = x * math.cos(directionRad) - z * math.sin(directionRad)
                            local rotZ = x * math.sin(directionRad) + z * math.cos(directionRad)
                            
                            -- Add to center point for final position
                            local finalX = pos[1] + rotX
                            local finalZ = pos[3] + rotZ
                            local finalY = Spring.GetGroundHeight(finalX, finalZ) or 0
                            
                            gl.Vertex(finalX, finalY, finalZ)
                        end
                    end
                end
            end)
        end
        
        -- Draw direction indicator
        gl.Color(0.0, 1.0, 0.8, 0.8)  -- Turquoise for direction
        gl.LineWidth(2.0)
        gl.BeginEnd(GL.LINES, function()
            -- Draw a line indicating the direction of the W
            local dirX = pos[1] + 40 * math.cos(directionRad)
            local dirZ = pos[3] + 40 * math.sin(directionRad)
            local dirY = Spring.GetGroundHeight(dirX, dirZ) or 0
            gl.Vertex(pos[1], pos[2], pos[3])
            gl.Vertex(dirX, dirY, dirZ)
        end)
    end
    
    -- Draw diamond formation indicator with 3 waypoints
    if diamondFormationActive then
        -- Get mouse position for visualization
        local mx, my = GetMouseState()
        
        -- Skip drawing if mouse position is invalid
        if not mx or not my then 
            return 
        end
        
        -- Safely trace screen ray to get 3D position
        local _, pos = TraceScreenRay(mx, my, true)
        
        -- Skip drawing if position is invalid
        if not pos or not pos[1] or not pos[3] then 
            return 
        end
        
        -- Try to draw at least basic diamond formation shape
        gl.LineWidth(2.0)
        gl.Color(1.0, 0.0, 1.0, 0.8)  -- Bright purple
        
        -- Get where the cursor is pointing - this will be the target
        local topX, topZ = pos[1], pos[3]
        local topY = Spring.GetGroundHeight(topX, topZ) or pos[2] or 0
        
        -- Get the average position of selected units for the bottom point
        local unitsX, unitsZ = 0, 0
        local unitCount = 0
        local selectedUnits = Spring.GetSelectedUnits() or {}
        
        for _, unitID in ipairs(selectedUnits) do
            if Spring.ValidUnitID(unitID) then
                local x, y, z = Spring.GetUnitPosition(unitID)
                if x and z then
                    unitsX = unitsX + x
                    unitsZ = unitsZ + z
                    unitCount = unitCount + 1
                end
            end
        end
        
        -- Calculate average unit position
        local bottomX, bottomZ
        if unitCount > 0 then
            bottomX = unitsX / unitCount
            bottomZ = unitsZ / unitCount
        else
            -- Fallback if no units or can't get positions
            bottomX = topX
            bottomZ = topZ + 450  -- Default 450 units south
        end
        
        local bottomY = Spring.GetGroundHeight(bottomX, bottomZ) or topY
        
        -- Calculate the distance and direction from units to target
        local pathX = topX - bottomX
        local pathZ = topZ - bottomZ
        local pathLength = math.sqrt(pathX * pathX + pathZ * pathZ)
        
        -- Ensure minimum distance
        if pathLength < 100 then
            local tempPathLength = 450
            -- If path is too short, extend in the same direction
            if pathX ~= 0 or pathZ ~= 0 then
                local tempDirX = pathX / math.max(pathLength, 0.001)  -- Avoid division by zero
                local tempDirZ = pathZ / math.max(pathLength, 0.001)
                topX = bottomX + tempDirX * tempPathLength
                topZ = bottomZ + tempDirZ * tempPathLength
                topY = Spring.GetGroundHeight(topX, topZ) or topY
            else
                -- Default north direction if no valid direction
                topX = bottomX
                topZ = bottomZ - tempPathLength
                topY = Spring.GetGroundHeight(topX, topZ) or topY
            end
            -- Recalculate path vector after adjusting top point
            pathX = topX - bottomX
            pathZ = topZ - bottomZ
            pathLength = math.sqrt(pathX * pathX + pathZ * pathZ)
        end
        
        -- Make sure we have normalized direction vectors
        local dirX, dirZ
        if pathLength > 0 then
            dirX = pathX / pathLength
            dirZ = pathZ / pathLength
        else
            dirX, dirZ = 0, -1
        end
        
        -- Check that we have valid values
        if not bottomX or not bottomZ or not dirX or not dirZ or not pathLength then
            -- Log error and use safe defaults
            Echo("[ERROR] Diamond visualization: Missing required values")
            bottomX = bottomX or pos[1] or 0
            bottomZ = bottomZ or pos[3] or 0
            dirX = dirX or 0
            dirZ = dirZ or -1
            pathLength = pathLength or 450
        end
        
        -- Calculate dynamic width based on path length (wider)
        local width = math.min(pathLength * 1.2, 600)  -- Match settings in formation execution
        
        -- Calculate flank points position (closer to target)
        local flankRatio = 0.65  -- Match settings in formation execution
        local flankX = bottomX + dirX * pathLength * flankRatio
        local flankZ = bottomZ + dirZ * pathLength * flankRatio
        
        -- Calculate perpendicular vector with safety check
        local perpX, perpZ
        if dirX and dirZ then
            perpX = -dirZ
            perpZ = dirX
        else
            -- Default perpendicular if direction is invalid
            perpX, perpZ = 1, 0
            Echo("[ERROR] Diamond visualization: Invalid direction for perpendicular calculation")
        end
        
        -- Safety check for flank position
        if not flankX or not flankZ or not perpX or not perpZ or not width then
            Echo("[ERROR] Diamond visualization: Invalid flank or perpendicular values")
            flankX = flankX or pos[1] or 0
            flankZ = flankZ or pos[3] or 0
            perpX = perpX or 1
            perpZ = perpZ or 0
            width = width or 400
        end
        
        -- Left and right flanking points at flank position (closer to target)
        local leftX = flankX + perpX * width/2
        local leftZ = flankZ + perpZ * width/2
        local leftY = Spring.GetGroundHeight(leftX, leftZ) or topY
        
        local rightX = flankX - perpX * width/2
        local rightZ = flankZ - perpZ * width/2
        local rightY = Spring.GetGroundHeight(rightX, rightZ) or topY
        
        -- Make sure all coordinates are valid before drawing
        if topX and topY and topZ and rightX and rightY and rightZ and 
           bottomX and bottomY and bottomZ and leftX and leftY and leftZ then
            -- Draw diamond outline
            gl.LineWidth(3.0)
            gl.Color(1.0, 0.0, 1.0, 0.8)
            gl.BeginEnd(GL.LINE_LOOP, function()
                gl.Vertex(topX, topY + 10, topZ)
                gl.Vertex(rightX, rightY + 10, rightZ)
                gl.Vertex(bottomX, bottomY + 10, bottomZ)
                gl.Vertex(leftX, leftY + 10, leftZ)
            end)
        else
            -- Report error if we can't draw the diamond
            Echo("[ERROR] Diamond visualization: Invalid coordinates for drawing")
        end
        
        -- Draw path lines (only if coordinates are valid)
        if topX and topY and topZ and rightX and rightY and rightZ and 
           bottomX and bottomY and bottomZ and leftX and leftY and leftZ then
            
            gl.LineWidth(2.0)
            
            -- Left path
            gl.Color(0.0, 0.0, 1.0, 0.9)
            gl.BeginEnd(GL.LINE_STRIP, function()
                gl.Vertex(bottomX, bottomY + 15, bottomZ)
                gl.Vertex(leftX, leftY + 15, leftZ)
                gl.Vertex(topX, topY + 15, topZ)
            end)
            
            -- Right path
            gl.Color(0.0, 1.0, 0.0, 0.9)
            gl.BeginEnd(GL.LINE_STRIP, function()
                gl.Vertex(bottomX, bottomY + 15, bottomZ)
                gl.Vertex(rightX, rightY + 15, rightZ)
                gl.Vertex(topX, topY + 15, topZ)
            end)
        end
        
        -- Draw waypoint markers (only if coordinates are valid)
        if topX and topY and topZ and rightX and rightY and rightZ and 
           bottomX and bottomY and bottomZ and leftX and leftY and leftZ then
            
            gl.PointSize(10.0)
            
            -- Bottom point
            gl.Color(1.0, 1.0, 0.0, 1.0)
            gl.BeginEnd(GL.POINTS, function()
                gl.Vertex(bottomX, bottomY + 20, bottomZ)
            end)
            
            -- Left and right flanking points
            gl.Color(1.0, 0.5, 0.0, 1.0)
            gl.BeginEnd(GL.POINTS, function()
                gl.Vertex(leftX, leftY + 20, leftZ)
                gl.Vertex(rightX, rightY + 20, rightZ)
            end)
            
            -- Target point
            gl.Color(1.0, 0.0, 0.0, 1.0)
            gl.BeginEnd(GL.POINTS, function()
                gl.Vertex(topX, topY + 20, topZ)
            end)
            
            -- Draw more visible 3D markers at waypoints
        end
        
        -- Function to draw a 3D marker at a position with error checking
        local function drawWaypointMarker(x, y, z, color, number)
            -- Check for valid inputs
            if not x or not y or not z or not color or not color[1] or not color[2] or not color[3] then
                Echo("[ERROR] Diamond visualization: Invalid marker parameters")
                return
            end
            
            -- Draw a vertical line from ground to marker
            gl.Color(color[1], color[2], color[3], 0.7)
            gl.LineWidth(3.0)
            gl.BeginEnd(GL.LINES, function()
                gl.Vertex(x, y, z)
                gl.Vertex(x, y + 50, z)
            end)
            
            -- Draw a cross marker at the top
            gl.Color(color[1], color[2], color[3], 0.9)
            gl.LineWidth(3.0)
            local size = 15
            gl.BeginEnd(GL.LINES, function()
                -- Horizontal cross
                gl.Vertex(x - size, y + 50, z)
                gl.Vertex(x + size, y + 50, z)
                gl.Vertex(x, y + 50, z - size)
                gl.Vertex(x, y + 50, z + size)
                
                -- Optional: Add a vertical component
                gl.Vertex(x, y + 50 - size, z)
                gl.Vertex(x, y + 50 + size, z)
            end)
            
            -- Draw a circle around the marker
            gl.Color(color[1], color[2], color[3], 0.8)
            gl.LineWidth(2.0)
            gl.BeginEnd(GL.LINE_LOOP, function()
                for i = 1, 20 do
                    local angle = i * 2 * math.pi / 20
                    gl.Vertex(x + math.cos(angle) * size, y + 50, z + math.sin(angle) * size)
                end
            end)
            
            -- Draw filled circle for number 
            gl.Color(0, 0, 0, 0.7)
            gl.BeginEnd(GL.TRIANGLE_FAN, function()
                gl.Vertex(x, y + 50, z)
                for i = 0, 21 do
                    local angle = i * 2 * math.pi / 20
                    gl.Vertex(x + math.cos(angle) * (size/2), y + 50, z + math.sin(angle) * (size/2))
                end
            end)
            
            -- Add a number label (1, 2, 3)
            gl.PushMatrix()
                gl.Translate(x, y + 50, z)
                gl.Billboard()
                gl.Color(1.0, 1.0, 1.0, 1.0)
                -- Render the number centered on the marker
                gl.Text(number, 0, -5, 14, "cn")
            gl.PopMatrix()
        end
        
        -- Only draw markers if we have valid coordinates
        if topX and topY and topZ and rightX and rightY and rightZ and 
           bottomX and bottomY and bottomZ and leftX and leftY and leftZ then
            
            -- Draw the waypoint markers with different colors and numbers
            drawWaypointMarker(bottomX, bottomY, bottomZ, {1.0, 1.0, 0.0}, "1")  -- Yellow for start
            drawWaypointMarker(leftX, leftY, leftZ, {0.0, 0.0, 1.0}, "2L")       -- Blue for left flank
            drawWaypointMarker(rightX, rightY, rightZ, {0.0, 1.0, 0.0}, "2R")    -- Green for right flank
            drawWaypointMarker(topX, topY, topZ, {1.0, 0.0, 0.0}, "3")           -- Red for target
            
            -- Add distance markers to make the path more clear
            gl.PushMatrix()
                gl.Translate(leftX - 40, leftY + 70, leftZ)
                gl.Billboard()
                gl.Color(0.0, 0.0, 1.0, 0.9)
                gl.Text("LEFT FLANK (STAGE 2)", 0, 0, 12, "c")
            gl.PopMatrix()
            
            gl.PushMatrix()
                gl.Translate(rightX + 40, rightY + 70, rightZ)
                gl.Billboard()
                gl.Color(0.0, 1.0, 0.0, 0.9)
                gl.Text("RIGHT FLANK (STAGE 2)", 0, 0, 12, "c")
            gl.PopMatrix()
            
            gl.PushMatrix()
                gl.Translate(topX, topY + 80, topZ)
                gl.Billboard()
                gl.Color(1.0, 0.0, 0.0, 0.9)
                gl.Text("TARGET (STAGE 3)", 0, 0, 14, "c")
            gl.PopMatrix()
            
            -- Add timing indicator
            gl.PushMatrix()
                gl.Translate(topX, topY + 120, topZ)
                gl.Billboard()
                gl.Color(1.0, 1.0, 1.0, 0.9)
                gl.Text("Units move to WIDE flanking points, WAIT FOR ALL UNITS, then converge TOGETHER", 0, 0, 12, "c")
            gl.PopMatrix()
                
            -- Add a starting position indicator
            gl.PushMatrix()
                gl.Translate(bottomX, bottomY + 40, bottomZ)
                gl.Billboard()
                gl.Color(1.0, 1.0, 0.5, 0.9)
                gl.Text("CURRENT UNIT POSITION", 0, 0, 12, "c")
            gl.PopMatrix()
        end
        
        -- Draw unit count indicators for left/right groups (with safety checks)
        if leftX and leftY and leftZ and rightX and rightY and rightZ and #selectedUnits > 0 then
            local unitCountL = math.ceil(#selectedUnits / 2)
            local unitCountR = math.floor(#selectedUnits / 2)
            
            -- Left group count
            gl.PushMatrix()
                gl.Translate(leftX - 30, leftY + 60, leftZ)
                gl.Billboard()
                gl.Color(0.0, 0.0, 1.0, 0.9)
                gl.Text(unitCountL .. " units", 0, 0, 12, "c")
            gl.PopMatrix()
            
            -- Right group count
            gl.PushMatrix()
                gl.Translate(rightX + 30, rightY + 60, rightZ)
                gl.Billboard()
                gl.Color(0.0, 1.0, 0.0, 0.9)
                gl.Text(unitCountR .. " units", 0, 0, 12, "c")
            gl.PopMatrix()
        end
    end
end

-- Key press handler
function widget:KeyPress(key, mods, isRepeat)
    if key == 109 then  -- M key
        menuVisible = not menuVisible
        Echo("Menu " .. (menuVisible and "visible" or "hidden"))
        return true
    elseif key == 27 and (spawnModeActive or pizzaModeActive or wFormationActive or diamondFormationActive) then  -- ESC key
        if spawnModeActive then
            deactivateSpawnMode()
        elseif pizzaModeActive then
            deactivatePizzaMode()
        elseif wFormationActive then
            deactivateWFormation()
        elseif diamondFormationActive then
            deactivateDiamondFormation()
        end
        return true
    -- Rotation keys for pizza formation
    elseif pizzaModeActive and key == 113 then  -- Q key = rotate left
        pizzaDirection = (pizzaDirection - 15) % 360
        Echo("Pizza direction: " .. pizzaDirection .. " degrees")
        return true
    elseif pizzaModeActive and key == 101 then  -- E key = rotate right
        pizzaDirection = (pizzaDirection + 15) % 360
        Echo("Pizza direction: " .. pizzaDirection .. " degrees")
        return true
    -- Toggle pizza fill mode
    elseif pizzaModeActive and key == 102 then  -- F key = toggle fill
        pizzaFillSides = not pizzaFillSides
        Echo("Pizza fill sides: " .. (pizzaFillSides and "ON" or "OFF"))
        return true
    -- Rotation keys for W formation
    elseif wFormationActive and key == 113 then  -- Q key = rotate left
        wDirection = (wDirection - 15) % 360
        Echo("W formation direction: " .. wDirection .. " degrees")
        return true
    elseif wFormationActive and key == 101 then  -- E key = rotate right
        wDirection = (wDirection + 15) % 360
        Echo("W formation direction: " .. wDirection .. " degrees")
        return true
    -- Rotation keys for Diamond formation
    elseif diamondFormationActive and key == 113 then  -- Q key = rotate left
        diamondDirection = (diamondDirection - 15) % 360
        Echo("Diamond formation direction: " .. diamondDirection .. " degrees")
        return true
    elseif diamondFormationActive and key == 101 then  -- E key = rotate right
        diamondDirection = (diamondDirection + 15) % 360
        Echo("Diamond formation direction: " .. diamondDirection .. " degrees")
        return true
    end
    return false
end

-- Mouse press handler
function widget:MousePress(mx, my, button)
    -- Handle left-click in spawn mode
    if spawnModeActive and button == 1 then
        -- Safely trace screen ray
        local _, pos = TraceScreenRay(mx, my, true)
        if pos then
            -- Store target position safely
            safeClickX = pos[1]
            safeClickY = pos[2]
            safeClickZ = pos[3]
            hasValidTarget = true
            
            -- Execute spawn in next frame to avoid crash during click handling
            Echo("Target acquired, spawning unit...")
            return true
        else
            Echo("Cannot spawn: invalid position")
            return false
        end
    end
    
    -- Handle left-click in circle formation mode
    if circleModeActive and button == 1 then
        -- Refresh selected units to make sure we have the latest selection
        local tempUnits = Spring.GetSelectedUnits() or {}
        selectedUnits = {}
        
        -- Copy only valid units
        for i, unitID in ipairs(tempUnits) do
            if unitID and unitID > 0 and ValidUnitID(unitID) then
                table.insert(selectedUnits, unitID)
            end
        end
        
        -- Check if we have units to move
        if #selectedUnits == 0 then
            Echo("No valid units selected for formation. Please select units first.")
            return false
        end
        
        -- Safely trace screen ray
        local _, pos = TraceScreenRay(mx, my, true)
        if pos then
            -- Store target position safely
            safeClickX = pos[1]
            safeClickY = pos[2]
            safeClickZ = pos[3]
            hasValidTarget = true
            
            -- Execute formation in next frame to avoid crash during click handling
            Echo("Target acquired, moving " .. #selectedUnits .. " units into formation...")
            for i, unitID in ipairs(selectedUnits) do
                Echo("Will move unit " .. i .. ": ID " .. unitID)
            end
            return true
        else
            Echo("Cannot place formation: invalid position")
            return false
        end
    end
    
    -- Handle left-click in pizza formation mode
    if pizzaModeActive and button == 1 then
        -- Refresh selected units to make sure we have the latest selection
        local tempUnits = Spring.GetSelectedUnits() or {}
        selectedUnits = {}
        
        -- Copy only valid units
        for i, unitID in ipairs(tempUnits) do
            if unitID and unitID > 0 and ValidUnitID(unitID) then
                table.insert(selectedUnits, unitID)
            end
        end
        
        -- Check if we have units to move
        if #selectedUnits == 0 then
            Echo("No valid units selected for pizza formation. Please select units first.")
            return false
        end
        
        -- Safely trace screen ray
        local _, pos = TraceScreenRay(mx, my, true)
        if pos then
            -- Store target position safely
            safeClickX = pos[1]
            safeClickY = pos[2]
            safeClickZ = pos[3]
            hasValidTarget = true
            
            -- Execute formation in next frame to avoid crash during click handling
            Echo("Target acquired, moving " .. #selectedUnits .. " units into pizza formation...")
            for i, unitID in ipairs(selectedUnits) do
                Echo("Will move unit " .. i .. ": ID " .. unitID)
            end
            return true
        else
            Echo("Cannot place pizza formation: invalid position")
            return false
        end
    end
    
    -- Handle left-click in diamond formation mode
    if diamondFormationActive and button == 1 then
        -- Refresh selected units to make sure we have the latest selection
        local tempUnits = Spring.GetSelectedUnits() or {}
        selectedUnits = {}
        
        -- Copy only valid units
        for i, unitID in ipairs(tempUnits) do
            if unitID and unitID > 0 and Spring.ValidUnitID(unitID) then
                table.insert(selectedUnits, unitID)
            end
        end
        
        -- Check if we have units to move
        if #selectedUnits == 0 then
            Echo("ERROR: No valid units selected for diamond formation. Please select units first.")
            return false
        end
        
        -- Safely trace screen ray
        local mode, pos = TraceScreenRay(mx, my, true)
        if not pos then
            Echo("ERROR: Cannot determine target position. Try clicking on valid terrain.")
            return false
        end
        
        -- Store target position safely
        safeClickX = pos[1]
        safeClickY = pos[2]
        safeClickZ = pos[3]
        hasValidTarget = true
        
        -- Execute formation in next frame to avoid crash during click handling
        Echo("Diamond Formation: Target acquired at " .. math.floor(pos[1]) .. ", " .. math.floor(pos[3]))
        Echo("Diamond Formation: Moving " .. #selectedUnits .. " units in diamond flanking attack")
        Echo("Diamond Formation: NOTICE - Synchronized Flanking Pattern:")
        Echo("  STAGE 1: Units will stop and clear current orders")
        Echo("  STAGE 2: All units will move from CURRENT POSITION to WIDE flanking points")
        Echo("  STAGE 3: Units will WAIT at flank points, then ALL CONVERGE on target TOGETHER")
        Echo("Diamond Formation: Coordinated attack ensures all units arrive at flanks before final assault")
        
        -- This will be processed in the Update function
        return true
    end
    
    -- Handle left-click in W formation mode
    if wFormationActive and button == 1 then
        -- Refresh selected units to make sure we have the latest selection
        local tempUnits = Spring.GetSelectedUnits() or {}
        selectedUnits = {}
        
        -- Copy only valid units
        for i, unitID in ipairs(tempUnits) do
            if unitID and unitID > 0 and ValidUnitID(unitID) then
                table.insert(selectedUnits, unitID)
            end
        end
        
        -- Check if we have units to move
        if #selectedUnits == 0 then
            Echo("No valid units selected for W formation. Please select units first.")
            return false
        end
        
        -- Safely trace screen ray
        local _, pos = TraceScreenRay(mx, my, true)
        if pos then
            -- Store target position safely
            safeClickX = pos[1]
            safeClickY = pos[2]
            safeClickZ = pos[3]
            hasValidTarget = true
            
            -- Execute formation in next frame to avoid crash during click handling
            Echo("Target acquired, moving " .. #selectedUnits .. " units into W formation...")
            Echo("Direction: " .. wDirection .. " degrees")
            for i, unitID in ipairs(selectedUnits) do
                Echo("Will move unit " .. i .. ": ID " .. unitID)
            end
            return true
        else
            Echo("Cannot place W formation: invalid position")
            return false
        end
    end
    
    -- Handle button clicks only if visible and left-click
    if not menuVisible or button ~= 1 then 
        return false 
    end
    
    -- Check each button
    if isMouseOverButton(1) then
        executeCommand("cheat")
        return true
    elseif isMouseOverButton(2) then
        executeCommand("nocost")
        return true
    elseif isMouseOverButton(3) then
        executeCommand("godmode")
        return true
    elseif isMouseOverButton(4) then
        executeCommand("nofog")
        return true
    elseif isMouseOverButton(5) then
        executeCommand("spawn_comm")
        return true
    elseif isMouseOverButton(6) then
        executeCommand("spawn_acv")
        return true
    elseif isMouseOverButton(7) then
        executeCommand("circle_formation")
        return true
    elseif isMouseOverButton(8) then
        executeCommand("pizza_formation")
        return true
    elseif isMouseOverButton(9) then
        executeCommand("w_formation")
        return true
    elseif isMouseOverButton(10) then
        executeCommand("diamond_formation")
        return true
    end
    
    return false
end

-- Frame update handler
function widget:Update()
    -- Update command states occasionally
    if math.random() < 0.01 then  -- ~1% chance per frame
        local wasCheatEnabled = cheatEnabled
        cheatEnabled = IsCheatingEnabled() or false
        
        -- If cheat mode was just disabled, reset all other cheat states
        if wasCheatEnabled and not cheatEnabled then
            nocostEnabled = false
            godmodeEnabled = false
            nofogEnabled = false
        end
    end
    
    -- Execute actions if we have a valid target
    if hasValidTarget then
        if spawnModeActive then
            executeSafeSpawn()
        elseif circleModeActive then
            executeCircleFormation()
        elseif pizzaModeActive then
            executePizzaFormation()
        elseif wFormationActive then
            executeWFormation()
        elseif diamondFormationActive then
            executeDiamondFormation()
        end
    end
    
    -- Process pending diamond formation commands
    if #diamondPendingCommands > 0 then
        local currentFrame = Spring.GetGameFrame()
        local commandsToExecute = {}
        local remainingCommands = {}
        
        -- Separate commands that should be executed now from those to keep for later
        for _, cmd in ipairs(diamondPendingCommands) do
            if cmd.frame <= currentFrame then
                table.insert(commandsToExecute, cmd)
            else
                table.insert(remainingCommands, cmd)
            end
        end
        
        -- Execute commands that are due
        if #commandsToExecute > 0 then
            for _, cmd in ipairs(commandsToExecute) do
                -- Normal command handling for all commands
                if Spring.ValidUnitID(cmd.unitID) then
                    Echo("[DIAMOND FORMATION] Executing: " .. cmd.description .. " for unit " .. cmd.unitID)
                    Spring.GiveOrderToUnit(cmd.unitID, cmd.cmdID, cmd.params, cmd.options)
                    
                    -- Report extra info for debugging
                    if cmd.isFlankPoint then
                        local x, y, z = Spring.GetUnitPosition(cmd.unitID)
                        if x and z then
                            Echo(string.format("[DIAMOND FORMATION] Unit %d moving from (%.1f, %.1f) to flank at (%.1f, %.1f)", 
                                cmd.unitID, x, z, cmd.params[1], cmd.params[3]))
                        end
                    elseif cmd.isConvergeCommand then
                        Echo(string.format("[DIAMOND FORMATION] *** CONVERGE PHASE *** Unit %d moving to target (%.1f, %.1f)", 
                            cmd.unitID, cmd.params[1], cmd.params[3]))
                        -- Make it very clear this is happening
                        Echo("[DIAMOND FORMATION] FINAL ASSAULT INITIATED - Units converging from flanks!")
                    end
                end
            end
            
            Echo("[DIAMOND FORMATION] Executed " .. #commandsToExecute .. " commands, " .. 
                 #remainingCommands .. " remaining")
        end
        
        -- Update pending commands list
        diamondPendingCommands = remainingCommands
        
        -- If all commands have been executed, we can deactivate the formation
        if #diamondPendingCommands == 0 then
            Echo("[DIAMOND FORMATION] All commands executed, formation complete")
            deactivateDiamondFormation()
        end
    end
end

-- Initialize widget
function widget:Initialize()
    Echo("Developer Menu initialized")
    Echo("Press M to toggle menu visibility")
    Echo("Press ESC to cancel spawn mode")
    
    -- Initialize states
    cheatEnabled = IsCheatingEnabled() or false
    
    -- Try to determine other cheat states - we'll need to guess initially
    -- as Spring doesn't provide direct access to these states
    
    -- These states are reset when changing maps, so we need to update them
    nocostEnabled = false
    godmodeEnabled = false
    nofogEnabled = false
end

-- GameStart is called when a new game or replay begins
function widget:GameStart()
    -- Reset cheat states when a new map starts
    cheatEnabled = IsCheatingEnabled() or false
    nocostEnabled = false
    godmodeEnabled = false
    nofogEnabled = false
end

-- GameFrame handles per-frame game events
function widget:GameFrame(frame)
    -- Check cheat status at game start and after a few frames
    -- (Some engines might not have IsCheatingEnabled fully initialized on GameStart)
    if frame == 1 or frame == 10 or frame == 30 then
        cheatEnabled = IsCheatingEnabled() or false
        
        -- Reset other cheat states if cheating is disabled
        if not cheatEnabled then
            nocostEnabled = false
            godmodeEnabled = false
            nofogEnabled = false
        end
    end
end
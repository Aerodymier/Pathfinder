--!strict

local PathfindingService = game:GetService("PathfindingService")

local Types = require(script.Parent.Types)
local PathfinderMethods = require(script.PathfinderMethods)

local Pathfinder = {}
Pathfinder.__index = setmetatable(Pathfinder, PathfinderMethods)

--[[
	Create a new Pathfinder instance.
]]
function Pathfinder.new(char: Model, config: Types.PathfinderConfiguration)
	assert(char, "A character is required for Pathfinder.")

	if config.MovingTarget then
		assert(typeof(config.Target) ~= "Vector3", "A BasePart or a Model needs to be provided if MovingTarget is enabled.")
	end

	local _, charBoundingBox = char:GetBoundingBox()

	local s = {} :: Types.Pathfinder
	s._character = char
	s._running = false
	s._target = config.Target
	s._pathfinderAbilities = config.AbilitiesTable :: Types.PathfinderAbilities
	s._movingTargetTrackingRange = config.MovingTargetTrackingRange or 100
	s._movingTargetRetargetingRange = config.MovingTargetRetargetingRange or
		math.max(charBoundingBox.X, charBoundingBox.Y, charBoundingBox.Z)
	s._movingTarget = config.MovingTarget or false
	s._debugMode = config.DebugMode or false
	s._debugWaypoint = config.DebugWaypoint or false
	s._randomMove = config.RandomMove or false
	s._moveFunction = config.MoveFunction
	s._jumpFunction = config.JumpFunction
	s._randomMoveFunction = config.RandomMoveFunction
	s._abilityLastActivated = -1
	s._connections = {}
	s._memory = {}
	s._abilityCooldowns = {}

	s._path = PathfindingService:CreatePath(config.AgentParameters or 	
		{
			AgentRadius = 2, 
			AgentHeight = 5,
			AgentCanJump = true,
			AgentCanClimb =  true,
			PathSettings = 
				{
					SupportPartialPath = true
				}
		}
	)

	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = {char}
	rp.FilterType = Enum.RaycastFilterType.Exclude

	s._rp = rp

	setmetatable(s, Pathfinder)

	return s
end

--[[
	Change the target. Use this when you want to change the active target.
]]
function Pathfinder:ChangeTarget(newTarget: Vector3 | BasePart | Model)
	self._target = newTarget

	if self._movingTarget then
		self._pathDone = true
	end
end

--[[
	Run Pathfinder. Will continue to run unless stopped if movingTarget is true.
]]
function Pathfinder:Run()
	self:_DebugPrint("Pathfinding started.")
	self._running = true
	self:_InitPathfinding()
	
	local function checkAbilities(dist: number)
		if self._pathfinderAbilities and next(self._pathfinderAbilities) then
			for n, v in pairs(self._pathfinderAbilities) do
				if dist <= v.ActivationRange 
					and self._abilityLastActivated < os.clock()
					and (if self._abilityCooldowns[n] then 
						os.clock() - self._abilityCooldowns[n] >= v.CooldownTime else true)
					and (if v.CustomConditions then v.CustomConditions({
						Character = self._character,
						Target = self._target,
						Distance = dist,
					}) 
					else true) then

					self:_DebugPrint("Activating ability " .. tostring(n))

					self._abilityCooldowns[n] = os.clock()
					self._abilityLastActivated = os.clock() + (v.ActiveTime or 0)
					
					v.Callback({
						Character = self._character,
						Target = self._target,
						Distance = dist,
					})
				end
			end
		end
	end

	if self._movingTarget then
		task.spawn(function()
			while self._running do
				if self._target.Parent then
					local charPos = self:_GetCharacterPosition() :: Vector3
					local targetPos = self:_GetTargetPosition() :: Vector3
					
					local dist = (charPos - targetPos).Magnitude
					
					checkAbilities(dist)
					
					if dist <= self._movingTargetTrackingRange
						and dist > self._movingTargetRetargetingRange then
						self:_PathOperations(self._target)
					else
						self:_DebugPrint("Moving target not in range or distance is lower than "
							.. "retargeting range: " .. tostring(dist) ..
							" - " .. tostring(self._movingTargetTrackingRange)
						)

						if self._abilityLastActivated < os.clock() and self._randomMove then 
							self:_RandomMove() 
						end
					end
				elseif self._abilityLastActivated < os.clock() and self._randomMove then
					self:_RandomMove()
				end

				task.wait()
			end
		end)
	else
		local pos = self:_GetTargetPosition()

		self:_DebugPrint("Moving to " .. tostring(pos))

		self:_PathOperations(pos)
		
		task.spawn(function()
			while not self._pathDone do
				local charPos = self:_GetCharacterPosition() :: Vector3
				local targetPos = self:_GetTargetPosition() :: any 
				-- for some reasons, Luau thinks that this Vector3 return has a parent
	
				local dist = (charPos - targetPos).Magnitude
				
				checkAbilities(dist)
				task.wait()
			end
		end)
		
		self._running = false
	end
end

--[[
	Stops the Pathfinder instance.
]]
function Pathfinder:Stop()
	self._running = false
	self._pathDone = true
end

--[[
	Destroy the Pathfinder instance.
]]
function Pathfinder:Destroy()
	if self._running then
		self:Stop()
	end

	for _, c: RBXScriptConnection in self._connections do
		c:Disconnect()
	end

	setmetatable(self, nil)
end

return Pathfinder
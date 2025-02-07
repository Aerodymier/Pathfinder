--!strict

local PathfindingService = game:GetService("PathfindingService")

local Types = require(script.Parent.Types)
local PathfinderMethods = require(script.PathfinderMethods)
local PathfinderHelper = require(script.PathfinderMethods.PathfinderHelper)

local Pathfinder = {}
Pathfinder.__index = setmetatable(Pathfinder, PathfinderMethods)

export type PathfinderInstance = typeof(setmetatable(
	{} :: Types.Pathfinder
, Pathfinder))

--[[
	Create a new Pathfinder instance.
]]
function Pathfinder.new(char: Model, config: Types.PathfinderConfiguration): PathfinderInstance
	assert(char, "A character is required for Pathfinder.")

	if config.MovingTarget then
		assert(typeof(config.Target) ~= "Vector3", "A BasePart or a Model needs to be provided if MovingTarget is enabled.")
	end

	if config.AbilitiesTable then
		for i, _ in config.AbilitiesTable do
			assert(typeof(i) == "number", "AbilitiesTable keys must be numeric.")
		end
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
	s._activateAbilitiesInSequence = config.ActivateAbilitiesInSequence or false
	s._movingTarget = config.MovingTarget or false
	s._debugMode = config.DebugMode or false
	s._debugWaypoint = config.DebugWaypoint or false
	s._randomMove = config.RandomMove or false
	s._moveFunction = config.MoveFunction
	s._jumpFunction = config.JumpFunction
	s._randomMoveFunction = config.RandomMoveFunction
	s._noPathAction = config.NoPathAction
	s._abilityLastActivated = -1
	s._currentAbilityIndex = 0
	s._connections = {}
	s._memory = {}
	s._abilityCooldowns = {}

	s._pathCompletedEvent = Instance.new("BindableEvent")
	s._pathBlockedEvent = Instance.new("BindableEvent")
	s._waypointReachedEvent = Instance.new("BindableEvent")

	s.OnPathCompleted = s._pathCompletedEvent.Event
	s.OnPathBlocked = s._pathBlockedEvent.Event
	s.OnWaypointReached = s._waypointReachedEvent.Event

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
		if self._pathfinderAbilities and #self._pathfinderAbilities > 0 then
			if self._activateAbilitiesInSequence then
				local currentIndex = self._currentAbilityIndex :: number -- luau typing issue
				local newInd = currentIndex % #self._pathfinderAbilities + 1

				if self:_CheckAndRunAbility(dist, newInd) then
					self._currentAbilityIndex = newInd
				end
			else
				local randomTable = {}
				local total = 1
				local rollN
				local abilityToActivate

				for n, v in ipairs(self._pathfinderAbilities) do
					if self:_CheckIfAbilityCanBeActivated(dist, n) then
						table.insert(randomTable, {
							Weight = v.Weight or 1,
							n = n
						}) -- set up a table for roll

						total += v.Weight
					end
				end

				if #randomTable == 0 then return end -- no abilities to activate

				rollN = math.random(total, total*4)
				abilityToActivate = PathfinderHelper:Roll(rollN, randomTable)
				
				self:_CheckAndRunAbility(dist, abilityToActivate)
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

	self._waypointReachedEvent:Destroy()
	self._pathCompletedEvent:Destroy()
	self._pathBlockedEvent:Destroy()

	setmetatable(self, nil)
end

return Pathfinder
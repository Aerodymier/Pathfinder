--!strict

local PathfinderHelper = require(script.PathfinderHelper)

local PathfinderMethods = {}
PathfinderMethods.__index = setmetatable(PathfinderMethods, PathfinderHelper)

--[[
	MoveTo function which accounts for a custom MoveTo method.
]]
function PathfinderMethods:_MoveTo(p: Vector3)
	if self._moveFunction then
		self._moveFunction(p)
	else
		local Humanoid = self._character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			Humanoid:MoveTo(p)
		else
			self:_DebugPrint("Humanoid does not exist, MoveTo did not run.")
		end
	end
end

--[[
	Jump function which accounts for a custom jump method.
]]
function PathfinderMethods:_Jump(p: Vector3): boolean
	if self._jumpFunction then
		return self._jumpFunction(p)
	else
		local Humanoid = self._character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			Humanoid.Jump = true
		else
			self:_DebugPrint("Humanoid does not exist, Jump did not run.")
		end

		return true
	end
end

--[[
	RandomMove which is structurally like an ability. Basically randomly moves to a close position.
]]
function PathfinderMethods:_RandomMove()
	local pos: Vector3?
	self:_DebugPrint("Random moving")
	self._abilityLastActivated = os.clock() + 5

	if self._randomMoveFunction then
		pos = self._randomMoveFunction()

		assert(pos and typeof(pos) == "Vector3", "RandomMoveFunction did not return a Vector3.")
	else
		local Humanoid = self._character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			local RootPart = Humanoid.RootPart or self._character:FindFirstChild("HumanoidRootPart") :: Part

			if RootPart then
				pos = Vector3.new(
					RootPart.Position.X + math.random(0, 6), 
					RootPart.Position.Y + math.random(0, 2), 
					RootPart.Position.Z + math.random(0, 6)
				)
			end
		end
	end

	if pos then
		self:_InitPathfinding()
		self:_MoveInPath(pos)
	end
end

--[[
	Handles basic waypoint actions and increments _currentWaypoint.
]]
function PathfinderMethods:_OnWaypointReached()
	if self._waypoints and self._currentWaypoint and self._currentWaypoint < #self._waypoints then
		self._currentWaypoint += 1
		local currentWaypointInfo = self._waypoints[self._currentWaypoint]

		self._lastPathTick = os.clock()
		if currentWaypointInfo.Action == Enum.PathWaypointAction.Walk then
			self:_MoveTo(currentWaypointInfo.Position)
		elseif currentWaypointInfo.Action == Enum.PathWaypointAction.Jump then
			self:_DebugPrint("Waypoint " .. self._currentWaypoint .. " action is Jump.")
			local Humanoid = self._character:FindFirstChildOfClass("Humanoid")
			if not Humanoid then return end

			local willMoveTo = self:_Jump(currentWaypointInfo.Position)

			if willMoveTo then
				self:_MoveTo(currentWaypointInfo.Position)
			end
		else
			self:_DebugPrint("Waypoint action: " .. currentWaypointInfo.Action.Name)
			self:_MoveTo(currentWaypointInfo.Position)
		end

		self:_InsertDebugWaypoint(currentWaypointInfo.Position, self._currentWaypoint-1, nil, currentWaypointInfo.Action)

		self:_DebugPrint("Passed waypoint " .. self._currentWaypoint .. "/" .. #self._waypoints)
	elseif self._currentWaypoint and self._waypoints and self._currentWaypoint == #self._waypoints then
		self._pathDone = true
		self:_DebugPrint("Path is done, completed.")
	end
end

--[[
	The main function for pathfinding to a position.
]]
function PathfinderMethods:_MoveInPath(to: Vector3)
	self._pathDone = false
	self:_DebugPrint("Moving in path to " .. tostring(to))
	local Humanoid = self._character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local RootPart = Humanoid.RootPart or self._character:FindFirstChild("HumanoidRootPart") :: Part

	self._path:ComputeAsync(RootPart.Position, to)
	self._waypoints = {}

	if self._path.Status == Enum.PathStatus.Success then
		self:_DebugPrint("Path creation was successful.")
		self._waypoints = self._path:GetWaypoints()
		self._currentWaypoint = 0

		task.spawn(function()
			local previousDirection
			local start = os.clock()

			while not self._pathDone do
				self:_OnWaypointReached()
				local currentWaypointInfo = self._waypoints[self._currentWaypoint]
				local previousPos = self._memory["PreviousPos"] :: Vector3
				
				if Humanoid and currentWaypointInfo then
					local currentWaypointPos = currentWaypointInfo.Position
					
					if previousPos then
						local charPos = self:_GetCharacterPosition() :: Vector3
						
						local direction1 = self:_GetXZDirection(charPos, previousPos)
						local direction2 = self:_GetXZDirection(charPos, currentWaypointPos)
						local directionNext
						local angleNext
						
						if self._currentWaypoint < #self._waypoints then
							directionNext = self:_GetXZDirection(charPos, self._waypoints[self._currentWaypoint+1].Position)
							angleNext = directionNext:Angle(direction2)
						end
						
						local angle = direction1:Angle(direction2)
						
						if directionNext and angleNext and math.round(angle) == 3 and 
							math.round(angleNext) == 3 then
							self:_DebugPrint("Skipped the waypoint behind the character " .. tostring(angle) .. " " .. tostring(angleNext))
							continue
						--else
							--self:_DebugPrint("Angle " .. " " .. tostring(self._currentWaypoint) .. " " .. tostring(angle) .. " " .. tostring(angleNext))
						end
					end

					local sAngle = self:_GetSurfaceAngle()
					local angle = 1-sAngle

					local groundDistance = (Vector3.new(currentWaypointPos.X,
						0,
						currentWaypointPos.Z
						) - Vector3.new(RootPart.Position.X,
							0,
							RootPart.Position.Z
						)).Magnitude

					local waitTime = if self._pathDone or not self._waypoints or not currentWaypointInfo or not RootPart then 
						0 else (if sAngle > 0 then angle else 1) * groundDistance/(Humanoid.WalkSpeed*2)

					task.wait(waitTime)

					if self._currentWaypoint > 2 then
						local prePrevWaypointP = self._waypoints[self._currentWaypoint-2].Position
						local prevWaypoint = self._waypoints[self._currentWaypoint-1]
						local prevWaypointP = prevWaypoint.Position

						local direction = self:_GetXZDirection(prePrevWaypointP, prevWaypointP)
						
						--self:_DebugPrint(tostring(self._currentWaypoint) .. " " .. tostring(direction) .. " " .. tostring(previousDirection))

						if previousDirection and not previousDirection:FuzzyEq(direction, 0.01) and
							(prePrevWaypointP.Y == prevWaypointP.Y 
								or prevWaypoint.Action == Enum.PathWaypointAction.Jump 
								or (prevWaypoint.Action == Enum.PathWaypointAction.Walk and 
									math.round(prePrevWaypointP.Y) ~= math.round(prevWaypointP.Y)
								)) then
							
							self:_InsertDebugWaypoint(prevWaypointP, self._currentWaypoint-2, Color3.fromRGB(255, 0, 0))

							if not RootPart.AssemblyLinearVelocity:FuzzyEq(Vector3.new(0, 0, 0), 0.01) then
								self:_DebugPrint("Waiting for MoveToFinished")
								--Humanoid.MoveToFinished:Wait()
								--MoveToFinished doesn't do the job in most cases and is not the effect we want

								repeat
									task.wait()
								until RootPart.AssemblyLinearVelocity:FuzzyEq(Vector3.new(0, 0, 0), .1)
							end
						end

						previousDirection = direction
					end
				else
					break -- TODO
				end
			end

			self:_DebugPrint("Path took " .. os.clock() - start .. " seconds.")
		end)
	elseif self._path.Status == Enum.PathStatus.NoPath or 
		self._path.Status == Enum.PathStatus.ClosestNoPath  then
		-- 04/12/2024, even if it is marked as deprecated, pathfinding service still returns ClosestNoPath
		self:_DebugPrint("No path.")

		local targetPos = self:_GetTargetPosition() :: Vector3
		local charPos = self:_GetCharacterPosition() :: Vector3
		local dist = (targetPos-charPos).Magnitude

		if self._noPathAction then
			self._noPathAction(self:_DefaultT())
		else
			if dist < (self._movingTargetTrackingRange or math.huge) then
				self:_DebugPrint("Moving target is in range, moving to moving target.")
				self:_MoveTo(targetPos)
			else
				self:_DebugPrint("Random moving.")
				self:_RandomMove()
			end

			task.wait(0.5)

			self._pathDone = true
		end
	else
		self:_MoveTo(RootPart.Position)
		self:_DebugPrint("Unknown path status: " .. self._path.Status.Name)
		self:_RandomMove()

		self._pathDone = true
	end
end

--[[
	Currently only sets the path as done and recalculates from current position.
]]
function PathfinderMethods:_OnPathBlocked(blockedWaypointIndex: number)
	if blockedWaypointIndex > self._currentWaypoint then
		local Humanoid = self._character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			self:_DebugPrint("Current waypoint is blocked.")
			self._pathDone = true

			self:_PathOperations(self:_GetTargetPosition())
		end
	end
end

--[[
	Cleanup past waypoints and reset some variables
]]
function PathfinderMethods:_InitPathfinding()
	self:_DebugPrint("Pathfinding init")
	self._waypoints = {}
	self._currentWaypoint = 1
	self._lastPathTick = nil

	self._pathDone = true

	self._connections[#self._connections+1] = self._path.Blocked:Once(function(blockedWaypointIndex)
		self:_OnPathBlocked(blockedWaypointIndex)
	end)
end

--[[
	The main function to get paths started and manage moving target retargeting.
]]
function PathfinderMethods:_PathOperations()
	if self._movingTarget then
		self._memory["CurrentPos"] = self:_GetTargetPosition()

		if self._memory["PreviousPos"] and not
			self._memory["PreviousPos"]:FuzzyEq(self._memory["CurrentPos"]) then
			self:_OnPositionChanged()
		end
		
		self._memory["PreviousPos"] = self._memory["CurrentPos"]
	end

	self:_DebugPrint("Path done status: " .. tostring(self._pathDone) or "nil")
	if self._pathDone then
		self:_DebugPrint("Path was done, initializing")
		self:_InitPathfinding()

		self:_MoveInPath(self:_GetTargetPosition())
	else
		if self._lastPathTick then
			if os.clock() - self._lastPathTick  > 5 then
				self._pathDone = true
			end
		end
	end
end

return PathfinderMethods

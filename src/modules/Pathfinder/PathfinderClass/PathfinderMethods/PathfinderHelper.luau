--!strict
local Debris = game:GetService("Debris")

local PathfinderHelper = {}
PathfinderHelper.__index = PathfinderHelper

function PathfinderHelper:_InsertDebugWaypoint(pos: Vector3, num: number, color: Color3?, action: Enum.PathWaypointAction?)
	if not self._debugWaypoint then return end

	local b = Instance.new("Part")
	b.Shape = Enum.PartType.Ball
	b.Size = color and Vector3.new(1.1, 1.1, 1.1) or Vector3.new(1,1,1)
	b.Anchored = true
	b.CanCollide = false
	b.Material = Enum.Material.Neon
	b.Color = color or ((action and action == Enum.PathWaypointAction.Jump) and Color3.fromRGB(255, 186, 12) or Color3.fromRGB(255, 255, 255))
	b.Position = pos
	b.Parent = workspace

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.StudsOffset = Vector3.new(0, 1, 0)
	bg.LightInfluence = 0

	local tl = Instance.new("TextLabel")
	tl.TextScaled = true
	tl.TextWrapped = true
	tl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	tl.TextColor3 = Color3.fromRGB(255, 255, 255)
	tl.Size = UDim2.new(.9, 0, .9, 0)
	tl.Text = tostring(num)
	tl.Parent = bg

	local uc = Instance.new("UICorner")
	uc.CornerRadius = UDim.new(0.5, 0)
	uc.Parent = tl

	bg.Parent = b

	Debris:AddItem(b, 5)
end

function PathfinderHelper:_GetXZDirection(pos1: Vector3, pos2: Vector3): Vector3
	return Vector3.new(
		pos1.X-pos2.X,
		0,
		pos1.Z-pos2.Z
	)
end

function PathfinderHelper:_GetSurfaceAngle(): number
	local Humanoid = self._character:FindFirstChildOfClass("Humanoid")

	if Humanoid then
		local RootPart = Humanoid.RootPart or self._character:FindFirstChild("HumanoidRootPart") :: Part

		if RootPart then
			local raycast = workspace:Raycast(RootPart.Position, Vector3.new(0, -1, 0) * 5, self._rp) -- TODO

			if raycast then
				return math.acos(raycast.Normal:Dot(Vector3.new(0, 1, 0)))
			end
		end
	end

	return -1
end

function PathfinderHelper:_GetTargetPosition(): Vector3
	local pos

	if typeof(self._target) == "Vector3" then
		pos = self._target
	elseif self._target:IsA("Part") then
		pos = self._target.Position
	else
		pos = self._target:GetPivot().Position
	end

	return pos
end

function PathfinderHelper:_GetCharacterPosition(): Vector3
	local charPart = self._character:FindFirstChild("HumanoidRootPart") :: BasePart
	local Humanoid = self._character:FindFirstChildOfClass("Humanoid")

	if Humanoid then
		charPart = Humanoid.RootPart
	else
		charPart = self._character:FindFirstChildWhichIsA("BasePart")
	end
	
	return charPart.Position
end

function PathfinderHelper:_OnPositionChanged()
	local newPos = self._memory["CurrentPos"] :: Vector3

	local direction = newPos - self._memory["PreviousPos"]

	if self._memory["PreviousDirection"] and 
		self._memory["PreviousDirection"]:FuzzyEq(direction, .75) then
		self:_DebugPrint("direction same " .. tostring(self._memory["PreviousDirection"]) .. " " .. tostring(direction))
	else
		self._pathDone = true
		self:_DebugPrint("direction different " .. tostring(self._memory["PreviousDirection"]) .. " " .. tostring(direction))
	end

	self._memory["PreviousDirection"] = direction
end

function PathfinderHelper:_CheckIfAbilityCanBeActivated(dist: number, n: number): boolean
	local ability = self._pathfinderAbilities[n]
	assert(ability, "An ability with " .. n  .. " key does not exist.")

	if dist <= ability.ActivationRange 
		and self._abilityLastActivated < os.clock()
		and (if self._abilityCooldowns[n] then 
			os.clock() - self._abilityCooldowns[n] >= ability.CooldownTime else true)
		and (if ability.CustomConditions then ability.CustomConditions({
			self:_DefaultT()
		})
	else true) then
		return true
	else
		return false
	end
end

function PathfinderHelper:_CheckAndRunAbility(dist: number, n: number): boolean
	local ability = self._pathfinderAbilities[n]
	assert(ability, "An ability with " .. n  .. " key does not exist.")

	local canBeActivated = self:_CheckIfAbilityCanBeActivated(dist, n)

	if canBeActivated then
		self:_DebugPrint("Activating ability " .. tostring(n))

		self._abilityCooldowns[n] = os.clock()
		self._abilityLastActivated = os.clock() + (ability.ActiveTime or 0)
		
		ability.Callback(self:_DefaultT())

		return true
	end

	return false
end

function PathfinderHelper:_DebugPrint(...: any)
	if self._debugMode then
		local charName: string = self._character.Name
		
		print("[" .. charName .. "]", ...)
	end
end

function PathfinderHelper:Roll(n: number, randomTable: {[number]: {[string]: number}}): number
	while true do
		for _, v in ipairs(randomTable) do
			n -= v.Weight

			if n < 0 then
				return v.n
			end
		end
	end
end

function PathfinderHelper:_DefaultT()
	local targetPos = self:_GetTargetPosition() :: Vector3
	local charPos = self:_GetCharacterPosition() :: Vector3
	local dist = (targetPos-charPos).Magnitude

	return {
		Character = self._character,
		Target = self._target,
		Distance = dist,
		Move = function(p: Vector3)
			self:_InitPathfinding()
			self:_MoveInPath(p)
		end,
		RandomMove = function()	
			self:_RandomMove()
		end
	}
end

return PathfinderHelper

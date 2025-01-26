--!strict

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local TAG = "AbilityRig"

local Types = require(ServerStorage:FindFirstChild("Pathfinder"):FindFirstChild("Types"))
local Pathfinder = require(ServerStorage:FindFirstChild("Pathfinder"))
type PathfinderAbilities = Types.PathfinderAbilities

local function onCharacterAdded(char: Model)
	if not char.Parent then return end
	local t = char.Parent:FindFirstChild("End") :: BasePart
	local isMovingTarget = char:GetAttribute("MovingTarget") :: boolean
	
	local PathfinderAbilities = {
		{
			ActivationRange = 30,
			ActiveTime = 3,
			CooldownTime = 10,
			CustomConditions = function()
				return true
			end,
			Callback = function(t2)
				local vf = t2.Character:FindFirstChildOfClass("VectorForce")
					or Instance.new("VectorForce")
				
				vf.Force = Vector3.new(0, 1, 0) * 5000
				vf.ApplyAtCenterOfMass = true
				vf.Attachment0 = t2.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("RootAttachment")
				vf.Parent = t2.Character:FindFirstChild("HumanoidRootPart")
				vf.Enabled = true
				
				task.delay(.3, function()
					vf.Enabled = false
				end)
			end,
		}
	} :: PathfinderAbilities
	
	local p = Pathfinder.new(char, {
		Target = t,
		MovingTarget = false or isMovingTarget,
		MovingTargetTrackingRange = 100,
		DebugMode = true,
		RandomMove = false,
		DebugWaypoint = true,
		AgentCanClimb = true,
		AgentParameters = {
			AgentRadius = 2, 
			AgentHeight = 5,
			AgentCanJump = true, 
			AgentCanClimb =  true,
			PathSettings = 
				{
					SupportPartialPath = true
				},
			Costs = {
				PathfindAvoid = 9999,
				Truss = 1
			}
		},
		AbilitiesTable = PathfinderAbilities
	}) :: any
	
	p:Run()
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(onCharacterAdded)

for _, v in ipairs(CollectionService:GetTagged(TAG)) do
	onCharacterAdded(v)
end
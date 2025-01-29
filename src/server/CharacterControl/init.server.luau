--!strict

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local TAG = "TestRig"

local Pathfinder = require(ServerStorage:FindFirstChild("Pathfinder"))
local Types = require(ServerStorage:FindFirstChild("Pathfinder"):FindFirstChild("Types"))

local function onCharacterAdded(char: Model)
	if not char.Parent then return end
	local target = char.Parent:FindFirstChild("End") :: BasePart
	local isMovingTarget = char:GetAttribute("MovingTarget") :: boolean

	local function NoPathAction(t: Types.t)
		local TestFolder = t.Character.Parent
		if not TestFolder then return end
		local start = TestFolder:FindFirstChild("Start") :: BasePart?
		assert(start, "Start does not exist for the selected folder.")

		t.Move(start.Position)
	end

	local p = Pathfinder.new(char, {
		Target = target,
		MovingTarget = false or isMovingTarget,
		MovingTargetTrackingRange = 100,
		DebugMode = if char.Name == "Rig22" then true else false,
		-- change it to any rig you want to test
		-- you can just make it true as well but the prints lag studio with 20 rigs
		RandomMove = false,
		DebugWaypoint = true,
		NoPathAction = if char.Name == "Rig22" then NoPathAction else nil,

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
		}
	}) :: any
	
	p:Run()
	
	if char.Name == "Rig12" then
		task.delay(3, function()
			local end2 = char.Parent:FindFirstChild("End2") :: BasePart

			p:ChangeTarget(end2)
		end)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(onCharacterAdded)

for _, v in ipairs(CollectionService:GetTagged(TAG)) do
	onCharacterAdded(v)
end
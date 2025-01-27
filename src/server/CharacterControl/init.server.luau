--!strict

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local TAG = "TestRig"

local Pathfinder = require(ServerStorage:FindFirstChild("Pathfinder"))

local function onCharacterAdded(char: Model)
	if not char.Parent then return end
	local t = char.Parent:FindFirstChild("End") :: BasePart
	local isMovingTarget = char:GetAttribute("MovingTarget") :: boolean

	local p = Pathfinder.new(char, {
		Target = t,
		MovingTarget = false or isMovingTarget,
		MovingTargetTrackingRange = 100,
		DebugMode = if char.Name == "Rig10" then true else false,
		-- change it to any rig you want to test
		-- you can just make it true as well but the prints lag studio with 20 rigs
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
--!strict

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local TAG = "EventsRig"

local Pathfinder = require(ServerStorage:FindFirstChild("Pathfinder"))
local Types = require(ServerStorage:FindFirstChild("Pathfinder"):FindFirstChild("Types"))

local function onPathBlocked(t: Types.t)
    t.DebugPrint("OnPathBlocked event triggered.")
end

local function onPathCompleted(t: Types.t)
    t.DebugPrint("OnPathCompleted event triggered.")
end

local function onWaypointReachedEvent(t: Types.t)
    t.DebugPrint("OnWaypointReachedEvent event triggered.")
end

local function onIdle(t: Types.t)
	t.DebugPrint("OnIdle event triggered.")
end

local function onCharacterAdded(char: Model)
	if not char.Parent then return end
	local target = char.Parent:FindFirstChild("End") :: BasePart
	local isMovingTarget = char:GetAttribute("MovingTarget") :: boolean

	local p = Pathfinder.new(char, {
		Target = target,
		MovingTarget = false or isMovingTarget,
		MovingTargetTrackingRange = 100,
		DebugMode = true,
		-- change it to any rig you want to test
		-- you can just make it true as well but the prints lag studio with 20 rigs
		RandomMove = false,
		DebugWaypoint = true,

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

    p.OnPathCompleted:Connect(onPathCompleted)
    p.OnWaypointReached:Connect(onWaypointReachedEvent)
    p.OnPathBlocked:Connect(onPathBlocked)
	p.OnIdle:Connect(onIdle)
	
	p:Run()
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(onCharacterAdded)

for _, v in ipairs(CollectionService:GetTagged(TAG)) do
	onCharacterAdded(v)
end
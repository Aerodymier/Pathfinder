--!strict

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG = "ChaseRig"

local Pathfinder = require(ServerStorage:FindFirstChild("Pathfinder"))

local function onPlrAdded(plr: Player, char: Model)
	local function onCharAdded(plrChar: Model)
		local p = Pathfinder.new(char, {
			Target = plrChar,
			MovingTarget = true,
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
			}
		}) :: any

		p:Run()
	end
	
	if plr.Character then
		onCharAdded(plr.Character)
	end
	
	plr.CharacterAdded:Connect(onCharAdded)
end

local function onCharacterAdded(char: Model)
	if not char.Parent then return end
	
	Players.PlayerAdded:Connect(function(plr: Player)
		onPlrAdded(plr, char)
	end)
	
	for _, v in ipairs(Players:GetPlayers()) do
		onPlrAdded(v, char)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(onCharacterAdded)

for _, v in ipairs(CollectionService:GetTagged(TAG)) do
	onCharacterAdded(v)
end
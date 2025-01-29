--!strict
export type Pathfinder = {
	["_character"]: Model,
	["_target"]: Vector3 | BasePart | Model,
	["_movingTarget"]: boolean,
	["_abilityLastActivated"]: number,
	["_movingTargetTrackingRange"]: number?,
	["_movingTargetRetargetingRange"]: number?,
	["_pathfinderAbilities"]: PathfinderAbilities?,
	["_running"]: boolean,
	["_path"]: Path,
	["_pathDone"]: boolean,
	["_waypoints"]: {[number]: PathWaypoint},
	["_currentWaypoint"]: number,
	["_currentAbilityIndex"]: number,
	["_rp"]: RaycastParams,
	["_lastPathTick"]: number?,
	["_debugMode"]: boolean?,
	["_debugWaypoint"]: boolean?,
	["_randomMove"]: boolean?,
	["_activateAbilitiesInSequence"]: boolean?,
	["_connections"]: {[number]: RBXScriptConnection},
	["_memory"]: {any: any},
	["_abilityCooldowns"]: {[string | number]: number},
	["_moveFunction"]: ((Vector3) -> ())?,
	["_jumpFunction"]: ((Vector3) -> (boolean))?,
	["_randomMoveFunction"]: (() -> (Vector3))?
}

export type PathfinderAbilities = {
	[number]: {
		["ActivationRange"]: number,
		["ActiveTime"]: number,
		["CooldownTime"]: number,
		["Weight"]: number?,
		["CustomConditions"]: (({[string]: any}) -> (boolean))?,
		["Callback"]: ({[string]: any}) -> (),
	}
}

export type PathfinderConfiguration = {
	["Target"]: Vector3 | BasePart | Model,
	["MovingTargetTrackingRange"]: number?,
	["MovingTargetRetargetingRange"]: number?,
	["DebugMode"]: boolean?,
	["DebugWaypoint"]: boolean?,
	["MovingTarget"]: boolean?,
	["RandomMove"]: boolean?,
	["ActivateAbilitiesInSequence"]: boolean?,
	["MoveFunction"]: ((Vector3) -> ())?,
	["JumpFunction"]: ((Vector3) -> (boolean))?,
	["RandomMoveFunction"]: (() -> (Vector3))?,
	["AgentParameters"]: {[string]: any}?,
	["AbilitiesTable"]: PathfinderAbilities?,
}

return {}
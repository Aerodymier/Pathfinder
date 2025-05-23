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
	["_noPathAction"]: ((t) -> ())?,
	["_moveFunction"]: ((Vector3) -> ())?,
	["_jumpFunction"]: ((Vector3) -> (boolean))?,
	["_randomMoveFunction"]: (() -> (Vector3))?,
	["_pathCompletedEvent"]: BindableEvent,
	["_waypointReachedEvent"]: BindableEvent,
	["_pathBlockedEvent"]: BindableEvent,
	["_idleEvent"]: BindableEvent,
	["_pathCount"]: number,
	["_startTime"]: number,
	["_debugLevel"]: number,
	["OnPathCompleted"]: RBXScriptSignal,
	["OnPathBlocked"]: RBXScriptSignal,
	["OnWaypointReached"]: RBXScriptSignal,
	["OnIdle"]: RBXScriptSignal,
}

export type PathfinderAbilities = {
	[number]: {
		["ActivationRange"]: number,
		["ActiveTime"]: number,
		["CooldownTime"]: number,
		["Weight"]: number?,
		["CustomConditions"]: ((t) -> (boolean))?,
		["Callback"]: (t) -> (),
	}
}

export type PathfinderConfiguration = {
	["Target"]: Vector3 | BasePart | Model,
	["MovingTargetTrackingRange"]: number?,
	["MovingTargetRetargetingRange"]: number?,
	["DebugMode"]: boolean?,
	["DebugLevel"]: number?,
	["DebugWaypoint"]: boolean?,
	["MovingTarget"]: boolean?,
	["RandomMove"]: boolean?,
	["ActivateAbilitiesInSequence"]: boolean?,
	["MoveFunction"]: ((Vector3) -> ())?,
	["JumpFunction"]: ((Vector3) -> (boolean))?,
	["RandomMoveFunction"]: (() -> (Vector3))?,
	["NoPathAction"]: ((t) -> ())?,
	["AgentParameters"]: {[string]: any}?,
	["AbilitiesTable"]: PathfinderAbilities?,
}

export type t = {
	["Character"]: Model,
	["Target"]: Model | Part | Vector3,
	["Distance"]: number,
	["Move"]: (Vector3) -> (),
	["RandomMove"]: () -> (),
	["DebugPrint"]: (any) -> (),
}

return {}
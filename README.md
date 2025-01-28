# Pathfinder
Pathfinder is a pathfinding NPC character control module, aimed to be easy to use and flexible for different use cases.

## What does Pathfinder do?
- Pathfinder uses PathfindingService for waypoints and waypoint actions, which means it supports every PathfindingService features Roblox offers.
- Pathfinder uses custom logic (instead of MoveToFinished) to control the delays the character needs to follow the target, which can be a still or a moving target.
- Pathfinder offers defaults which will be useful for most of the use cases, however, is designed to be configurable.
- Pathfinder offers user-made actions for NPC characters (example, NPC can jump to the target player if the distance is less than an amount).

## What does Pathfinder NOT do?
- Pathfinder is not a replacement to PathfindingService. It actively uses PathfindingService to create the waypoints.
- Pathfinder is not made for non-Humanoid or non-character (such as cars) entities. They might or might not work.
- Pathfinder will not work as fast as non-pathfinding character control methods, such as the plain MoveTo.
- Pathfinder will not add new waypoints, although it can skip some waypoints to move without stopping, which means your paths will be as good as your navigation mesh in most cases.

## Installation

### Using wally
You can install this module using wally by adding this to your [dependencies],

```
TimerModule = "aerodymier/Pathfinder^@0.1.0"
```

and then run ``wally install`` in your current directory.

### Using Roblox Studio
You can get the module asset from [here](https://create.roblox.com/store/asset/125173551498545/Pathfinder) or download it as a .rbxl file manually from [here](https://github.com/Aerodymier/Pathfinder/releases/latest/download/module.rbxl).

## Usage
You can find better examples in the example place which you can download from Releases or [here](https://github.com/Aerodymier/Pathfinder/releases/latest/download/ExamplePlace.rbxl).

Create a new ``Pathfinder`` instance:

```luau
local p = Pathfinder.new(char, {
    Target = t,
    MovingTarget = false,
    MovingTargetTrackingRange = 100,
    DebugMode = true,
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
    },
}) :: any
```
(all options are explained below)

And just use ``p:Run()`` to run Pathfinder.

If you want to use abilities, you will also need to define ``PathfinderAbilities``:

```luau
local PathfinderAbilities = {
    {
        ActivationRange = 30,
        ActiveTime = 3,
        CooldownTime = 10,
        CustomConditions = function(t)
            return true
        end, -- optional
        Callback = function(t)
            -- t.Character, t.Target and t.Distance are available
        end,
    }
} :: PathfinderAbilities
```

Report any issues to the [issues](https://github.com/Aerodymier/Pathfinder/issues) tab.

## API

``Pathfinder.new(char: Model, config: Types.PathfinderConfiguration)``
char: The character which you want to use with Pathfinder, not the target.
Config has the following options as keys of a table:

``["Target"]: Vector3 | BasePart | Model`` : The target you want the NPC to pathfind to. Cannot be a Vector3 if ``MovingTarget`` is ``true``.

``["MovingTargetTrackingRange"]: number?`` : Optional, defaults to 100. Only used when ``MovingTarget`` is ``true``and represents the tracking range. If target is outside of the tracking range, NPC will random move if enabled.

``["MovingTargetRetargetingRange"]: number?`` : Optional, defaults to a max of X, Y, Z of target character's bounding box. Only used when ``MovingTarget`` is ``true``and represents the minimum distance value which NPC will start to move to the target. Setting it too low might cause the character to create short paths and continuously run against the target.

``["DebugMode"]: boolean?`` : Optional, defaults to ``false``, enables or disables the debug prints. Might lag Studio if used with too many NPCs.

``["DebugWaypoint"]: boolean?`` :  Optional, defaults to ``false``, enables or disables the debug waypoints. If you are having path issues, this will be helpful to point out the issue.

``["MovingTarget"]: boolean?`` : Optional, defaults to ``false``, enables or disables moving target support. Prefer disabling it if the target will not move.

``["RandomMove"]: boolean?`` : Optional, defaults to ``false``, enables or disables random moving when there is no path or moving target is outside of the tracking range.

``["MoveFunction"]: ((Vector3) -> ())?`` : Optional, defaults to ``Humanoid:MoveTo()``.

``["JumpFunction"]: ((Vector3) -> (boolean))?`` : Optional, defaults to ``Humanoid.Jump = true``. Passes the position which the character needs to jump to and expects a boolean return which represents if character will need to move to the target or not.
Example, if you just want to play an animation, return true, if the character will leap to the target, return false.

``["RandomMoveFunction"]: (() -> (Vector3))?`` : Optional, defaults to

```luau
    pos = Vector3.new(
        RootPart.Position.X + math.random(0, 6), 
        RootPart.Position.Y + math.random(0, 2), 
        RootPart.Position.Z + math.random(0, 6)
    )
```

and expects a Vector3 return which the character will move to.

``["AgentParameters"]: {[string]: any}?`` : Same with [agentParameters](https://create.roblox.com/docs/reference/engine/classes/PathfindingService#CreatePath), defaults to the following:

```luau
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
```

- ``["AbilitiesTable"]: PathfinderAbilities?`` : Optional, defaults to ``nil``. Follows this structure, all time based values are in seconds and all abilities have a string or number key:

- ``["ActivationRange"]: number`` : When the distance is less than ActivationRange, the ability will activate.

- ``["ActiveTime"]: number`` : The time which the ability will be active for. No other abilities will be ran meanwhile.

- ``["CooldownTime"]: number`` : -- Ability cooldown time

- ``["CustomConditions"]: (({[string]: any}) -> (boolean))?`` : -- Optional, gets passed the same t as Callback. Custom conditions to check if the ability will activate or not.

- ``["Callback"]: ({[string]: any}) -> ()`` : -- t.Character, t.Target and t.Distance are available. Ability callback.

```luau
{
	[string | number]: {
		["ActivationRange"]: number,
		["ActiveTime"]: number,
		["CooldownTime"]: number,
		["CustomConditions"]: (({[string]: any}) -> (boolean))?,
		["Callback"]: ({[string]: any}) -> (),
	}
}
```

``PathfinderInstance:Run()``: Runs Pathfinder.
``PathfinderInstance:ChangeTarget(Vector3 | BasePart | Model))``: Used to change the target and also retarget to the new target. Still targets will not retarget unless ``:Run()`` is called manually.
``PathfinderInstance:Stop()``: Stops a running Pathfinder instance.
``PathfinderInstance:Destroy()``: Destroys a Pathfinder instance.
#include "Navy_Macros.h"

Navy_Vehicle_SpawnAirVehicle =
{
	FUN_ARGS_2(_classname,_spawn_position);
	DECLARE(_vehicleID) = createVehicle [_classname,_spawn_position,[],0,Navy_Vehicle_StartingForm];
	WAIT_DELAY(0.1,!isNil "_vehicleID");
	DEBUG
	{
		Navy_Vehicles pushBack _vehicleID;
		INC(Navy_Vehicle_Counter);
	};
	_vehicleID;
};

Navy_Vehicle_SpawnFilledAirVehicle =
{
	FUN_ARGS_5(_unit_template,_gunners,_vehicle_classname,_spawn_position,_cargo_amount);
	PVT_5(_driver,_gunner,_vehicleID,_vehicle_type,_cargo_group);
	_driver = [_unit_template] call Navy_Units_SpawnDriver;
	_vehicleID = [_vehicle_classname,_spawn_position] call Navy_Vehicle_SpawnAirVehicle;
	_driver assignAsDriver _vehicleID;
	_driver moveinDriver _vehicleID;
	[_vehicleID] call Navy_Vehicle_RemoveSelectedWeapons;
	if (_gunners) then
	{
		DECLARE(_available_turrets) = allTurrets [_vehicleID,false];
		{
			_gunner = [_unit_template] call Navy_Units_SpawnGunner;
			_gunner moveInTurret [_vehicleID,_x];
			_gunner assignAsTurret [_vehicleID,_x];
		} forEach _available_turrets;
	};
	if (_cargo_amount > 0) then
	{
		_cargo_group = [_unit_template,_cargo_amount] call Navy_Vehicle_FillCargo;
		{
			_x assignAsCargo _vehicleID;
			_x moveInCargo _vehicleID;
		} forEach units _cargo_group;
	}
	else
	{
		_cargo_group = []; // Avoids RPT errors when the function returns an undefined array
	};
	_vehicle_type = [CONFIG_TYPE_STRING,"Vehicles",(typeOf _vehicleID),"Type"] call Navy_Config_GetConfigValue;
	if (_vehicle_type isEqualTo "FIXED") then
	{
		//_vehicleID setVelocity NAVY_FIXED_WING_STARTING_VELOCITY;
		[_vehicleID,NAVY_FIXED_WING_STARTING_VELOCITY,2] spawn Navy_Vehicle_DelayedVelocityChange;
	};
	DEBUG
	{
		[_vehicleID] spawn Navy_Debug_TrackVehicle;
		[["Vehicle %1 with type %2 with form %3 has been spawned at %4 containing %5",_vehicleID,_vehicle_type,Navy_Vehicle_StartingForm,_spawn_position,(crew _vehicleID)]] call Navy_Debug_HintRPT;
	};
	[_vehicleID,_cargo_group];
};

Navy_Vehicle_DelayedVelocityChange =
{
	FUN_ARGS_3(_vehicleID,_velocity_array,_delay);
	sleep _delay;
	_vehicleID setVelocity _velocity_array;
};

Navy_Vehicle_FillCargo =
{
	FUN_ARGS_2(_unit_template,_amount);
	DECLARE(_group) = createGroup ([_unit_template] call adm_common_fnc_getUnitTemplateSide);
	PVT_2(_i,_cargo_unit);
	for "_i" from 1 to _amount do
	{
		_cargo_unit = [_unit_template,_group] call Navy_Units_SpawnCargoUnit;
	};
	DEBUG
	{
		Navy_Cargo_Unit_Groups pushBack _group;
		[["Cargo Unit group created: %1",_group]] call Navy_Debug_HintRPT;
	};
	_group;
};

Navy_Vehicle_CargoUnassign =
{
	FUN_ARGS_2(_cargo_group,_delay);
	if (isNil "_delay") then
	{
		_delay = NAVY_DEFAULT_PARADROP_DELAY;
	};
	{
		unassignVehicle _x;
		sleep _delay;
	} forEach units _cargo_group;
	DEBUG
	{
		[["Cargo Unit Group: %1 has been unassigned from their vehicle",_cargo_group]] call Navy_Debug_HintRPT;
	};
};

Navy_Vehicle_CargoAction =
{
	FUN_ARGS_3(_cargo_group,_action,_delay);
	if (isNil "_delay") then
	{
		_delay = NAVY_DEFAULT_PARADROP_DELAY;
	};
	{
		(_x) action [_action, vehicle _x];
		sleep _delay;
	} forEach units _cargo_group;
	DEBUG
	{
		[["Cargo Unit Group: %1 have been assigned action: %2",_cargo_group,_action]] call Navy_Debug_HintRPT;
	};
};

Navy_Vehicle_CargoGetOut =
{
	FUN_ARGS_2(_cargo_group,_delay);
	if (isNil "_delay") then
	{
		_delay = NAVY_DEFAULT_PARADROP_DELAY;
	};
	{
		unassignVehicle _x;
		(_x) action ["GETOUT", vehicle _x];
		sleep _delay;
	} forEach units _cargo_group;
	DEBUG
	{
		[["Cargo Unit Group: %1 have been ordered to get out",_cargo_group]] call Navy_Debug_HintRPT;
	};
};

Navy_Vehicle_EjectCargo =
{
	FUN_ARGS_2(_cargo_group,_delay);
	if (isNil "_delay") then
	{
		_delay = NAVY_DEFAULT_PARADROP_DELAY;
	};
	{
		moveOut _x;
		unassignVehicle _x;
		_x setVelocity [0,0,-5];
		sleep _delay;
	} forEach units _cargo_group;
	DEBUG
	{
		[["Cargo Unit Group: %1 has paradropped successfully.",_cargo_group]] call Navy_Debug_HintRPT;
	};
};

Navy_Vehicle_Animation_Door =
{
	FUN_ARGS_3(_vehicleID,_door,_phase);
	_vehicleID animateDoor [_door,_phase,false];
};

Navy_Vehicle_Animation_OpenDoor =
{
	FUN_ARGS_2(_vehicleID,_door);
	[_vehicleID,_door,1] call Navy_Vehicle_Animation_Door;
};

Navy_Vehicle_Animation_CloseDoor =
{
	FUN_ARGS_2(_vehicleID,_door);
	[_vehicleID,_door,0] call Navy_Vehicle_Animation_Door;
};

Navy_Vehicle_Animation_OpenDoorArray =
{
	FUN_ARGS_2(_vehicleID,_door_array);
	{
		[_vehicleID,_x] call Navy_Vehicle_Animation_OpenDoor;
	} forEach _door_array;
};

Navy_Vehicle_Animation_CloseDoorArray =
{
	FUN_ARGS_2(_vehicleID,_door_array);
	{
		[_vehicleID,_x] call Navy_Vehicle_Animation_CloseDoor;
	} forEach _door_array;
};

Navy_Vehicle_RemoveWeapon =
{
	FUN_ARGS_3(_vehicleID,_turret_path,_weapon_name);
	_vehicleID removeWeaponTurret [_weapon_name,_turret_path];
	DEBUG
	{
		[["Vehicle: %1 has had weapon: %2 removed from turret path: %3",_vehicleID,_weapon_name,_turret_path]] call Navy_Debug_HintRPT;
	};
};

Navy_Vehicle_RemoveSelectedWeapons =
{
	FUN_ARGS_1(_vehicleID);
	PVT_1(_i);
	DECLARE(_ordnance) = [CONFIG_TYPE_ARRAY,"Vehicles",(typeOf _vehicleID),"Ordnance"] call Navy_Config_GetConfigValue;
	DECLARE(_amount) = (count _ordnance);
	if (_amount > 0) then
	{
		_amount = _amount / 2;
		for "_i" from 0 to _amount step 2 do
		{
			[_vehicleID,(_ordnance select _i),(_ordnance select (_i + 1))] call Navy_Vehicle_RemoveWeapon;
		};
	}
	else
	{
		DEBUG
		{
			[["Vehicle: %1 did not have any weapons removed",_vehicleID]] call Navy_Debug_HintRPT;
		};
	};
};

Navy_Vehicle_CleanUp =
{
	FUN_ARGS_1(_vehicleID);
	DEBUG
	{
		[["Vehicle %1 with crew %2 are being deleted",_vehicleID,(crew _vehicleID)]] call Navy_Debug_HintRPT;
		DECLARE(_waypoints) = waypoints _vehicleID; // Required to remove debug markers
		PVT_1(_i);
		for "_i" from 1 to (count _waypoints) do // waypoint 0 does not have a debug marker attached
		{
			deleteMarkerLocal (str(_waypoints select _i));
		};
	};
	sleep 1;
	{
		deleteVehicle _x;
	} forEach (crew _vehicleID);
	deleteVehicle _vehicleID;
};
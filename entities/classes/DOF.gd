extends Resource
class_name DoF
tool

enum Axis {
	X,
	Y,
	Z
}

enum RetractMode {
	RETRACTS_CLOSED,
	RETRACTS_OPEN,
	NO_RETRACT
}

enum DoFMode {
	ROTATION,
	TRANSLATION
}

export(DoFMode) var mode: int = DoFMode.TRANSLATION;
export(Axis) var primary_axis: int = Axis.X;
export(Axis) var secondary_axis: int;

export(float) var open_rom: float = 0# setget _set_open_rom;
export(float) var close_rom: float = 0# setget _set_close_rom;

export(RetractMode) var retract_mode: int = RetractMode.NO_RETRACT# setget _set_retract_mode;
export(float) var retract_speed: float = 0# setget _set_retract_speed;

export(float) var max_open_speed: float = 0# setget _set_max_open_speed;
export(float) var max_close_speed: float = 0# setget _set_max_close_speed;

export(int) var num_ticks: int = 0

func _set_open_rom(val: float):
	if mode == DoFMode.ROTATION:
		open_rom = deg2rad(val)
	else:
		open_rom = val
		
func _set_close_rom(val: float):
	if mode == DoFMode.ROTATION:
		close_rom = deg2rad(val)
	else:
		close_rom = val
		
func _set_retract_mode(val: int):
	retract_mode = retract_mode
	if mode == DoFMode.ROTATION:
		match retract_mode:
			RetractMode.RETRACTS_CLOSED:
				retract_speed = -retract_speed
			RetractMode.RETRACTS_OPEN:
				retract_speed = retract_speed
				
func _set_retract_speed(val: float):
	if mode == DoFMode.ROTATION:
		match retract_mode:
			RetractMode.RETRACTS_CLOSED:
				retract_speed = -deg2rad(val)
			RetractMode.RETRACTS_OPEN:
				retract_speed = deg2rad(val)
	else:
		retract_speed = val

func _set_max_open_speed(val: float):
	if mode == DoFMode.ROTATION:
		max_open_speed = deg2rad(val)
	else:
		max_open_speed = val
		
func _set_max_close_speed(val: float):
	if mode == DoFMode.ROTATION:
		max_close_speed = deg2rad(val)
	else:
		max_close_speed = val

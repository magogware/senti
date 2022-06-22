extends Resource
class_name DoF

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

export(float) var open_rom: float = 0;
export(float) var close_rom: float = 0;

export(RetractMode) var retract_mode: int = RetractMode.NO_RETRACT;
export(float) var retract_speed: float = 0;

export(float) var max_open_speed: float = 0;
export(float) var max_close_speed: float = 0;

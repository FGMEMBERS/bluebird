# ===== Bluebird Explorer Hovercraft  version 10.4 for FlightGear 1.9 OSG =====

# strobes -----------------------------------------------------------
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
var strobe_light = aircraft.light.new("sim/model/bluebird/lighting/strobe1", [0.1, 0.2, 0.1, 1.4], strobe_switch);
strobe_light.interval = 0.1;
strobe_light.switch( 1 );

# beacons -----------------------------------------------------------
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/bluebird/lighting/beacon1", [0.25, 1.55], beacon_switch);

# interior lighting -------------------------------------------------
var alert_switch_Node = props.globals.getNode("controls/lighting/alert", 1);
aircraft.light.new("sim/model/bluebird/lighting/alert1", [2.0, 0.75], alert_switch_Node);
# /sim/model/bluebird/lighting/alert1/state is destination, alert_level drifts to chase alert_state

# Hull and fuselage colors and livery ====================================
aircraft.livery.init("Aircraft/bluebird/Models/Liveries");
aircraft.livery.select(getprop("sim/model/livery/name"));

# Add second popupTip to avoid being overwritten by primary joystick messages ==
var tipArg2 = props.Node.new({ "dialog-name" : "PopTip2" });
var currTimer2 = 0;
var popupTip2 = func {
	var delay2 = if(size(arg) > 1) {arg[1]} else {1.5};
	var tmpl2 = { name : "PopTip2", modal : 0, layout : "hbox",
		y: gui.screenHProp.getValue() - 110,
		text : { label : arg[0], padding : 6 } };

	fgcommand("dialog-close", tipArg2);
	fgcommand("dialog-new", props.Node.new(tmpl2));
	fgcommand("dialog-show", tipArg2);

	currTimer2 = currTimer2 + delay2;
	var thisTimer2 = currTimer2;

		# Final argument is a flag to use "real" time, not simulated time
	settimer(func { if(currTimer2 == thisTimer2) { fgcommand("dialog-close", tipArg2); } }, delay2, 1);
}

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }
var RAD2DEG = 180 / math.pi;

# === global nodes, and constants ===================================

# view nodes and offsets --------------------------------------------
var zNoseNode = props.globals.getNode("sim/view/config/y-offset-m", 1);
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var zViewNode = props.globals.getNode("sim/current-view/y-offset-m", 1);
var hViewNode = props.globals.getNode("sim/current-view/heading-offset-deg", 1);
#var pViewNode = props.globals.getNode("sim/current-view/pitch-offset-deg", 1);
#var rViewNode = props.globals.getNode("sim/current-view/roll-offset-deg", 1);
var vertical_offset_ft = 0.5830;
	# keep shadow off ground at expense of keeping wheels and gear
	# at ground level. Also adjust Shadow in bluebird.xml line# 13997 with negative
	# of change. Default offset in model = 0.483 feet for gear on ground
	# or 0.583 feet to match with shadow at offset of -0.1 meters.

# nav lights --------------------------------------------------------
var nav_lights_state = props.globals.getNode("sim/model/bluebird/lighting/nav-lights-state", 1);
var nav_light_switch = props.globals.getNode("sim/model/bluebird/lighting/nav-light-switch", 1);

# landing lights ----------------------------------------------------
var landing_light_switch = props.globals.getNode("sim/model/bluebird/lighting/landing-lights", 1);

# doors -------------------------------------------------------------
var doors = [];
var doortiming = [3, 3, 1, 1, 2, 9];  # different timing for different size doors
var door0_pos = props.globals.getNode("sim/model/bluebird/doors/door[0]/position-norm", 1);
var door1_pos = props.globals.getNode("sim/model/bluebird/doors/door[1]/position-norm", 1);
var door5_pos = props.globals.getNode("sim/model/bluebird/doors/door[5]/position-norm", 1);
	# adjusted positions are a workaround for gear up modes, so that doors do not
	#  dig into the ground. Would be better if interpolation could be combined
	#  with max or other property modifier.
var door0_adjpos = props.globals.getNode("sim/model/bluebird/doors/door[0]/position-adj", 1);
var door1_adjpos = props.globals.getNode("sim/model/bluebird/doors/door[1]/position-adj", 1);
var door5_adjpos = props.globals.getNode("sim/model/bluebird/doors/door[5]/position-adj", 1);

# gear --------------------------------------------------------------
var gear = [];
append(gear, aircraft.door.new("gear/gear[0]", 3));
append(gear, aircraft.door.new("gear/gear[1]", 2.8));

# movement and position ---------------------------------------------
var airspeed_kt_Node = props.globals.getNode("velocities/airspeed-kt", 1);
var abs_airspeed_Node = props.globals.getNode("velocities/abs-airspeed-kt", 1);

# maximum speed for ufo model at 100% throttle ----------------------
var maxspeed = props.globals.getNode("engines/engine/speed-max-mps", 1);
var speed_mps = [1, 20, 50, 100, 200, 500, 1000, 2000, 5000, 11176, 20000];
# level 9 maximum speed 11176mps is 25000mph. aka escape velocity.
# level 10 is not really useful without interplanetary capabilities,
#  and is thus not allowed below the boundary to space.
var limit = [1, 3, 6, 7, 1, 3, 6, 10];
var current = props.globals.getNode("engines/engine/speed-max-powerlevel", 1);

# VTOL counter-grav -------------------------------------------------
var joystick_elevator = props.globals.getNode("input/joysticks/js/axis[1]/binding/setting", 1);
var countergrav = { input_type: 0, momentum_watch: 0, momentum: 0, up_factor: 0, request: 0, control_factor: 6 };
	# input_type ; 1 = keyboard, 2 = joystick, 3 = mouse
	# request = for during startup, includes timer to cancel request if no further requests are made. Returns to zero after complete.
	# control_factor = multiplier or power level from lever next to throttle, for VTOL movement
var joystick_collective = props.globals.getNode("controls/engines/countergrav-factor", 1);

# ground detection and adjustment -----------------------------------
var altitude_ft_Node = props.globals.getNode("position/altitude-ft", 1);
var ground_elevation_ft = props.globals.getNode("position/ground-elev-ft", 1);
var pitch_deg = props.globals.getNode("orientation/pitch-deg", 1);
var roll_deg = props.globals.getNode("orientation/roll-deg", 1);
var roll_control = props.globals.getNode("controls/flight/aileron", 1);
var pitch_control = props.globals.getNode("controls/flight/elevator", 1);

# define damage variables -------------------------------------------
	# significant damage occurs above 50 impacts, each exceeding 600 fps per clock cycle
	# changing this number also requires changing <value> and <ind> in both xml files.
var destruction_threshold = 50;

# === define nasal non-local variables at startup ===================
# interior lighting and emissions -----------------------------------
	# surface# color/location 
	#  0       Overhead lights
	#  1       Blue        Rug/Floor		Livery
	#  2       Light blue  Door panels		Livery
	#  3       Tan         Upper walls		Livery
	#  4       Grey45      Lower walls and covers	Livery
	#  5       Grey36      Panel surfaces
	#  6       Tan         Chairs
	#  7       Brown       Rear hatch non-skid flooring
	#  8       Grey80      Light fixture housing
	#  9       Grey60      Buttons
	#  A       Grey14      Door seals
	#  B       WHITE       Door markers/lights
	#  C       YELLOW      Hatch Safety marker Lights
var livery_I1AR = 0;	# Ambient from livery, only updates upon livery change
var livery_I1AG = 0;
var livery_I1AB = 1;
var livery_I1R_add = 0.5;  # factor to calculate ambient from livery
var livery_I1G_add = 0.0;  #  accounting for alert_level
var livery_I1B_add = -0.25;
var livery_I1R = 0;	# calculated emissions. material 1 flooring (red, green, blue)
var livery_I1G = 0;
var livery_I1B = 0;
var livery_I2AR = 0.50;
var livery_I2AG = 0.70;
var livery_I2AB = 0.90;
var livery_I2R_add = 0.0;
var livery_I2G_add = 0.0;
var livery_I2B_add = 0.0;
var livery_I2R = 0.0;
var livery_I2G = 0.0;
var livery_I2B = 0.0;
var livery_I3AR = 0.70;
var livery_I3AG = 0.69;
var livery_I3AB = 0.55;
var livery_I3R_add = 0.0;
var livery_I3G_add = 0.0;
var livery_I3B_add = 0.0;
var livery_I3R = 0.0;
var livery_I3G = 0.0;
var livery_I3B = 0.0;
var livery_I4AR = 0.6;
var livery_I4AG = 0.6;
var livery_I4AB = 0.6;
var livery_I4R_add = 0;
var livery_I4G_add = 0;
var livery_I4B_add = 0;
var livery_I4R = 0;
var livery_I4G = 0;
var livery_I4B = 0;
var livery_I5AR = 0.36;
var livery_I5AG = 0.37;
var livery_I5AB = 0.32;
var livery_I5R_add = 0.18;
var livery_I5G_add = -0.0925;
var livery_I5B_add = -0.08;
var livery_I5R = 0;
var livery_I5G = 0;
var livery_I5B = 0;
var livery_I6AR = 0.7;
var livery_I6AG = 0.69;
var livery_I6AB = 0.59;
var livery_I6R_add = 0.3;
var livery_I6G_add = -0.1725;
var livery_I6B_add = -0.1475;
var livery_I6R = 0;
var livery_I6G = 0;
var livery_I6B = 0;
var livery_I7AR = 0.25;
var livery_I7AG = 0.25;
var livery_I7AB = 0.17;
var livery_I7R_add = 0.125;
var livery_I7G_add = -0.06;
var livery_I7B_add = -0.0425;
var livery_I7R = 0;
var livery_I7G = 0;
var livery_I7B = 0;
var livery_I8AR = 0.8;
var livery_I8AGB = 0.8;
var livery_I8R_add = 0.2;
var livery_I8GB_add = -0.2;
var livery_I8R = 0;
var livery_I8GB = 0;
var livery_I9AR = 0.6;
var livery_I9AGB = 0.6;
var livery_I9R_add = 0.2;
var livery_I9GB_add = -0.2;
var livery_I9R = 0;
var livery_I9GB = 0;
var livery_IAARGB = 0.02;

var button_G1 = 0;	# remember current button colors to limit spending time in setprop.
var button_G2 = 0;	# binary operators: 1 = red, 2 = green, 4 = blue, 8 = dim
var button_G3 = 0;
var button_G4 = 0;
var button_LT1 = 0;
var button_LT2 = 0;
var button_LT6 = 0;	# includes LT3 thru 6
var button_LT7 = 0;
var button_LT8 = 0;
var button_LT9 = 0;
var button_RT1 = 0;
var button_RT2 = 0;
var button_RT3 = 0;
var button_RT4 = 0;
var button_RT5 = 0;
var button_RT6 = 0;
var button_RT7 = 0;
var button_RT8 = 0;
var button_RT9 = 0;
var button_lit = 0;	# brightness. global to remember between updates
var interior_lighting_base_R = 0;   # base for calculating individual colors inside
var interior_lighting_base_GB = 0;  # Red, and GreenBlue
var unlit_lighting_base = 0;     # also includes alert level and sun angle
var panel_lighting_R = 0;
var panel_lighting_GB = 0;
var panel_ambient_R = 0;
var panel_ambient_GB = 0;
var panel_specular = 0;
var alert_switch = 0;
var int_switch = 1;
# specular: 1 = full reflection, 0 = no reflection from sun

# ------ components ------
var nacelleL_attached = 1;
var nacelleR_attached = 1;
# -------- damage --------
var damage_count = 0;
var lose_altitude = 0;   # drift or sink when damaged or power shuts down
var damage_blocker = 0;
# ------ nav lights ------
var sun_angle = 0;	# down to 0 at high noon, 2 at midnight, depending on latitude
var visibility = 16000;		# 16Km
# --------- gear ---------
var gear_looping = 0;          # keep track of gear loop, so there is only one instance per call
var gear_position = 1;
var gear_mode = 0;             # 0 = full pressure, stiff gear (or) 1 = lower, settle closer to ground
var active_gear_button = [1, 3];
var gear_height = 2.47;           # Height of gear
		# zero when gear down at base of model offset.
var wheel_looping = 0;         # keep track of wheel loop
var wheel_position = 0;
var wheels_switch = 0;           # 0 = not extended, land on skid plates (or) 1 = extend wheels down
var wheel_height = 0;
var contact_altitude = 0;      # the altitude at which the model touches ground (modifiers are gear and pitch/roll with hover_add)
var gear_request = 1;          # direction = down
var gear_x_pitch_deg = 0;      # pitch and roll for ground slope under gear contact points
var gear_y_roll_deg = 0;
var groundslope_enabled = 0;
# --------- doors --------
door0_adjpos.setValue(0);
door1_adjpos.setValue(0);
door5_adjpos.setValue(0);
var door0_position = 0;
var door1_position = 0;
var door5_position = 0;
var active_door = 0;
# -------- engines -------
	# /sim/model/bluebird/lighting/power-glow from fusion reactor under hull cover,
	#   visible only when engine cover is off
	# engine refers to countergrav or hover-fans (your choice),
	# powered by a fusion reactor.
	# /sim/model/bluebird/lighting/engine-glow is a combination of engine sounds
	# counter-grav provides hover capability (exclusively under 150 kts)
	# wave-drive propulsion is based on quantum particle wave physics
	# using the nacelles to create a wave guide.
	# stage 1 covers all forward flight modes up to 3900 kts.
	# stage 2 "increases energy flow" so that orbital velocity can be attained
var power_switch = 1;		# no request in-between. power goes direct to state.
var reactor_request = 1;	# Request. level follows.
var reactor_level = 1;		# follows request, provides spin down delay when going off
var wave1_request = 1;
var wave1_level = 1;
var wave2_request = 0;
var wave2_level = 0;
var reactor_state = 0;		# destination level for reactor_level
var reactor_drift = 0;		# follows reactor_state, equal to engines_glow_level
var wave_state = 0;		# state = destination level
var wave_drift = 0;
# ------- movement -------
airspeed_kt_Node.setValue(0);
abs_airspeed_Node.setValue(0);
var pitch_d = 0;
var roll_d = 0;
var airspeed = 0;
var asas = 0;
var hover_add = 0;              # increase in altitude to keep nacelles and nose from touching ground
var hover_reset_timer = 0;      # timer so vtol movement in yoke is not jerky
var hover_target_altitude = 0;  # ground_elevation + hover_ft (not for comparing to contact point)
var h_contact_target_alt = 0;   # adjusted for contact altitude
var skid_last_value = 0;
# ------ submodel control -----
var nacelle_L_venting = 0;
var nacelle_R_venting = 0;
var venting_direction = -2;     # start disabled. -1=backward, 1=forward, 0=both
var shutdown_venting = 0;
# --- ground detection ---
var init_agl = 5;     # some airports reported elevation change after movement begins
var ground_near = 1;  # instrument panel indicator lights
var ground_warning = 1;
# ----- maximum speed ----
maxspeed.setValue(500);
current.setValue(5);  # needed for engine-digital panel
var cpl = 5;          # current power level
var current_to = 5;   # distinguishes between change_maximum types. Current or To
var max_drift = 0;    # smoothen drift between maxspeed power levels
var max_lose = 0;     # loss of momentum after shutdown of engines
var max_from = 5;
var max_to = 5;
# -------- sounds --------
var sound_level = 0;
var sound_state = 0;
var alert_level = 0;
# -------
var cockpit_locations = [ { x: -7.35, y: 0, z: [1.47, 1.70, 1.88], h: 0, p: -2, fov: 55 },
		{ x: -5.6, y: 0, z: [2.1, 2.33, 2.47], h: 0, p: 0, fov: 55 },
		{ x: -5.94, y: -0.73, z: [1.47, 1.68, 1.79], h: 0, p: 0, fov: 55 },
		{ x: -5.93, y: 0.77, z: [1.47, 1.68, 1.79], h: 0, p: 0, fov: 55 },
		{ x: -3.3, y: 0, z: [2.1, 2.32, 2.43], h: 0, p: 0, fov: 55 },
		{ x: -2.55, y: -1.9, z: [2.1, 2.3, 2.4], h: 0, p: 0, fov: 55 } ];	# left doorway
		# Waldo eye height is 1.625m
var cockpitView = 0;
var active_nav_button = [3, 3, 1];
var active_landing_button = [3, 1, 3];
var config_dialog = nil;
var systems_dialog = nil;
var livery_dialog = nil;

var reinit_bluebird = func {	# reset the above variables
	damage_blocker = 0;
	damage_count = 0;
	lose_altitude = 0;
	gear_looping = 0;
	gear_position = 1;
	gear_mode = 0;
	active_gear_button = [1, 3];
	gear_request = 1;
	gear_x_pitch_deg = 0;
	gear_y_roll_deg = 0;
	gear_height = 2.47;
	wheels_switch = 0;
	wheel_looping = 0;
	wheel_position = 0;
	wheel_height = 0;
	contact_altitude = 0;
	groundslope_enabled = 0;
	door0_position = 0;
	door1_position = 0;
	door5_position = 0;
	active_door = 0;
	power_switch = 1;
	reactor_request = 1;
	reactor_level = 1;
	wave1_request = 1;
	wave1_level = 1;
	wave2_request = 0;
	wave2_level = 0;
	countergrav.request = 0;
	countergrav.control_factor = 6;
	reactor_state = 0;
	reactor_drift = 0;
	wave_state = 0;
	wave_drift = 0;
	pitch_d = 0;
	roll_d = 0;
	airspeed = 0;
	asas = 0;
	hover_reset_timer = 0;
	hover_add = 0;
	hover_target_altitude = 0;
	h_contact_target_alt = 0;
	skid_last_value = 0;
	nacelle_L_venting = 0;
	nacelle_R_venting = 0;
	venting_direction = -2;
	shutdown_venting = 0;
	init_agl = 5;
	cpl = 5;
	current_to = 5;
	max_drift = 0;
	max_lose = 0;
	max_from = 5;
	max_to = 5;
	sound_state = 0;
	alert_level = 0;
	int_switch = 1;
	interior_lighting_base_R = 0;
	interior_lighting_base_GB = 0;
	unlit_lighting_base = 0;
	panel_lighting_R = 0;
	panel_lighting_GB = 0;
	panel_ambient_R = 0;
	panel_ambient_GB = 0;
	panel_specular = 0;
	button_G1 = 0;
	button_G2 = 0;
	button_G3 = 0;
	button_G4 = 0;
	button_LT1 = 0;
	button_LT2 = 0;
	button_LT6 = 0;
	button_LT7 = 0;
	button_LT8 = 0;
	button_LT9 = 0;
	button_RT1 = 0;
	button_RT2 = 0;
	button_RT3 = 0;
	button_RT4 = 0;
	button_RT5 = 0;
	button_RT6 = 0;
	button_RT7 = 0;
	button_RT8 = 0;
	button_RT9 = 0;
	button_lit = 0;
	cockpitView = 0;
	cycle_cockpit(0);
	active_nav_button = [3, 3, 1];
	active_landing_button = [3, 1, 3];
	name = "bluebird-config";
	if (config_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		config_dialog = nil;
	}
	if (systems_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		systems_dialog = nil;
	}
	if (getprop("sim/ai-traffic/enabled") or getprop("sim/multiplay/rxport")) {
		setprop("instrumentation/tracking/enabled", 1);
	}
}

 setlistener("sim/signals/reinit", func {
	reinit_bluebird();
 });

# display screens ---------------------------------------------------
var screen_3R_on = 0;	# debug screen at 3 right
setlistener("instrumentation/display-screens/enabled-3R", func(n) { screen_3R_on = n.getValue() }, 1, 0);

var screen_4R_on = 0;	# hover diagnostics screen at 4 right
setlistener("instrumentation/display-screens/enabled-4R", func(n) { screen_4R_on = n.getValue() }, 1, 0);

var screen_5R_on = 0;	# countergrav diagnostics screen at 5 right
setlistener("instrumentation/display-screens/enabled-5R", func(n) { screen_5R_on = n.getValue() }, 1, 0);

# door functions ----------------------------------------------------

var init_doors = func {
	var id_i = 0;
	foreach (var id_d; props.globals.getNode("sim/model/bluebird/doors").getChildren("door")) {
		if (doortiming[id_i] == 1) {		# double leaf inside
			append(doors, aircraft.door.new(id_d, 1.25));
		} elsif (doortiming[id_i] == 2) {	# single leaf inside
			append(doors, aircraft.door.new(id_d, 1.73));
		} elsif (doortiming[id_i] == 3) {	# front side hatches
			append(doors, aircraft.door.new(id_d, 2.255));
		} else {				# rear hatch
			append(doors, aircraft.door.new(id_d, 9.0));
		}
		id_i += 1;
	}
}
settimer(init_doors, 0);

var next_door = func { select_door(active_door + 1) }

var previous_door = func { select_door(active_door - 1) }

var select_door = func(sd_number) {
	active_door = sd_number;
	if (active_door < 0) {
		active_door = size(doors) - 1;
	} elsif (active_door >= size(doors)) {
		active_door = 0;
	}
	gui.popupTip("Selecting " ~ doors[active_door].node.getNode("name").getValue());
}

var door_coord_x_m = [-2.55, -2.55, -1.733, -0.608, -0.083, 9.223];
var door_coord_y_m = [-1.75, 1.75, 0, -0.66, 0, 0];

var door_update = func(door_number) {
	var c_view = getprop("sim/current-view/view-number");
	var y_position = yViewNode.getValue();
	var x_position = xViewNode.getValue();
	if (door_number == 0) {
		var gear_position2 = (gear_position * gear_position * 0.204304) + (gear_position * 0.0627) + 0.733;
		door0_position = door0_pos.getValue();
		if (door0_position > gear_position2) {
			door0_adjpos.setValue(gear_position2);
		} else {
			door0_adjpos.setValue(door0_position);
		}
		# check for closing door while standing on ramp
		if (c_view == 0 and door0_position < 0.62) {
			if (y_position < -1.3) {
				if (x_position > -3.2 and x_position < -2.0) {
					# between front hatches
					yViewNode.setValue(-1.3);
				}
			}
		}
		if (door0_position < 0.62) {
			if (getprop("sim/model/bluebird/crew/walker/y-offset-m") < -1.3) {
				var walker_x_position = getprop("sim/model/bluebird/crew/walker/x-offset-m");
				if (walker_x_position > -3.2 and walker_x_position < -2.0) {
					# between front hatches
					setprop("sim/model/bluebird/crew/walker/y-offset-m", -1.3);
				}
			}
		}
		setprop("sim/model/bluebird/sound/door0-volume", doorProximityVolume(c_view, 0, x_position, y_position));
		hatch_lighting_update();
	} elsif (door_number == 1) {
		var gear_position2 = (gear_position * gear_position * 0.204304) + (gear_position * 0.0627) + 0.733;
		door1_position = door1_pos.getValue();
		if (door1_position > gear_position2) {
			door1_adjpos.setValue(gear_position2);
		} else {
			door1_adjpos.setValue(door1_position);
		}
		if (c_view == 0 and door1_position < 0.62) {
			if (y_position > 1.3) {
				if (x_position > -3.2 and x_position < -2.0) {
					# between front hatches
					yViewNode.setValue(1.3);
				}
			}
		}
		if (door1_position < 0.62) {
			if (getprop("sim/model/bluebird/crew/walker/y-offset-m") > 1.3) {
				var walker_x_position = getprop("sim/model/bluebird/crew/walker/x-offset-m");
				if (walker_x_position > -3.2 and walker_x_position < -2.0) {
					# between front hatches
					setprop("sim/model/bluebird/crew/walker/y-offset-m", 1.3);
				}
			}
		}
		setprop("sim/model/bluebird/sound/door1-volume", doorProximityVolume(c_view, 1, x_position, y_position));
		hatch_lighting_update();
	} elsif (door_number == 2) {
		setprop("sim/model/bluebird/sound/door2-volume", doorProximityVolume(c_view, 2, x_position, y_position));
	} elsif (door_number == 3) {
		setprop("sim/model/bluebird/sound/door3-volume", doorProximityVolume(c_view, 3, x_position, y_position));
	} elsif (door_number == 4) {
		setprop("sim/model/bluebird/sound/door4-volume", doorProximityVolume(c_view, 4, x_position, y_position));
	} elsif (door_number == 5) {
		var gear_position2 = clamp(((gear_position * gear_position * 0.1207) + (gear_position * 0.2299) + 0.79), 0, 1);
		door5_position = door5_pos.getValue();
		if (door5_position > 0.66 and airspeed > 40) {
			door5_position = 0.66;
		}
		if (door5_position > gear_position2) {
			door5_adjpos.setValue(gear_position2);
		} else {
			door5_adjpos.setValue(door5_position);
		}
		if (c_view == 0 and door5_position < 0.62) {
			if (x_position > 8.9) {
				xViewNode.setValue(8.9);
			}
		}
		if (door5_position < 0.62) {
			if (getprop("sim/model/bluebird/crew/walker/x-offset-m") > 8.9) {
				setprop("sim/model/bluebird/crew/walker/x-offset-m", 8.9);
			}
		}
		setprop("sim/model/bluebird/sound/door5-volume", doorProximityVolume(c_view, 5, x_position, y_position));
		hatch_lighting_update();
	}
}

setlistener("sim/model/bluebird/doors/door[0]/position-norm", func {
	door_update(0);
});

setlistener("sim/model/bluebird/doors/door[1]/position-norm", func {
	door_update(1);
});

setlistener("sim/model/bluebird/doors/door[2]/position-norm", func {
	door_update(2);
});

setlistener("sim/model/bluebird/doors/door[3]/position-norm", func {
	door_update(3);
});

setlistener("sim/model/bluebird/doors/door[4]/position-norm", func {
	door_update(4);
});

setlistener("sim/model/bluebird/doors/door[5]/position-norm", func {
	door_update(5);
});

var toggle_door = func {
	if ((active_door <= 1 and airspeed > 1000) or 
			(active_door == 5 and airspeed > 3900)) {
		if ((active_door == 0 and door0_position == 0) or
				(active_door == 1 and door1_position == 0) or
				(active_door == 5 and door5_position == 0)) {
			popupTip2("Unable to comply. Velocity too fast for safe deployment.");
			return 2;
		}
	}
	doors[active_door].toggle();
	var td_dr = doors[active_door].node.getNode("position-norm").getValue();
	setprop("sim/model/bluebird/sound/door-direction", td_dr);  # attempt to determine direction

	if (active_door == 0) {
		setprop("sim/model/bluebird/sound/hatch0-trigger", 1);
		settimer(reset_trigger0, 1);
	} elsif (active_door == 1) {
		setprop("sim/model/bluebird/sound/hatch1-trigger", 1);
		settimer(reset_trigger1, 1);
	} elsif (active_door == 5) {
		setprop("sim/model/bluebird/sound/hatch5-trigger", 1);
		settimer(reset_trigger5, 1);
	}
	settimer(panel_lighting_loop, 0.05);
}

# give hatch sound effect one second to play ------------------------
var reset_trigger0 = func {
	setprop("sim/model/bluebird/sound/hatch0-trigger", 0);
}

var reset_trigger1 = func {
	setprop("sim/model/bluebird/sound/hatch1-trigger", 0);
}

var reset_trigger5 = func {
	setprop("sim/model/bluebird/sound/hatch5-trigger", 0);
}

var doorProximityVolume = func (current_view, door,x,y) {
	if (current_view) {	# outside view
		if (current_view == view.indexof("Walk View")) {
			var distToDoor_m = walk.distFromCraft(getprop("sim/walker/latitude-deg"),getprop("sim/walker/longitude-deg")) - 10;
			if (distToDoor_m < 0) {
				distToDoor_m = 0;
			}
			if (door >=2 and door <= 4) {
				distToDoor_m = distToDoor_m * 3;
			}
		} else {
			if (door >=2 and door <=4) {
				return 0.1;
			} else {
				return 0.5;
			}
		}
	} else {
		var a = (x - door_coord_x_m[door]);
		var b = (y - door_coord_y_m[door]);
		var distToDoor_m = math.sqrt(a * a + b * b);
	}
	if (distToDoor_m > 50) {
		return 0;
	} elsif (distToDoor_m > 25) {
		return (50 - distToDoor_m) / 250;
	} elsif (distToDoor_m > 10) {
		return (0.1 + ((25 - distToDoor_m) / 60));
	} else {
		return (0.35 + ((10 - distToDoor_m) / 15.3846));
	}
}

# systems -----------------------------------------------------------

setlistener("sim/model/bluebird/systems/power-switch", func(n) {
	power_switch = n.getValue();
	if (damage_count) {
		var flaringL = getprop("ai/submodels/engine-L-flaring");
		var flaringR = getprop("ai/submodels/engine-R-flaring");
		if (!power_switch and flaringL) {
			setprop ("ai/submodels/engine-L-flaring", 0);
		} elsif (power_switch and !nacelleL_attached) {
			setprop ("ai/submodels/engine-L-flaring", 1);
		}
		if (!power_switch and flaringR) {
			setprop ("ai/submodels/engine-R-flaring", 0);
		} elsif (power_switch and !nacelleR_attached) {
			setprop ("ai/submodels/engine-R-flaring", 1);
		}
	}
});

setlistener("controls/engines/countergrav-factor", func(n) { countergrav.control_factor = n.getValue() },, 0);

setlistener("sim/model/bluebird/systems/reactor-request", func(n) { reactor_request = n.getValue() },, 0);

setlistener("sim/model/bluebird/systems/reactor-level", func(n) { reactor_level = n.getValue() },, 0);

setlistener("sim/model/bluebird/systems/wave1-request", func(n) { wave1_request = n.getValue() },, 0);

setlistener("sim/model/bluebird/systems/wave1-level", func(n) { wave1_level = n.getValue() },, 0);

setlistener("sim/model/bluebird/systems/wave2-request", func(n) { wave2_request = n.getValue() },, 0);

# interior ----------------------------------------------------------

setlistener("sim/model/bluebird/lighting/interior-switch", func(n) { int_switch = n.getValue() },, 0);

var isodd = func(n) { int(n / 2) * 2 != int(n) };

# lighting and texture ----------------------------------------------

setlistener("environment/visibility-m", func(n) { visibility = n.getValue() }, 1, 0);

var emis_calc = 0.7;	# maximum emission at night.
setlistener("sim/model/bluebird/lighting/overhead/emission/factor", func(n) { emis_calc = n.getValue() }, 1, 0);
var amb_calc = 0.1;
setlistener("sim/model/bluebird/lighting/interior-ambient-factor", func(n) { amb_calc = n.getValue() }, 1, 0);

var set_I1_ambient = func {
	# emission calculation base
	livery_I1R = livery_I1AR + (livery_I1R_add * alert_level * int_switch * power_switch);
	livery_I1G = livery_I1AG + (livery_I1G_add * alert_level * int_switch * power_switch);
	livery_I1B = livery_I1AB + (livery_I1B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior1-flooring/amb-dif/red", livery_I1R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior1-flooring/amb-dif/green", livery_I1G * amb_calc);
	setprop("sim/model/bluebird/lighting/interior1-flooring/amb-dif/blue", livery_I1B * amb_calc);
}

var recalc_material_I1 = func {
	# calculate emission and ambient base levels upon loading new livery
	var red_amb_flr_R = clamp(livery_I1AR * 1.5, 0.5, 1.0);     # tint calculations
	var red_amb_flr_G = clamp(livery_I1AG * 0.75, 0, 1);
	var red_amb_flr_B = clamp(livery_I1AB * 0.75, 0, 1);
	livery_I1R_add = red_amb_flr_R - livery_I1AR;  # amount to add when calculating alert_level
	livery_I1G_add = red_amb_flr_G - livery_I1AG;
	livery_I1B_add = red_amb_flr_B - livery_I1AB;
}

var set_I2_ambient = func {
	livery_I2R = livery_I2AR + (livery_I2R_add * alert_level * int_switch * power_switch);
	livery_I2G = livery_I2AG + (livery_I2G_add * alert_level * int_switch * power_switch);
	livery_I2B = livery_I2AB + (livery_I2B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior2-door-panels/amb-dif/red", livery_I2R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior2-door-panels/amb-dif/green", livery_I2G * amb_calc);
	setprop("sim/model/bluebird/lighting/interior2-door-panels/amb-dif/blue", livery_I2B * amb_calc);
}

var recalc_material_I2 = func {
	var red_amb_flr_R = clamp(livery_I2AR * 1.5, 0.5, 1.0);
	var red_amb_flr_G = clamp(livery_I2AG * 0.75, 0, 1);
	var red_amb_flr_B = clamp(livery_I2AB * 0.75, 0, 1);
	livery_I2R_add = red_amb_flr_R - livery_I2AR;
	livery_I2G_add = red_amb_flr_G - livery_I2AG;
	livery_I2B_add = red_amb_flr_B - livery_I2AB;
}

var set_I3_ambient = func {
	livery_I3R = livery_I3AR + (livery_I3R_add * alert_level * int_switch * power_switch);
	livery_I3G = livery_I3AG + (livery_I3G_add * alert_level * int_switch * power_switch);
	livery_I3B = livery_I3AB + (livery_I3B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior3-upper-walls/amb-dif/red", livery_I3R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior3-upper-walls/amb-dif/green", livery_I3G * amb_calc);
	setprop("sim/model/bluebird/lighting/interior3-upper-walls/amb-dif/blue", livery_I3B * amb_calc);
}

var recalc_material_I3 = func {
	var red_amb_flr_R = clamp(livery_I3AR * 1.5, 0.5, 1.0);
	var red_amb_flr_G = clamp(livery_I3AG * 0.75, 0, 1);
	var red_amb_flr_B = clamp(livery_I3AB * 0.75, 0, 1);
	livery_I3R_add = red_amb_flr_R - livery_I3AR;
	livery_I3G_add = red_amb_flr_G - livery_I3AG;
	livery_I3B_add = red_amb_flr_B - livery_I3AB;
}

var set_I4_ambient = func {
	livery_I4R = livery_I4AR + (livery_I4R_add * alert_level * int_switch * power_switch);
	livery_I4G = livery_I4AG + (livery_I4G_add * alert_level * int_switch * power_switch);
	livery_I4B = livery_I4AB + (livery_I4B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior4-lower-walls/amb-dif/red", livery_I4R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior4-lower-walls/amb-dif/green", livery_I4G * amb_calc);
	setprop("sim/model/bluebird/lighting/interior4-lower-walls/amb-dif/blue", livery_I4B * amb_calc);
}

var recalc_material_I4 = func {
	var red_amb_flr_R = clamp(livery_I4AR * 1.5, 0.5, 1.0);
	var red_amb_flr_G = clamp(livery_I4AG * 0.75, 0, 1);
	var red_amb_flr_B = clamp(livery_I4AB * 0.75, 0, 1);
	livery_I4R_add = red_amb_flr_R - livery_I4AR;
	livery_I4G_add = red_amb_flr_G - livery_I4AG;
	livery_I4B_add = red_amb_flr_B - livery_I4AB;
}

var set_I5_ambient = func {
	livery_I5R = livery_I5AR + (livery_I5R_add * alert_level * int_switch * power_switch);
	livery_I5G = livery_I5AG + (livery_I5G_add * alert_level * int_switch * power_switch);
	livery_I5B = livery_I5AB + (livery_I5B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior5-console/amb-dif/red", livery_I5R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior5-console/amb-dif/green", livery_I5G * amb_calc);
	setprop("sim/model/bluebird/lighting/interior5-console/amb-dif/blue", livery_I5B * amb_calc);
}

var set_I6_ambient = func {
	livery_I6R = livery_I6AR + (livery_I6R_add * alert_level * int_switch * power_switch);
	livery_I6G = livery_I6AG + (livery_I6G_add * alert_level * int_switch * power_switch);
	livery_I6B = livery_I6AB + (livery_I6B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior6-chairs/amb-dif/red", livery_I6R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior6-chairs/amb-dif/green", livery_I6G * amb_calc);
	setprop("sim/model/bluebird/lighting/interior6-chairs/amb-dif/blue", livery_I6B * amb_calc);
}

var set_I7_ambient = func {
	livery_I7R = livery_I7AR + (livery_I7R_add * alert_level * int_switch * power_switch);
	livery_I7G = livery_I7AG + (livery_I7G_add * alert_level * int_switch * power_switch);
	livery_I7B = livery_I7AB + (livery_I7B_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/amb-dif/red", livery_I7R * amb_calc);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/amb-dif/green", livery_I7G * amb_calc);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/amb-dif/blue", livery_I7B * amb_calc);
}

var set_I8_ambient = func {
	livery_I8R = livery_I8AR + (livery_I8R_add * alert_level * int_switch * power_switch);
	livery_I8GB = livery_I8AGB + (livery_I8GB_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior8-light-frame/amb-dif/red", livery_I8R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior8-light-frame/amb-dif/gb", livery_I8GB * amb_calc);
}

var set_I9_ambient = func {
	livery_I9R = livery_I9AR + (livery_I9R_add * alert_level * int_switch * power_switch);
	livery_I9GB = livery_I9AGB + (livery_I9GB_add * alert_level * int_switch * power_switch);
	setprop("sim/model/bluebird/lighting/interior9-buttons/amb-dif/red", livery_I9R * amb_calc);
	setprop("sim/model/bluebird/lighting/interior9-buttons/amb-dif/gb", livery_I9GB * amb_calc);
}

var hatch_interpolate = func (i_from, i_to, i_slider) {
	return ((i_to - i_from) * i_slider) + i_from;
}

var hatch_lighting_update = func {
	var door0_opening = clamp(((door0_position - 0.15) * 1.887), 0, 1);
	setprop("sim/model/bluebird/lighting/door0/interior1-flooring/emission/red", hatch_interpolate((livery_I1R * interior_lighting_base_R), livery_I1AR, (door0_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door0/interior1-flooring/emission/green", hatch_interpolate((livery_I1G * interior_lighting_base_GB), livery_I1AG, (door0_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door0/interior1-flooring/emission/blue", hatch_interpolate((livery_I1B * interior_lighting_base_GB), livery_I1AB, (door0_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door0/interior4-lower-walls/emission/red", hatch_interpolate(0, (livery_I4R * interior_lighting_base_R), door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior4-lower-walls/emission/green", hatch_interpolate(0, (livery_I4G * interior_lighting_base_GB), door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior4-lower-walls/emission/blue", hatch_interpolate(0, (livery_I4B * interior_lighting_base_GB), door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior8-light-frame/emission/red", hatch_interpolate(0, (livery_I8R * interior_lighting_base_R), door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior8-light-frame/emission/gb", hatch_interpolate(0, (livery_I8GB * interior_lighting_base_GB), door0_opening));
	setprop("sim/model/bluebird/lighting/door0/hatchA-steps/emission/red", hatch_interpolate(0, (livery_IAARGB * interior_lighting_base_R), door0_opening));
	setprop("sim/model/bluebird/lighting/door0/hatchA-steps/emission/gb", hatch_interpolate(0, (livery_IAARGB * interior_lighting_base_GB), door0_opening));

	setprop("sim/model/bluebird/lighting/door0/interior1-flooring/amb-dif/red", hatch_interpolate((livery_I1R * interior_lighting_base_R), livery_I1AR, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior1-flooring/amb-dif/green", hatch_interpolate((livery_I1G * interior_lighting_base_GB), livery_I1AG, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior1-flooring/amb-dif/blue", hatch_interpolate((livery_I1B * interior_lighting_base_GB), livery_I1AB, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior4-lower-walls/amb-dif/red", hatch_interpolate((livery_I4R * interior_lighting_base_R), livery_I4AR, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior4-lower-walls/amb-dif/green", hatch_interpolate((livery_I4G * interior_lighting_base_GB), livery_I4AG, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior4-lower-walls/amb-dif/blue", hatch_interpolate((livery_I4B * interior_lighting_base_GB), livery_I4AB, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior8-light-frame/amb-dif/red", hatch_interpolate((livery_I8R * interior_lighting_base_R), livery_I8AR, door0_opening));
	setprop("sim/model/bluebird/lighting/door0/interior8-light-frame/amb-dif/gb", hatch_interpolate((livery_I8GB * interior_lighting_base_GB), livery_I8AGB, door0_opening));

	var door1_opening = clamp(((door1_position - 0.15) * 1.887), 0, 1);
	setprop("sim/model/bluebird/lighting/door1/interior1-flooring/emission/red", hatch_interpolate((livery_I1R * interior_lighting_base_R), livery_I1AR, (door1_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door1/interior1-flooring/emission/green", hatch_interpolate((livery_I1G * interior_lighting_base_GB), livery_I1AG, (door1_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door1/interior1-flooring/emission/blue", hatch_interpolate((livery_I1B * interior_lighting_base_GB), livery_I1AB, (door1_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door1/interior4-lower-walls/emission/red", hatch_interpolate(0, (livery_I4R * interior_lighting_base_R), door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior4-lower-walls/emission/green", hatch_interpolate(0, (livery_I4G * interior_lighting_base_GB), door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior4-lower-walls/emission/blue", hatch_interpolate(0, (livery_I4B * interior_lighting_base_GB), door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior8-light-frame/emission/red", hatch_interpolate(0, (livery_I8R * interior_lighting_base_R), door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior8-light-frame/emission/gb", hatch_interpolate(0, (livery_I8GB * interior_lighting_base_GB), door1_opening));
	setprop("sim/model/bluebird/lighting/door1/hatchA-steps/emission/red", hatch_interpolate(0, (livery_IAARGB * interior_lighting_base_R), door1_opening));
	setprop("sim/model/bluebird/lighting/door1/hatchA-steps/emission/gb", hatch_interpolate(0, (livery_IAARGB * interior_lighting_base_GB), door1_opening));

	setprop("sim/model/bluebird/lighting/door1/interior1-flooring/amb-dif/red", hatch_interpolate((livery_I1R * interior_lighting_base_R), livery_I1AR, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior1-flooring/amb-dif/green", hatch_interpolate((livery_I1G * interior_lighting_base_GB), livery_I1AG, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior1-flooring/amb-dif/blue", hatch_interpolate((livery_I1B * interior_lighting_base_GB), livery_I1AB, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior4-lower-walls/amb-dif/red", hatch_interpolate((livery_I4R * interior_lighting_base_R), livery_I4AR, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior4-lower-walls/amb-dif/green", hatch_interpolate((livery_I4G * interior_lighting_base_GB), livery_I4AG, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior4-lower-walls/amb-dif/blue", hatch_interpolate((livery_I4B * interior_lighting_base_GB), livery_I4AB, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior8-light-frame/amb-dif/red", hatch_interpolate((livery_I8R * interior_lighting_base_R), livery_I8AR, door1_opening));
	setprop("sim/model/bluebird/lighting/door1/interior8-light-frame/amb-dif/gb", hatch_interpolate((livery_I8GB * interior_lighting_base_GB), livery_I8AGB, door1_opening));
	var doors0_1_opening = (door0_opening + door1_opening) * 0.5;
	setprop("sim/model/bluebird/lighting/doors0-1/interior1-flooring/amb-dif/red", hatch_interpolate((livery_I1R * interior_lighting_base_R * amb_calc), livery_I1AR, doors0_1_opening));
	setprop("sim/model/bluebird/lighting/doors0-1/interior1-flooring/amb-dif/green", hatch_interpolate((livery_I1G * interior_lighting_base_GB * amb_calc), livery_I1AG, doors0_1_opening));
	setprop("sim/model/bluebird/lighting/doors0-1/interior1-flooring/amb-dif/blue", hatch_interpolate((livery_I1B * interior_lighting_base_GB * amb_calc), livery_I1AB, doors0_1_opening));

	var door5_opening = clamp((door5_position * 1.724), 0, 1);
	setprop("sim/model/bluebird/lighting/door5/interior-specular", door5_opening);
	var door5_E_factor = 1 - (door5_opening * 0.5);
	var f5R = interior_lighting_base_R * door5_E_factor;
	var f5GB = interior_lighting_base_GB * door5_E_factor;
	setprop("sim/model/bluebird/lighting/door5/hatch1-flooring-center/emission/red", livery_I1R * f5R);
	setprop("sim/model/bluebird/lighting/door5/hatch1-flooring-center/emission/green", livery_I1G * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch1-flooring-center/emission/blue", livery_I1B * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch3-upper-walls/emission/red", livery_I3R * f5R);
	setprop("sim/model/bluebird/lighting/door5/hatch3-upper-walls/emission/green", livery_I3G * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch3-upper-walls/emission/blue", livery_I3B * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch4-lower-walls/emission/red", livery_I4R * f5R);
	setprop("sim/model/bluebird/lighting/door5/hatch4-lower-walls/emission/green", livery_I4G * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch4-lower-walls/emission/blue", livery_I4B * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/emission/red", livery_I7R * f5R);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/emission/green", livery_I7G * f5GB);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/emission/blue", livery_I7B * f5GB);
	setprop("sim/model/bluebird/lighting/door5/interior1-flooring/emission/red", hatch_interpolate((livery_I1R * interior_lighting_base_R), livery_I1AR, (door5_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door5/interior1-flooring/emission/green", hatch_interpolate((livery_I1G * interior_lighting_base_GB), livery_I1AG, (door5_opening * 0.5)));
	setprop("sim/model/bluebird/lighting/door5/interior1-flooring/emission/blue", hatch_interpolate((livery_I1B * interior_lighting_base_GB), livery_I1AB, (door5_opening * 0.5)));

	setprop("sim/model/bluebird/lighting/door5/hatch1-flooring-center/amb-dif/red", livery_I1AR * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch1-flooring-center/amb-dif/green", livery_I1AG * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch1-flooring-center/amb-dif/blue", livery_I1AB * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch3-upper-walls/amb-dif/red", livery_I3AR * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch3-upper-walls/amb-dif/green", livery_I3AG * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch3-upper-walls/amb-dif/blue", livery_I3AB * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch4-lower-walls/amb-dif/red", livery_I4AR * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch4-lower-walls/amb-dif/green", livery_I4AG * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch4-lower-walls/amb-dif/blue", livery_I4AB * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/amb-dif/red", livery_I7AR * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/amb-dif/green", livery_I7AG * door5_opening);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/amb-dif/blue", livery_I7AB * door5_opening);

	var f5 = door5_opening * (1 - int_switch);
	setprop("sim/model/bluebird/lighting/door5/interior1-flooring/amb-dif/red", livery_I1AR * f5);
	setprop("sim/model/bluebird/lighting/door5/interior1-flooring/amb-dif/green", livery_I1AG * f5);
	setprop("sim/model/bluebird/lighting/door5/interior1-flooring/amb-dif/blue", livery_I1AB * f5);
	setprop("sim/model/bluebird/lighting/door5/interior2-door-panels/amb-dif/red", livery_I2AR * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior2-door-panels/amb-dif/green", livery_I2AG * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior2-door-panels/amb-dif/blue", livery_I2AB * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior3-upper-walls/amb-dif/red", livery_I3AR * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior3-upper-walls/amb-dif/green", livery_I3AG * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior3-upper-walls/amb-dif/blue", livery_I3AB * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior4-lower-walls/amb-dif/red", livery_I4AR * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior4-lower-walls/amb-dif/green", livery_I4AG * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior4-lower-walls/amb-dif/blue", livery_I4AB * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior8-light-frame/amb-dif/red", livery_I8AR * f5 * 0.5);
	setprop("sim/model/bluebird/lighting/door5/interior8-light-frame/amb-dif/gb", livery_I8AGB * f5 * 0.5);
}

setlistener("sim/model/livery/material/interior-flooring/ambient/red", func(n) {
	livery_I1AR = n.getValue();
	recalc_material_I1();
	set_I1_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-flooring/ambient/green", func(n) {
	livery_I1AG = n.getValue();
	recalc_material_I1();
	set_I1_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-flooring/ambient/blue", func(n) {
	livery_I1AB = n.getValue();
	recalc_material_I1();
	set_I1_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-door-panels/ambient/red", func(n) {
	livery_I2AR = n.getValue();
	recalc_material_I2();
	set_I2_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-door-panels/ambient/green", func(n) {
	livery_I2AG = n.getValue();
	recalc_material_I2();
	set_I2_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-door-panels/ambient/blue", func(n) {
	livery_I2AB = n.getValue();
	recalc_material_I2();
	set_I2_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-upper/ambient/red", func(n) {
	livery_I3AR = n.getValue();
	recalc_material_I3();
	set_I3_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-upper/ambient/green", func(n) {
	livery_I3AG = n.getValue();
	recalc_material_I3();
	set_I3_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-upper/ambient/blue", func(n) {
	livery_I3AB = n.getValue();
	recalc_material_I3();
	set_I3_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-lower/ambient/red", func(n) {
	livery_I4AR = n.getValue();
	recalc_material_I4();
	set_I4_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-lower/ambient/green", func(n) {
	livery_I4AG = n.getValue();
	recalc_material_I4();
	set_I4_ambient();
},, 0);

setlistener("sim/model/livery/material/interior-lower/ambient/blue", func(n) {
	livery_I4AB = n.getValue();
	recalc_material_I4();
	set_I4_ambient();
},, 0);

setlistener("controls/lighting/alert", func {
	alert_switch = alert_switch_Node.getValue();
	alert_level = alert_switch;  # reset brightness to full upon change
	if (!alert_switch) {
		setprop("sim/model/bluebird/lighting/overhead/emission/red", int_switch);
		setprop("sim/model/bluebird/lighting/overhead/emission/gb", int_switch);
	}
	recalc_material_I1();
	recalc_material_I2();
	recalc_material_I3();
	recalc_material_I4();
	interior_lighting_update();
},, 0);

# watch for damage --------------------------------------------------

setlistener("sim/model/bluebird/components/nacelle-L", func(n) {
	nacelleL_attached = n.getValue();
	if (!nacelleL_attached) {
		if (power_switch) {
			setprop ("ai/submodels/engine-L-flaring", 1);
		}
		if (nacelle_L_venting) {
			setprop ("sim/model/bluebird/systems/nacelle-L-venting", 0);
		}
		if (damage_count) {
			setprop ("ai/submodels/engine-L-venting", 1);
		}
	} else {
		setprop ("ai/submodels/engine-L-flaring", 0);
		setprop ("ai/submodels/engine-L-venting", 0);
	}
}, 1);

setlistener("sim/model/bluebird/components/nacelle-R", func(n) {
	nacelleR_attached = n.getValue();
	if (!nacelleR_attached) {
		if (power_switch) {
			setprop ("ai/submodels/engine-R-flaring", 1);
		}
		if (nacelle_R_venting) {
			setprop ("sim/model/bluebird/systems/nacelle-R-venting", 0);
		}
		if (damage_count) {
			setprop ("ai/submodels/engine-R-venting", 1);
		}
	} else {
		setprop ("ai/submodels/engine-R-flaring", 0);
		setprop ("ai/submodels/engine-R-venting", 0);
	}
}, 1);

var update_venting = func(uv_change, left_right) {	# 1=left,2=right
	var old_direction = venting_direction;
	var new_venting = 0;
	if (nacelle_L_venting or nacelle_R_venting) {
		# make venting submodels appear realistic as wind direction blows them
		if (airspeed > 10) {
			venting_direction = 1;
		} elsif (airspeed < -10) {
			venting_direction = -1;
		} else {
			venting_direction = 0;
		}
		if ((old_direction != venting_direction) or (uv_change)) {
			if (nacelle_L_venting) {
				if (nacelleL_attached) {
					if (venting_direction == 1) {
						setprop ("ai/submodels/nacelle-LR-venting", 1);
						setprop ("ai/submodels/nacelle-LF-venting", 0);
					} elsif (venting_direction == -1) {
						setprop ("ai/submodels/nacelle-LR-venting", 0);
						setprop ("ai/submodels/nacelle-LF-venting", 1);
					} elsif (venting_direction == 0) {
						setprop ("ai/submodels/nacelle-LR-venting", 1);
						setprop ("ai/submodels/nacelle-LF-venting", 1);
					}
					new_venting = 1;
				} else {
					setprop ("ai/submodels/engine-L-flaring", 1);
					setprop ("ai/submodels/engine-L-venting", 1);
				}
			} else {
				setprop ("ai/submodels/nacelle-LR-venting", 0);
				setprop ("ai/submodels/nacelle-LF-venting", 0);
			}
			if (nacelle_R_venting) {
				if (nacelleR_attached) {
					if (venting_direction == 1) {
						setprop ("ai/submodels/nacelle-RR-venting", 1);
						setprop ("ai/submodels/nacelle-RF-venting", 0);
					} elsif (venting_direction == -1) {
						setprop ("ai/submodels/nacelle-RR-venting", 0);
						setprop ("ai/submodels/nacelle-RF-venting", 1);
					} elsif (venting_direction == 0) {
						setprop ("ai/submodels/nacelle-RR-venting", 1);
						setprop ("ai/submodels/nacelle-RF-venting", 1);
					}
					new_venting += 2;
				} else {
					setprop ("ai/submodels/engine-R-flaring", 1);
					setprop ("ai/submodels/engine-R-venting", 1);
				}
			} else {
				setprop ("ai/submodels/nacelle-RR-venting", 0);
				setprop ("ai/submodels/nacelle-RF-venting", 0);
			}
		}
	} else {
		venting_direction = -3;
		if (uv_change) {
			setprop ("ai/submodels/nacelle-LR-venting", 0);
			setprop ("ai/submodels/nacelle-LF-venting", 0);
			setprop ("ai/submodels/nacelle-RR-venting", 0);
			setprop ("ai/submodels/nacelle-RF-venting", 0);
		}
	}
	if (left_right != new_venting) {
		if ((left_right != 2) and ((new_venting == 0) or (new_venting == 2))) {
			setprop ("sim/model/bluebird/systems/nacelle-L-venting", 0);
		} elsif ((left_right != 1) and (new_venting <= 1)) {
			setprop ("sim/model/bluebird/systems/nacelle-R-venting", 0);
		}
	}
}

setlistener("sim/model/bluebird/systems/nacelle-L-venting", func(n) {
	nacelle_L_venting = n.getValue();
	update_venting(1,1);
}, 1);

setlistener("sim/model/bluebird/systems/nacelle-R-venting", func(n) {
	nacelle_R_venting = n.getValue();
	update_venting(1,2);
}, 1);

# panel lighting ====================================================
var set_button_color = func(sbc_prop, sbc_color) {
	if (sbc_color < 0.9 or sbc_color >= 16) {
		# button off, color for interior lighting and alert level
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/red", panel_ambient_R * 0.75);	# edge
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/red", panel_ambient_R);		# face
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/red", panel_lighting_R * 0.75);	# bright lit
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/red", panel_lighting_R * 0.33);	# very dark unlit
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/red", panel_lighting_R * 0.5);	# dark (face)
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/green", panel_ambient_GB * 0.75);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/green", panel_ambient_GB);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/green", panel_lighting_GB * 0.75);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/green", panel_lighting_GB * 0.33);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/green", panel_lighting_GB * 0.5);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/blue", panel_ambient_GB * 0.75);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/blue", panel_ambient_GB);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/blue", panel_lighting_GB * 0.75);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/blue", panel_lighting_GB * 0.33);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/blue", panel_lighting_GB * 0.5);
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/specular", panel_specular);
	} else {
		# button on, determine color
		setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/specular", (1 - power_switch));
		if (sbc_color == 1 or sbc_color == 3) {		# red (or yellow) on
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/red", 0.75);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/red", 1);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/red", button_lit * 0.5);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/red", button_lit * 0.5);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/red", button_lit);
		} elsif (sbc_color == 9 or sbc_color == 15) {		# half intensity red or grey on
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/red", 0.45);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/red", 0.6);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/red", button_lit * 0.3);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/red", button_lit * 0.3);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/red", button_lit * 0.6);
		} else {		# red off
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/red", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/red", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/red", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/red", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/red", 0);
		}
		if (sbc_color == 2 or sbc_color == 3) {		# green (or yellow) on
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/green", 0.75);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/green", 1);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/green", button_lit * 0.5);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/green", button_lit * 0.5);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/green", button_lit);
		} elsif (sbc_color == 10 or sbc_color == 15) {	# half intensity green or grey on
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/green", 0.45);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/green", 0.6);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/green", button_lit * 0.3);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/green", button_lit * 0.3);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/green", button_lit * 0.6);
		} else {		# green off
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/green", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/green", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/green", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/green", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/green", 0);
		}
		if (sbc_color == 4) {		# blue on
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/blue", 0.75);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/blue", 1);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/blue", button_lit * 0.5);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/blue", button_lit * 0.5);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/blue", button_lit);
		} elsif (sbc_color == 15) {		# grey on
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/blue", 0.45);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/blue", 0.6);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/blue", button_lit * 0.3);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/blue", button_lit * 0.3);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/blue", button_lit * 0.6);
		} else {		# blue off
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/amb-dif/blue", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/amb-dif/blue", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-b/emission/blue", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/edge-k/emission/blue", 0);
			setprop("sim/model/bluebird/lighting/buttons/" ~ sbc_prop ~ "/face/emission/blue", 0);
		}
	}
}

var buttonL67_update = func(b67_change_all) {
	var old_button_1 = button_LT6;
	if (power_switch) {
		if (reactor_drift == 1) {
			button_LT6 = 2;
		} elsif (damage_count) {
			button_LT6 = 1;
		} elsif (reactor_drift == 0) {
			button_LT6 = unlit_lighting_base;
		} else {
			button_LT6 = 3;
		}
	} else {
		button_LT6 = unlit_lighting_base;
	}
	if (old_button_1 != button_LT6 or b67_change_all) {
		set_button_color("left3-6-countergrav", button_LT6);
	}

	old_button_1 = button_LT7;
	if (reactor_request) {	# countergrav powered on or on standby
		if (reactor_drift) {	# not on standby, powering up
			plu_return = 1;
			if (reactor_state and reactor_drift >= 0.48) {	# powered up sufficiently = 7green
				button_LT7 = 2;
			} else {	# in lower transit
				plu_return = 1;
				var plu_time = getprop("sim/time/elapsed-sec") * 0.5;
				plu_time = int((plu_time - int(plu_time)) * 10);
				if (isodd(plu_time)) {	# 7yellow flashing
					button_LT7 = 3;
				} else {
					if (sound_state) {	# going up, flash with green
						button_LT7 = 10;
					} else {
						button_LT7 = 9;
					}
				}
			}
		} else {	# standby =7grey
			button_LT7 = 15;
		}
	} else {
		button_LT7 = unlit_lighting_base;
	}
	if (old_button_1 != button_LT7 or b67_change_all) {
		set_button_color("left7-countergrav", button_LT7);
	}
}

#==========================================================================
# loop function #1 called by panel_lighting_loop every 0.05 seconds 
#   only when changes are in progress ===============================

var panel_lighting_update = func {
	var plu_return = 0;
	var old_lit = button_lit;
	# instrument panel sun angle
	var ipsa = (power_switch > 0 ? ((sun_angle - 1.1) * 3.3) : 2.5);
		# sun_angle = 2.46 midnight 1.0 noon at mid-latitude
		# ipsa = 1.0 dusk-midnight-dawn  0.33 at high noon
	if (power_switch) {
		ipsa = clamp(ipsa, 0, 1);	# daytime , nighttime
		panel_specular = 0.5 - (0.5 * int_switch);  # interior specular
		panel_lighting_R = 0.0600 * interior_lighting_base_R;  # Grey60 button Lighting
		panel_lighting_GB = 0.0600 * interior_lighting_base_GB;  # alert tint
			# lighting_base oscillates from 7 at midnight to 0 at noon
		unlit_lighting_base = interior_lighting_base_R + interior_lighting_base_GB + 16.0 + alert_level;
		button_lit = ((1 - (ipsa * 0.2)) * (int_switch + 1) * 0.5) + (((1 - ipsa) * (1 - int_switch)) * 0.5);
			#  emissions 	night	noon
			# LightsOff	0.4	0.8
			# LightsOn	0.8	0.93	 dim button lights for nighttime
	} else {
		panel_specular = 1;	# full reflection
		panel_lighting_R = 0;
		panel_lighting_GB = 0;
		unlit_lighting_base = 0.60;
		button_lit = 0;
	}
	setprop("sim/model/material/instruments/factor", (1 - (ipsa * 0.4)));
	panel_ambient_R = 0.60 + (0.2 * alert_level * int_switch * power_switch);
	panel_ambient_GB = 0.60 + (-0.2 * alert_level * int_switch * power_switch);
	old_button_1 = button_RT9;
	if (power_switch) {
		if (int_switch) {	# lights on = 9green
			if (alert_switch or damage_count) {	# red
				button_RT9 = 1;
			} else {
				button_RT9 = 2;
			}
		} else {
			if (alert_switch or damage_count) {	# dim red
				button_RT9 = 9;
			} else {
				button_RT9 = unlit_lighting_base;
			}
		}
	} else {
		button_RT9 = unlit_lighting_base;
	}
	var plu_change_all = 0;
	if (abs(old_lit - button_lit) > 0.001) {
		plu_change_all = 1;
	}

	if (old_button_1 != button_RT9 or plu_change_all) {
		set_button_color("right9-overhead", button_RT9);
		plu_change_all = 1;
	}

	var old_button_1 = button_G1;
	var old_button_2 = button_G3;
	if (power_switch) {
		if (gear_position == 0) {	# up
			if (wheel_position == 0) {	# up = 1green
				button_G1 = 2;
			} else {		# wheels barely down = 1yellow
				button_G1 = 3;
			}
			button_G3 = unlit_lighting_base;
		} elsif (gear_position == 1 or (gear_position > 0.409 and gear_position < 0.411)) {
			if (wheel_position < 0.5) {	# skid-plate down = 3blue
				button_G3 = 4;
			} else {			# wheels down = 3green
				button_G3 = 2;
			}
			button_G1 = unlit_lighting_base;
		} else {
			plu_return = 1;
			var plu_time = getprop("sim/time/elapsed-sec") * 0.5;
			plu_time = int((plu_time - int(plu_time)) * 10);
			if (isodd(plu_time)) {
				if (!gear_request) {		# moving up = 1yellow-flash
					button_G1 = 3;
					button_G3 = unlit_lighting_base;
				} else {			# moving down = 3yellow-flash
					button_G1 = unlit_lighting_base;
					button_G3 = 3;
				}
			} else {
				if (!gear_request) {		# moving up
					button_G1 = 9;
					button_G3 = unlit_lighting_base;
				} else {			# moving down
					button_G1 = unlit_lighting_base;
					button_G3 = 9;
				}
			}
		}
	} else {
		button_G1 = unlit_lighting_base;
		button_G3 = unlit_lighting_base;
	}
	if (old_button_1 != button_G1 or plu_change_all) {
		set_button_color("gear1-up", button_G1);
	}
	if (old_button_2 != button_G3 or plu_change_all) {
		set_button_color("gear3-down", button_G3);
	}

	old_button_1 = button_G2;
	if (power_switch and gear_mode) {
		if (gear_position) {		# down and relevant = 2yellow
			button_G2 = 3;
		} else {			# up and on standby = 2grey
			button_G2 = 15;
		}
	} else {
		button_G2 = unlit_lighting_base;
	}
	if (old_button_1 != button_G2 or plu_change_all) {
		set_button_color("gear2-mode", button_G2);
	}

	old_button_1 = button_G4;
	if (power_switch) {
		if (wheel_position == 1) {		# wheels down = 4green
			button_G4 = 2;
		} elsif (wheel_position == 0) {
			if (wheels_switch) {		# wheels up and on standby = 4grey
				button_G4 = 15;
			} else {
				button_G4 = unlit_lighting_base;
			}
		} else {				# in transit = 4yellow flashing
			plu_return = 1;
			var plu_time = getprop("sim/time/elapsed-sec") * 0.5;
			plu_time = int((plu_time - int(plu_time)) * 10);
			if (isodd(plu_time)) {
				button_G4 = 3;
			} else {
				button_G4 = 9;
			}
		}
	} else {
		button_G4 = unlit_lighting_base;
	}
	if (old_button_1 != button_G4 or plu_change_all) {
		set_button_color("gear4-wheels", button_G4);
	}

	old_button_1 = button_RT1;
	if (power_switch) {
		if (door0_position == 0) {	# closed = 1green
			button_RT1 = 2;
		} elsif (door0_position == 1) {	# open = 1red
			button_RT1 = 1;
		} elsif (isodd(door0_position * 10)) {	# in transit = 1yellow flashing
			button_RT1 = 3;
			plu_return = 1;
		} else {
			plu_return = 1;
			if (doors[0].target) {
				button_RT1 = 10;
			} else {
				button_RT1 = 9;
			}
		}
	} else {
		button_RT1 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT1 or plu_change_all) {
		set_button_color("right1-hatch-left", button_RT1);
	}

	old_button_1 = button_RT2;
	if (power_switch) {
		if (door1_position == 0) {	# closed = 2green
			button_RT2 = 2;
		} elsif (door1_position == 1) {	# open = 2red
			button_RT2 = 1;
		} elsif (isodd(door1_position * 10)) {	# in transit = 2yellow flashing
			button_RT2 = 3;
			plu_return = 1;
		} else {
			if (doors[1].target) {
				button_RT2 = 10;
			} else {
				button_RT2 = 9;
			}
			plu_return = 1;
		}
	} else {
		button_RT2 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT2 or plu_change_all) {
		set_button_color("right2-hatch-right", button_RT2);
	}

	old_button_1 = button_RT3;
	if (power_switch) {
		if (door5_position == 0) {	# closed = 3green
			button_RT3 = 2;
		} elsif (door5_position == 1) {	# open = 3red
			button_RT3 = 1;
		} elsif (isodd(door5_position * 40)) {	# in transit = 3yellow flashing
			button_RT3 = 3;
			plu_return = 1;
		} else {
			plu_return = 1;
			if (doors[5].target) {
				button_RT3 = 10;
			} else {
				button_RT3 = 9;
			}
		}
	} else {
		button_RT3 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT3 or plu_change_all) {
		set_button_color("right3-hatch-rear", button_RT3);
	}

	old_button_1 = button_RT4;
	var ipll = landing_light_switch.getValue();
	if (power_switch and ipll and !damage_count) {
		if ((ipll == 2 or sun_angle > 1.57) and gear_position > 0.4) {
			if (gear_position > 0.5) {
				button_RT4 = 2;
			} else {
				button_RT4 = 10;
			}
		} else {
			button_RT4 = 15;
		}
	} else {
		button_RT4 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT4 or plu_change_all) {
		set_button_color("right4-landing-down", button_RT4);
	}

	old_button_1 = button_RT5;
	if (power_switch and ipll and !damage_count) {	# on = 5green or dim green
		if (ipll == 2 or sun_angle > 1.57) {
			button_RT5 = 18 - (ipll * 8);
		} else {
			button_RT5 = 15;
		}
	} else {
		button_RT5 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT5 or plu_change_all) {
		set_button_color("right5-landing-forward", button_RT5);
	}

	old_button_1 = button_RT6;
	var ipnl = nav_light_switch.getValue();
	if (power_switch and ipnl) {	# on = 6green or dim green
		button_RT6 = 18 - (ipnl * 8);
	} else {
		button_RT6 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT6 or plu_change_all) {
		set_button_color("right6-nav", button_RT6);
	}

	old_button_1 = button_RT7;
	if (power_switch and beacon_switch.getValue()) {	# on = 7green
		button_RT7 = 2;
	} else {
		button_RT7 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT7 or plu_change_all) {
		set_button_color("right7-beacon", button_RT7);
	}

	old_button_1 = button_RT8;
	if (power_switch and strobe_switch.getValue()) {	# on = 8green
		button_RT8 = 2;
	} else {
		button_RT8 = unlit_lighting_base;
	}
	if (old_button_1 != button_RT8 or plu_change_all) {
		set_button_color("right8-strobe", button_RT8);
	}

	old_button_1 = button_LT1;
	if (power_switch) {	# main power = 1green
		button_LT1 = 2;
	} else {
		button_LT1 = unlit_lighting_base;
	}
	if (old_button_1 != button_LT1 or plu_change_all) {
		set_button_color("left1-power", button_LT1);
	}

	old_button_1 = button_LT2;
	if (power_switch and reactor_request) {	# power subsystem on = 2green
		button_LT2 = 2;
	} else {
		button_LT2 = unlit_lighting_base;
	}
	if (old_button_1 != button_LT2 or plu_change_all) {
		set_button_color("left2-reactor", button_LT2);
	}

	buttonL67_update(plu_change_all);

	old_button_1 = button_LT8;
	if (wave1_level == 1) {	# engine (request) on = 8green
		if (wave_drift) {	# not on standby
			button_LT8 = 2;
		} else {	# standby =8grey
			button_LT8 = 15;
		}
	} else {
		if (damage_count and power_switch) {
			button_LT8 = 1;
		} else {
			button_LT8 = unlit_lighting_base;
		}
	}
	if (old_button_1 != button_LT8 or plu_change_all) {
		set_button_color("left8-wave-guide", button_LT8);
	}

	old_button_1 = button_LT9;
	if (wave2_level == 1) {	# orbital power = 9green
		if (wave_drift) {	# not on standby
			button_LT9 = 2;
		} else {	# standby = 9grey
			button_LT9 = 15;
		}
	} else {
		button_LT9 = unlit_lighting_base;
	}
	if (old_button_1 != button_LT9 or plu_change_all) {
		set_button_color("left9-overdrive", button_LT9);
	}
	return plu_return;
}

var panel_lighting_loop = func {
	if (panel_lighting_update() > 0) {
		settimer(panel_lighting_loop, 0.05);
	}
}


#==========================================================================
# loop function #2 called by interior_lighting_loop every 3 seconds
#    or every 0.25 when time warp or every 0.05 during condition red lighting

var interior_lighting_update = func {
	var intli = 0;    # calculate brightness of interior lighting as sun goes down
	var intlir = 0;    # condition lighting tint for red emissions
	var intlig = 0;    # condition lighting tint for green and blue emissions
	sun_angle = getprop("sim/time/sun-angle-rad");  # Tied property, cannot listen
	if (power_switch) {
		if (int_switch) {
			intli = emis_calc;
		}
		if (alert_switch or damage_count > 0) {
			var red_state = getprop("sim/model/bluebird/lighting/alert1/state");  # bring lighting up or down
			if (red_state) {
				alert_level += 0.08;
				if (alert_level > 1.0) {
					alert_level = 1.0;
				}
			} elsif (!red_state) {
				alert_level -= 0.08;
				if (alert_level < 0.25) {
					alert_level = 0.25;
				}
			}
			setprop("sim/model/bluebird/lighting/overhead/emission/red", alert_level * int_switch);  # set red brightness
			setprop("sim/model/bluebird/lighting/overhead/emission/gb", 0);
			intlir = intli * alert_level;  # adjust lighting accordingly
			intlig = intli * alert_level * 0.25;
			setprop("sim/model/bluebird/lighting/waldo/emission/red", (alert_level * 0.8 * int_switch));
			setprop("sim/model/bluebird/lighting/waldo/emission/gb", (alert_level * 0.4 * int_switch));
		} else {
			setprop("sim/model/bluebird/lighting/overhead/emission/red", int_switch);
			setprop("sim/model/bluebird/lighting/overhead/emission/gb", int_switch);
			setprop("sim/model/bluebird/lighting/waldo/emission/red", int_switch * 0.8);
			setprop("sim/model/bluebird/lighting/waldo/emission/gb", int_switch * 0.8);
			intlir = intli;
			intlig = intli;
		}
		# fade marker lighting when damaged
		setprop("sim/model/bluebird/lighting/interiorC-safety-lights/emission/rg", 1.0 - (damage_count * 0.25));
		setprop("sim/model/bluebird/lighting/interiorB-door-lights/emission/rgb", 1.0 - (damage_count * 0.25));
	} else {
		setprop("sim/model/bluebird/lighting/interiorC-safety-lights/emission/rg", 0);
		setprop("sim/model/bluebird/lighting/interiorB-door-lights/emission/rgb", 0);
		setprop("sim/model/bluebird/lighting/overhead/emission/red", 0);
		setprop("sim/model/bluebird/lighting/overhead/emission/gb", 0);
		setprop("sim/model/bluebird/lighting/waldo/emission/red", 0);
		setprop("sim/model/bluebird/lighting/waldo/emission/gb", 0);
	}
	set_I1_ambient();  # calculate and set ambient levels
	set_I2_ambient();
	set_I3_ambient();
	set_I4_ambient();
	set_I5_ambient();
	set_I6_ambient();
	set_I7_ambient();
	set_I8_ambient();
	set_I9_ambient();
	# next calculate emissions for night lighting
	interior_lighting_base_R = intlir;
	setprop("sim/model/bluebird/lighting/interior1-flooring/emission/red", livery_I1R * intlir);
	setprop("sim/model/bluebird/lighting/interior2-door-panels/emission/red", livery_I2R * intlir);
	setprop("sim/model/bluebird/lighting/interior3-upper-walls/emission/red", livery_I3R * intlir);
	setprop("sim/model/bluebird/lighting/interior4-lower-walls/emission/red", livery_I4R * intlir);
	setprop("sim/model/bluebird/lighting/interior5-console/emission/red", livery_I5R * intlir);
	setprop("sim/model/bluebird/lighting/interior6-chairs/emission/red", livery_I6R * intlir);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/emission/red", livery_I7R * intlir);
	setprop("sim/model/bluebird/lighting/interior8-light-frame/emission/red", livery_I8R * intlir);
	setprop("sim/model/bluebird/lighting/interior9-buttons/emission/red", livery_I9R * intlir);
	setprop("sim/model/bluebird/lighting/interiorA-door-seals/emission/red", livery_IAARGB * intlir);
	interior_lighting_base_GB = intlig;
	setprop("sim/model/bluebird/lighting/interior1-flooring/emission/green", livery_I1G * intlig);
	setprop("sim/model/bluebird/lighting/interior1-flooring/emission/blue", livery_I1B * intlig);
	setprop("sim/model/bluebird/lighting/interior2-door-panels/emission/green", livery_I2G * intlig);
	setprop("sim/model/bluebird/lighting/interior2-door-panels/emission/blue", livery_I2B * intlig);
	setprop("sim/model/bluebird/lighting/interior3-upper-walls/emission/green", livery_I3G * intlig);
	setprop("sim/model/bluebird/lighting/interior3-upper-walls/emission/blue", livery_I3B * intlig);
	setprop("sim/model/bluebird/lighting/interior4-lower-walls/emission/green", livery_I4G * intlig);
	setprop("sim/model/bluebird/lighting/interior4-lower-walls/emission/blue", livery_I4B * intlig);
	setprop("sim/model/bluebird/lighting/interior5-console/emission/green", livery_I5G * intlig);
	setprop("sim/model/bluebird/lighting/interior5-console/emission/blue", livery_I5B * intlig);
	setprop("sim/model/bluebird/lighting/interior6-chairs/emission/green", livery_I6G * intlig);
	setprop("sim/model/bluebird/lighting/interior6-chairs/emission/blue", livery_I6B * intlig);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/emission/green", livery_I7G * intlig);
	setprop("sim/model/bluebird/lighting/door5/hatch7-flooring-side/emission/blue", livery_I7B * intlig);
	setprop("sim/model/bluebird/lighting/interior8-light-frame/emission/gb", livery_I8GB * intlig);
	setprop("sim/model/bluebird/lighting/interior9-buttons/emission/gb", livery_I9GB* intlig);
	setprop("sim/model/bluebird/lighting/interiorA-door-seals/emission/gb", livery_IAARGB * intlig);

	setprop("sim/model/bluebird/lighting/interior-specular", (0.5 - (0.5 * int_switch)));

	hatch_lighting_update();
	panel_lighting_update();
}

var interior_lighting_loop = func {
	interior_lighting_update();
	if (alert_switch) {
		settimer(interior_lighting_loop, 0.05);
	} else {
		if (getprop("sim/time/warp-delta")) {
			settimer(interior_lighting_loop, 0.25);
		} else {
			settimer(interior_lighting_loop, 3);
		}
	}
}

#==========================================================================
# loop function #3 called by nav_light_loop every 3 seconds
#    or every 0.5 seconds when time warp ============================

var nav_lighting_update = func {
	var nlu_nav = nav_light_switch.getValue();
	if (nlu_nav == 2) {
		nav_lights_state.setBoolValue(1);
	} else {
		if (nlu_nav == 1) {
			nav_lights_state.setBoolValue(visibility < 5000 or sun_angle > 1.4);
		} else {
			nav_lights_state.setBoolValue(0);
		}
	}
	# window shading factor between 0 transparent and 1 opaque
	#      if lights on   range(0.2-0.5) midnight to noon
	#    else lights off  range(0.3-0.6)
	if (!getprop("sim/model/cockpit-visible")) {
		var wsv = 1.0;
	} else {  
		var wsv = -9999;
		if (visibility < 5000 or sun_angle > 1.2) {  # dawn/dusk bright side
			if (int_switch) {      # lights on
				# dawn/dusk darkest : dark night
				wsv = (sun_angle < 2.0 ? (0.95 - (sun_angle * 0.375)) : 0.2);
			} else {            # lights off
				wsv = (sun_angle < 2.0 ? (1.05 - (sun_angle * 0.375)) : 0.3);
			}
		} else {      # daytime
			wsv = (int_switch ? 0.5 : 0.6);
		}
	}
	setprop("sim/model/bluebird/lighting/window-factor", wsv);
}

var nav_light_loop = func {
	nav_lighting_update();
	if (getprop("sim/time/warp-delta")) {
		settimer(nav_light_loop, 0.5);
	} else {
		settimer(nav_light_loop, 3);
	}
}

# gear and wheels --------------------------------------------------
setlistener("gear/gear-agl-m", func(n) { gear_height = n.getValue() },, 0);

setlistener("gear/gear[0]/position-norm", func(n) {
	gear_position = n.getValue();
	if (wheel_position) {
		var ppos = gear_position - wheel_position;
		if (ppos < 0) {
			ppos = 0;
		}
		setprop("gear/gear[0]/position-side-pads", ppos);
	} else {
		setprop("gear/gear[0]/position-side-pads", gear_position);
	}
	setprop ("gear/gear-agl-m", (gear_position * 2.47) + wheel_height);
	if (door0_position > 0.7) {
		door_update(0);
	}
	if (door1_position > 0.7) {
		door_update(1);
	}
	if (door5_position > 0.7) {
		door_update(5);
	}
	contact_altitude = altitude_ft_Node.getValue() - vertical_offset_ft - gear_height - hover_add;
	panel_lighting_update();
},, 0);

setlistener("gear/gear[1]/position-norm", func(n) {
	wheel_position = n.getValue();
	if (wheel_position) {
		var ppos = gear_position - wheel_position;
		if (ppos < 0) {
			ppos = 0;
		}
		setprop("gear/gear[0]/position-side-pads", ppos);
	} else {
		setprop("gear/gear[0]/position-side-pads", gear_position);
	}
	if (wheel_position > 0.5) {	# wheels below skid plate of main gear
		if (wheel_position > 0.90) {	# calculate actual height
			wheel_height = ((wheel_position - 0.9) * 1.31234) + 1.03893;
		} else {
			wheel_height = (wheel_position - 0.5) * 2.59733;
		}
	} else {
		wheel_height = 0;
	}
	setprop ("gear/gear-agl-m", (gear_position * 2.47) + wheel_height);
	# contact = altitude origin - offset - gear - (keep nacelle and nose from touching)
	contact_altitude = altitude_ft_Node.getValue() - vertical_offset_ft - gear_height - hover_add;
	panel_lighting_update();
},, 0);

var toggle_gear_mode = func(gm_request) {
	if (power_switch) {
		if (gm_request == 1) {	# crouch low
			setprop("controls/gear/height-switch", 1);
		} elsif (gm_request == 0) {	# extend fully
			setprop("controls/gear/height-switch", 0);
		} else {	# toggle
			if (gear_mode) {
				setprop("controls/gear/height-switch", 0);
			} else {
				setprop("controls/gear/height-switch", 1);
			}
		}
	} else {	# no power to comply
		popupTip2("Unable to comply. No power.");
	}
	bluebird.reloadDialog1();
}

setlistener("controls/gear/height-switch", func(n) {
	gear_mode = n.getValue();
	if (getprop("gear/gear[0]/last-request")) {	# is down
		if (gear_mode) {
			gear[0].move(0.41);
		} else {
			gear[0].open();
			setprop("gear/gear[0]/last-request", 1);
		}
	} else {
		gear[0].close();
		setprop("gear/gear[0]/last-request", 0);
	}
	if (gear_mode) {	# crouch low
		active_gear_button = [ 3, 1];
	} else {		# extend fully
		active_gear_button = [ 1, 3];
	}
	panel_lighting_update();
},, 0);

setlistener("controls/gear/wheels-switch", func(n) {
	wheels_switch = n.getValue();
	if (wheels_switch) {	# request down
		if (power_switch) {
			if (airspeed > 2000) {
				if (current_to > 6) {
					popupTip2("Velocity too fast for safe deployment. Reducing speed");
					change_maximum(cpl, 6, 1); 
				}
			}
			gear[1].open();
		} else {	# no power to comply
			popupTip2("Unable to comply. No power.");
			setprop("controls/gear/wheels-switch", 0);
		}
	} else {		# up
		gear[1].close();
	}
},, 0);

controls.gearDown = func(direction) {
	if (direction > 0) {		# down requested
		if (power_switch) {
			gear_request = 1;
			if (airspeed > 2000 and !gear_mode) {
				if (cpl > 6) {
					popupTip2("Velocity too fast for safe deployment. Reducing speed");
					change_maximum(cpl, 6, 1); 
				}
			}
			if (gear_mode) {	# crouch low
				gear[0].move(0.41);
			} else {		# extend fully
				gear[0].open();
			}
			setprop("gear/gear[0]/last-request", 1);
			if (wheels_switch) {
				gear[1].open();
			}
		} else {		# no power to comply
			popupTip2("Unable to comply. No power.");
		}
	} elsif (direction < 0) {	# up requested
		gear_request = 0;
		gear[0].close();
		setprop("gear/gear[0]/last-request", 0);
		gear[1].close();	# both gear and wheels up
	}
}

#==========================================================================

var change_maximum = func(cm_from, cm_to, cm_type) {
	var lmt = limit[(reactor_level + (wave1_level* 2) + (wave2_level* 4))] - damage_count ;
	if (lmt < 0) {
		lmt = 0;
	}
	if (cm_to < 0) {  # shutdown by crash
		cm_to = 0;
	}
	if (max_drift) {   # did not finish last request yet
		if (cm_to > cm_from) {
			if (cm_type < 2) {  # startup from power down. bring systems back online
				cm_to = max_to + 1;
			}
		} else {
			var cm_to_new = max_to - 1;
			if (cm_to_new < 0) {  # midair shutdown
				cm_to_new = 0;
			}
			cm_to = cm_to_new;
		}
		if (cm_to >= size(speed_mps)) { 
			cm_to = size(speed_mps) - 1;
		}
		if (cm_to >= lmt) {
			cm_to = lmt;
		}
		if (cm_to < 0) {
			cm_to = 0;
		}
	} else {
		max_from = cm_from;
	}
	max_to = cm_to;
	max_drift = abs(speed_mps[cm_from] - speed_mps[cm_to]) / 20;
	if (cm_type > 1) {  
		# separate new maximum from limit. by engine shutdown/startup
		current_to = cpl;
	} else { 
		# by joystick flaps request
		current_to = cm_to;
	}
}

# modify flaps to change maximum speed --------------------------

controls.flapsDown = func(fd_d) {  # 1 decrease speed gearing -1 increases by default
	var fd_return = 0;
	if(power_switch) {
		if (!fd_d) {
			return;
		} elsif (fd_d > 0 and cpl > 0) {    # reverse joystick buttons direction by exchanging < for >
			change_maximum(cpl, (cpl-1), 1);
			fd_return = 1;
		} elsif (fd_d < 0 and cpl < size(speed_mps) - 1) {    # reverse joystick buttons direction by exchanging < for >
			var check_max = cpl;
			if (max_drift > 0) {
				check_max = max_to;
			}
			if (cpl >= limit[(reactor_level + (wave1_level* 2) + (wave2_level* 4))]) {
				if (wave1_level) {
					if (reactor_level) {
						popupTip2("Unable to comply. Orbital velocities requires higher energy setting");
					} else {
						popupTip2("Unable to comply. Requested velocity requires fusion reactor to be online");
					}
				} else {  
					popupTip2("Unable to comply. Primary Wave-guide engine OFF LINE");
				}
			} elsif (check_max > 5 and gear_position > 0.5) {
				popupTip2("Unable to comply. Gear is down");
			} elsif (check_max > 5 and wheel_position > 0.5) {
				popupTip2("Unable to comply. Gear wheels are down");
			} elsif (check_max > 4 and door0_position > 0) {
				popupTip2("Unable to comply. Side hatch is open");
			} elsif (check_max > 4 and door1_position > 0) {
				popupTip2("Unable to comply. Side hatch is open");
			} elsif (check_max > 6 and door5_position > 0) {
				popupTip2("Unable to comply. Rear hatch is open");
			} elsif (check_max > 6 and contact_altitude < 15000) {
				popupTip2("Unable to comply below 15,000 ft.");
			} elsif (check_max > 7 and contact_altitude < 50000) {
				popupTip2("Unable to comply below 50,000 ft.");
			} elsif (check_max > 8 and contact_altitude < 328000) {
				popupTip2("Unable to comply below 328,000 ft. (100 Km) The boundary between atmosphere and space.");
			} elsif (check_max > 9 and contact_altitude < 792000) {
				popupTip2("Unable to comply below 792,000 ft. (150 Miles) The NASA defined boundary for space.");
			} else {
				change_maximum(cpl, (cpl + 1), 1);
				fd_return = 1;
			}
		}
		if (fd_return) {
			var ss = speed_mps[max_to];
			popupTip2("Max. Speed " ~ ss ~ " m/s");
		}
		current.setValue(cpl);
	} else {
		popupTip2("Unable to comply. Main power is off.");
	}
}


# position adjustment function =====================================

var reset_impact = func {
	damage_blocker = 0;
}

setlistener("sim/model/bluebird/systems/groundslope-enable", func(n) {
	groundslope_enabled = n.getValue();
	if (!groundslope_enabled) {
		setprop("orientation/ground-pitch", 0);
		setprop("orientation/groundsloped-pitch-deg", 0);
		setprop("orientation/ground-roll", 0);
		setprop("orientation/groundsloped-roll-deg", 0);
	}
}, 1);

var settle_to_level = func {
	# determine slope of ground if on hill, necessary for ufo fdm
	if (groundslope_enabled) {
		var gear1_lat_lon = walk.xy2LatLonZ(-7.087,0);
		var gear2_lat_lon = walk.xy2LatLonZ(4.918,-1.74);
		var gear3_lat_lon = walk.xy2LatLonZ(4.918,1.74);
		var gear1_gnd_elev_m = geo.elevation(gear1_lat_lon[0],gear1_lat_lon[1]);
		var gear2_gnd_elev_m = geo.elevation(gear2_lat_lon[0],gear2_lat_lon[1]);
		var gear3_gnd_elev_m = geo.elevation(gear3_lat_lon[0],gear3_lat_lon[1]);
		var gear23_diff = gear2_gnd_elev_m - gear3_gnd_elev_m;
		var gear23_oh = gear23_diff / (1.74 * 2);
		var gear23_avg = (gear2_gnd_elev_m + gear3_gnd_elev_m) / 2;
		var gear123_diff = gear1_gnd_elev_m - gear23_avg;
		var gear123_oh = gear123_diff / (7.087+4.918);
		if (abs(gear123_oh) > 1) {	# nose > rear gear  hyp distance
			gear123_oh = 1;
		}
		if (gear23_oh > 1) {
			gear23_oh = 1;
		} elsif (gear23_oh < -1) {
			gear23_oh = -1;
		}
		gear_y_roll_deg = walk.asin(gear23_oh) * RAD2DEG;
		gear_x_pitch_deg = walk.asin(gear123_oh) * RAD2DEG;
		setprop("orientation/ground-pitch",gear_x_pitch_deg);
		setprop("orientation/groundsloped-pitch-deg",(gear_x_pitch_deg + pitch_d));
		setprop("orientation/ground-roll",gear_y_roll_deg);
		setprop("orientation/groundsloped-roll-deg",(gear_y_roll_deg + roll_d));
	}
	var hg_roll = roll_deg.getValue() * 0.75;
	roll_deg.setValue(hg_roll);
	var hg_roll = roll_control.getValue() * 0.75;
	roll_control.setValue(hg_roll);
	var hg_pitch = pitch_d * 0.75;
	pitch_deg.setValue(hg_pitch);
	var hg_pitch = pitch_control.getValue() * 0.75;
	pitch_control.setValue(hg_pitch);
}

var check_damage = func (dmg_add) {
	var dmg = getprop("sim/model/bluebird/damage/hits-counter") + dmg_add;
	setprop("sim/model/bluebird/damage/hits-counter", int(dmg));
	if (dmg > destruction_threshold) { 
		# set condition-red damage
		alert_switch_Node.setBoolValue(1);
		if (damage_blocker == 0) {
			damage_blocker = 1;
			damage_count += 1;
			settimer(reset_impact, 2);
			setprop("sim/model/bluebird/position/crash-wow", 1);
			settimer(reset_crash, 5);
			setprop("sim/model/bluebird/damage/major-counter", damage_count);
			strobe_switch.setValue(0);
			zNoseNode.setValue(2.4);
			setprop("sim/model/bluebird/systems/nacelle-L-venting", 1);
			setprop("sim/model/bluebird/systems/nacelle-R-venting", 1);
			setprop("autopilot/locks/altitude", "");
			setprop("autopilot/locks/heading", "");
			set_cockpit(cockpitView);
			interior_lighting_update();
			if (int(100 * rand()) > 70 or dmg > (destruction_threshold * 1.5)) {  # 30% chance a nacelle is destroyed
				setprop("sim/model/bluebird/components/nacelle-L", 0);
				setprop("sim/model/bluebird/components/engine-cover1", 0);
				setprop("sim/model/bluebird/systems/nacelle-L-venting", 0);
				setprop("ai/submodels/engine-L-flaring", 1);
				if (int(100 * rand()) > 90 or dmg > (destruction_threshold * 2)) {  # how likely both were
					setprop("sim/model/bluebird/components/nacelle-R", 0);
					setprop("sim/model/bluebird/components/engine-cover4", 0);
					setprop("sim/model/bluebird/systems/nacelle-R-venting", 0);
					setprop("ai/submodels/engine-R-flaring", 1);
				}
			} elsif (dmg > (destruction_threshold * 0.7)) {
				setprop("ai/submodels/engine-L-flaring", 1);
			}
		}
	}
}

var xyz2sloped = func (x,y,z) {
	# given the x,y offsets of the cockpit view (in meters)
	# translate into view offset considering ground slope
	var c_head_rad = getprop("orientation/heading-deg") * walk.DEG2RAD;
	var c_pitch = getprop("orientation/groundsloped-pitch-deg");
	var c_roll = getprop("orientation/groundsloped-roll-deg");
	var xZ_factor = math.cos(c_pitch * walk.DEG2RAD);
	var x_Zadjust = x * xZ_factor;	# adjusted for pitch
	var yZ_factor = math.cos(c_roll * walk.DEG2RAD);
	var y_Zadjust = y * yZ_factor;	# adjusted for roll
	var zxZ_m = -(x * math.sin(c_pitch * walk.DEG2RAD));
	var zyZ_m = -(y * math.sin(c_roll * walk.DEG2RAD));
	return [x_Zadjust,y_Zadjust,(zxZ_m+zyZ_m)];	# meters
}

#==========================================================================
# -------- MAIN LOOP called by itself every cycle --------

var update_main = func {
	var gnd_elev = ground_elevation_ft.getValue();  # ground elevation
	var altitude = altitude_ft_Node.getValue();  # aircraft altitude
	if (gnd_elev == nil) {    # startup check
		gnd_elev = 0;
	}
	if (altitude == nil) {
		altitude = -9999;
	}
	if (altitude > -9990) {   # wait until program has started
		pitch_d = pitch_deg.getValue();   # update variables used by everybody
		roll_d = roll_deg.getValue();
		airspeed = airspeed_kt_Node.getValue();
		asas = abs(airspeed);
		abs_airspeed_Node.setDoubleValue(asas);
		# ----- initialization checks -----
		if (init_agl > 0) {
			# trigger rumble sound to be on
			setprop("controls/engines/engine/throttle",0.01);
			# find real ground level
			altitude = gnd_elev + init_agl;
			altitude_ft_Node.setDoubleValue(altitude);
			if (init_agl > 1) {
				init_agl -= 0.75;
			} elsif (init_agl > 0.25) {
				init_agl -= 0.25;
			} else {
				init_agl -= 0.05;
			}
			if (init_agl <= 0) {
				setprop("controls/engines/engine/throttle",0);
			}
		}
		var hover_ft = 0;
		contact_altitude = altitude - vertical_offset_ft - gear_height - hover_add;   # adjust calculated altitude for gear up and nacelle/nose dip
		# ----- only check hover if near ground ------------------
		var new_ground_near = 0;   # see if indicator lights can be turned off
		var new_ground_warning = 0;
		var check_agl = (asas * 0.05) + 40;
		if (check_agl < 50) {
			check_agl = 50;
		}
		if (contact_altitude < (gnd_elev + check_agl)) {
			new_ground_near = 1;
			var rolld = abs(roll_deg.getValue()) / 3.5;
			var skid_w2 = 0;
			var skid_altitude_change = 0;
			var g_pitch_d = pitch_d + gear_x_pitch_deg;
			if (g_pitch_d > 0) {    # calculations optimized for gear Down
				if (g_pitch_d < 7.6) {  # try to keep rear of nacelles from touching ground
					hover_add = g_pitch_d / 2.8;
				} elsif (g_pitch_d < 25) {
					hover_add = ((g_pitch_d - 7.6) / 1.65) + 2.714;
				} elsif (g_pitch_d < 52) {
					hover_add = ((g_pitch_d - 25) / 1.8) + 13.259;  # ((25-7.6)/1.65)+2.714
				} elsif (g_pitch_d < 75) {
					hover_add = ((g_pitch_d - 52) / 3.25) + 28.259;
				} else {
					hover_add = ((g_pitch_d - 75) / 7.0) + 35.336;
				}
			} else {
				if (g_pitch_d > -7.6) {  # try to keep nose from touching ground
					hover_add = abs(g_pitch_d / 2.2);
				} elsif (g_pitch_d > -14) {
					hover_add = abs((g_pitch_d + 7.6) / 2.05 ) + 3.455;
				} elsif (g_pitch_d > -32) {
					hover_add = abs((g_pitch_d + 14) / 1.6) + 6.576;
				} elsif (g_pitch_d > -43) {
					hover_add = abs((g_pitch_d + 32) / 1.8) + 17.826;
				} elsif (g_pitch_d > -60) {
					hover_add = abs((g_pitch_d + 43) / 2.2) + 23.937;
				} elsif (g_pitch_d > -73) {
					hover_add = abs((g_pitch_d + 60) / 3.0) + 31.664;
				} else {
					hover_add = abs((g_pitch_d + 73) / 6.5) + 35.997;
				}
			}
			# 1st threshold rolld @ 27 degrees = 7.71
			if (rolld > 7.71) {  # keep nacelles from touching ground
				rolld = ((rolld - 7.71) / 0.6) + 7.71;
			}
			hover_add = hover_add + rolld;   # total clearance for model above gnd_elev
			# add to hover_add the airspeed calculation to increase ground separation with airspeed
			if (asas < 100) {  # near ground hovering altitude calculation
				hover_ft = gear_height + (reactor_drift * asas * 0.03);
			} elsif (asas > 1000) {  # increase separation from ground
				hover_ft = gear_height + (reactor_drift * ((asas * 0.02) + 28));
			} else {    # hold altitude above ground, increasing with velocity
				hover_ft = gear_height + (reactor_drift * ((asas * 0.05) - 2));
			}
			if (gnd_elev < 0) {   
				# likely over ocean water
				gnd_elev = 0;  # keep above water until there is ocean bottom
			}
			contact_altitude = altitude - vertical_offset_ft - gear_height - hover_add;   # update with new hover amounts
			hover_target_altitude = gnd_elev + hover_ft + hover_add + vertical_offset_ft;  # includes gear_height
			h_contact_target_alt = hover_target_altitude - gear_height - hover_add - vertical_offset_ft;
			if (screen_4R_on) {
				var text_4R = sprintf("% 7.3f    % 7.3f    % 8.3f % 11.3f",g_pitch_d,rolld,hover_add,hover_ft);
				displayScreens.scroll_4R(text_4R);
			}
			if (altitude < hover_target_altitude) {
				# below ground/flight level
				if (altitude > 0) {            # check for skid, smoothen sound effects
					if (contact_altitude < gnd_elev) {
						skid_w2 = (gnd_elev - contact_altitude);  # depth
						if (skid_w2 < skid_last_value) {  # abrupt impact or
							# below ground, contact should skid
							skid_w2 = (skid_w2 + skid_last_value) * 0.75; # smoothen ascent
						}
					}
				}
				skid_altitude_change = hover_target_altitude - altitude;
				if (skid_altitude_change > 0.5) {
					new_ground_warning = 1;
					if (skid_altitude_change < hover_ft) {
						# hover increasing altitude, but still above ground
						# add just enough skid to create the sound of 
						# emergency counter-grav to increase elevation
						if (skid_w2 < 1.0) {
							skid_w2 = 1.0;
						}
					}
					if (skid_altitude_change > skid_w2) {
						# keep skid sound going and dig in if bounding up large hill
						var impact_factor = (skid_altitude_change / asas * 25);
						# vulnerability to impact. Increasing from 25 increases vulnerability
						if (skid_altitude_change > impact_factor) {  # but not if on flat ground
							new_ground_warning = 2;
							skid_w2 = skid_altitude_change;  # choose the larger skid value
						}
					}
				}
				if (hover_ft < 0) {  # separate skid effects from actual impact
					altitude = hover_target_altitude - hover_ft;
				} else {
					altitude = hover_target_altitude;
				}
				altitude_ft_Node.setDoubleValue(altitude);  # force above ground elev to hover elevation at contact
				contact_altitude = altitude - vertical_offset_ft - gear_height - hover_add;
				if (g_pitch_d > 0 or g_pitch_d < -0.5) {
					# If aircraft hits ground, then nose/tail gets thrown up
					if (asas > 500) {  # new pitch adjusted for airspeed
						var airspeed_pch = 0.2;  # rough ride
					} else {
						var airspeed_pch = asas / 500 * 0.2;
					}
					if (airspeed > 0.1) {
						if (g_pitch_d > 0) {
							# going uphill
#FIXME account for groundsloped
							g_pitch_d = g_pitch_d * (1.0 + airspeed_pch);
							pitch_d = g_pitch_d - gear_x_pitch_deg;
							pitch_deg.setDoubleValue(pitch_d);
						} else {
							# nose down
							g_pitch_d = g_pitch_d * (1.0 - airspeed_pch);
							pitch_d = g_pitch_d - gear_x_pitch_deg;
							pitch_deg.setDoubleValue(pitch_d);
						}
					} elsif (airspeed < -0.1) {    # reverse direction
						if (g_pitch_d < 0) {  # uphill
							g_pitch_d = g_pitch_d * (1.0 + airspeed_pch);
							pitch_d = g_pitch_d - gear_x_pitch_deg;
							pitch_deg.setDoubleValue(pitch_d);
						} else {
							g_pitch_d = g_pitch_d * (1.0 - airspeed_pch);
							pitch_d = g_pitch_d - gear_x_pitch_deg;
							pitch_deg.setDoubleValue(pitch_d);
						}
					}
				}
			} else {
				# smoothen to zero
				var skid_w2 = (skid_last_value) / 2;
			}
			if (skid_w2 < 0.001) {
				skid_w2 = 0;
			}
			# threshold for determining a damage Hit
			if (skid_w2 > 8 and asas > 80) {   
				# impact greater than 480 feet per second
				wildfire.ignite(geo.aircraft_position());
				var dmg_factor = int(skid_w2 * 0.025 * (abs(g_pitch_d) * 0.011) + 1.0);  # vulnerability to impact
				# increasing number from 0.025 ^^^^^ increases damage per hit
				if (dmg_factor < 1) {  # if impact, then at least one damage unit
					dmg_factor = 1;
				} else {
					var angle_of_damage_max = ((abs(g_pitch_d) * 0.67) + 30);
					if (dmg_factor > angle_of_damage_max) {  # maximum damage per major impact
						dmg_factor = angle_of_damage_max;
					}
				}
				check_damage(dmg_factor);
				var text_3L = sprintf("%3i  **  %4.1f  **  %4.1f  ** %2.0f",getprop("sim/model/bluebird/damage/hits-counter"),skid_w2,angle_of_damage_max,dmg_factor);
				displayScreens.scroll_3L(text_3L);
			}
			var skid_w_vol = clamp((skid_w2 * 0.1), 0, 1);  # factor for volume usage
			if (!damage_count and (skid_altitude_change < 5)) {
				if (abs(g_pitch_d) < 3.75) {
					skid_w_vol = skid_w_vol * (abs(g_pitch_d + 0.25)) * 0.25;
				}
			}
			setprop("sim/model/bluebird/position/skid-wow", skid_w_vol);
			skid_last_value = skid_w2;
		} else { 
			# not near ground, skipping hover
			setprop("sim/model/bluebird/position/skid-wow", 0);
			skid_last_value = 0;
			hover_add = 0;
			h_contact_target_alt = 0;
			if (screen_4R_on) {
				displayScreens.scroll_4R("Above ground envelope");
			}
		}
		# update instrument warning lights if changed
		if (new_ground_near != ground_near) {
			if (new_ground_near) {
				setprop("sim/model/bluebird/lighting/ground-near", 1);
			} else {
				setprop("sim/model/bluebird/lighting/ground-near", 0);
			}
			ground_near = new_ground_near;
		}
		if (new_ground_warning != ground_warning) {
			setprop("sim/model/bluebird/lighting/ground-warning", new_ground_warning);
			ground_warning = new_ground_warning;
		}
		# ----- lose altitude -----
		if (damage_count > 0 or reactor_drift < 0.2 or power_switch == 0) {
			if ((contact_altitude - 0.0001) < h_contact_target_alt) {
				# already on/near ground
				if (lose_altitude > 0.2) {
					lose_altitude = 0.2;  # avoid bouncing by simulating gravity
				}
				if (!countergrav.request) {
					if (!reactor_request) {
						settle_to_level();
					} else {
						setprop("orientation/ground-pitch",0);
						setprop("orientation/groundsloped-pitch-deg",pitch_d);
						setprop("orientation/ground-roll",0);
						setprop("orientation/groundsloped-roll-deg",roll_d);
					}
				} else {
					lose_altitude = 0;
				}
			} else {
				# not on/near ground
				if (!(wave1_level and asas > 150)) {
					# Wave-guide off and not fast enough to fly without counter-grav
					lose_altitude += 0.01;
	# need to adjust terminal velocity based on pitch and add actual physics
					if (lose_altitude > 17) {
						# maximum at terminal velocity with nose down unpowered estimated: 1026ft/sec
						lose_altitude = 17;
					}
					if ((contact_altitude - h_contact_target_alt) < 3) {   # really close to ground but not below it
						if (!reactor_request) {
							settle_to_level();
					} else {
						setprop("orientation/ground-pitch",0);
						setprop("orientation/groundsloped-pitch-deg",pitch_d);
						setprop("orientation/ground-roll",0);
						setprop("orientation/groundsloped-roll-deg",roll_d);
						}
					}
				} else { # fast enough to fly without counter-grav
					lose_altitude = lose_altitude * 0.5;
					if (lose_altitude < 0.001) {
						lose_altitude = 0;
					}
				}
			}
			if (lose_altitude > 0) {
				up(-1, lose_altitude, 0);
			}
		} else {
			lose_altitude = 0;
		}

		# ----- also calculate altitude-agl since ufo model doesn't -----
		var aa = altitude - gnd_elev;
		setprop("sim/model/bluebird/position/shadow-alt-agl-ft", aa);  # shadow doesn't need adjustment for gear
		var agl = contact_altitude - gnd_elev + hover_add;
		setprop("sim/model/bluebird/position/altitude-agl-ft", agl);
		var text_2R = sprintf("%12.2f", agl);
		displayScreens.scroll_2R(text_2R);

		# ----- handle traveling backwards and update movement variables ------
		#       including updating sound based on airspeed
		# === speed up or slow down from engine level ===
		var max = maxspeed.getValue();
		if ((damage_count > 0) or
			(!nacelleL_attached and wave1_request > 0) or 
			(!nacelleR_attached and wave1_request > 0) or
			(!power_switch)) { 
			if (wave1_request) {   # deny Wave-guide drive request
				setprop("sim/model/bluebird/systems/wave1-request", 0);
				wave1_request = 0;
			}
			if (wave2_request) {
				setprop("sim/model/bluebird/systems/wave2-request", 0);
				wave2_request = 0;
			}
			if (damage_count > 2) {
				setprop("sim/model/bluebird/systems/reactor-request", 0);
				reactor_request = 0;
				setprop("sim/model/bluebird/systems/power-switch", 0);
				if (shutdown_venting == 0) {    # turn off extra particles after 1 minute
					shutdown_venting = 1;
					settimer(func {
						setprop("sim/model/bluebird/systems/nacelle-L-venting", 0);
						setprop("sim/model/bluebird/systems/nacelle-R-venting", 0);
						update_venting(1,0);
						}, 60, 1);
				}
			}
		}
		if (cpl > 6) {
			if (cpl > 10 and contact_altitude < 792000 and max_to > 10) {
				popupTip2("Approaching planet. Reducing speed");
				change_maximum(cpl, 10, 1); 
			} elsif (cpl > 9 and contact_altitude < 328000 and max_to > 9) {
				popupTip2("Entering upper atmosphere. Reducing speed");
				change_maximum(cpl, 9, 1); 
			} elsif (cpl > 8 and contact_altitude < 50000 and max_to > 8) {
				popupTip2("Entering lower atmosphere. Reducing speed");
				change_maximum(cpl, 8, 1); 
			} elsif (cpl > 7 and contact_altitude < 15000 and max_to > 7) {
				popupTip2("Entering lower atmosphere. Reducing speed");
				change_maximum(cpl, 7, 1); 
			}
		}
		if (!power_switch) {
			change_maximum(cpl, 0, 2);
			if (wave1_level) {
				setprop("sim/model/bluebird/systems/wave1-level", 0);
			}
			if (wave2_level) {
				wave2_level = 0;
			}
			if (agl > 10) {   # not in ground contact, glide
				max_lose = max_lose + (0.005 * abs(pitch_d));
			} else {     # rapid deceleration
				if (gear_position) {
					max_lose = (asas > 15 ? (asas * 0.2) : 3);
				} else {
					max_lose = (asas < 80 ? (asas > 20 ? 16 : ((100 - asas) * asas * 0.01)) : (asas * 0.2));
				}
			}
	# need to import acceleration physics calculations from walker
			if (max_lose > 10) {  # don't decelerate too quickly
				if (agl > 10) {
					max_lose = 10;
				} else {
					if (max_lose > 75) {
						max_lose = 75;
					}
				}
			}
			if (asas < 5) {  # already stopped
				maxspeed.setDoubleValue(0);
				setprop("controls/engines/engine/throttle", 0.0);
			}
			max_drift = max_lose;
		} else {  # power is on
			if (reactor_request != reactor_level) {
				change_maximum(cpl, limit[(reactor_request + (wave1_level * 2) + (wave2_level * 4))] - damage_count, 2);
				setprop("sim/model/bluebird/systems/reactor-level", reactor_request);
			}
			if (wave1_request != wave1_level) {
				change_maximum(cpl, limit[(reactor_level + (wave1_request * 2) + (wave2_level * 4))] - damage_count, 2);
				setprop("sim/model/bluebird/systems/wave1-level", wave1_request);
			}
			if (wave2_request != wave2_level) {
				change_maximum(cpl, limit[(reactor_level + (wave1_level * 2) + (wave2_request * 4))] - damage_count, 2);
				wave2_level = wave2_request;
			}
		}
		if (max > 1 and max_to < max_from) {      # decelerate smoothly
			max -= (max_drift / 2);
			if (max <= speed_mps[max_to]) {     # destination reached
				cpl = max_to;
				max_from = max_to;
				max = speed_mps[max_to];
				max_drift = 0;
				max_lose = 0;
				if (!power_switch) {       # override if no power
					max = 1;
				}
			}
			maxspeed.setDoubleValue(max);
		}
		if (max_to > max_from) {         # accelerate
			if (current_to == max_to) {   # normal request to change power-maxspeed
				max += max_drift;
				if (max >= speed_mps[max_to]) { 
					# destination reached
					cpl = max_to;
					max_from = max_to;
					max = speed_mps[max_to];
					max_drift = 0;
					max_lose = 0;
				}
				maxspeed.setDoubleValue(max);
			} else {    # only change maximum, as when turning on an engine
				max_from = max_to;
				max_drift = 0;
				max_lose = 0;
				if (cpl == 0 and current_to == 0) {     # turned on power from a complete shutdown
					maxspeed.setDoubleValue(speed_mps[2]);
					current_to = max_to;
					cpl = 2;
				}
			}
		}
		current.setValue(cpl);

		# vtol control in cockpit yoke
		if (hover_reset_timer > 0) {
			hover_reset_timer -= 0.1;
			if (hover_reset_timer < 0.9 or countergrav.momentum_watch < 3) {
				var rh_x = (getprop("sim/model/bluebird/position/hover-rise") * 0.5);
				if (abs(rh_x) < 0.1) {
					setprop("sim/model/bluebird/position/hover-rise", 0);
					hover_reset_timer = 0;
				} else {
					setprop("sim/model/bluebird/position/hover-rise", rh_x);
				}
			}
		}

		# === sound section based on position/airspeed/altitude ===
		var slv = sound_level;
		var old_engine_level = reactor_drift;
		if (power_switch) {
			if (reactor_drift < 1 and slv > 1) {  # shutdown reactor before timer shutdown of standby power
				slv = 0.99;
			}
			if (asas < 1 and agl < 2 and !countergrav.request) {
				if (sound_state and slv > 0.999) {  # shutdown request by landing has 2.5 sec delay
					slv = 2.5;
				}
				sound_state = 0;
			} else {
				if (((reactor_state < reactor_drift) or (!reactor_state)) and asas < 5 and !countergrav.request) {  # countergrav shutdown
					sound_state = 0;
					countergrav.request = 0;
					if (countergrav.momentum_watch) {
						countergrav.up_factor = 0;
						countergrav.momentum_watch -= 1;
					}
					if (slv >= 1) {
						slv = 0.99;
					}
				} else {
					if (asas > 5 or agl >= 2 or countergrav.request) {
						sound_state = 1;
					} else {
						sound_state = 0;
					}
				}
			}
		} else {
			if (sound_state) {  # power shutdown with reactor on. single entry.
				slv = 0.99;
				sound_state = 0;
				countergrav.request = 0;
			}
		}
		if (sound_state != slv) {  # ramp up reactor sound fast or down slow
			if (sound_state) { 
				slv += 0.02;
			} else {
				slv -= 0.00625;
			}
			if (sound_state and slv > 1.0) {  # bounds check
				slv = 1.000;
				countergrav.request = 0;
			}
			if (slv > 0.5 and countergrav.request > 0) {
				if (countergrav.request <= 1) {
					countergrav.request -= 0.025;  # reached sufficient power to turn off trigger
					slv -= 0.02;  # hold this level for a couple seconds until either another
					# keyboard/joystick request confirms startup, or time expires and shutdown
					if (countergrav.request < 0.1) {
						countergrav.request = 0;  # holding time expired
					}
				}
			}
			if (slv < 0.0) {
				slv = 0.000;
			}
			sound_level = slv;
		}
		# engine rumble sound
		if (asas < 200) {
			var a1 = 0.1 + (asas * 0.002);
		} elsif (asas < 4000) {
			var a1 = 0.5 + ((asas - 200) * 0.0001315);
		} else {
			var a1 = 1.0;
		}
		var a3 = (asas * 0.000187) + 0.25;
		if (a3 > 0.75) {
			a3 = ((asas - 4000) / 384000) + 0.75;
		}
		if (slv > 1.0) {    # timer to shutdown
			var a2 = a1;
			var a6 = 1;
		} else {      # shutdown progressing
			var a2 = a1 * slv;
			a3 = a3 * slv;
			var a6 = slv;
		}
		if (wave1_level) {
			if (asas > 1 or slv == 1.0 or slv > 2.0) {
				wave_state = (asas * 0.0004) + 0.2;
			} elsif (slv > 1.6) {
				wave_state = ((slv * 3) - 5) * ((asas * 0.0004) + 0.2);
			} else {
				wave_state = 0;
			}
		} else {
			wave_state = 0;
		}
		if (reactor_level) {
			if (damage_count) {
				reactor_state = a6 * 0.5;
				setprop("instrumentation/display-screens/t1L-3", "50%");
			} else {
				reactor_state = a6;
			}
		} else {
			reactor_state = 0;
		}
		if (power_switch) {
			if (reactor_state > reactor_drift) {
				reactor_drift += 0.04;
				setprop("instrumentation/display-screens/t1L-3", "POWERING UP");
				if (reactor_drift > reactor_state) {
					reactor_drift = reactor_state;
				}
			} elsif (reactor_state < reactor_drift) {
				setprop("instrumentation/display-screens/t1L-3", "POWERING DOWN");
				if (reactor_level) {
					reactor_drift = reactor_state;
				} else {
					reactor_drift -= 0.02;
				}
			}
		} else {
			reactor_drift -= 0.02;
			setprop("instrumentation/display-screens/t1L-3", "POWERING DOWN");
		}
		if (reactor_drift < 0) {  # bounds check
			reactor_drift = 0;
		}
		if (wave_state > wave_drift) {
			wave_drift += 0.1;
			if (wave_drift > wave_state) {
				wave_drift = wave_state;
			}
		} elsif (wave_state < wave_drift) {
			if (wave1_level) {
				wave_drift -= 0.1;
			} else {
				wave_drift -= 0.02;
			}
			if (wave_drift < wave_state) {
				wave_drift = wave_state;
			}
		}
		var a4 = wave_drift;
		if (!reactor_level and !wave1_level) {
			a2 = a2 / 2;
		}
		if (a3 > 2.0) {  # upper limit of pitch factoring
			a3 = 2.0;
		}
		if (a4 > 1.75) {
			a4 = 1.75;
		}
		setprop("sim/model/bluebird/sound/engines-volume-level", a2);
		setprop("sim/model/bluebird/sound/pitch-level", a3);
		if (old_engine_level != reactor_drift) {
			setprop("sim/model/bluebird/lighting/engine-glow", reactor_drift);
			buttonL67_update(0);
		}
		if (!power_switch) {
			setprop("sim/model/bluebird/lighting/power-glow", reactor_drift);
		}
		if (reactor_level) {
			if (!reactor_drift and !power_switch and !slv) {
				setprop("sim/model/bluebird/systems/reactor-level", 0);
			}
		}
		setprop("sim/model/bluebird/lighting/wave-guide-glow", a4);
		var a9 = (wave_drift * 56.41) - 9;
		if (a9 > 90) {
			a9 = 78.898 + (math.sqrt(wave_drift) * 8.38);
		} elsif (a9 < 0) {
			a9 = 0;
		}
		setprop("instrumentation/display-screens/t1L-10", int(a9));
		var a7 = getprop("sim/model/bluebird/lighting/wave-guide-halo-spin");
		var a8 = a7 + (airspeed * 0.00017);
		if (a8 < 0) {
			a8 = abs(1 + a8);
		}
		a7 = abs(a8 - int(a8));
		setprop("sim/model/bluebird/lighting/wave-guide-halo-spin", a7);

		if (cockpitView == 1 or cockpitView == 4) {
			var damage_adjust_z = 0;
		} else {
			var damage_adjust_z = (damage_count <= 2 ? damage_count : 2);
		}

		if (groundslope_enabled) {
			var view0_coord = xyz2sloped(cockpit_locations[cockpitView].x,cockpit_locations[cockpitView].y,cockpit_locations[cockpitView].z[damage_adjust_z]);
			setprop("/sim/view[0]/config/z-offset-m", (cockpit_locations[cockpitView].x + view0_coord[0]));
			setprop("/sim/view[0]/config/x-offset-m", (cockpit_locations[cockpitView].y + view0_coord[1]));
			setprop("/sim/view[0]/config/y-offset-m", (cockpit_locations[cockpitView].z[damage_adjust_z] + view0_coord[2]));
			setprop("/sim/view[0]/config/pitch-offset-deg", (getprop("/orientation/pitch-deg") + gear_x_pitch_deg));
			setprop("/sim/view[0]/config/roll-offset-deg", (getprop("/orientation/roll-deg") + gear_y_roll_deg));
			if (getprop("sim/current-view/view-number") == 0) {
				xViewNode.setValue(view0_coord[0]);
				yViewNode.setValue(view0_coord[1]);
				zViewNode.setValue(cockpit_locations[cockpitView].z[damage_adjust_z] + view0_coord[2]);
			}
		}

		# nacelle venting
		if (venting_direction >= -1) {
			update_venting(0,0);
		}
	}
	settimer(update_main, 0);
}

# VTOL counter-grav functions ---------------------------------------

controls.aileronTrim = func(at_d) {
	if (!at_d) {
		return;
	} else {
		var js1collective = abs(joystick_collective.getValue());
		if (at_d < 0 and js1collective >= 1) {
			joystick_collective.setValue(js1collective - 1);
		} elsif (at_d <= 15) {
			joystick_collective.setValue(js1collective + 1);
		}
	}
}

controls.elevatorTrim = func(et_d) {
	if (!et_d) {
		return;
	} else {
		countergrav.input_type = 2;
		var js1pitch = abs(joystick_elevator.getValue());
		up((et_d < 0 ? -1 : 1), js1pitch, 2);
	}
}

var reset_landing = func {
	setprop("sim/model/bluebird/position/landing-wow", 0);
}

setlistener("sim/model/bluebird/position/landing-wow", func(n) {
	if (n.getValue()) {
		settimer(reset_landing, 0.4);
		if (countergrav.momentum) {
			countergrav.up_factor = 0;
			countergrav.momentum_watch -= 1;
			countergrav.momentum = 0;
		}
	}
},, 0);

var reset_squeal = func {
	setprop("sim/model/bluebird/position/squeal-wow", 0);
}

setlistener("sim/model/bluebird/position/squeal-wow", func(n) {
	if (n.getValue()) {
		settimer(reset_squeal, 0.3);
	}
},, 0);

var reset_crash = func {
	setprop("sim/model/bluebird/position/crash-wow", 0);
}

# mouse hover -------------------------------------------------------
#var KbdShift = props.globals.getNode("/devices/status/keyboard/shift");
#var KbdCtrl = props.globals.getNode("/devices/status/keyboard/ctrl");
var mouse = { savex: nil, savey: nil };
setlistener("/sim/startup/xsize", func(n) mouse.centerx = int(n.getValue() / 2), 1);
setlistener("/sim/startup/ysize", func(n) mouse.centery = int(n.getValue() / 2), 1);
setlistener("/sim/mouse/hide-cursor", func(n) mouse.hide = n.getValue(), 1);
#setlistener("/devices/status/mice/mouse/x", func(n) mouse.x = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/y", func(n) mouse.y = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/mode", func(n) mouse.mode = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/button[0]", func(n) mouse.lmb = n.getValue(), 1);
setlistener("/devices/status/mice/mouse/button[1]", func(n) {
	mouse.mmb = n.getValue();
	if (mouse.mode)
		return;
	if (mouse.mmb) {
		controls.centerFlightControls();
#		mouse.savex = mouse.x;
		mouse.savey = mouse.y;
		gui.setCursor(mouse.centerx, mouse.centery, "none");
	} else {
		gui.setCursor(mouse.savex, mouse.savey, "pointer");
		countergrav.up_factor = 0;
		if (countergrav.momentum_watch > 0) {
			countergrav.momentum_watch -= 1;
		}
	}
}, 1);
setlistener("/devices/status/mice/mouse/button[2]", func(n) {
	mouse.rmb = n.getValue();
	if (countergrav.momentum_watch) {
		countergrav.up_factor = 0;
		countergrav.momentum_watch -= 1;
	}
}, 1);


mouse.loop = func {
	if (mouse.mode or !mouse.mmb) {
		return settimer(mouse.loop, 0);
	}
#	var dx = mouse.x - mouse.centerx;
	var dy = -mouse.y + mouse.centery;
	if (dy) {
		countergrav.input_type = 3;
		countergrav.up_factor = dy * 0.001;
		if (countergrav.momentum_watch < 1) {
			countergrav.momentum_watch = 3;
			coast_up(coast_loop_id += 1);
		}
		gui.setCursor(mouse.centerx, mouse.centery);
	}
	settimer(mouse.loop, 0);
}
mouse.loop();

# keyboard hover ----------------------------------------------------
setlistener("sim/model/bluebird/hover/key-up", func(n) {
	var key_dir = n.getValue();
	if (key_dir) {	# repetitive input or lack of older mod-up may keep triggering
		countergrav.input_type = 1;
		countergrav.up_factor = (key_dir < 0 ? -0.01 : 0.01);
		if (countergrav.momentum_watch <= 0) {
			countergrav.momentum_watch = 3;	# start or reset timer for countdown
			coast_up(coast_loop_id += 1);	# starting from rest, start new loop
		} else {
			countergrav.momentum_watch = 3;	# reset watcher
		}
	} else {
		countergrav.momentum_watch -= 1;
		countergrav.up_factor = 0;
		if (countergrav.momentum_watch < 0) {
			countergrav.momentum_watch = 0;
		}
	}
});

var coast_loop_id = 0;
var coast_up = func (id) {
	id == coast_loop_id or return;
	if (countergrav.momentum_watch >= 3) {
		countergrav.momentum += countergrav.up_factor;
		if (countergrav.input_type == 3) {
			countergrav.up_factor = 0;
		}
		if (abs(countergrav.momentum) > 2.0) {
			countergrav.momentum = (countergrav.momentum < 0 ? -2.0 : 2.0);
		}
	} elsif (countergrav.momentum_watch >= 2) {
		countergrav.momentum_watch -= 1;
	} else {
		countergrav.momentum = countergrav.momentum * 0.75;
		if (abs(countergrav.momentum) < 0.02) {
			countergrav.momentum = 0;
			countergrav.momentum_watch = 0;
		}
	}
	if (countergrav.momentum) {
		up((countergrav.momentum < 0 ? -1 : 1), countergrav.momentum, countergrav.input_type);
	}
	if (countergrav.momentum_watch) {
		settimer(func { coast_up(coast_loop_id += 1) }, 0);
	} else {
		countergrav.momentum = 0;
	}
}

var up = func(hg_dir, hg_thrust, hg_mode) {  # d=direction p=thrust_power m=source of request
	var entry_altitude = altitude_ft_Node.getValue();
	var altitude = entry_altitude;
	contact_altitude = altitude - vertical_offset_ft - gear_height - hover_add;
	if (hg_mode == 1 or hg_mode == 3) {
		# 1 = keyboard , 3 = mouse
		var hg_rise = countergrav.momentum * countergrav.control_factor;
	} else {
		# 0 = gravity , 2 = joystick
		var hg_rise = hg_thrust * countergrav.control_factor * hg_dir;
	}
	var contact_rise = contact_altitude + hg_rise;
	if (hg_dir < 0) {    # down requested by drift, fall, or VTOL down buttons
		if (contact_rise < h_contact_target_alt) {  # too low
			contact_rise = h_contact_target_alt + 0.0001;
			if ((contact_rise < contact_altitude) and !countergrav.request) {
				if (asas < 40) {  # ground contact by landing or falling fast
					if (lose_altitude > 0.2 or hg_rise < -0.5) {
						var already_landed = getprop("sim/model/bluebird/position/landing-wow");
						if (!already_landed) {
							setprop("sim/model/bluebird/position/landing-wow", 1);
						}
						check_damage(lose_altitude * 5);
						var text_3L = sprintf("%3i  **             %4.1f",getprop("sim/model/bluebird/damage/hits-counter"), (lose_altitude * 5));
						displayScreens.scroll_3L(text_3L);
						lose_altitude = 0;
						if (!reactor_request) {
							settle_to_level();
						} else {
							setprop("orientation/ground-pitch",0);
							setprop("orientation/groundsloped-pitch-deg",pitch_d);
							setprop("orientation/ground-roll",0);
							setprop("orientation/groundsloped-roll-deg",roll_d);
						}
					} else {
						lose_altitude = lose_altitude * 0.5;
					}
				} elsif (lose_altitude > 0.26 and hg_rise < -1.1) {  # ground contact by skidding slowly
					setprop("sim/model/bluebird/position/squeal-wow", 1);
						lose_altitude = lose_altitude * 0.5;
					check_damage(lose_altitude);
					var text_3L = sprintf("%3i  **             %4.1f",getprop("sim/model/bluebird/damage/hits-counter"), (lose_altitude * 5));
					displayScreens.scroll_3L(text_3L);
					if (!reactor_request) {
						settle_to_level();
					} else {
						setprop("orientation/ground-pitch",0);
						setprop("orientation/groundsloped-pitch-deg",pitch_d);
						setprop("orientation/ground-roll",0);
						setprop("orientation/groundsloped-roll-deg",roll_d);
					}
				}
			} else {
				lose_altitude = lose_altitude * 0.5;
			}
		}
		if (!countergrav.request) {  # fall unless countergrav just requested
			altitude = contact_rise + vertical_offset_ft + gear_height + hover_add;
			altitude_ft_Node.setDoubleValue(altitude);
			contact_altitude = contact_rise;
		}
	} elsif (hg_dir > 0) {  # up
		if (reactor_drift < 0.5 and reactor_level) {  # on standby, power up requested for hover up
			if (power_switch) {
				setprop("sim/model/bluebird/systems/reactor-request", 1);
				countergrav.request += 1;   # keep from forgetting until reactor powers up over 0.5
				countergrav.momentum = 0;
			}
		}
		if (reactor_drift > 0.2 and reactor_level) {  # sufficient power to comply and lift
			contact_rise = contact_altitude + (reactor_drift * hg_rise);
			altitude = contact_rise + vertical_offset_ft + gear_height + hover_add;
			altitude_ft_Node.setDoubleValue(altitude);
			contact_altitude = contact_rise;
		}
	}
	if (screen_5R_on) {
		var text_5R = sprintf("% 10.3f   % 8.2f     % 6.2f",hg_rise,reactor_drift,lose_altitude);
		displayScreens.scroll_5R(text_5R);
	}
	if (hg_mode) {
		# move control yoke up or down. maximum rotation = 4 deg.
		var new_rise = 0;
		if (hg_mode == 2) {	# joystick
			new_rise = 3.3 * hg_thrust * hg_dir;
			hover_reset_timer = 1.0;
			setprop("sim/model/bluebird/position/hover-rise", new_rise);
		} else {
			if (countergrav.momentum_watch >= 3) {
				new_rise = countergrav.momentum * 1.66 + (hg_dir < 0 ? -1 : 1);
				hover_reset_timer = 1.0;
				setprop("sim/model/bluebird/position/hover-rise", new_rise);
			}
		}
	}
	if ((entry_altitude + hg_rise + 0.01) < altitude) {  # did not achieve full request. must've touched ground
		if (lose_altitude > 0.2) {
			lose_altitude = 0.2;
		}
	}
}

# keyboard and 3-d functions ----------------------------------------

var toggle_power = func(tp_mode) {
	if (tp_mode == 9) {  # clicked from dialog box
		if (!power_switch) {
			setprop("sim/model/bluebird/systems/reactor-request", 0);
			setprop("sim/model/bluebird/systems/wave1-request", 0);
		}
	} else {   # clicked from 3d-panel
		if (power_switch) {
			setprop("sim/model/bluebird/systems/power-switch", 0);
			setprop("sim/model/bluebird/systems/reactor-request", 0);
			setprop("sim/model/bluebird/systems/wave1-request", 0);
		} else {
			setprop("sim/model/bluebird/systems/power-switch", 1);
			setprop("sim/model/bluebird/lighting/power-glow", 1);
		}
	}
	interior_lighting_update();
	bluebird.reloadDialog1();
}

var toggle_fusion = func {
	if (reactor_request) {
		setprop("sim/model/bluebird/systems/reactor-request", 0);
	} else {
		if (power_switch) {
			setprop("sim/model/bluebird/systems/reactor-request", 1);
		} else {
			popupTip2("Unable to comply. Main power is off.");
		}
	}
	settimer(panel_lighting_loop, 0.05);
	bluebird.reloadDialog1();
}

var toggle_wave1 = func {
	if (wave1_request) {
		setprop("sim/model/bluebird/systems/wave1-request", 0);
	} else {
		if (power_switch) {
			setprop("sim/model/bluebird/systems/wave1-request", 1);
		} else {
			popupTip2("Unable to comply. Main power is off.");
		}
	}
	settimer(panel_lighting_loop, 0.05);
	bluebird.reloadDialog1();
}

var toggle_wave2 = func {
	if (wave2_request) {
		setprop("sim/model/bluebird/systems/wave2-request", 0);
	} else {
		if (power_switch) {
			if (wave1_request) {
				setprop("sim/model/bluebird/systems/wave2-request", 1);
			} else {
				popupTip2("Unable to comply. Wave-guide drive is off.");
			}
		} else {
			popupTip2("Unable to comply. Main power is off.");
		}
	}
	settimer(panel_lighting_loop, 0.05);
	bluebird.reloadDialog1();
}

var toggle_lighting = func(tl_button_num) {
	if (tl_button_num == 5) {
		set_landing_lights(-1);
	} elsif (tl_button_num == 6) {
		set_nav_lights(-1);
	} elsif (tl_button_num == 7) {
		if (beacon_switch.getValue()) {
			beacon_switch.setBoolValue(0);
		} else {
			beacon_switch.setBoolValue(1);
		}
	} elsif (tl_button_num == 8) {
		if (strobe_switch.getValue()) {
			strobe_switch.setBoolValue(0);
		} else {
			strobe_switch.setBoolValue(1);
		}
	} elsif (tl_button_num == 9) {
		if (int_switch) {
			int_switch = 0;
		} else {
			int_switch = 1;
		}
		setprop("sim/model/bluebird/lighting/interior-switch", int_switch);
		interior_lighting_update();
	}
	settimer(panel_lighting_loop, 0.05);
	bluebird.reloadDialog1();
}

var delayed_panel_update = func {
	if (!power_switch) {
		setprop("sim/model/bluebird/systems/reactor-request", 0);
		setprop("sim/model/bluebird/systems/wave1-request", 0);
		setprop("sim/model/bluebird/systems/wave2-request", 0);
		popupTip2("Unable to comply. Main power is off.");
	} else {
		settimer(panel_lighting_loop, 0.1);
	}
}

setlistener("sim/model/bluebird/crew/cockpit-position", func(n) {
	cockpitView = n.getValue();
	var move_chair = [0,1,0,0,1];
	if (!getprop("sim/model/bluebird/crew/pilot/visible") and move_chair[cockpitView]) {
		setprop("sim/model/bluebird/crew/pilot/chair-back", 1);
	} else {
		setprop("sim/model/bluebird/crew/pilot/chair-back", 0);
	}
});

var set_cockpit = func(cockpitPosition) {
	var num_positions = size(cockpit_locations) - 1;
	if (cockpitPosition > num_positions) {
		cockpitPosition = 0;
	}
	if (cockpitPosition < 0) { cockpitPosition = num_positions; }
	setprop("sim/model/bluebird/crew/cockpit-position", cockpitPosition);
	if (!getprop("sim/walker/outside")) {
		setprop("sim/model/bluebird/crew/walker/x-offset-m", cockpit_locations[cockpitPosition].x);
		setprop("sim/model/bluebird/crew/walker/y-offset-m", cockpit_locations[cockpitPosition].y);
	}
	if (getprop("sim/current-view/view-number") == 0) {
		var damage_adjust_x = (damage_count == 0 ? cockpit_locations[cockpitPosition].x : cockpit_locations[cockpitPosition].x - 0.1);
		if (cockpitPosition == 1 or cockpitPosition == 4) {
			var damage_adjust_z = 0;
		} else {
			var damage_adjust_z = (damage_count <= 2 ? damage_count : 2);
		}
		# axis are different for current-view
		#  x = right/left
		#  y = up/down
		#  z = aft/fore
		setprop("sim/current-view/z-offset-m", damage_adjust_x);
		setprop("sim/current-view/x-offset-m", cockpit_locations[cockpitPosition].y);
		setprop("sim/current-view/y-offset-m", cockpit_locations[cockpitPosition].z[damage_adjust_z]);
		setprop("sim/current-view/goal-heading-offset-deg", cockpit_locations[cockpitPosition].h);
		setprop("sim/current-view/heading-offset-deg", cockpit_locations[cockpitPosition].h);
		setprop("sim/current-view/goal-pitch-offset-deg", cockpit_locations[cockpitPosition].p);
		setprop("sim/current-view/pitch-offset-deg", cockpit_locations[cockpitPosition].p);
		setprop("sim/current-view/field-of-view", cockpit_locations[cockpitPosition].fov);
	}
}

var cycle_cockpit = func(cc_i) {
	if (cc_i == 10) {	# jump to helm and restore forward view
		setprop("sim/current-view/view-number", 0);
		cockpitView = 0;
	} else {
		cockpitView += cc_i;
	}
	set_cockpit(cockpitView);
	if (cc_i == 10) {
		hViewNode.setValue(0.0);
		setprop("sim/current-view/goal-roll-offset-deg", 0.0);
	}
}

var walk_about_cabin = func(wa_distance, walk_offset) {
	# x,y,z axis are as expected here. Check boundaries/walls.
	#  x = aft/fore
	#  y = right/left
	#  z = up/down
	var w_out = 0;
	var cpos = getprop("sim/model/bluebird/crew/cockpit-position");
	if (cpos != 0) {
		var view_head = hViewNode.getValue();
		setprop("sim/model/bluebird/crew/walker/head-offset-deg", view_head);
		var heading = walk_offset + view_head;
		while (heading >= 360.0) {
			heading -= 360.0;
		}
		while (heading < 0.0) {
			heading += 360.0;
		}
		var wa_heading_rad = heading * 0.01745329252;
		var new_x_position = getprop("sim/model/bluebird/crew/walker/x-offset-m") - (math.cos(wa_heading_rad) * wa_distance);
		var new_y_position = getprop("sim/model/bluebird/crew/walker/y-offset-m") - (math.sin(wa_heading_rad) * wa_distance);
		var door0_barrier = (door0_position < 0.62 ? -1.3 : -4.42);
		var door1_barrier = (door1_position < 0.62 ? 1.3 : 4.42);
		var door5_barrier = (door5_position < 0.62 ? 8.9 : 10.57);	# 10.8 when hatch up in flight
		if (cpos == 1 or cpos == 4) {
			if (new_x_position < -5.85) {
				new_x_position = -5.85;
			}
		} elsif (cpos == 2 or cpos == 3) {
			if (new_x_position < -6.79) {
				new_x_position = -6.79;
			}
		}
		# check outside walls
		if (new_x_position <= -1.92) {	# divide search by half
			if (new_x_position <= -8.0) {
				new_x_position = -8.0;
				if (new_y_position < -0.4) {
					new_y_position = -0.4;
				} elsif (new_y_position > 0.4) {
					new_y_position = 0.4;
				}
			} elsif (new_x_position > -8.0 and new_x_position < -5.76) {
				var y_angle = (new_x_position + 8.0) / 2.24 * 0.92;
				if (new_y_position < (-0.24 - y_angle)) {
					new_y_position = -0.24 - y_angle;
				} elsif (new_y_position > (0.24 + y_angle)) {
					new_y_position = 0.24 + y_angle;
				}
			} elsif (new_x_position >= -5.76 and new_x_position <= -4.9) {
				var y_angle = (new_x_position + 5.76) / 0.86 * 0.088;
				if (new_y_position < (-1.16 - y_angle)) {
					new_y_position = -1.16 - y_angle;
				} elsif (new_y_position > (1.16 + y_angle)) {
					new_y_position = 1.16 + y_angle;
				}
			} elsif (new_x_position > -4.9 and new_x_position < -4.2) {
				if (new_y_position < -1.0) {
					new_x_position = -4.9;
					if (new_y_position < -1.248) {
						new_y_position = -1.248;
					}
				} elsif (new_y_position < -0.83) {
					new_y_position = -0.83;
				} elsif (new_y_position > 1.0) {
					new_x_position = -4.9;
					if (new_y_position > 1.248) {
						new_y_position = 1.248;
					}
				} elsif (new_y_position > 0.83) {
					new_y_position = 0.83;
				}
			} elsif (new_x_position >= -4.2 and new_x_position <= -3.95) {
				if (new_y_position < -0.83) {
					new_y_position = -0.83;
				} elsif (new_y_position > 0.83) {
					new_y_position = 0.83;
				}
			} elsif (new_x_position > -3.95 and new_x_position < -3.45) {
				var y_angle = (new_x_position + 3.95) / 0.5 * 0.27;
				if (new_y_position < (-0.83 - y_angle)) {
					new_y_position = -0.83 - y_angle;
				} elsif (new_y_position > (0.83 + y_angle)) {
					new_y_position = 0.83 + y_angle;
				}
			} elsif (new_x_position >= -3.45 and new_x_position <= -3.1) {
				if (new_y_position < door0_barrier) {
					new_x_position = -3.1;
					new_y_position = door0_barrier;
				} elsif (new_y_position < -1.4) {
					new_x_position = -3.1;
				} elsif (new_y_position < -1.1) {
					new_y_position = -1.1;
				} elsif (new_y_position > door1_barrier) {
					new_x_position = -3.1;
					new_y_position = door1_barrier;
				} elsif (new_y_position > 1.4) {
					new_x_position = -3.1;
				} elsif (new_y_position > 1.1) {
					new_y_position = 1.1;
				}
			} elsif (new_x_position > -3.1 and new_x_position < -2.1) {
				# between front hatches
				if (new_x_position < -3.1 and 
					(new_y_position < door0_barrier or new_y_position > door1_barrier)) {
						new_x_position = -3.1;
				} elsif (new_x_position > -2.1 and 
					(new_y_position < door0_barrier or new_y_position > door1_barrier)) {
						new_x_position = -2.1;
				}
				if (new_y_position < door0_barrier) {
					if (door0_position > 0.62) {
						w_out = 1;
					}
					new_y_position = door0_barrier;
				} elsif (new_y_position > door1_barrier) {
					if (door1_position > 0.62) {
						w_out = 2;
					}
					new_y_position = door1_barrier;
				}
			} elsif (new_x_position >= -2.1 and new_x_position <= -1.94) {
				if (new_y_position < door0_barrier) {
					new_x_position = -2.1;
					new_y_position = door0_barrier;
				} elsif (new_y_position < -1.4) {
					new_x_position = -2.1;
				} elsif (new_y_position < -1.1) {
					new_y_position = -1.1;
				} elsif (new_y_position > door1_barrier) {
					new_x_position = -2.1;
					new_y_position = door1_barrier;
				} elsif (new_y_position > 1.4) {
					new_x_position = -2.1;
				} elsif (new_y_position > 1.1) {
					new_y_position = 1.1;
				}
			}
		} else {
			if (new_x_position > -1.94 and new_x_position < -1.52) {
				if (new_y_position < -0.6) {
					new_x_position = -1.94;
					if (new_y_position < -1.3) {
						new_y_position = -1.3;
					}
				} elsif (new_y_position < -0.38) {
					new_y_position = -0.38;
				} elsif (new_y_position > 0.6) {
					new_x_position = -1.94;
					if (new_y_position > 1.3) {
						new_y_position = 1.3;
					}
				} elsif (new_y_position > 0.38) {
					new_y_position = 0.38;
				}
				if (new_y_position > -0.40 and new_y_position < 0.40) {
					if (getprop("sim/model/bluebird/doors/door[2]/position-norm") < 0.7) {
						if (new_x_position < -1.733) {
							new_x_position = -1.94;
						} else {
							new_x_position = -1.51;
						}
					}
				}
			} elsif (new_x_position >= -1.52 and new_x_position < -1.22) {
				if (new_y_position < -0.38) {
					new_y_position = -0.38;
				} elsif (new_y_position > 0.38) {
					new_y_position = 0.38;
				}
			} elsif (new_x_position >= -1.22 and new_x_position <= -0.81) {
				if (new_y_position < -0.54) {
					new_x_position = -0.81;
					if (new_y_position < -1.39) {
						new_y_position = -1.39;
					} elsif (getprop("sim/model/bluebird/doors/door[3]/position-norm") < 0.7 and new_y_position > -0.81) {
						new_y_position = -0.81;
					}
				} else {
					if (new_y_position < -0.38) {
						new_y_position = -0.38;
					} elsif (new_y_position > 0.38) {
						new_y_position = 0.38;
					}
				}
			} elsif (new_x_position > -0.81 and new_x_position < -0.40) {
				if (new_y_position < -0.38) {
					if (new_y_position < -1.39) {
						new_y_position = -1.39;
					} elsif (getprop("sim/model/bluebird/doors/door[3]/position-norm") < 0.7) {
						if (new_y_position > -0.54) {
							new_y_position = -0.38;
						} elsif (new_y_position > -0.81) {
							new_y_position = -0.81;
						}
					}
				} elsif (new_y_position > 0.38) {
					new_y_position = 0.38;
				}
			} elsif (new_x_position >= -0.40 and new_x_position < -0.24) {
				if (new_y_position < -0.54) {
					new_x_position = -0.40;
					if (new_y_position < -1.39) {
						new_y_position = -1.39;
					} elsif (getprop("sim/model/bluebird/doors/door[3]/position-norm") < 0.7 and new_y_position > -0.81) {
						new_y_position = -0.81;
					}
				} else {
					if (new_y_position < -0.38) {
						new_y_position = -0.38;
					} elsif (new_y_position > 0.38) {
						new_y_position = 0.38;
					}
				}
			} elsif (new_x_position >= -0.24 and new_x_position <= -0.09) {
				if (new_y_position < -0.38) {
					new_y_position = -0.38;
				} elsif (new_y_position > 0.38) {
					new_y_position = 0.38;
				}
				if (new_y_position > -0.40 and new_y_position < 0.40) {
					if (getprop("sim/model/bluebird/doors/door[4]/position-norm") < 0.7) {
						new_x_position = -0.25;
					}
				}
			} elsif (new_x_position > -0.09 and new_x_position < 0.11) {
				if (new_y_position < -0.6) {
					new_x_position = 0.11;
					if (new_y_position < -1.62) {
						new_y_position = -1.62;
					}
				} elsif (new_y_position < -0.38) {
					new_y_position = -0.38;
				} elsif (new_y_position > 0.6) {
					new_x_position = 0.11;
					if (new_y_position > 1.62) {
						new_y_position = 1.62;
					}
				} elsif (new_y_position > 0.38) {
					new_y_position = 0.38;
				}
				if (new_y_position > -0.40 and new_y_position < 0.40) {
					if (getprop("sim/model/bluebird/doors/door[4]/position-norm") < 0.7) {
						new_x_position = 0.12;
					}
				}
			} elsif (new_x_position >= 0.11 and new_x_position <= door5_barrier) {
				if (new_y_position < -1.62) {
					new_y_position = -1.62;
				} elsif (new_y_position > 1.62) {
					new_y_position = 1.62;
				}
			} elsif (new_x_position > door5_barrier) {
				if (door5_position > 0.62) {
					w_out = 5;
				}
				new_x_position = door5_barrier;
				if (new_y_position < -1.62) {
					new_y_position = -1.62;
				} elsif (new_y_position > 1.62) {
					new_y_position = 1.62;
				}
			}
		}
		if (w_out) {
			walk.get_out(w_out);
		} else {
			if (getprop("sim/current-view/view-number") == 0) {
				xViewNode.setValue(new_x_position);
				yViewNode.setValue(new_y_position);
			}
			setprop("sim/model/bluebird/crew/walker/x-offset-m", new_x_position);
			setprop("sim/model/bluebird/crew/walker/y-offset-m", new_y_position);
		}
	}
}

# dialog functions --------------------------------------------------

var set_nav_lights = func(snl_i) {
	var snl_new = nav_light_switch.getValue();
	if (snl_i == -1) {
		snl_new += 1;
		if (snl_new > 2) {
			snl_new = 0;
		}
	} else {
		snl_new = snl_i;
	}
	nav_light_switch.setValue(snl_new);
	active_nav_button = [ 3, 3, 3];
	if (snl_new == 0) {
		active_nav_button[0]=1;
	} elsif (snl_new == 1) {
		active_nav_button[1]=1;
	} else {
		active_nav_button[2]=1;
	}
	nav_lighting_update();
	bluebird.reloadDialog1();
}

var set_landing_lights = func(sll_i) {
	var sll_new = landing_light_switch.getValue();
	if (sll_i == -1) {
		sll_new += 1;
		if (sll_new > 2) {
			sll_new = 0;
		}
	} else {
		sll_new = sll_i;
	}
	landing_light_switch.setValue(sll_new);
	active_landing_button = [ 3, 3, 3];
	if (sll_new == 0) {
		active_landing_button[0]=1;
	} elsif (sll_new == 1) {
		active_landing_button[1]=1;
	} else {
		active_landing_button[2]=1;
	}
	nav_lighting_update();
	bluebird.reloadDialog1();
}

var toggle_venting_both = func {
	if (!nacelle_R_venting) {
		if (nacelleL_attached) {
			setprop("sim/model/bluebird/systems/nacelle-L-venting", 1);
		}
		if (nacelleR_attached) {
			setprop("sim/model/bluebird/systems/nacelle-R-venting", 1);
		}
		if (nacelleL_attached or nacelleR_attached) {
			popupTip2("Smoke venting ON");
		} else {
			popupTip2("Unable to comply. Too much damage.");
		}
	} else {
		setprop("sim/model/bluebird/systems/nacelle-L-venting", 0);
		setprop("sim/model/bluebird/systems/nacelle-R-venting", 0);
		popupTip2("Smoke venting OFF");
	}
}

var reloadDialog1 = func {
	name = "bluebird-systems";
	interior_lighting_update();
	if (systems_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		systems_dialog = nil;
		bluebird.showDialog1();
		return;
	}
}

var showDialog = func {
	var c_view = getprop("sim/current-view/view-number");
	var outside = getprop("sim/walker/outside");
	if (outside and ((c_view == view.indexof("Walk View")) or (c_view == view.indexof("Walker Orbit View")))) {
		walker.sequence.showDialog();
	} else {
		showDialog1();
	}
}

var showDialog1 = func {
	name = "bluebird-systems";
	if (systems_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		systems_dialog = nil;
		return;
	}

	systems_dialog = gui.Widget.new();
	systems_dialog.set("layout", "vbox");
	systems_dialog.set("name", name);
	systems_dialog.set("x", -40);
	systems_dialog.set("y", -40);

	# "window" titlebar
	titlebar = systems_dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Bluebird Explorer systems");
	titlebar.addChild("empty").set("stretch", 1);

	systems_dialog.addChild("hrule").addChild("dummy");

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("bluebird.systems_dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	var checkbox = func {
		group = systems_dialog.addChild("group");
		group.set("layout", "hbox");
		group.addChild("empty").set("pref-width", 4);
		var box = group.addChild("checkbox");
		group.addChild("text").set("label", arg[0]);
		group.addChild("empty").set("stretch", 1);

		box.set("halign", "left");
		box.set("label", "");
		box.set("live", 1);
		return box;
	}

	# master power switch
	var w = checkbox("master power                       [~]");
	w.setColor(0.45, (0.45 + (getprop("sim/model/bluebird/systems/power-switch") * 0.55)), 0.45);
	w.set("property", "sim/model/bluebird/systems/power-switch");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.toggle_power(9)");

	# fusion reactor and countergrav glow
	w = checkbox("countergrav fusion reactor          [\]");
	w.setColor(0.45, (0.45 + (getprop("sim/model/bluebird/systems/reactor-request") * 0.55)), 0.45);
	w.set("property", "sim/model/bluebird/systems/reactor-request");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.delayed_panel_update()");
	w.prop().getNode("binding[2]/command", 1).setValue("nasal");
	w.prop().getNode("binding[2]/script", 1).setValue("bluebird.reloadDialog1()");

	# Wave-guide drive glow and halos
	w = checkbox("Primary wave-guide engine    [space]");
	w.setColor(0.45, (0.45 + (getprop("sim/model/bluebird/systems/wave1-request") * 0.55)), 0.45);
	w.set("property", "sim/model/bluebird/systems/wave1-request");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.delayed_panel_update()");
	w.prop().getNode("binding[2]/command", 1).setValue("nasal");
	w.prop().getNode("binding[2]/script", 1).setValue("bluebird.reloadDialog1()");

	# for orbital velocities
	w = checkbox("Enable upper atmosphere velocities");
	w.setColor(0.45, (0.45 + (getprop("sim/model/bluebird/systems/wave2-request") * 0.55)), 0.45);
	w.set("property", "sim/model/bluebird/systems/wave2-request");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.delayed_panel_update()");
	w.prop().getNode("binding[2]/command", 1).setValue("nasal");
	w.prop().getNode("binding[2]/script", 1).setValue("bluebird.reloadDialog1()");

	systems_dialog.addChild("hrule").addChild("dummy");

	# lights
	var g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "nav lights:");
	g.addChild("empty").set("stretch", 1);

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);

	var box = g.addChild("button");
	g.addChild("empty").set("stretch", 1);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("legend", "Stay On");
	box.set("border", active_nav_button[2]);
	box.setColor(0.45, (0.975 - (active_nav_button[2] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_nav_lights(2)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 18);
	box.set("legend", "Dusk to Dawn");
	box.set("border", active_nav_button[1]);
	box.setColor(0.45, (0.975 - (active_nav_button[1] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_nav_lights(1)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 50);
	box.set("pref-height", 18);
	box.set("legend", "Off");
	box.set("border", active_nav_button[0]);
	box.setColor((0.975 - (active_nav_button[0] * 0.175)), 0.45, 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_nav_lights(0)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	w = checkbox("beacons");
	w.setColor(0.45, (0.45 + (getprop("controls/lighting/beacon") * 0.55)), 0.45);
	w.set("property", "controls/lighting/beacon");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	w = checkbox("strobes");
	w.setColor(0.45, (0.45 + (getprop("controls/lighting/strobe") * 0.55)), 0.45);
	w.set("property", "controls/lighting/strobe");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "landing lights:");
	g.addChild("empty").set("stretch", 1);

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);

	box = g.addChild("button");
	g.addChild("empty").set("stretch", 1);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("legend", "Stay On");
	box.set("border", active_landing_button[2]);
	box.setColor(0.45, (0.975 - (active_landing_button[2] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_landing_lights(2)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 18);
	box.set("legend", "Dusk to Dawn");
	box.set("border", active_landing_button[1]);
	box.setColor(0.45, (0.975 - (active_landing_button[1] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_landing_lights(1)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 50);
	box.set("pref-height", 18);
	box.set("legend", "Off");
	box.set("border", active_landing_button[0]);
	box.setColor((0.975 - (active_landing_button[0] * 0.175)), 0.45, 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_landing_lights(0)");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	# interior
	w = checkbox("interior lights");
	w.setColor(0.45, (0.45 + (getprop("sim/model/bluebird/lighting/interior-switch") * 0.55)), 0.45);
	w.set("property", "sim/model/bluebird/lighting/interior-switch");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.nav_lighting_update()");
	w.prop().getNode("binding[2]/command", 1).setValue("nasal");
	w.prop().getNode("binding[2]/script", 1).setValue("bluebird.reloadDialog1()");

	# red-alert and damage
	w = checkbox("Condition Red");
	w.setColor((0.45 + (getprop("controls/lighting/alert") * 0.55)), 0.45, 0.45);
	w.set("property", "controls/lighting/alert");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	systems_dialog.addChild("hrule").addChild("dummy");

	# landing gear mode
	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Landing Gear deployment mode: [ctrl-g]");
	g.addChild("empty").set("stretch", 1);

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);

	box = g.addChild("button");
	g.addChild("empty").set("stretch", 1);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 150);
	box.set("pref-height", 18);
	box.set("legend", "Extend fully");
	box.set("border", active_gear_button[0]);
	box.setColor(0.45, (0.975 - (active_gear_button[0] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.toggle_gear_mode(0)");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 150);
	box.set("pref-height", 18);
	box.set("legend", "Cargo loading");
	box.set("border", active_gear_button[1]);
	box.setColor(0.45, (0.975 - (active_gear_button[1] * 0.175)), 0.45);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.toggle_gear_mode(1)");

	w = checkbox("Wheels down                   [ctrl-w]");
	w.setColor(0.45, (0.45 + (getprop("controls/gear/wheels-switch") * 0.45)), 0.45);
	w.set("property", "controls/gear/wheels-switch");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog1()");

	systems_dialog.addChild("hrule").addChild("dummy");

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Display screens:");
	g.addChild("empty").set("stretch", 1);

	w = checkbox("Left #2");
	w.set("property", "instrumentation/display-screens/enabled-2L");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	w = checkbox("Right #2");
	w.set("property", "instrumentation/display-screens/enabled-2R");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Engineering screens:");
	g.addChild("empty").set("stretch", 1);

	w = checkbox("Right #3 - ground elevations");
	w.set("property", "instrumentation/display-screens/enabled-3R");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	w = checkbox("Right #4 - hover diagnostics");
	w.set("property", "instrumentation/display-screens/enabled-4R");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	w = checkbox("Right #5 - countergrav diagnostics");
	w.set("property", "instrumentation/display-screens/enabled-5R");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	g = systems_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	g.addChild("empty").set("stretch", 1);
	box = g.addChild("button");
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 19);
	box.set("legend", "More...");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.showDialog2()");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.systems_dialog = nil");
	box.prop().getNode("binding[2]/command", 1).setValue("dialog-close");
	g.addChild("empty").set("pref-width", 4);

	# finale
	systems_dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", systems_dialog.prop());
	gui.showDialog(name);
}

var reloadDialog2 = func {
	name = "bluebird-config";
	interior_lighting_update();
	if (config_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		config_dialog = nil;
		showDialog2();
		return;
	}
}

var showDialog2 = func {
	name = "bluebird-config";
	if (config_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		config_dialog = nil;
		return;
	}

	config_dialog = gui.Widget.new();
	config_dialog.set("layout", "vbox");
	config_dialog.set("name", name);
	config_dialog.set("x", -40);
	config_dialog.set("y", -40);

	# "window" titlebar
	titlebar = config_dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Bluebird Explorer configuration");
	titlebar.addChild("empty").set("stretch", 1);

	config_dialog.addChild("hrule").addChild("dummy");

	var w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("bluebird.config_dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	var checkbox = func {
		group = config_dialog.addChild("group");
		group.set("layout", "hbox");
		group.addChild("empty").set("pref-width", 4);
		box = group.addChild("checkbox");
		group.addChild("empty").set("stretch", 1);

		box.set("halign", "left");
		box.set("label", arg[0]);
		return box;
	}

	w = checkbox("Transparent windows");
	w.set("property", "sim/model/cockpit-visible");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w.prop().getNode("binding[1]/command", 1).setValue("nasal");
	w.prop().getNode("binding[1]/script", 1).setValue("bluebird.nav_lighting_update()");

	w = checkbox("Simple 2D shadow");
	w.set("live", 1);
	w.set("property", "sim/model/bluebird/shadow");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	var g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Reactor maintenance covers:");
	w = g.addChild("checkbox");
	w.set("halign", "left");
	w.set("label", "");
	w.set("live", 1);
	w.set("property", "sim/model/bluebird/components/engine-cover1");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w = g.addChild("checkbox");
	w.set("halign", "left");
	w.set("label", "");
	w.set("live", 1);
	w.set("property", "sim/model/bluebird/components/engine-cover2");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w = g.addChild("checkbox");
	w.set("halign", "left");
	w.set("label", "");
	w.set("live", 1);
	w.set("property", "sim/model/bluebird/components/engine-cover3");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	w = g.addChild("checkbox");
	w.set("halign", "left");
	w.set("label", "");
	w.set("live", 1);
	w.set("property", "sim/model/bluebird/components/engine-cover4");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	g.addChild("empty").set("stretch", 1);

	config_dialog.addChild("hrule").addChild("dummy");

	w = checkbox("Pilot visible as separate person");
	w.set("property", "sim/model/bluebird/crew/pilot/visible");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	var box = g.addChild("checkbox");
	box.set("halign", "left");
	box.set("label", "");
	box.set("live", 1);
	box.set("property", "sim/model/bluebird/crew/walker/visible");
	box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	g.addChild("text").set("label", "Walker visible");
	g.addChild("empty").set("stretch", 1);
	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 19);
	box.set("legend", "Animations");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("walker.sequence.showDialog()");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("bluebird.config_dialog = nil");
	box.prop().getNode("binding[2]/command", 1).setValue("dialog-close");

	config_dialog.addChild("hrule").addChild("dummy");

	# walk around cabin
	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Move around cockpit:");
	g.addChild("empty").set("stretch", 1);

	var box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 19);
	box.set("legend", "Pilot's chair");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(0)");

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 40);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Jump to:");
	g.addChild("empty").set("stretch", 1);

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 70);
	box.set("pref-height", 19);
	box.set("legend", "Left");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(2)");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 70);
	box.set("pref-height", 19);
	box.set("legend", "Right");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(3)");

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("stretch", 1);

	box = g.addChild("button");
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 19);
	box.set("legend", "Behind pilot");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(1)");

	box = g.addChild("button");
	g.addChild("empty").set("pref-width", 4);
	box.set("halign", "left");
	box.set("label", "");
	box.set("pref-width", 130);
	box.set("pref-height", 19);
	box.set("legend", "Between doors");
	box.set("border", 3);
	box.prop().getNode("binding[0]/command", 1).setValue("nasal");
	box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(4)");

	config_dialog.addChild("hrule").addChild("dummy");

	w = checkbox("Output position of walker/skydiver");
	w.set("property", "logging/walker-position");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	w = checkbox("Output debug of walker");
	w.set("property", "logging/walker-debug");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	config_dialog.addChild("hrule").addChild("dummy");

	w = checkbox("Experimental ground slope based orientation");
	w.set("property", "sim/model/bluebird/systems/groundslope-enable");
	w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

	g = config_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 40);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "(Effective when counter-grav hover is off)");
	g.addChild("empty").set("stretch", 1);

	# finale
	config_dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", config_dialog.prop());
	gui.showDialog(name);
}

var gui_livery_node = props.globals.getNode("/sim/gui/dialogs/livery", 1);
var livery_hull_list = [ "fuselage-top", "hull-trim", "fuselage-upper", "fuselage-lower", "hull-wings", "hull-bottom"];
if (gui_livery_node.getNode("list") == nil) {
	gui_livery_node.getNode("list", 1).setValue("");
}
for (var i = 0; i < size(livery_hull_list); i += 1) {
	gui_livery_node.getNode("list["~i~"]", 1).setValue(livery_hull_list[i]);
}
gui_livery_node = gui_livery_node.getNode("list", 1);

var listbox_apply = func {
	material.showDialog("sim/model/livery/material/" ~ gui_livery_node.getValue() ~ "/", nil, getprop("/sim/startup/xsize") - 200, 20);
}

var showLiveryDialog1 = func {
	name = "bluebird-livery-select";
	if (livery_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		livery_dialog = nil;
		return;
	}

	livery_dialog = gui.Widget.new();
	livery_dialog.set("layout", "vbox");
	livery_dialog.set("name", name);
	livery_dialog.set("x", 40);
	livery_dialog.set("y", -40);

 # "window" titlebar
	titlebar = livery_dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Bluebird Explorer Hovercraft");
	titlebar.addChild("empty").set("stretch", 1);

	livery_dialog.addChild("hrule").addChild("dummy");

	w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("bluebird.livery_dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	g = livery_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 4);
	w = g.addChild("text");
	w.set("halign", "left");
	w.set("label", "Edit External Livery Hull materials:");
	g.addChild("empty").set("stretch", 1);

	var a = livery_dialog.addChild("list");
	a.set("name", "livery-hull-list");
	a.set("pref-width", 300);
	a.set("pref-height", 160);
	a.set("slider", 18);
	a.set("property", "/sim/gui/dialogs/livery/list");
	for (var i = 0 ; i < size(livery_hull_list) ; i += 1) {
		a.set("value[" ~ i ~ "]", livery_hull_list[i]);
	}
	a.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	a.prop().getNode("binding[0]/object-name", 1).setValue("livery-hull-list");
	a.prop().getNode("binding[1]/command", 1).setValue("nasal");
	a.prop().getNode("binding[1]/script", 1).setValue("bluebird.listbox_apply()");
	g.addChild("empty").set("pref-width", 4);

	livery_dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", livery_dialog.prop());
	gui.showDialog(name);
}


#==========================================================================
#                 === initial calls at startup ===
 setlistener("sim/signals/fdm-initialized", func {

 update_main();  # starts continuous loop
 settimer(interior_lighting_loop, 0.25);
 settimer(interior_lighting_update, 0.5);
 settimer(nav_light_loop, 0.5);
 if (getprop("sim/ai-traffic/enabled") or getprop("sim/multiplay/rxport")) {
 	setprop("instrumentation/tracking/enabled", 1);
 }

 var t = getprop("/sim/description");
 print (t);
 print ("  version 10.4  release date 2010.Mar.01  by Stewart Andreason");
});

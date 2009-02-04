# ===== common base for walking functions   version 3.11       =====
# ===== plus coordinates for Bluebird Explorer Hovercraft 8.91 =====

var sin = func(a) { math.sin(a * math.pi / 180.0) }	# degrees
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var asin = func(y) { math.atan2(y, math.sqrt(1-y*y)) }	# radians
var ERAD = 6378138.12; 		# Earth radius (m)
var ERAD_deg = 180 / (ERAD * math.pi);
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var zViewNode = props.globals.getNode("sim/current-view/y-offset-m", 1);
var fps_node = props.globals.getNode("sim/frame-rate", 1);
var falling = 0;	# 0/1 = false/true
var last_altitude = 0;	# remember last position to detect falling from ground
var exit_time_sec = 0.0;
var parachute_ft = 0.0;
var parachute_deployed_sec = 0.0;
var elapsed_chute_sec = 0.0;
var lat_vector = 0.0;
var lon_vector = 0.0;
var z_vector_mps = 0.0;
var time_to_top_sec = 0.0;
var starting_lat = 0.0;
var starting_lon = 0.0;
var walk_heading = 0;
var walk_watch = 0;
var walk_factor = 1.0;

# debug section
var measure_main_count = 0;
var measure_walk_count = 0;	# momentum_walk loops
var measure_extmov_count = 0;
var measure_sec = 0;
var measure_alt = 0;
var last_elapsed_sec = 0;

# ===== functions ======
var normheading = func (a) {
	while (a >= 360)
		a -= 360;
	while (a < 0)
		a += 360;
	return a;
}

var distFromCraft = func (lat,lon) {
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var a = sin((lat - c_lat) * 0.5);
	var b = sin((lon - c_lon) * 0.5);
	return 2.0 * ERAD * asin(math.sqrt(a * a + cos(lat) * cos(c_lat) * b * b));
}

var xy2LatLonZ = func (x,y) {
	# given the x,y offsets of the cockpit view when walking
	# or the hatch location upon exit
	# translate into lat,lon,z-offset for transfer to outside walker
	var c_head_rad = getprop("orientation/heading-deg") * 0.01745329252; # (math.pi / 180)
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var c_pitch = getprop("orientation/pitch-deg");
	var c_roll = getprop("orientation/roll-deg");
	var xZ_factor = math.cos(c_pitch * 0.01745329252);
	var x_Zadjust = x * xZ_factor;	# adjusted for pitch
	var y_Zadjust = y * math.cos(c_roll * 0.01745329252);	# adjusted for roll
#	print(sprintf("x= %6.2f xZ= %6.2f  y= %6.2f yZ= %6.2f",x,x_Zadjust,y,y_Zadjust));
	var xy_hyp = math.sqrt((x_Zadjust * x_Zadjust) + (y_Zadjust * y_Zadjust));
	var a = (xy_hyp == 0 ? 0 : asin(y_Zadjust / xy_hyp));
	if (x > 0) {
		a = math.pi - a;
	}
	var xy_head_rad = c_head_rad + a;
#	print(sprintf ("c_head= %6.2f a= %6.2f xy_head= %6.2f",(c_head_rad*180/math.pi),(a*180/math.pi),(xy_head_rad*180/math.pi)));
	var xy_lat_m = xy_hyp * math.cos(xy_head_rad);
	var xy_lon_m = xy_hyp * math.sin(xy_head_rad);
#	print(sprintf ("x= %9.8f y= %9.8f xy_lat_m= %9.8f xy_lon_m= %9.8f",x_Zadjust,y_Zadjust,xy_lat_m,xy_lon_m));
	var xy_lat = xy_lat_m * ERAD_deg;
	var xy_lon = xy_lon_m * ERAD_deg / cos(c_lat);
#	print(sprintf ("position/lat= %9.8f lon= %9.8f xy_lat= %9.8f xy_lon= %9.8f",c_lat,c_lon,xy_lat,xy_lon));
	var zxZ_ft = -(x * math.sin(c_pitch * 0.01745329252) / 0.3048);
	var zyZ_ft = -(y * math.sin(c_roll * 0.01745329252) / 0.3048 * xZ_factor);	# goes to zero as pitch to 90

# MARK: not Perfect yet: z of hatch and height of walker (1.67m) is not adjusted for at angle.
#	print (sprintf ("zxZ= %6.2f zyZ= %6.2f z= %6.2f",zxZ_ft,zyZ_ft,(zxZ_ft+zyZ_ft)));
	return [(c_lat + xy_lat) , (c_lon + xy_lon) , (zxZ_ft + zyZ_ft)];
}

var calc_heading = func {
	var w_forward = getprop("sim/walker/key-triggers/forward");
	var w_left = getprop("sim/walker/key-triggers/slide");
	var new_head = -999;
	var new_walking = 0;
	if (w_forward > 0) {
		new_walking = 1;
		if (w_left < 0) {
			new_head = 45;
		} elsif (w_left > 0) {
			new_head = -45;
		} else {
			new_head = 0;
		}
	} elsif (w_forward < 0) {
		new_walking = -1;
		if (w_left < 0) {
			new_head = 135;
		} elsif (w_left > 0) {
			new_head = -135;
		} else {
			new_head = 180;
		}
	} else {
		if (w_left < 0) {
			new_walking = 4;
			new_head = 90;
		} elsif (w_left > 0) {
			new_walking = 6;
			new_head = -90;
		} else {
			setprop ("sim/walker/walking", 0);
			return 0;
		}
	}
	walk_heading = new_head;
	setprop ("sim/walker/walking", new_walking);
}

var momentum_walk = func {
	measure_walk_count += 1;
	if (walk_watch >= 3) {
		if (walk_factor < 2.0) {	# speed up when holding down key
			walk_factor += 0.025;
		}
		setprop ("sim/walker/walking-momentum", 1);
	} elsif (walk_watch >= 2) {
		setprop ("sim/walker/walking-momentum", 1);
		walk_watch -= 1;
	} else {
		walk_factor = ((walk_factor - 1.0) * 0.5) + 1.0;
		if (walk_factor < 1.1) {
			walk_factor = 1.0;
			walk_watch = 0;
		} else {
			setprop ("sim/walker/walking-momentum", 1);
		}
	}
	if (walk_watch) {
		settimer(momentum_walk,0.05);
	} else {
		setprop ("sim/walker/walking-momentum", 0);
	}
}

var main_loop = func {
	measure_main_count += 1;
	var c_view = getprop ("sim/current-view/view-number");
	var moved = 0;
	if (c_view == 0 and getprop("sim/walker/walking-momentum")) {
		# inside aircraft
		bluebird.walk_about_cabin(0.1, walk_heading);
		moved = 1;
	}
	if (getprop("sim/walker/outside")) {
		if (falling or getprop("sim/walker/walking-momentum")) {
			ext_mov(moved);
		}
		# check for proximity to hatches for entry after 0.3 sec.
		var elapsed_sec = getprop("sim/time/elapsed-sec");
		var elapsed_fall_sec = elapsed_sec - exit_time_sec;
		if (elapsed_fall_sec > 0.75) {
			if (abs(getprop("sim/walker/altitude-ft") - getprop("position/altitude-ft")) < 6) {
				# must be within 6 ft vertically to climb in
				var posy = getprop("sim/walker/latitude-deg");
				var posx = getprop("sim/walker/longitude-deg");

				# the following section is aircraft specific for locations of entry hatches and doors
				if (getprop("sim/model/bluebird/doors/door[0]/position-norm") > 0.73) {
					var door0_ll = xy2LatLonZ(-2.6,-3.42);
					var a0 = sin((door0_ll[0] - posy) * 0.5);
					var b0 = sin((door0_ll[1] - posx) * 0.5);
					# doesn't actually check z-axis, mis-alignments in rare orientations
					var d0 = 2.0 * ERAD * asin(math.sqrt(a0 * a0 + cos(door0_ll[0]) * cos(posy) * b0 * b0));
					if (d0 < 1.2) {
						get_in(1);
					}
				}
				if (getprop("sim/model/bluebird/doors/door[1]/position-norm") > 0.73) {
					var door1_ll = xy2LatLonZ(-2.6,3.42);
					var a1 = sin((door1_ll[0] - posy) * 0.5);
					var b1 = sin((door1_ll[1] - posx) * 0.5);
					var d1 = 2.0 * ERAD * asin(math.sqrt(a1 * a1 + cos(door1_ll[0]) * cos(posy) * b1 * b1));
					if (d1 < 1.2) {
						get_in(2);
					}
				}
				if (getprop("sim/model/bluebird/doors/door[5]/position-norm") > 0.78) {
					var door5_ll = xy2LatLonZ(9.0,0);
					var a5 = sin((door5_ll[0] - posy) * 0.5);
					var b5 = sin((door5_ll[1] - posx) * 0.5);
					var d5 = 2.0 * ERAD * asin(math.sqrt(a5 * a5 + cos(door5_ll[0]) * cos(posy) * b5 * b5));
					if (d5 < 1.9) {
						get_in(5);
					}
				}
			}
		}
	} elsif (!moved and getprop("sim/walker/walking-momentum")) {
		bluebird.walk_about_cabin(0.1, walk_heading);
	}

	if (getprop("logging/walker-debug")) {
		var elapsed_sec = getprop("sim/time/elapsed-sec");
		var t = elapsed_sec - measure_sec;
		if (t >= 0.991) {
			var posz1 = getprop("sim/walker/altitude-ft");
			print(sprintf("========= at %6.2f : %3i %3i %3i : Z-axis %6.2f ft / %6.4f sec = %6.2f mps",elapsed_sec,measure_main_count,measure_walk_count,measure_extmov_count,(measure_alt-posz1),t,((measure_alt-posz1)*0.3028/t)));
			measure_alt = posz1;
			measure_sec = elapsed_sec;
			measure_main_count = 0;
			measure_walk_count = 0;
			measure_extmov_count = 0;
		}
	}

	settimer(main_loop, 0.01)
}

var walker_model = {
	add:	func {
			if (getprop("sim/model/bluebird/crew/walker/visible")) {
				if (getprop("logging/walker-position")) {
					print("walker_model.add");
				}
				props.globals.getNode("models/model/path", 1);
				props.globals.getNode("models/model/longitude-deg-prop", 1);
				props.globals.getNode("models/model/latitude-deg-prop", 1);
				props.globals.getNode("models/model/elevation-ft-prop", 1);
				props.globals.getNode("models/model/heading-deg-prop", 1);
				
				var desc = getprop("sim/description");
				if (substr(desc, size(desc) - 3, 3) == "1.0") {
					setprop ("models/model/path", "Aircraft/bluebird/Models/walker-1.xml");
				} else {
					setprop ("models/model/path", "Aircraft/bluebird/Models/walker.xml");
				}
				setprop ("models/model/longitude-deg-prop", "sim/walker/longitude-deg");
				setprop ("models/model/latitude-deg-prop", "sim/walker/latitude-deg");
				setprop ("models/model/elevation-ft-prop", "sim/walker/altitude-ft");
				setprop ("models/model/heading-deg-prop", "sim/walker/model-heading-deg");
				props.globals.getNode("models/model/load", 1);
			}
		},
	remove:	func {
			if (getprop("logging/walker-position")) {
				print("walker_model.remove");
			}
			props.globals.getNode("models", 1).removeChild("model", 0);
			walker_model.reset_fall();
		},
	reset_fall: func {
			falling = 0;
			walk_factor = 1.0;
			setprop("sim/walker/airborne", 0);
			setprop("sim/walker/parachute-opened-altitude-ft", 0);
			parachute_deployed_sec = 0;
			setprop("sim/walker/parachute-opened-sec", 0);
			setprop("sim/walker/starting-trajectory-lat", 0.0);
			setprop("sim/walker/starting-trajectory-lon", 0.0);
			setprop("sim/walker/starting-trajectory-z-mps", 0.0);
			setprop("sim/walker/time-to-zero-z-sec", 0.0);
		},
	land:	func (lon,lat,alt) {
			walker_model.reset_fall();
			setprop("sim/walker/latitude-deg", lat);
			setprop("sim/walker/longitude-deg", lon);
			setprop("sim/walker/altitude-ft", alt);
			last_altitude = alt;
		},
};

var open_chute = func {
	if (getprop("sim/walker/airborne") and exit_time_sec and !parachute_ft) {
		setprop("sim/walker/parachute-opened-altitude-ft", getprop("sim/walker/altitude-ft"));
		parachute_deployed_sec = getprop("sim/time/elapsed-sec");
		setprop("sim/walker/parachute-opened-sec", 0);
	}
}

var reinit_walker = func {
	setprop("sim/walker/outside", 0);
	setprop("sim/view[100]/enabled",0);
	setprop("sim/view[101]/enabled",0);
	setprop("sim/walker/crashed", 0);
	setprop("sim/walker/airborne", 0);
	falling = 0;
	walk_factor = 1.0;
	setprop("sim/walker/parachute-opened-altitude-ft", 0);
	parachute_deployed_sec = 0;
	setprop("sim/walker/parachute-opened-sec", 0);
}

var init_common = func {
	setlistener("sim/walker/time-of-exit-sec", func(n) exit_time_sec = n.getValue());

	setlistener("sim/walker/parachute-opened-altitude-ft", func(n) parachute_ft = n.getValue());

	setlistener("sim/walker/parachute-opened-sec", func(n) elapsed_chute_sec = n.getValue());

	setlistener("sim/walker/starting-trajectory-lat", func(n) lat_vector = n.getValue());

	setlistener("sim/walker/starting-trajectory-lon", func(n) lon_vector = n.getValue());

	setlistener("sim/walker/starting-trajectory-z-mps", func(n) z_vector_mps = n.getValue());

	setlistener("sim/walker/time-to-zero-z-sec", func(n) time_to_top_sec = n.getValue());

	setlistener("sim/walker/starting-lat", func(n) starting_lat = n.getValue());

	setlistener("sim/walker/starting-lon", func(n) starting_lon = n.getValue());

	setlistener("sim/walker/key-triggers/forward", func {
		calc_heading();
	});

	setlistener("sim/walker/key-triggers/slide", func {
		calc_heading();
	});

	setlistener("sim/model/bluebird/crew/walker/visible", func(n) {
		if (n.getValue()) {
			if (getprop("sim/walker/outside")) {
				walker_model.add();
			}
		} else {
			walker_model.remove();
		}
	});

	setlistener("sim/signals/reinit", func {
		reinit_walker();
	});

	setlistener("sim/signals/fdm-initialized", func {
		reinit_walker();
	});
}
settimer(init_common,0);

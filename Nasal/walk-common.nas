# ===== common base for walking functions   version 2.3   =====
# ===== plus coordinates for Bluebird Explorer Hovercraft =====

var sin = func(a) { math.sin(a * math.pi / 180.0) }	# degrees
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var asin = func(y) { math.atan2(y, math.sqrt(1-y*y)) }	# radians
var ERAD = 6378138.12; 		# Earth radius (m)
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var zViewNode = props.globals.getNode("sim/current-view/y-offset-m", 1);
var falling = 0;

var exit_time_sec = 0.0;
setlistener("sim/walker/time-of-exit-sec", func {
	exit_time_sec = getprop("sim/walker/time-of-exit-sec");
});

var parachute_ft = 0.0;
setlistener("sim/walker/parachute-opened-altitude-ft", func {
	parachute_ft = getprop("sim/walker/parachute-opened-altitude-ft");
});

var parachute_sec = 0.0;
setlistener("sim/walker/parachute-opened-sec", func {
	parachute_sec = getprop("sim/walker/parachute-opened-sec");
});

var lat_vector = 0.0;
setlistener("sim/walker/starting-trajectory-lat", func {
	lat_vector = getprop("sim/walker/starting-trajectory-lat");
});

var lon_vector = 0.0;
setlistener("sim/walker/starting-trajectory-lon", func {
	lon_vector = getprop("sim/walker/starting-trajectory-lon");
});

var starting_lat = 0.0;
setlistener("sim/walker/starting-lat", func {
	starting_lat = getprop("sim/walker/starting-lat");
});

var starting_lon = 0.0;
setlistener("sim/walker/starting-lon", func {
	starting_lon = getprop("sim/walker/starting-lon");
});

setlistener("sim/walker/key-triggers/outside-toggle", func {
	var c_view = getprop ("sim/current-view/view-number");
	if (c_view == 0) {
		get_out(0);
	} elsif (c_view == view.indexof("Walk View")) {
		get_in(0);
	}
});

var distFromCraft = func (lat,lon) {
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var a = sin((lat - c_lat) * 0.5);
	var b = sin((lon - c_lon) * 0.5);
	return 2.0 * ERAD * asin(math.sqrt(a * a + cos(lat) * cos(c_lat) * b * b));
}

var xy2LatLon = func (x,y) {
	# given the x,y offsets of the cockpit view when walking
	# or the hatch location upon exit
	# translate into lat,lon for transfer to outside walker
	var c_head_rad = getprop("orientation/heading-deg") * 0.01745329252; # (math.pi / 180)
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var xy_hyp = math.sqrt((x * x) + (y * y));
	var a = (xy_hyp == 0 ? 0 : asin(y / xy_hyp));
	if (x > 0) {
		a = math.pi - a;
	}
	var xy_head_rad = c_head_rad + a;
#	print(sprintf ("c_head= %6.2f a= %6.2f xy_head= %6.2f",(c_head_rad*180/math.pi),(a*180/math.pi),(xy_head_rad*180/math.pi)));
	var xy_lat_m = xy_hyp * math.cos(xy_head_rad);
	var xy_lon_m = xy_hyp * math.sin(xy_head_rad);
#	print(sprintf ("x= %9.8f y= %9.8f xy_lat_m= %9.8f xy_lon_m= %9.8f",x,y,xy_lat_m,xy_lon_m));
	var xy_lat = xy_lat_m / (ERAD * math.pi) * 180;
	var xy_lon = xy_lon_m / (ERAD * cos(c_lat) * math.pi) * 180;
#	print(sprintf ("position/lat= %9.8f lon= %9.8f xy_lat= %9.8f xy_lon= %9.8f",c_lat,c_lon,xy_lat,xy_lon));
	return [(c_lat + xy_lat) , (c_lon + xy_lon)];
}

var walk_heading = 0;
var calc_heading = func {
	var w_forward = getprop("sim/walker/key-triggers/forward");
	var w_left = getprop("sim/walker/key-triggers/slide");
	var new_head = -999;
	if (w_forward > 0) {
		if (w_left < 0) {
			new_head = 45;
		} elsif (w_left > 0) {
			new_head = -45;
		} else {
			new_head = 0;
		}
	} elsif (w_forward < 0) {
		if (w_left < 0) {
			new_head = 135;
		} elsif (w_left > 0) {
			new_head = -135;
		} else {
			new_head = 180;
		}
	} else {
		if (w_left < 0) {
			new_head = 90;
		} elsif (w_left > 0) {
			new_head = -90;
		} else {
			setprop ("sim/walker/walking", 0);
			return 0;
		}
	}
	walk_heading = new_head;
	setprop ("sim/walker/walking", 1);
}

setlistener("sim/walker/key-triggers/forward", func {
	calc_heading();
});

setlistener("sim/walker/key-triggers/slide", func {
	calc_heading();
});

var walk_watch = 0;
var walk_factor = 1.0;
var momentum_walk = func {
	if (walk_watch >= 3) {
		if (walk_factor < 2.0) {
			walk_factor += 0.025;
		}
		walk();
	} elsif (walk_watch >= 2) {
		walk();
		walk_watch -= 1;
	} else {
		walk_factor = ((walk_factor - 1.0) * 0.5) + 1.0;
		if (walk_factor < 1.1) {
			walk_factor = 1.0;
			walk_watch = 0;
		} else {
			walk();
		}
	}
	if (walk_watch) {
		settimer(momentum_walk,0.05);
	}
}

var main_loop = func {
	if (getprop("sim/walker/outside") == 0) {
		# keep walker in sync with craft when inside
		setprop ("sim/walker/latitude-deg" , (getprop ("position/latitude-deg")));
		setprop ("sim/walker/longitude-deg" , (getprop ("position/longitude-deg")));
		setprop ("sim/walker/altitude-ft" , (getprop ("position/altitude-ft")));
		setprop ("sim/walker/roll-deg" , (getprop ("orientation/roll-deg")));
		setprop ("sim/walker/pitch-deg" , (getprop ("orientation/pitch-deg")));
		setprop ("sim/walker/heading-deg" , (getprop ("orientation/heading-deg")));
	} else {
		if (falling) {
			ext_mov();
		}
		# check for proximity to hatches for entry
		if (abs(getprop("sim/walker/altitude-ft") - getprop("position/altitude-ft")) < 6) {
			var posy = getprop("sim/walker/latitude-deg");
			var posx = getprop("sim/walker/longitude-deg");
			if (getprop("sim/model/bluebird/doors/door[0]/position-norm") > 0.73) {
				var door0_ll = xy2LatLon(-2.6,-3.42);
				var a0 = sin((door0_ll[0] - posy) * 0.5);
				var b0 = sin((door0_ll[1] - posx) * 0.5);
				var d0 = 2.0 * ERAD * asin(math.sqrt(a0 * a0 + cos(door0_ll[0]) * cos(posy) * b0 * b0));
				if (d0 < 1.2) {
					get_in(1);
				}
			}
			if (getprop("sim/model/bluebird/doors/door[1]/position-norm") > 0.73) {
				var door1_ll = xy2LatLon(-2.6,3.42);
				var a1 = sin((door1_ll[0] - posy) * 0.5);
				var b1 = sin((door1_ll[1] - posx) * 0.5);
				var d1 = 2.0 * ERAD * asin(math.sqrt(a1 * a1 + cos(door1_ll[0]) * cos(posy) * b1 * b1));
				if (d1 < 1.2) {
					get_in(2);
				}
			}
			if (getprop("sim/model/bluebird/doors/door[5]/position-norm") > 0.78) {
				var door5_ll = xy2LatLon(9.0,0);
				var a5 = sin((door5_ll[0] - posy) * 0.5);
				var b5 = sin((door5_ll[1] - posx) * 0.5);
				var d5 = 2.0 * ERAD * asin(math.sqrt(a5 * a5 + cos(door5_ll[0]) * cos(posy) * b5 * b5));
				if (d5 < 1.9) {
					get_in(5);
				}
			}
		}
	}
	settimer(main_loop, 0.01)
}

var walk = func {
	var c_view = getprop ("sim/current-view/view-number");
	if (c_view == 0) {
		# inside aircraft
		bluebird.walk_about_cabin(0.1, walk_heading);
	} elsif (c_view == view.indexof("Walk View")) {
		if (getprop ("sim/walker/outside") == 1) {
			ext_mov();
		} else {
			gui.popupTip("walker is not supported inside. Press o to move outside, or walk through hatches and doors.");
		}
	}
}

var ext_mov = func {
	var speed = getprop("sim/walker/speed") * walk_factor;
	var head0 = getprop("sim/current-view/heading-offset-deg");
	var posy = getprop("sim/walker/latitude-deg");
	var posx = getprop("sim/walker/longitude-deg");
	var posz1 = getprop("sim/walker/altitude-ft");
	var posz3 = getprop("sim/walker/altitude-at-exit-ft");
	var check_movement = 1;
	var head = head0 + walk_heading;
	while (head >= 360.0) {
		head -= 360.0;
	}
	while (head < 0.0) {
		head += 360.0;
	}
	if (falling) {
		var elapsed_sec = getprop("sim/time/elapsed-sec");
		var elapsed_fall_sec = elapsed_sec - exit_time_sec;
		if (elapsed_fall_sec < 2) {	# wait 2 seconds before able to aim/fly skydiver
			check_movement = 0;
		}
	}
	if (check_movement) {
		var posx1 = posx - (speed * sin(head));
		if (posy < 0 ) {
			# southern hemisphere
			var posy1 = posy + (speed+0.000001*sin(posy))*cos(head);
		} else {
			# northern hemisphere
			var posy1 = posy + (speed-0.000001*sin(posy))*cos(head);
		}
	} else {
		var posx1 = posx;
		var posy1 = posy;
	}
	if (falling) {	# add movement from aircraft upon jumping
		var parabola = 0;
		var parachute_drag = 0;
		var zero_xy_sec = (elapsed_fall_sec < 10 ? elapsed_fall_sec : 10.0);
		var elapsed_chute_sec = 0;
		if (parachute_ft) {	# chute open
			var elapsed_chute_sec = elapsed_sec - parachute_sec - 1.0;
			# chute starts to add drag at 1 second, fully open at 3 sec. Slows to 17 ft/sec
			if (elapsed_chute_sec >= 3.0) {
				parachute_drag = 0.9;
			} elsif (elapsed_chute_sec >= 0.0) {	# 1 second delay for chute to deploy
				parachute_drag = sin(elapsed_chute_sec * 30) * 0.9;	# 0 to 0.9 in 3 sec.
			}
		}
		if (parachute_drag) {
			zero_xy_sec = parachute_sec - exit_time_sec + 1.0;
			if (zero_xy_sec > 10.0) {
				zero_xy_sec = 10.0;
			}
		}
		parabola = sin(90 - zero_xy_sec ) * zero_xy_sec - (0.096 * zero_xy_sec * zero_xy_sec / 2);
#		print (sprintf("exit_time_sec= %6.2f elapsed= %6.2f elapsed_fall_sec= %5.2f zero_xy= %5.2f parachute= %5.2f elapsed_chute_sec= %5.2f p_drag= %4.2f parabola= %4.2f",exit_time_sec,elapsed_sec,elapsed_fall_sec,zero_xy_sec,parachute_sec,elapsed_chute_sec,parachute_drag,parabola));
		if (parachute_drag and zero_xy_sec < 7) {
			posy1 = starting_lat + (lat_vector * parabola) + (lat_vector * parachute_drag);
			posx1 = starting_lon + (lon_vector * parabola) + (lon_vector * parachute_drag);
		} else {
			posy1 = starting_lat + (lat_vector * parabola);
			posx1 = starting_lon + (lon_vector * parabola);
		}
	}
	var posz2 = geo.elevation (posy1, posx1) * 3.28084;	# convert to ft
	if (falling) {	# 13,000 to 12,000 ft = 10 sec. 12,000 - 4,000 = 44 sec.
			# 5.5 sec to cover each 1000 ft at terminal velocity
		var dist_traveled_z = 0;
		if (posz2 < posz1) {	# ground is below walker
			if (elapsed_fall_sec > 5.358) {	# time to reach terminal velocity
				dist_traveled_z = 461.56 + ((elapsed_fall_sec - 5.358) * 172);
			} else {	# 9.8m/s/s up to terminal velocity 172ft/s 54m/s spread eagle
				dist_traveled_z = 32.15 * elapsed_fall_sec * elapsed_fall_sec / 2;
			}
			if (parachute_ft) {	# chute open
				var subtract_z = 0;
				if (elapsed_chute_sec >= 5.0) {
					subtract_z = 363.14 + ((elapsed_chute_sec - 5.0) * 155);
				} elsif (elapsed_chute_sec >= 2.0) {
					subtract_z = 32.15 * parachute_drag * elapsed_chute_sec * elapsed_chute_sec / 2;
				} elsif (elapsed_chute_sec >= 0.0) {
					subtract_z = 32.15 * parachute_drag * elapsed_chute_sec * elapsed_chute_sec / 2;
				}
				dist_traveled_z -= subtract_z;
			}
			posz1 = posz3 - dist_traveled_z;
			if (posz1 < posz2) {	# below ground
				posz1 = posz2;
				falling = 0;
			}
		} else {
			falling = 0;
			walk_factor = 1.0;
			posz1 = posz2;
			setprop("sim/walker/parachute-opened-altitude-ft", 0);
			setprop("sim/walker/parachute-opened-sec", 0);
		}
		setprop("sim/walker/latitude-deg", posy1);
		setprop("sim/walker/longitude-deg", posx1);
#		print(sprintf("falling_lat= %9.8f lon= %9.8f alt= %7.2f elapsed_fall_sec= %5.2f zero_xy_sec= %5.2f parabola= %4.2f chute_drag= %4.2f",posy,posx,posz1,elapsed_fall_sec,zero_xy_sec,parabola,parachute_drag));
		setprop ("sim/walker/altitude-ft", posz1);
	} else {
		if (posz2 < (posz1 + 10)) {
#print(sprintf("lat= %9.8f posy= %9.8f posy1= %9.8f",getprop("sim/walker/latitude-deg"),posy,posy1));
			interpolate ("sim/walker/latitude-deg", posy1,0.25,0.3);
#print(sprintf("lat= %9.8f posy= %9.8f posy1= %9.8f",getprop("sim/walker/latitude-deg"),posy,posy1));
			interpolate ("sim/walker/longitude-deg", posx1,0.25,0.3);
#print(sprintf("walker_lat= %9.8f lon= %9.8f heading= %6.2f groundDistance= %3.2f",posy,posx,head0,distFromCraft(posy,posx)));
#			print ("posz1=",posz1," posz2=", posz2);

			if ((posz1+0.4) > posz2 or (posz1-0.4) < posz2) {
				interpolate ("sim/walker/altitude-ft", posz2, 0.25, 0.3);
			}
		}
	}
}

var get_out = func (loc) {
	var c_view = getprop("sim/current-view/view-number");
	var head_add = 0;
	if (c_view == 0) {
		setprop("sim/walker/keep-inside-offset-x", getprop("sim/current-view/x-offset-m"));
		setprop("sim/walker/keep-inside-offset-y", getprop("sim/current-view/y-offset-m"));
		setprop("sim/walker/keep-inside-offset-z", getprop("sim/current-view/z-offset-m"));
		setprop("sim/walker/keep-pitch-offset-deg", getprop("sim/current-view/pitch-offset-deg"));
		head_add = getprop("sim/current-view/heading-offset-deg");
	}
	var c_airspeed_mps = getprop("velocities/airspeed-kt") * 0.51444444;
	var walk_dir = getprop("sim/walker/walking");
	if (walk_dir and loc == 5) {
		c_airspeed_mps -= 1;
	}
	var c_head_deg = getprop("orientation/heading-deg");
	if (c_airspeed_mps < 0) {
		c_airspeed_mps = abs(c_airspeed_mps);
		c_head_deg += 180;
		if (c_head_deg >= 360.0) {
			c_head_deg -= 360.0;
		}
	}
	var c_head_rad = c_head_deg * 0.01745329252;
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var xy_lat_m = c_airspeed_mps * math.cos(c_head_rad);
	var xy_lon_m = c_airspeed_mps * math.sin(c_head_rad);
	var xy_lat = xy_lat_m / (ERAD * math.pi) * 180;
	var xy_lon = xy_lon_m / (ERAD * cos(c_lat) * math.pi) * 180;
	setprop("sim/walker/starting-trajectory-lat", xy_lat);
	setprop("sim/walker/starting-trajectory-lon", xy_lon);
	if (loc == 0) {
		var new_coord = xy2LatLon(-12.0,-8.0);	# coordinates outside front hatch
	} elsif (loc == 1) {
		var new_coord = xy2LatLon(xViewNode.getValue(),-4.9);
	} elsif (loc == 2) {
		var new_coord = xy2LatLon(xViewNode.getValue(),4.9);
	} elsif (loc == 5) {
		var new_coord = xy2LatLon(11.0,yViewNode.getValue());
	} else {
		var new_coord = xy2LatLon(xViewNode.getValue(),yViewNode.getValue());
	}
	var head = abs(getprop("orientation/heading-deg") -360.00) + head_add;
	while (head >= 360.0) {
		head -= 360.0;
	}
	setprop("sim/view[100]/enabled", "true");
	setprop("sim/walker/outside", 1);
	setprop("sim/current-view/view-number", view.indexof("Walk View"));
	var posy = new_coord[0];
	var posx = new_coord[1];
	setprop("sim/walker/heading-deg", 0);
	setprop("sim/walker/roll-deg", 0);
	setprop("sim/walker/pitch-deg", 0);
	setprop("sim/walker/latitude-deg", new_coord[0]);
	setprop("sim/walker/longitude-deg", new_coord[1]);
	setprop("sim/current-view/pitch-offset-deg", getprop("sim/walker/keep-pitch-offset-deg"));
	setprop("sim/current-view/roll-offset-deg", 0);
	yViewNode.setValue(0);
	zViewNode.setValue(1.67);	# matches person height when inside due to aircraft offsets
	xViewNode.setValue(0);
	setprop("sim/current-view/heading-offset-deg", head);
	falling = 1;
	setprop("sim/walker/time-of-exit-sec", getprop("sim/time/elapsed-sec"));
	setprop("sim/walker/altitude-at-exit-ft", getprop("position/altitude-ft"));
	setprop("sim/walker/starting-lat", new_coord[0]);
	setprop("sim/walker/starting-lon", new_coord[1]);
	walk_factor = 1.0;
}

var get_in = func (loc) {
	var c_view = getprop("sim/current-view/view-number");
	setprop("sim/current-view/view-number", 0);
	setprop("sim/walker/outside", 0);
	setprop("sim/view[100]/enabled", "false");
	setprop("sim/walker/parachute-opened-altitude-ft", 0);
	setprop("sim/walker/parachute-opened-sec", 0);
	if (loc == 1) {
		yViewNode.setValue(-3.4);
		zViewNode.setValue(2.1);
		xViewNode.setValue(-2.55);
		setprop("sim/current-view/heading-offset-deg", 270.0);
	} elsif (loc == 2) {
		yViewNode.setValue(3.4);
		zViewNode.setValue(2.1);
		xViewNode.setValue(-2.55);
		setprop("sim/current-view/heading-offset-deg", 90.0);
	} elsif (loc == 5) {
		yViewNode.setValue(0.0);
		zViewNode.setValue(2.1);
		xViewNode.setValue(10.0);
		setprop("sim/current-view/heading-offset-deg", 0.0);
	} else {
		yViewNode.setValue(getprop("sim/walker/keep-inside-offset-x"));
		zViewNode.setValue(getprop("sim/walker/keep-inside-offset-y"));
		xViewNode.setValue(getprop("sim/walker/keep-inside-offset-z"));
	}
}

var open_chute = func {
	if (exit_time_sec and !parachute_ft) {
		setprop("sim/walker/parachute-opened-altitude-ft", getprop("sim/walker/altitude-ft"));
		setprop("sim/walker/parachute-opened-sec", getprop("sim/time/elapsed-sec"));
	}
}


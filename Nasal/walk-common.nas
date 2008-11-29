# ===== common base for walking functions   version 2.7   =====
# ===== plus coordinates for Bluebird Explorer Hovercraft =====

var sin = func(a) { math.sin(a * math.pi / 180.0) }	# degrees
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var asin = func(y) { math.atan2(y, math.sqrt(1-y*y)) }	# radians
var ERAD = 6378138.12; 		# Earth radius (m)
var ERAD_deg = 180 / (ERAD * math.pi);
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var zViewNode = props.globals.getNode("sim/current-view/y-offset-m", 1);
var falling = 0;	# 0/1 = false/true
var last_altitude = 0;	# remember last position to detect falling from ground

var normheading = func (a) {
	while (a >= 360)
		a -= 360;
	while (a < 0)
		a += 360;
	return a;
}

var exit_time_sec = 0.0;
setlistener("sim/walker/time-of-exit-sec", func {
	exit_time_sec = getprop("sim/walker/time-of-exit-sec");
});

var parachute_ft = 0.0;
setlistener("sim/walker/parachute-opened-altitude-ft", func {
	parachute_ft = getprop("sim/walker/parachute-opened-altitude-ft");
});

var parachute_deployed_sec = 0.0;

var elapsed_chute_sec = 0.0;
setlistener("sim/walker/parachute-opened-sec", func {
	elapsed_chute_sec = getprop("sim/walker/parachute-opened-sec");
});

var lat_vector = 0.0;
setlistener("sim/walker/starting-trajectory-lat", func {
	lat_vector = getprop("sim/walker/starting-trajectory-lat");
});

var lon_vector = 0.0;
setlistener("sim/walker/starting-trajectory-lon", func {
	lon_vector = getprop("sim/walker/starting-trajectory-lon");
});

var z_vector_mps = 0.0;
setlistener("sim/walker/starting-trajectory-z-mps", func {
	z_vector_mps = getprop("sim/walker/starting-trajectory-z-mps");
});

var time_to_top_sec = 0.0;
setlistener("sim/walker/time-to-zero-z-sec", func {
	time_to_top_sec = getprop("sim/walker/time-to-zero-z-sec");
});

var starting_lat = 0.0;
setlistener("sim/walker/starting-lat", func {
	starting_lat = getprop("sim/walker/starting-lat");
});

var starting_lon = 0.0;
setlistener("sim/walker/starting-lon", func {
	starting_lon = getprop("sim/walker/starting-lon");
});

var fps = 0;
setlistener("sim/frame-rate", func {
	fps = getprop("sim/frame-rate");
	fps = (fps < 10 ? 10 : fps);	# only realistic above 10fps. Slow down below that so that walker pauses instead of jumping.
});

setlistener("sim/walker/key-triggers/outside-toggle", func {
	var c_view = getprop ("sim/current-view/view-number");
	if (c_view == 0) {
		if (getprop("sim/walker/outside")) {
			setprop("sim/current-view/view-number", view.indexof("Walk View"));
		} else {
			get_out(0);
		}
	} elsif (c_view == view.indexof("Walk View")) {
		get_in(0);
	} else {
		if (getprop("sim/walker/outside")) {
			get_in(0);
		} else {
			get_out(0);
		}
	}
});

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
#	print(sprintf ("x= %9.8f y= %9.8f xy_lat_m= %9.8f xy_lon_m= %9.8f",xZ,yZ,xy_lat_m,xy_lon_m));
	var xy_lat = xy_lat_m * ERAD_deg;
	var xy_lon = xy_lon_m * ERAD_deg / cos(c_lat);
#	print(sprintf ("position/lat= %9.8f lon= %9.8f xy_lat= %9.8f xy_lon= %9.8f",c_lat,c_lon,xy_lat,xy_lon));
	var zxZ_ft = -(x * math.sin(c_pitch * 0.01745329252) / 0.3048);
	var zyZ_ft = -(y * math.sin(c_roll * 0.01745329252) / 0.3048 * xZ_factor);	# goes to zero as pitch to 90

# MARK: not Perfect yet: z of hatch and height of walker (1.67m) is not adjusted for at angle.
#	print (sprintf ("zxZ= %6.2f zyZ= %6.2f z= %6.2f",zxZ_ft,zyZ_ft,(zxZ_ft+zyZ_ft)));
	return [(c_lat + xy_lat) , (c_lon + xy_lon) , (zxZ_ft + zyZ_ft)];
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
		if (walk_factor < 2.0) {	# speed up when holding down key
			walk_factor += 0.025;
		}
		setprop ("sim/walker/walking-momentum", "true");
	} elsif (walk_watch >= 2) {
		setprop ("sim/walker/walking-momentum", "true");
		walk_watch -= 1;
	} else {
		walk_factor = ((walk_factor - 1.0) * 0.5) + 1.0;
		if (walk_factor < 1.1) {
			walk_factor = 1.0;
			walk_watch = 0;
		} else {
			setprop ("sim/walker/walking-momentum", "true");
		}
	}
	if (walk_watch) {
		settimer(momentum_walk,0.05);
	} else {
		setprop ("sim/walker/walking-momentum", "false");
	}
}

var main_loop = func {
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
		if (elapsed_fall_sec > 0.3) {
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
	settimer(main_loop, 0.01)
}

var ext_mov = func (moved) {
	var c_view = getprop("sim/current-view/view-number");
	var head_v = getprop("sim/current-view/heading-offset-deg");
	var c_head_deg = getprop("orientation/heading-deg");
	var posy1 = getprop("sim/walker/latitude-deg");
	var posx1 = getprop("sim/walker/longitude-deg");
	var posz1 = getprop("sim/walker/altitude-ft");
	var posx2 = posx1;	# new after calculations
	var posy2 = posy1;
	var posz2 = posz1;
	var check_movement = 1;
	var speed = getprop("sim/walker/speed-mps") * walk_factor / fps;
	if (c_view >= 1 and c_view <=3) {
		head_v = normheading(360 - c_head_deg + head_v);
	} elsif (c_view == 5) {
		head_v = normheading(c_head_deg + head_v + 90);
	}	# TIP: walker is best controlled 3rd perspective, from view #6 (Fly-by view) 
	var head_w = normheading(head_v + walk_heading);
	if (!moved) {
		setprop("sim/walker/model-heading-deg" , 360 - head_v);
	}
	var elapsed_sec = getprop("sim/time/elapsed-sec");
	if (falling) {
		var elapsed_fall_sec = elapsed_sec - exit_time_sec;
		if (elapsed_fall_sec > 0.1) {
			check_movement = 0;
		}
	}
	if (check_movement and !moved) {
		var lat_m = speed * cos(head_w);
		var lon_m = speed * sin(head_w);
		var lat3 = lat_m * ERAD_deg;
		var lon3 = lon_m * ERAD_deg / cos(posy1);
		posx2 = posx1 - lon3;	# heading is offset or reversed west to east
		posy2 = (posy1 < 0 ? posy1 - lat3 : posy1 + lat3);
				#        southern or northern hemisphere
	}
	if (falling) {	# add movement from aircraft upon jumping
		var parabola = 0;
		var parachute_drag = 0;
		var zero_xy_sec = (elapsed_fall_sec < 10 ? elapsed_fall_sec : 10.0);
		if (parachute_ft) {	# chute open
			setprop("sim/walker/parachute-opened-sec", (elapsed_sec - parachute_deployed_sec - 1.0));
			# chute starts to add drag at 1 second, fully open at 3 sec. Slows to 17 ft/sec
			if (elapsed_chute_sec >= 3.0) {
				parachute_drag = 0.9;
			} elsif (elapsed_chute_sec >= 0.0) {	# 1 second delay for chute to deploy
				parachute_drag = sin(elapsed_chute_sec * 30) * 0.9;	# 0 to 0.9 in 3 sec.
			}
		}
		if (parachute_drag) {
			zero_xy_sec = parachute_deployed_sec - exit_time_sec + 1.0;
			if (zero_xy_sec > 10.0) {
				zero_xy_sec = 10.0;
			}
		}
		parabola = sin(90 - zero_xy_sec ) * zero_xy_sec - (0.096 * zero_xy_sec * zero_xy_sec / 2);
		if (parachute_drag and zero_xy_sec < 7) {
			posy2 = starting_lat + (lat_vector * parabola) + (lat_vector * parachute_drag);
			posx2 = starting_lon + (lon_vector * parabola) + (lon_vector * parachute_drag);
		} else {
			posy2 = starting_lat + (lat_vector * parabola);
			posx2 = starting_lon + (lon_vector * parabola);
		}
	}
	var posz_geo = geo.elevation(posy2, posx2) / 0.3048;	# convert to ft
	if (falling) {	# 13,000 to 12,000 ft = 10 sec. 12,000 - 4,000 = 44 sec.
			# 5.5 sec to cover each 1000 ft at terminal velocity (ignoring altitude density and surface area)
		var dist_traveled_z = 0;	# feet
		if (posz_geo < posz1) {	# ground is below walker
			dist_traveled_z = -32.185 * time_to_top_sec * time_to_top_sec / 2;	# upward half of arc
			var elapsed1 = elapsed_fall_sec - time_to_top_sec;
				# excludes wind resistance and cross section of projectile. Assume negligible for now.
			if (elapsed_fall_sec > time_to_top_sec) {	# past zero_z and falling
				# drag constant is actually 0.515 kg/s for spread eagle, and 0.067 for feet first.
				# I am ignoring these distinctions for now, until a more complex formula can be made,
				# to go along with the new walker model visibility.
				# also needs to be improved is loss of acceleration due to drag forces
				if (elapsed_fall_sec > (time_to_top_sec + 5.358)) {	# time to reach terminal velocity
					dist_traveled_z += 461.99 + ((elapsed1 - 5.358) * 172);
				} else {	# 9.81m/s/s up to terminal velocity 172ft/s 54m/s spread eagle
					dist_traveled_z += 32.185 * elapsed1 * elapsed1 / 2;
				}
			} else {	# started going up, arch to zero_z before falling
				dist_traveled_z += 32.185 * elapsed1 * elapsed1 / 2;
				# print(sprintf("time_to_top_sec= %6.2f elapsed1= %6.2f  dist_traveled_z_ft = %8.3f  z_vector_mps= %6.2f exit_alt= %9.3f posz1= %9.3f posz2= %9.3f" , time_to_top_sec,elapsed1,dist_traveled_z,z_vector_mps,getprop("sim/walker/altitude-at-exit-ft"),posz1,(getprop("sim/walker/altitude-at-exit-ft")-posz1)));
			}
			if (parachute_ft) {	# chute open
				# need to better model deceleration due to opening of chute, change in surface area.
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
			posz2 = getprop("sim/walker/altitude-at-exit-ft") - dist_traveled_z;
			if (posz2 < posz_geo) {	# below ground
				posz2 = posz_geo;
				walker_model.land(posx2,posy2,posz_geo);
				if (!parachute_ft and dist_traveled_z > 20 and 
				    getprop("sim/current-view/view-number") == view.indexof("Walk View")) {
					# did not land on feet
					print(sprintf("OUCH! You fell %9.2f ft from an exit at %10.2f ft.",dist_traveled_z,getprop("sim/walker/altitude-at-exit-ft")));
					setprop("sim/current-view/pitch-offset-deg", -80);
					setprop("sim/model/bluebird/position/landing-wow", "true");
					# FIXME walker model needs to rotate also
				}
			}
		} else {
			walker_model.land(posx2,posy2,posz_geo);
			posz2 = posz_geo;
		}
	} else {	# not falling
		# check for sudden change in ground elevation
		if ((abs(posz1 - last_altitude) > 1) or ((posz_geo + 1) < posz1)) {
			setprop("sim/walker/time-of-exit-sec", getprop("sim/time/elapsed-sec"));
			setprop("sim/walker/altitude-at-exit-ft", last_altitude);
			# add "forward" momentum upon step out and down
			var lat_m = getprop("sim/walker/speed-mps") * walk_factor * cos(head_w);
			var lon_m = getprop("sim/walker/speed-mps") * walk_factor * (0 - sin(head_w));
			var lat3 = lat_m * ERAD_deg;
			var lon3 = lon_m * ERAD_deg / cos(posy1);
			posy3 = posy1 + lat3;
			posx3 = posx1 + lon3;
			setprop("sim/walker/starting-trajectory-lat", lat3);
			setprop("sim/walker/starting-trajectory-lon", lon3);
			setprop("sim/walker/starting-lat", posy2);
			setprop("sim/walker/starting-lon", posx2);
			setprop("sim/walker/latitude-deg", posy3);
			setprop("sim/walker/longitude-deg", posx3);
			setprop("sim/walker/starting-trajectory-z-mps", 0.0);
			falling = 1;
		}
		if (!falling) {
			if (posz_geo < (posz1 + 10)) {	# walking, ground within 10 ft below walker
				if ((posz1+0.4) > posz_geo or (posz1-0.4) < posz_geo) {	# smoothen stride
					interpolate ("sim/walker/altitude-ft", posz_geo, 0.25, 0.3);
					posz2 = getprop("sim/walker/altitude-ft");
				}
				# print(sprintf("walker_lat= %9.8f lon= %9.8f heading= %6.2f speed= %9.6f groundDistance= %3.2f posz_geo.elev= %8.3f , posz2= %8.3f",posy2,posx2,head_v,speed,distFromCraft(posy2,posx2),posz_geo,posz2));
			} else {
				print (sprintf ("Stopped by wall, has height %6.2f ft above your position.",(posz1-posz_geo)));
				posx2 = posx1;
				posy2 = posy1;
			}
		}
	}
	setprop("sim/walker/latitude-deg", posy2);
	setprop("sim/walker/longitude-deg", posx2);
	last_altitude = posz2;
	setprop("sim/walker/altitude-ft", posz2);
}

setlistener("sim/current-view/heading-offset-deg", func {
	var c_view = getprop("sim/current-view/view-number");
	if (c_view == 0) {
		var head_v = getprop("sim/current-view/heading-offset-deg");
		setprop("sim/model/bluebird/crew/walker/head-offset-deg" , head_v);
	} elsif (c_view == view.indexof("Walk View")) {
		var head_v = getprop("sim/current-view/heading-offset-deg");
		setprop("sim/walker/model-heading-deg" , 360 - head_v);
	}
});

setlistener("sim/current-view/view-number", func {
	if (getprop("sim/current-view/view-number") == view.indexof("Walk View")) {
		yViewNode.setValue(0);
		zViewNode.setValue(1.67);	# matches person height when inside due to aircraft offsets
		xViewNode.setValue(0);
	}
});

var walker_model = {
	add:	func (to_outside) {
			# print ("walker_model.add");
			if (getprop("sim/model/bluebird/crew/walker/visible")) {
				aircraft.makeNode("models/model/path");
				aircraft.makeNode("models/model/longitude-deg-prop");
				aircraft.makeNode("models/model/latitude-deg-prop");
				aircraft.makeNode("models/model/elevation-ft-prop");
				aircraft.makeNode("models/model/heading-deg-prop");
				setprop ("models/model/path", "Aircraft/bluebird/Models/walker.xml");
				setprop ("models/model/longitude-deg-prop", "sim/walker/longitude-deg");
				setprop ("models/model/latitude-deg-prop", "sim/walker/latitude-deg");
				setprop ("models/model/elevation-ft-prop", "sim/walker/altitude-ft");
				setprop ("models/model/heading-deg-prop", "sim/walker/model-heading-deg");
				aircraft.makeNode("models/model/load");
			}
		},
	remove:	func (from_outside) {
			# print ("walker_model.remove");
			if (getprop("sim/model/bluebird/crew/walker/visible")) {
				props.globals.getNode("models", 1).removeChild("model", 0);
			}
		},
	land:	func (lon,lat,alt) {
			falling = 0;
			walk_factor = 1.0;
			setprop("sim/walker/parachute-equipped", "false");
			setprop("sim/walker/parachute-opened-altitude-ft", 0);
			parachute_deployed_sec = 0;
			setprop("sim/walker/parachute-opened-sec", 0);
			setprop("sim/walker/latitude-deg", lat);
			setprop("sim/walker/longitude-deg", lon);
			setprop("sim/walker/altitude-ft", alt);
			setprop("sim/walker/starting-trajectory-lat", 0.0);
			setprop("sim/walker/starting-trajectory-lon", 0.0);
			setprop("sim/walker/starting-trajectory-z-mps", 0.0);
			setprop("sim/walker/time-to-zero-z-sec", 0.0);
			last_altitude = alt;
		},
};

var get_out = func (loc) {
	var c_view = getprop("sim/current-view/view-number");
	var head_add = 0;
	if (c_view == 0) {	# remember point of exit
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
	var c_pitch = getprop("orientation/pitch-deg");
	# for powered ejections, add to the next line the rocket thrust
	var c_z_vector_mps = sin(c_pitch) * c_airspeed_mps;
	# x and y are in meters, but z axis needs to be in feet once it enters altitude calculations
	setprop("sim/walker/starting-trajectory-z-mps", c_z_vector_mps);
	if (c_airspeed_mps < 0) {
		c_airspeed_mps = abs(c_airspeed_mps);
		c_head_deg = normheading(c_head_deg + 180);
	}
	var c_head_rad = c_head_deg * 0.01745329252;
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var xy_Z_factor = math.cos(c_pitch * 0.01745329252);	# factor to zero when pitch = +- 90
	var xy_lat_m = c_airspeed_mps * math.cos(c_head_rad) * xy_Z_factor;
	var xy_lon_m = c_airspeed_mps * math.sin(c_head_rad) * xy_Z_factor;
	var xy_lat = xy_lat_m * ERAD_deg;
	var xy_lon = xy_lon_m * ERAD_deg / cos(c_lat);
	setprop("sim/walker/starting-trajectory-lat", xy_lat);
	setprop("sim/walker/starting-trajectory-lon", xy_lon);
	var c_time0z_sec = math.sqrt(c_z_vector_mps * c_z_vector_mps / 9.81 / 9.81);	# time to top of arc
	if (c_z_vector_mps < 0) {	# going down
		c_time0z_sec = 0 - c_time0z_sec;
	}
	setprop("sim/walker/time-to-zero-z-sec", c_time0z_sec);
	# print(sprintf("get_out: traj-lat= %12.8f traj-lon= %12.8f  c_z_vector_mps= %12.8f",xy_lat,xy_lon,c_z_vector_mps));
	# the following section is aircraft specific for locations of exit hatches and doors
	if (loc == 0) {
		var new_coord = xy2LatLonZ(-12.0,-8.0);	# neutral coordinates outside front port wingtip
	} elsif (loc == 1) {
		var new_coord = xy2LatLonZ(getprop("sim/model/bluebird/crew/walker/x-offset-m"),-4.9);
	} elsif (loc == 2) {
		var new_coord = xy2LatLonZ(getprop("sim/model/bluebird/crew/walker/x-offset-m"),4.9);
	} elsif (loc == 5) {
		var new_coord = xy2LatLonZ(11.0,getprop("sim/model/bluebird/crew/walker/y-offset-m"));
	} else {
		var new_coord = xy2LatLonZ(xViewNode.getValue(),yViewNode.getValue());
	}
	# end aircraft specific
	var head = normheading(abs(getprop("orientation/heading-deg") -360.00) + head_add);
	setprop("sim/walker/latitude-deg" , (getprop("position/latitude-deg")));
	setprop("sim/walker/longitude-deg" , (getprop("position/longitude-deg")));
	setprop("sim/walker/roll-deg" , (getprop("orientation/roll-deg")));
	setprop("sim/walker/pitch-deg" , (getprop("orientation/pitch-deg")));
	setprop("sim/walker/heading-deg" , (getprop("orientation/heading-deg")));
	setprop("sim/view[100]/enabled", "true");
	var posy = new_coord[0];
	var posx = new_coord[1];
	var posz_ft = new_coord[2];
	setprop("sim/walker/outside", 1);
	if (c_view == 0) {
		setprop("sim/current-view/view-number", view.indexof("Walk View"));
		setprop("sim/current-view/view-number", view.indexof("Walk View"));
		setprop("sim/current-view/pitch-offset-deg", getprop("sim/walker/keep-pitch-offset-deg"));
		setprop("sim/current-view/roll-offset-deg", 0);
		setprop("sim/current-view/heading-offset-deg", head);
	}
	setprop("sim/walker/heading-deg", 0);
	setprop("sim/walker/roll-deg", 0);
	setprop("sim/walker/pitch-deg", 0);
	setprop("sim/walker/latitude-deg", new_coord[0]);
	setprop("sim/walker/longitude-deg", new_coord[1]);
	falling = 1;
	setprop("sim/walker/time-of-exit-sec", getprop("sim/time/elapsed-sec"));
	var alt1 = getprop("position/altitude-ft") + posz_ft;
	setprop("sim/walker/altitude-at-exit-ft", alt1);
	setprop("sim/walker/altitude-ft" , alt1);
	if ((alt1 - getprop("position/ground-elev-ft")) > 20) {
		setprop("sim/walker/parachute-equipped", "true");
	}
	setprop("sim/walker/starting-lat", new_coord[0]);
	setprop("sim/walker/starting-lon", new_coord[1]);
	walk_factor = 1.0;
	walker_model.add(1);
}

var get_in = func (loc) {
	walker_model.remove(1);
	setprop("sim/walker/parachute-equipped", "false");
	var c_view = getprop("sim/current-view/view-number");
	if (c_view > 0) {
		var new_walker_x = -2.55;
		var new_walker_y = 0;
		var new_walker_z = 2.1;
		var new_walker_h = 0;

		# the following section is aircraft specific for locations of entry hatches and doors
		if (loc == 0) {	# find open hatch
			if (getprop("sim/model/bluebird/doors/door[0]/position-norm") > 0) {
				new_walker_y = -1.9;
				new_walker_h = 270;
				setprop("sim/model/bluebird/crew/cockpit-position", 4);
				loc = 1;
			} elsif (getprop("sim/model/bluebird/doors/door[1]/position-norm") > 0) {
				new_walker_y = 1.9;
				new_walker_h = 90;
				setprop("sim/model/bluebird/crew/cockpit-position", 4);
				loc = 2;
			} elsif (getprop("sim/model/bluebird/doors/door[5]/position-norm") > 0) {
				new_walker_x = 9.1;
				new_walker_y = 0;
				setprop("sim/model/bluebird/crew/cockpit-position", 4);
				loc = 5;
			}
		} elsif (loc == 1) {
			new_walker_y = -3.4;
			new_walker_h = 270;
			setprop("sim/model/bluebird/crew/cockpit-position", 4);
		} elsif (loc == 2) {
			new_walker_y = 3.4;
			new_walker_h = 90;
			setprop("sim/model/bluebird/crew/cockpit-position", 4);
		} elsif (loc == 5) {
			new_walker_x = 10.0;
			new_walker_y = 0;
			setprop("sim/model/bluebird/crew/cockpit-position", 4);
		}
		if (loc >= 1) {
			setprop("sim/model/bluebird/crew/walker/x-offset-m", new_walker_x);
			setprop("sim/model/bluebird/crew/walker/y-offset-m", new_walker_y);
		} else {
			if (getprop("sim/model/bluebird/crew/walker/y-offset-m") > 1.3) {
				setprop("sim/model/bluebird/crew/walker/y-offset-m", 1.3);
			} elsif (getprop("sim/model/bluebird/crew/walker/y-offset-m") < -1.3) {
				setprop("sim/model/bluebird/crew/walker/y-offset-m", -1.3);
			}
		}
		if (c_view == view.indexof("Walk View")) {
			setprop("sim/current-view/view-number", 0);
			if (loc >= 1) {
				yViewNode.setValue(new_walker_y);
				zViewNode.setValue(new_walker_z);
				xViewNode.setValue(new_walker_x);
				setprop("sim/current-view/heading-offset-deg", new_walker_h);
			}
		}
	}
	setprop("sim/walker/outside", 0);
	setprop("sim/walker/parachute-opened-altitude-ft", 0);
	parachute_deployed_sec = 0;
	setprop("sim/walker/parachute-opened-sec", 0);
	setprop("sim/view[100]/enabled", "false");
}

var open_chute = func {
	if (getprop("sim/walker/parachute-equipped") and exit_time_sec and !parachute_ft) {
		setprop("sim/walker/parachute-opened-altitude-ft", getprop("sim/walker/altitude-ft"));
		parachute_deployed_sec = getprop("sim/time/elapsed-sec");
		setprop("sim/walker/parachute-opened-sec", 0);
	}
}

var reinit_walker = func {
	setprop("sim/walker/outside", 0);
	setprop("sim/view[100]/enabled","false");
	setprop("sim/walker/parachute-equipped", "false");
	falling = 0;
	walk_factor = 1.0;
	setprop("sim/walker/parachute-opened-altitude-ft", 0);
	parachute_deployed_sec = 0;
	setprop("sim/walker/parachute-opened-sec", 0);
}

setlistener("sim/signals/reinit", func {
	reinit_walker();
});

 setlistener("sim/signals/fdm-initialized", func {
	reinit_walker();
});

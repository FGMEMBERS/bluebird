# ===== text screen functions for version 1.0 and OSG =====
# ===== and backend for ai-vor
# ===== for Bluebird Explorer Hovercraft version 8.7 =====

var sin = func(a) { math.sin(a * math.pi / 180.0) }	# degrees
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var asin = func(y) { math.atan2(y, math.sqrt(1-y*y)) }	# radians
var ERAD = 6378138.12; 		# Earth radius (m)
var m_2_conv = [0.000621371192, 0.001];
var m_conv_units = [" MI"," KM"];
var m_conv_format = [" %5.2f "," %4.3f "];
var ft_2_conv = [1.0, 0.3048];
var ft_conv_units = [" FT"," M"];
var ft_conv_format = [" %7.0f "," %8.1f "];

var normbearing = func (a,c) {
	var h = a - c;
	while (h >= 180)
		h -= 360;
	while (h < -180)
		h += 360;
	return h;
}

var normheading = func (a) {
	while (a >= 360)
		a -= 360;
	while (a < 0)
		a += 360;
	return a;
}

var bearing_to = func (bearing) {
	var normalized = normheading(bearing);
	return ((normalized > 90 and normalized < 270)? -1 : 1);
}

var refresh_2L = 1.0;
var a_mode = 0;

# ======== nearest airport for screen-1R ============================
var apt_loop_id = 0;
var apt_loop = func (id) {
	id == apt_loop_id or return;
	var a = airportinfo();
	if (apt == nil or apt.id != a.id) {
		apt = a;
		var is_heliport = 1;
		foreach (var rwy; keys(apt.runways)) {
			if (rwy[0] != `H`) {
				is_heliport = 0;
			}
		}
		if (is_heliport) {
			setprop("instrumentation/display-screens/ap1-callsign", apt.id ~ "  HELIPORT");
		} else {
			setprop("instrumentation/display-screens/ap1-callsign", apt.id);
		}
		setprop("instrumentation/display-screens/t1R-16", apt.name);
		setprop("instrumentation/display-screens/t1R-17a", apt.lat);
		setprop("instrumentation/display-screens/t1R-17b", apt.lon);
		setprop("instrumentation/ai-vor/ap1-elevation", apt.elevation);
	}
	settimer(func { apt_loop(id) }, 5);
}

var apt_update_id = 0;
var apt_update = func (id) {
	id == apt_update_id or return;
	if (apt != nil) {
		var c_lat = getprop("position/latitude-deg");
		var c_lon = getprop("position/longitude-deg");
		var c_head_deg = getprop("orientation/heading-deg");
		var avglat = (c_lat + apt.lat) / 2;
		var y = apt.lat - c_lat;
		var x_grid = apt.lon - c_lon;
#		if (abs(x_grid) > 180) {	# international date line is not observed in airportinfo
#			if (apt.lon < -90) {
#				c_lon -= 360.0;
#			} else {
#				c_lon += 360.0;
#			}
#			x_grid = apt.lon - c_lon;
#		}
#		if (avglat < 90 and avglat > -90) {
			var x = x_grid * cos(avglat);
#		} else {
#			print ("Error detected in airport section, line 88  avglat= ",avglat);
#			var x = x_grid * cos(c_lat);
#		}
		var xy_hyp = math.sqrt((x * x) + (y * y));
		var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
		head = (c_lat > apt.lat ? normheading(180 - head) : normheading(head));
		var bearing = normbearing(head, c_head_deg);
		setprop("instrumentation/display-screens/t1R-18a", head);
		setprop("instrumentation/ai-vor/ap1-heading-offset", 360 - bearing - c_head_deg);
		setprop("instrumentation/ai-vor/ap1-to", bearing_to(bearing));
		var range = walk.distFromCraft(apt.lat, apt.lon);
		setprop("instrumentation/ai-vor/ap1-distance-m", range);
		var c_alt = getprop("position/altitude-ft");
		var e_m = apt.elevation - (c_alt * 0.3048);
		var xy_hyp = math.sqrt((e_m * e_m) + (range * range));
		var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
		setprop("instrumentation/ai-vor/ap1-elevation-deg", ze);
		range = range * m_2_conv[a_mode];
		var txt18 = sprintf("%7.2f",range) ~ m_conv_units[a_mode];
		setprop("instrumentation/display-screens/t1R-18b", txt18);
	}
	settimer(func { apt_update(id) }, 0.25);
}

# ======== nearest aircraft for screen-2L ============================
var cleanup_2L = func {
	var ai_s = getprop("instrumentation/ai-vor/ai-size");
	var mp_s = getprop("instrumentation/ai-vor/mp-size");
	var s = (ai_s > -1 ? ai_s : 0) + (mp_s > -1 ? mp_s : 0);
	for (var i = s ; i <= 13 ; i += 1) {
		setprop("instrumentation/display-screens/t2L-" ~ (i+3) ~ "a", " ");
		setprop("instrumentation/display-screens/t2L-" ~ (i+3) ~ "b", " ");
		setprop("instrumentation/display-screens/t2L-" ~ (i+3) ~ "c", " ");
	}
}

var ac_update = func {
	var ac = props.globals.getNode("ai/models").getChildren("aircraft");
	var mp = props.globals.getNode("ai/models").getChildren("multiplayer");
	if (ac != nil) {
		var c_lat = getprop("position/latitude-deg");
		var c_lon = getprop("position/longitude-deg");
		var c_alt = getprop("position/altitude-ft");
		var c_head_deg = getprop("orientation/heading-deg");
		var a_mode = getprop("instrumentation/digital/altitude-mode");
		var ac_list = [];
		var s = size(ac);
		var ac_closest = -1;
		var ac_closest_distance = 999999;
		var ac_i = 0;
		for (var i = 0 ; i < s ; i += 1) {
			if(ac[i].getNode("callsign") != nil and ac[i].getNode("valid").getValue()) {
				var b = ac[i].getNode("position");
				var alat = b.getNode("latitude-deg").getValue();
				var alon = b.getNode("longitude-deg").getValue();
				var avglat = (c_lat + alat) / 2;
				var y = alat - c_lat;
				var x_grid = alon - c_lon;
				# don't waste resources checking for longitude -180 in ai_aircraft
#				if (avglat < 90 and avglat > -90) {
					var x = x_grid * cos(avglat);
#				} else {
#					print ("Error detected in aircraft section, line 150  avglat= ",avglat);
#					var x = x_grid * cos(c_lat);
#				}
				var ah1 = sin(y * 0.5);
				var ah2 = sin(x * 0.5);
				var adist_m = 2.0 * ERAD * asin(math.sqrt(ah1 * ah1 + cos(alat) * cos(c_lat) * ah2 * ah2));
				var xy_hyp = math.sqrt((x * x) + (y * y));
				var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
				head = (c_lat > alat ? normheading(180 - head) : normheading(head));
				var bearing = normbearing(head, c_head_deg);
				append(ac_list, { callsign:ac[i].getNode("callsign").getValue(), index:i, dist_m:adist_m, alt_ft:b.getNode("altitude-ft").getValue(), bearing:bearing});
				if (adist_m < ac_closest_distance) {
					ac_closest_distance = adist_m;
					ac_closest = ac_i;
				}
				ac_i += 1;
			}
		}
		var vor_h = 0;
		if (size(ac_list) >= ac_closest and ac_closest != -1) {
			vor_h = 360 - ac_list[ac_closest].bearing - c_head_deg;
			setprop("instrumentation/ai-vor/ai-size", ac_i);
			setprop("instrumentation/ai-vor/ai1-callsign", ac_list[ac_closest].callsign);
			setprop("instrumentation/ai-vor/ai1-distance-m", ac_list[ac_closest].dist_m);
			setprop("instrumentation/ai-vor/ai1-to", bearing_to(ac_list[ac_closest].bearing));
			var e_m = (ac_list[ac_closest].alt_ft - c_alt) * 0.3048;
			var xy_hyp = math.sqrt((e_m * e_m) + (ac_list[ac_closest].dist_m * ac_list[ac_closest].dist_m));
			var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
			setprop("instrumentation/ai-vor/ai1-elevation-deg", ze);
		} else {
			if (getprop("instrumentation/ai-vor/mode") == 1) {
				setprop("instrumentation/ai-vor/mode", 0);
			}
			setprop("instrumentation/ai-vor/ai-size", -1);
			setprop("instrumentation/ai-vor/ai1-callsign", " ");
			setprop("instrumentation/ai-vor/ai1-distance-m", -999999);
			setprop("instrumentation/ai-vor/ai1-elevation-deg", -99);
		}
		setprop("instrumentation/ai-vor/ai1-heading-offset", vor_h);
		var ac_closest = -1;
		var ac_closest_distance = 999999;
		if (mp != nil) {
			var s = size(mp);
			for (var i = 0 ; i < s ; i += 1) {
				if(mp[i].getNode("callsign") != nil and mp[i].getNode("valid").getValue()) {
					var b = mp[i].getNode("position");
					var alat = b.getNode("latitude-deg").getValue();
					var alon = b.getNode("longitude-deg").getValue();
					var avglat = (c_lat + alat) / 2;
					var y = alat - c_lat;
					var x_grid = alon - c_lon;
					if (abs(x_grid) > 180) {
						if (alon < -90) {
							c_lon -= 360.0;
						} else {
							c_lon += 360.0;
						}
						x_grid = alon - c_lon;
					}
					if (avglat < 90 and avglat > -90) {
						var x = x_grid * cos(avglat);
					} else {
						print ("Error detected in mp section, line 212  avglat= ",avglat);
						var x = x_grid * cos(c_lat);
					}
					var ah1 = sin(y * 0.5);
					var ah2 = sin(x * 0.5);
					var adist_m = 2.0 * ERAD * asin(math.sqrt(ah1 * ah1 + cos(alat) * cos(c_lat) * ah2 * ah2));
					var xy_hyp = math.sqrt((x * x) + (y * y));
					var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
					head = (c_lat > alat ? normheading(180 - head) : normheading(head));
					var bearing = normbearing(head, c_head_deg);
					append(ac_list, { callsign:mp[i].getNode("callsign").getValue(), index:i, dist_m:adist_m, alt_ft:b.getNode("altitude-ft").getValue(), bearing:bearing});
					if (adist_m < ac_closest_distance) {
						ac_closest_distance = adist_m;
						ac_closest = ac_i;
					}
					ac_i += 1;
				}
			}
		}
		vor_h = 0;
		if (size(ac_list) >= ac_closest and ac_closest != -1) {
			vor_h = 360 - ac_list[ac_closest].bearing - c_head_deg;
			setprop("instrumentation/ai-vor/mp-size", ac_i);
			setprop("instrumentation/ai-vor/mp1-callsign", ac_list[ac_closest].callsign);
			setprop("instrumentation/ai-vor/mp1-distance-m", ac_list[ac_closest].dist_m);
			setprop("instrumentation/ai-vor/mp1-to", bearing_to(ac_list[ac_closest].bearing));
			var e_m = (ac_list[ac_closest].alt_ft - c_alt) * 0.3048;
			var xy_hyp = math.sqrt((e_m * e_m) + (ac_list[ac_closest].dist_m * ac_list[ac_closest].dist_m));
			var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
			setprop("instrumentation/ai-vor/mp1-elevation-deg", ze);
		} else {
			setprop("instrumentation/ai-vor/mp-size", -1);
			setprop("instrumentation/ai-vor/mp1-callsign", " ");
			setprop("instrumentation/ai-vor/mp1-distance-m", -999999);
			setprop("instrumentation/ai-vor/mp1-elevation-deg", -99);
		}
		setprop("instrumentation/ai-vor/mp1-heading-offset", vor_h);
		var sac = sort(ac_list, func(a,b) { return (a.dist_m > b.dist_m) });
		var s = size(sac);
		for (var i = 0 ; (i < s and i <= 13) ; i += 1) {
			setprop("instrumentation/display-screens/t2L-" ~ (i+3) ~ "a", sac[i].callsign);
			var txt2d = sprintf(m_conv_format[a_mode],m_2_conv[a_mode]*sac[i].dist_m) ~ m_conv_units[a_mode];
			var altn = ft_2_conv[a_mode]*sac[i].alt_ft;
			if (altn < 10000) { 
				if (altn < 100) {
					if (altn < 1) {
						var txt2a = "   " ~ sprintf(ft_conv_format[a_mode],altn) ~ ft_conv_units[a_mode];
					} else {
						var txt2a = "  " ~ sprintf(ft_conv_format[a_mode],altn) ~ ft_conv_units[a_mode];
					}
				} else {
					var txt2a = " " ~ sprintf(ft_conv_format[a_mode],altn) ~ ft_conv_units[a_mode];
				}
			} else {
				var txt2a = sprintf(ft_conv_format[a_mode],altn) ~ ft_conv_units[a_mode];
			}
			var txt2h = sprintf(" %3i",sac[i].bearing);
			setprop("instrumentation/display-screens/t2L-" ~ (i+3) ~ "b", txt2d ~ txt2a);
			setprop("instrumentation/display-screens/t2L-" ~ (i+3) ~ "c", txt2h);
		}
	}
}

var ac_loop_id = 0;
var ac_loop = func (id) {
	id == ac_loop_id or return;
	var ac = props.globals.getNode("ai/models").getChildren("aircraft");
	if ((aiac == nil) or (screen_2L_on)) {
		aiac = ac;	# copy of node vector
		ac_update();
	}
	if (screen_2L_on) {
		settimer(func { ac_loop(ac_loop_id += 1) }, refresh_2L);
	}
}

# ======== combined aircraft and airport section ===================
var apt = nil;
var aiac = nil;
settimer(func { apt_loop(apt_loop_id += 1) }, 2);

settimer(func { apt_update(apt_update_id += 1) }, 3);

# ======== screen-3R ==============================================
var screen_3R_on = 0;
var scroll_3R = func (newtext) {
	if (screen_3R_on) {
		setprop("instrumentation/display-screens/t3R-2", getprop("instrumentation/display-screens/t3R-3"));
		setprop("instrumentation/display-screens/t3R-3", getprop("instrumentation/display-screens/t3R-4"));
		setprop("instrumentation/display-screens/t3R-4", getprop("instrumentation/display-screens/t3R-5"));
		setprop("instrumentation/display-screens/t3R-5", getprop("instrumentation/display-screens/t3R-6"));
		setprop("instrumentation/display-screens/t3R-6", getprop("instrumentation/display-screens/t3R-7"));
		setprop("instrumentation/display-screens/t3R-7", getprop("instrumentation/display-screens/t3R-8"));
		setprop("instrumentation/display-screens/t3R-8", getprop("instrumentation/display-screens/t3R-9"));
		setprop("instrumentation/display-screens/t3R-9", getprop("instrumentation/display-screens/t3R-10"));
		setprop("instrumentation/display-screens/t3R-10", getprop("instrumentation/display-screens/t3R-11"));
		setprop("instrumentation/display-screens/t3R-11", getprop("instrumentation/display-screens/t3R-12"));
		setprop("instrumentation/display-screens/t3R-12", getprop("instrumentation/display-screens/t3R-13"));
		setprop("instrumentation/display-screens/t3R-13", getprop("instrumentation/display-screens/t3R-14"));
		setprop("instrumentation/display-screens/t3R-14", getprop("instrumentation/display-screens/t3R-15"));
		setprop("instrumentation/display-screens/t3R-15", getprop("instrumentation/display-screens/t3R-16"));
		setprop("instrumentation/display-screens/t3R-16", newtext);
	}
}

var update_3R = func {
	if (screen_3R_on) {
		#debug## note difference between ground-elevation and geo-reported-ground-elevation
		var gnd_elev = getprop("position/ground-elev-ft");
		var lat = getprop("position/latitude-deg");
		var lon = getprop("position/longitude-deg");
		var info = geodinfo(lat, lon);
		var geo_gnd = info[0] * 3.280839895;
		var text_3R = sprintf("    % 14.4f % 13.4f      % 6.4f    % 14.4f", gnd_elev, geo_gnd, (gnd_elev-geo_gnd), bluebird.contact_altitude);
		displayScreens.scroll_3R(text_3R);
	}
	settimer(update_3R, 0.25);
}
settimer(update_3R,3);

var init = func {
	setlistener("instrumentation/digital/altitude-mode", func {
		a_mode = getprop("instrumentation/digital/altitude-mode");
	});

	setlistener("instrumentation/display-screens/refresh-2L-sec", func {
		refresh_2L = getprop("instrumentation/display-screens/refresh-2L-sec");
	});

	setlistener("instrumentation/ai-vor/ai-size", func {
		cleanup_2L();
	},,0);

	setlistener("instrumentation/ai-vor/mp-size", func {
		cleanup_2L();
	},,0);

	setlistener("instrumentation/display-screens/enabled-2L", func {
		if (getprop("instrumentation/display-screens/enabled-2L")) {
			setprop("instrumentation/display-screens/t2L-2", "Callsign                 Distance   Altitude   Bearing");
			settimer(func { ac_loop(ac_loop_id += 1) }, 0);
		}
	}, 1);

	setlistener("sim/signals/reinit", func {
		apt = nil;
		aiac = nil;
	});

	setlistener("instrumentation/display-screens/enabled-3R", func {
		screen_3R_on = getprop("instrumentation/display-screens/enabled-3R");
		setprop("instrumentation/display-screens/t3R-1", "position/ground-elev  geo-ground    difference   contact-altitude");
	}, 1);
}
settimer(init,0);

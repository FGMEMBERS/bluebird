# ===== text screen functions for FG version 1.9-2.0 (OSG) =====
# ===== and backend for ai-vor
# ===== for Bluebird Explorer Hovercraft version 10.4 =====

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

var bearing_to_factor = func (bearing) {
	var normalized = normheading(bearing);
	return ((normalized > 90 and normalized < 270) ? -1 : 1);
}

# ======== update details for screen-1L =============================
var mps_2_conv = [1, 1.9438445, 2.2369363, 3.6, 1.9438445];
var mps_conv_units = [" MPS"," KNOTS"," MPH"," KMPH"," KNOTS"];

var refresh_2L = 1.0;
var a_mode = 0;

var tracking_on = 0;
# ======== nearest airport updated every 5 sec. =====================
var ap1_bearing_Node = props.globals.getNode("instrumentation/tracking/ap1-bearing-deg", 1);
var ap1_callsign_Node = props.globals.getNode("instrumentation/tracking/ap1-callsign", 1);
var ap1_dist_Node = props.globals.getNode("instrumentation/tracking/ap1-distance-m", 1);
var ap1_elev_Node = props.globals.getNode("instrumentation/tracking/ap1-elevation-deg", 1);
var ap1_heading_offset_Node = props.globals.getNode("instrumentation/tracking/ap1-heading-offset-deg", 1);
var ap1_heading_Node = props.globals.getNode("instrumentation/tracking/ap1-heading-deg", 1);
var ap1_name_Node = props.globals.getNode("instrumentation/tracking/ap1-name", 1);
var ap1_lat_Node = props.globals.getNode("instrumentation/tracking/ap1-lat", 1);
var ap1_lon_Node = props.globals.getNode("instrumentation/tracking/ap1-lon", 1);
var ap1_range_Node = props.globals.getNode("instrumentation/tracking/ap1-range", 1);
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
			ap1_callsign_Node.setValue(apt.id ~ "  HELIPORT");
		} else {
			ap1_callsign_Node.setValue(apt.id);
		}
		ap1_name_Node.setValue(apt.name);
		ap1_lat_Node.setValue(apt.lat);
		ap1_lon_Node.setValue(apt.lon);
		ap1_elev_Node.setValue(apt.elevation);
	}
	settimer(func { apt_loop(id) }, 5);
}

# ======== update tracking for nearest airport every 0.25 sec =======
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
		ap1_heading_Node.setValue(head);
		ap1_heading_offset_Node.setValue((360 - bearing - c_head_deg));
		setprop("instrumentation/tracking/ap1-to-factor", bearing_to_factor(bearing));
		var range = walk.distFromCraft(apt.lat, apt.lon);
		ap1_dist_Node.setValue(range);
		var c_alt = getprop("position/altitude-ft");
		var e_m = apt.elevation - (c_alt * 0.3048);
		var xy_hyp = math.sqrt((e_m * e_m) + (range * range));
		var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
		ap1_elev_Node.setValue(ze);
		range = range * m_2_conv[a_mode];
		var txt18 = sprintf("%7.2f",range) ~ m_conv_units[a_mode];
		ap1_range_Node.setValue(txt18);
	}
	settimer(func { apt_update(id) }, 0.25);
}

# ======== nearest aircraft for screen-2L ============================
var cleanup_2L = func {
	var ai_s = getprop("instrumentation/tracking/ai-size");
	var mp_s = getprop("instrumentation/tracking/mp-size");
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
			setprop("instrumentation/tracking/ai-size", ac_i);
			setprop("instrumentation/tracking/ai1-callsign", ac_list[ac_closest].callsign);
			setprop("instrumentation/tracking/ai1-distance-m", ac_list[ac_closest].dist_m);
			setprop("instrumentation/tracking/ai1-to-factor", bearing_to_factor(ac_list[ac_closest].bearing));
			var e_m = (ac_list[ac_closest].alt_ft - c_alt) * 0.3048;
			var xy_hyp = math.sqrt((e_m * e_m) + (ac_list[ac_closest].dist_m * ac_list[ac_closest].dist_m));
			var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
			setprop("instrumentation/tracking/ai1-elevation-deg", ze);
		} else {
			if (getprop("instrumentation/ai-vor/mode") == 1) {
				setprop("instrumentation/ai-vor/mode", 0);
			}
			setprop("instrumentation/tracking/ai-size", -1);
			setprop("instrumentation/tracking/ai1-callsign", " ");
			setprop("instrumentation/tracking/ai1-distance-m", -999999);
			setprop("instrumentation/tracking/ai1-elevation-deg", -99);
		}
		setprop("instrumentation/tracking/ai1-heading-offset-deg", vor_h);
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
						print ("Error detected in mp section, line 222  avglat= ",avglat);
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
# add walker to list
		if (getprop("sim/walker/outside")) {
			var alat = getprop("sim/walker/latitude-deg");
			var alon = getprop("sim/walker/longitude-deg");
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
				print ("Error detected in walker section, line 264  avglat= ",avglat);
				var x = x_grid * cos(c_lat);
			}
			var ah1 = sin(y * 0.5);
			var ah2 = sin(x * 0.5);
			var adist_m = 2.0 * ERAD * asin(math.sqrt(ah1 * ah1 + cos(alat) * cos(c_lat) * ah2 * ah2));
			var xy_hyp = math.sqrt((x * x) + (y * y));
			var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
			head = (c_lat > alat ? normheading(180 - head) : normheading(head));
			var bearing = normbearing(head, c_head_deg);
			append(ac_list, { callsign:"Walker", index:0, dist_m:adist_m, alt_ft:getprop("sim/walker/altitude-ft"), bearing:bearing});
			if (adist_m < ac_closest_distance) {
				ac_closest_distance = adist_m;
				ac_closest = ac_i;
			}
			ac_i += 1;
		}
		vor_h = 0;
		if (size(ac_list) >= ac_closest and ac_closest != -1) {
			vor_h = 360 - ac_list[ac_closest].bearing - c_head_deg;
			setprop("instrumentation/tracking/mp-size", ac_i);
			setprop("instrumentation/tracking/mp1-callsign", ac_list[ac_closest].callsign);
			setprop("instrumentation/tracking/mp1-distance-m", ac_list[ac_closest].dist_m);
			setprop("instrumentation/tracking/mp1-to-factor", bearing_to_factor(ac_list[ac_closest].bearing));
			var e_m = (ac_list[ac_closest].alt_ft - c_alt) * 0.3048;
			var xy_hyp = math.sqrt((e_m * e_m) + (ac_list[ac_closest].dist_m * ac_list[ac_closest].dist_m));
			var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
			setprop("instrumentation/tracking/mp1-elevation-deg", ze);
		} else {
			setprop("instrumentation/tracking/mp-size", -1);
			setprop("instrumentation/tracking/mp1-callsign", " ");
			setprop("instrumentation/tracking/mp1-distance-m", -999999);
			setprop("instrumentation/tracking/mp1-elevation-deg", -99);
		}
		setprop("instrumentation/tracking/mp1-heading-offset-deg", vor_h);
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
	if ((aiac == nil) or (tracking_on)) {
		aiac = ac;	# copy of node vector
		ac_update();
	}
	if (tracking_on) {
		settimer(func { ac_loop(ac_loop_id += 1) }, refresh_2L);
	}
}

# ======== fixed airport tracking and homing ========================
var ap2_bearing_Node = props.globals.getNode("instrumentation/tracking/ap2-bearing-deg", 1);
var ap2_callsign_Node = props.globals.getNode("instrumentation/tracking/ap2-callsign", 1);
var ap2_dist_Node = props.globals.getNode("instrumentation/tracking/ap2-distance-m", 1);
var ap2_elev_Node = props.globals.getNode("instrumentation/tracking/ap2-elevation-deg", 1);
var ap2_heading_offset_Node = props.globals.getNode("instrumentation/tracking/ap2-heading-offset-deg", 1);
var ap2_heading_Node = props.globals.getNode("instrumentation/tracking/ap2-heading-deg", 1);
var ap2_name_Node = props.globals.getNode("instrumentation/tracking/ap2-name", 1);
var ap2_lat_Node = props.globals.getNode("instrumentation/tracking/ap2-lat", 1);
var ap2_lon_Node = props.globals.getNode("instrumentation/tracking/ap2-lon", 1);
var ap2_range_Node = props.globals.getNode("instrumentation/tracking/ap2-range", 1);
var ap2 = nil;
var ap2c_L = nil;

var ap2_update = func {
	if (ap2 != nil) {
		var c_lat = getprop("position/latitude-deg");
		var c_lon = getprop("position/longitude-deg");
		var c_head_deg = getprop("orientation/heading-deg");
		var avglat = (c_lat + ap2.lat) / 2;
		var y = ap2.lat - c_lat;
		var x_grid = ap2.lon - c_lon;
		if (abs(x_grid) > 180) {	# international date line
			if (ap2.lon < -90) {
				c_lon -= 360.0;
			} else {
				c_lon += 360.0;
			}
			x_grid = ap2.lon - c_lon;
		}
		var x = x_grid * cos(avglat);
		var xy_hyp = math.sqrt((x * x) + (y * y));
		var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
		head = (c_lat > ap2.lat ? normheading(180 - head) : normheading(head));
		var bearing = normbearing(head, c_head_deg);
		ap2_bearing_Node.setValue(bearing);
		ap2_heading_Node.setValue(head);
		ap2_heading_offset_Node.setValue((360 - bearing - c_head_deg));
		setprop("instrumentation/tracking/ap2-to-factor", bearing_to_factor(bearing));
		var range = walk.distFromCraft(ap2.lat, ap2.lon);
		ap2_dist_Node.setValue(range);
		var c_alt = getprop("position/altitude-ft");
		var e_m = ap2.elevation - (c_alt * 0.3048);
		var xy_hyp = math.sqrt((e_m * e_m) + (range * range));
		var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
		ap2_elev_Node.setValue(ze);
		range = range * m_2_conv[a_mode];
		var txt18 = sprintf("%7.2f",range) ~ m_conv_units[a_mode];
		ap2_range_Node.setValue(txt18);
	} else {
		ap2_bearing_Node.setValue(0);
		ap2_dist_Node.setValue(-999999);
	}
}

var ap2_loop_id = 0;
var ap2_loop = func (id) {
	id == ap2_loop_id or return;
#	if (c_view == 0) {
		ap2_update();
#	}
	settimer(func { ap2_loop(id) }, 0.95);
}

settimer(func { ap2_loop(ap2_loop_id += 1) }, 3);

# ======== combined aircraft and airport section ===================
var apt = nil;
var aiac = nil;
settimer(func { apt_loop(apt_loop_id += 1) }, 2);

settimer(func { apt_update(apt_update_id += 1) }, 3);

# ======== scroll screen-2L and screen-2R ==========================
var screen_2L_on = 0;
var scroll_2L = func (newtext) {
	if (screen_2L_on) {
		setprop("instrumentation/display-screens/t2L-2", getprop("instrumentation/display-screens/t2L-3"));
		setprop("instrumentation/display-screens/t2L-3", getprop("instrumentation/display-screens/t2L-4"));
		setprop("instrumentation/display-screens/t2L-4", getprop("instrumentation/display-screens/t2L-5"));
		setprop("instrumentation/display-screens/t2L-5", getprop("instrumentation/display-screens/t2L-6"));
		setprop("instrumentation/display-screens/t2L-6", getprop("instrumentation/display-screens/t2L-7"));
		setprop("instrumentation/display-screens/t2L-7", getprop("instrumentation/display-screens/t2L-8"));
		setprop("instrumentation/display-screens/t2L-8", getprop("instrumentation/display-screens/t2L-9"));
		setprop("instrumentation/display-screens/t2L-9", getprop("instrumentation/display-screens/t2L-10"));
		setprop("instrumentation/display-screens/t2L-10", getprop("instrumentation/display-screens/t2L-11"));
		setprop("instrumentation/display-screens/t2L-11", getprop("instrumentation/display-screens/t2L-12"));
		setprop("instrumentation/display-screens/t2L-12", getprop("instrumentation/display-screens/t2L-13"));
		setprop("instrumentation/display-screens/t2L-13", getprop("instrumentation/display-screens/t2L-14"));
		setprop("instrumentation/display-screens/t2L-14", getprop("instrumentation/display-screens/t2L-15"));
		setprop("instrumentation/display-screens/t2L-15", getprop("instrumentation/display-screens/t2L-16"));
		setprop("instrumentation/display-screens/t2L-16", newtext);
	}
}

var screen_2R_on = 1;
var scroll_2R = func (newtext) {
	if (screen_2R_on) {
		setprop("instrumentation/display-screens/t2R-2", getprop("instrumentation/display-screens/t2R-3"));
		setprop("instrumentation/display-screens/t2R-3", getprop("instrumentation/display-screens/t2R-4"));
		setprop("instrumentation/display-screens/t2R-4", getprop("instrumentation/display-screens/t2R-5"));
		setprop("instrumentation/display-screens/t2R-5", getprop("instrumentation/display-screens/t2R-6"));
		setprop("instrumentation/display-screens/t2R-6", getprop("instrumentation/display-screens/t2R-7"));
		setprop("instrumentation/display-screens/t2R-7", getprop("instrumentation/display-screens/t2R-8"));
		setprop("instrumentation/display-screens/t2R-8", getprop("instrumentation/display-screens/t2R-9"));
		setprop("instrumentation/display-screens/t2R-9", getprop("instrumentation/display-screens/t2R-10"));
		setprop("instrumentation/display-screens/t2R-10", getprop("instrumentation/display-screens/t2R-11"));
		setprop("instrumentation/display-screens/t2R-11", getprop("instrumentation/display-screens/t2R-12"));
		setprop("instrumentation/display-screens/t2R-12", getprop("instrumentation/display-screens/t2R-13"));
		setprop("instrumentation/display-screens/t2R-13", getprop("instrumentation/display-screens/t2R-14"));
		setprop("instrumentation/display-screens/t2R-14", getprop("instrumentation/display-screens/t2R-15"));
		setprop("instrumentation/display-screens/t2R-15", getprop("instrumentation/display-screens/t2R-16"));
		setprop("instrumentation/display-screens/t2R-16", getprop("instrumentation/display-screens/t2R-17"));
		setprop("instrumentation/display-screens/t2R-17", getprop("instrumentation/display-screens/t2R-18"));
		setprop("instrumentation/display-screens/t2R-18", getprop("instrumentation/display-screens/t2R-19"));
		setprop("instrumentation/display-screens/t2R-19", getprop("instrumentation/display-screens/t2R-20"));
		setprop("instrumentation/display-screens/t2R-20", newtext);
	}
}

# ======== screen-3L and screen-3R ==============================
var screen_3L_on = 1;
var screen_3L_damage_level = 0;
var scroll_3L = func (newtext) {
	if (screen_3L_on) {
		setprop("instrumentation/display-screens/t3L-2", getprop("instrumentation/display-screens/t3L-3"));
		setprop("instrumentation/display-screens/t3L-3", getprop("instrumentation/display-screens/t3L-4"));
		setprop("instrumentation/display-screens/t3L-4", getprop("instrumentation/display-screens/t3L-5"));
		setprop("instrumentation/display-screens/t3L-5", getprop("instrumentation/display-screens/t3L-6"));
		setprop("instrumentation/display-screens/t3L-6", getprop("instrumentation/display-screens/t3L-7"));
		setprop("instrumentation/display-screens/t3L-7", getprop("instrumentation/display-screens/t3L-8"));
		setprop("instrumentation/display-screens/t3L-8", getprop("instrumentation/display-screens/t3L-9"));
		setprop("instrumentation/display-screens/t3L-9", getprop("instrumentation/display-screens/t3L-10"));
		setprop("instrumentation/display-screens/t3L-10", getprop("instrumentation/display-screens/t3L-11"));
		setprop("instrumentation/display-screens/t3L-11", getprop("instrumentation/display-screens/t3L-12"));
		setprop("instrumentation/display-screens/t3L-12", getprop("instrumentation/display-screens/t3L-13"));
		setprop("instrumentation/display-screens/t3L-13", getprop("instrumentation/display-screens/t3L-14"));
		setprop("instrumentation/display-screens/t3L-14", getprop("instrumentation/display-screens/t3L-15"));
		setprop("instrumentation/display-screens/t3L-15", getprop("instrumentation/display-screens/t3L-16"));
		setprop("instrumentation/display-screens/t3L-16", newtext);
	}
}

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

# ======== screen-4R ================================================
var screen_4R_on = 0;
var scroll_4R = func (newtext) {
	if (screen_4R_on) {
		setprop("instrumentation/display-screens/t4R-2", getprop("instrumentation/display-screens/t4R-3"));
		setprop("instrumentation/display-screens/t4R-3", getprop("instrumentation/display-screens/t4R-4"));
		setprop("instrumentation/display-screens/t4R-4", getprop("instrumentation/display-screens/t4R-5"));
		setprop("instrumentation/display-screens/t4R-5", getprop("instrumentation/display-screens/t4R-6"));
		setprop("instrumentation/display-screens/t4R-6", getprop("instrumentation/display-screens/t4R-7"));
		setprop("instrumentation/display-screens/t4R-7", getprop("instrumentation/display-screens/t4R-8"));
		setprop("instrumentation/display-screens/t4R-8", getprop("instrumentation/display-screens/t4R-9"));
		setprop("instrumentation/display-screens/t4R-9", getprop("instrumentation/display-screens/t4R-10"));
		setprop("instrumentation/display-screens/t4R-10", getprop("instrumentation/display-screens/t4R-11"));
		setprop("instrumentation/display-screens/t4R-11", getprop("instrumentation/display-screens/t4R-12"));
		setprop("instrumentation/display-screens/t4R-12", getprop("instrumentation/display-screens/t4R-13"));
		setprop("instrumentation/display-screens/t4R-13", getprop("instrumentation/display-screens/t4R-14"));
		setprop("instrumentation/display-screens/t4R-14", getprop("instrumentation/display-screens/t4R-15"));
		setprop("instrumentation/display-screens/t4R-15", getprop("instrumentation/display-screens/t4R-16"));
		setprop("instrumentation/display-screens/t4R-16", getprop("instrumentation/display-screens/t4R-17"));
		setprop("instrumentation/display-screens/t4R-17", getprop("instrumentation/display-screens/t4R-18"));
		setprop("instrumentation/display-screens/t4R-18", getprop("instrumentation/display-screens/t4R-19"));
		setprop("instrumentation/display-screens/t4R-19", getprop("instrumentation/display-screens/t4R-20"));
		setprop("instrumentation/display-screens/t4R-20", getprop("instrumentation/display-screens/t4R-21"));
		setprop("instrumentation/display-screens/t4R-21", getprop("instrumentation/display-screens/t4R-22"));
		setprop("instrumentation/display-screens/t4R-22", getprop("instrumentation/display-screens/t4R-23"));
		setprop("instrumentation/display-screens/t4R-23", getprop("instrumentation/display-screens/t4R-24"));
		setprop("instrumentation/display-screens/t4R-24", newtext);
	}
}

# ======== screen-5R ================================================
var screen_5R_on = 0;
var scroll_5R = func (newtext) {
	if (screen_5R_on) {
		setprop("instrumentation/display-screens/t5R-2", getprop("instrumentation/display-screens/t5R-3"));
		setprop("instrumentation/display-screens/t5R-3", getprop("instrumentation/display-screens/t5R-4"));
		setprop("instrumentation/display-screens/t5R-4", getprop("instrumentation/display-screens/t5R-5"));
		setprop("instrumentation/display-screens/t5R-5", getprop("instrumentation/display-screens/t5R-6"));
		setprop("instrumentation/display-screens/t5R-6", getprop("instrumentation/display-screens/t5R-7"));
		setprop("instrumentation/display-screens/t5R-7", getprop("instrumentation/display-screens/t5R-8"));
		setprop("instrumentation/display-screens/t5R-8", getprop("instrumentation/display-screens/t5R-9"));
		setprop("instrumentation/display-screens/t5R-9", getprop("instrumentation/display-screens/t5R-10"));
		setprop("instrumentation/display-screens/t5R-10", getprop("instrumentation/display-screens/t5R-11"));
		setprop("instrumentation/display-screens/t5R-11", getprop("instrumentation/display-screens/t5R-12"));
		setprop("instrumentation/display-screens/t5R-12", getprop("instrumentation/display-screens/t5R-13"));
		setprop("instrumentation/display-screens/t5R-13", getprop("instrumentation/display-screens/t5R-14"));
		setprop("instrumentation/display-screens/t5R-14", getprop("instrumentation/display-screens/t5R-15"));
		setprop("instrumentation/display-screens/t5R-15", getprop("instrumentation/display-screens/t5R-16"));
		setprop("instrumentation/display-screens/t5R-16", getprop("instrumentation/display-screens/t5R-17"));
		setprop("instrumentation/display-screens/t5R-17", getprop("instrumentation/display-screens/t5R-18"));
		setprop("instrumentation/display-screens/t5R-18", getprop("instrumentation/display-screens/t5R-19"));
		setprop("instrumentation/display-screens/t5R-19", getprop("instrumentation/display-screens/t5R-20"));
		setprop("instrumentation/display-screens/t5R-20", getprop("instrumentation/display-screens/t5R-21"));
		setprop("instrumentation/display-screens/t5R-21", getprop("instrumentation/display-screens/t5R-22"));
		setprop("instrumentation/display-screens/t5R-22", getprop("instrumentation/display-screens/t5R-23"));
		setprop("instrumentation/display-screens/t5R-23", getprop("instrumentation/display-screens/t5R-24"));
		setprop("instrumentation/display-screens/t5R-24", newtext);
	}
}

var init = func {
	setlistener("instrumentation/digital/altitude-mode", func(n) a_mode = n.getValue(), 1);

	setlistener("instrumentation/display-screens/refresh-2L-sec", func(n) refresh_2L = n.getValue());

	setlistener("instrumentation/tracking/ai-size", func {
		cleanup_2L();
	},,0);

	setlistener("instrumentation/tracking/mp-size", func {
		cleanup_2L();
	},,0);

	setlistener("instrumentation/tracking/enabled", func(n) {
		tracking_on = n.getValue();
		if (tracking_on) {
			setprop("instrumentation/display-screens/enabled-2L", 1);
			settimer(func { ac_loop(ac_loop_id += 1) }, 0);
		} else {
			setprop("instrumentation/display-screens/enabled-2L", 0);
		}
	}, 1);

	ap2c_L = setlistener("instrumentation/tracking/ap2-callsign", func(n) {
		ap2 = airportinfo(n.getValue());
		if (ap2 != nil) {
			ap2_name_Node.setValue(ap2.name);
			ap2_lat_Node.setValue(ap2.lat);
			ap2_lon_Node.setValue(ap2.lon);
			ap2_elev_Node.setValue(ap2.elevation);
			ap2_update();
		}
	}, 1);

	setlistener("instrumentation/display-screens/enabled-2L", func(n) {
		if (n.getValue()) {
			setprop("instrumentation/display-screens/t2L-2", "Callsign                 Distance   Altitude   Bearing");
		}
	}, 1);

	setlistener("sim/signals/reinit", func {
		apt = nil;
		aiac = nil;
	});

	setlistener("instrumentation/display-screens/enabled-3R", func(n) {
		screen_3R_on = n.getValue();
		setprop("instrumentation/display-screens/t3R-1", "position/ground-elev  geo-ground    difference   contact-altitude");
	}, 1);

	setlistener("engines/engine/speed-max-mps", func(n) {
		var max = n.getValue();
		var v_mode = getprop("instrumentation/digital/velocity-mode");
		var txt8 = sprintf("%5.0f",mps_2_conv[v_mode]*max) ~ mps_conv_units[v_mode];
		setprop("instrumentation/display-screens/t1L-8", txt8);
	},, 0);

	setlistener("sim/model/bluebird/systems/wave2-request", func(n) {
		var w2 = n.getValue();
		if (w2) {
			setprop("instrumentation/display-screens/t1L-9", "MAXIMUM");
		} else {
			setprop("instrumentation/display-screens/t1L-9", "STANDARD");
		}
	},, 0);

	setlistener("instrumentation/display-screens/enabled-2L", func(n) {
		screen_2L_on = n.getValue();
		setprop("instrumentation/display-screens/t2L-1", "Nearby Aircraft");
		if (!screen_2L_on) {
			setprop("instrumentation/tracking/ai-size", -1);
			setprop("instrumentation/tracking/ai1-distance-m", -999999);
			if (getprop("instrumentation/ai-vor/mode") == 1) {
				setprop("instrumentation/ai-vor/mode", 0);
			}
		}
	}, 1, 0);

	setlistener("instrumentation/display-screens/enabled-2R", func(n) {
		screen_2R_on = n.getValue();
		setprop("instrumentation/display-screens/t2R-1", "Altitude AGL");
	}, 1, 0);

	setlistener("instrumentation/display-screens/enabled-3L", func(n) { screen_3L_on = n.getValue() },, 0);

	setlistener("sim/model/bluebird/damage/hits-counter", func(n) {
		if (screen_3L_damage_level < 1) {
			if (n.getValue() > 0) {
				setprop("instrumentation/display-screens/enabled-3L", 1);
				setprop("instrumentation/display-screens/t3L-1", "-------- MINOR DAMAGE --------");
			}
		}
	},, 0);

	setlistener("sim/model/bluebird/damage/major-counter", func(n) {
		screen_3L_damage_level = n.getValue();
		if (screen_3L_damage_level > 0) {
			setprop("instrumentation/display-screens/enabled-3L", 1);
			setprop("instrumentation/display-screens/t3L-1", "------ STRUCTURAL DAMAGE ------");
		}
	},, 0);

	setlistener("instrumentation/display-screens/enabled-4R", func(n) {
		screen_4R_on = n.getValue();
		setprop("instrumentation/display-screens/t4R-1", "pitch-deg   roll-deg  hover-add   hover-ft");
	}, 1, 0);

	setlistener("instrumentation/display-screens/enabled-5R", func(n) {
		screen_5R_on = n.getValue();
		setprop("instrumentation/display-screens/t5R-1", "rise-thrust  reactor-level  down");
	}, 1, 0);
}
settimer(init,0);

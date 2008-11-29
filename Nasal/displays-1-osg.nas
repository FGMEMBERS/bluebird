# ===== text screen functions for version 1.0 and OSG =====
# ===== for Bluebird Explorer Hovercraft version 7.6 =====

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

# ======== nearest airport for screen-1R ============================
var apt_loop = func {
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
			setprop("instrumentation/display-screens/t1R-15", apt.id ~ "  HELIPORT");
		} else {
			setprop("instrumentation/display-screens/t1R-15", apt.id);
		}
		setprop("instrumentation/display-screens/t1R-16", apt.name);
		setprop("instrumentation/display-screens/t1R-17a", apt.lat);
		setprop("instrumentation/display-screens/t1R-17b", apt.lon);
	}
	settimer(apt_loop, 5);
}

var apt_update = func {
	if (apt != nil) {
		var a_mode = getprop("instrumentation/digital/altitude-mode");
		var c_lat = getprop("position/latitude-deg");
		var y = apt.lat - c_lat;
		var x = apt.lon - getprop("position/longitude-deg");
		var xy_hyp = math.sqrt((x * x) + (y * y));
		var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
		head = normheading(head);
		if (c_lat > apt.lat) {
			head = normheading(180 - head);
		}
		setprop("instrumentation/display-screens/t1R-18a", head);
		var range = walk.distFromCraft(apt.lat, apt.lon) * m_2_conv[a_mode];
		var txt18 = sprintf("%7.2f",range) ~ m_conv_units[a_mode];
		setprop("instrumentation/display-screens/t1R-18b", txt18);
	}
	settimer(apt_update,0.25);
}

# ======== nearest aircraft for screen-2L ============================
var screen_2L_on = 0;
setlistener("instrumentation/display-screens/enabled-2L", func {
	screen_2L_on = getprop("instrumentation/display-screens/enabled-2L");
	setprop("instrumentation/display-screens/t2L-1", "Callsign                 Distance   Altitude   Bearing");
	if (screen_2L_on) {
		settimer(ac_loop,0);
	}
}, 1);

var ac_loop = func {
	var ac = props.globals.getNode("ai/models").getChildren("aircraft");
	if ((aiac == nil) or (screen_2L_on)) {
		aiac = ac;	# copy of node vector
		ac_update();
	}
	if (screen_2L_on) {
		settimer(ac_loop, 1);
	}
}

var ac_update = func {
	var ac = props.globals.getNode("ai/models").getChildren("aircraft");
	if (ac != nil) {
		var s = size(ac);
		var ac_list = [];
		var c_lat = getprop("position/latitude-deg");
		var c_lon = getprop("position/longitude-deg");
		var c_head_deg = getprop("orientation/heading-deg");
		var a_mode = getprop("instrumentation/digital/altitude-mode");
		for (var i = 0 ; i < s ; i += 1) {
			if(ac[i].getNode("callsign") != nil) {
				var b = ac[i].getNode("position");
				var alat = b.getNode("latitude-deg").getValue();
				var alon = b.getNode("longitude-deg").getValue();
				var y = alat - c_lat;
				var x = alon - c_lon;
				var ah1 = sin(y * 0.5);
				var ah2 = sin(x * 0.5);
				var adist_m = 2.0 * ERAD * asin(math.sqrt(ah1 * ah1 + cos(alat) * cos(c_lat) * ah2 * ah2));
				var xy_hyp = math.sqrt((x * x) + (y * y));
				var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
				var bearing = normbearing(head, c_head_deg);
				if (c_lat > alat) {
					bearing = normbearing(180 - head, c_head_deg);
				}
				append(ac_list, { callsign:ac[i].getNode("callsign").getValue(), index:i, dist_m:adist_m, alt_ft:b.getNode("altitude-ft").getValue(), bearing:bearing});
			}
		}
		var sac = sort(ac_list, func(a,b) { return (a.dist_m > b.dist_m) });
		var s = size(sac);
		for (var i = 0 ; (i < s and i <= 14) ; i += 1) {
			setprop("instrumentation/display-screens/t2L-" ~ (i+2) ~ "a", sac[i].callsign);
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
			var txt2h = sprintf(" %3.0f",sac[i].bearing);
			setprop("instrumentation/display-screens/t2L-" ~ (i+2) ~ "b", txt2d ~ txt2a);
			setprop("instrumentation/display-screens/t2L-" ~ (i+2) ~ "c", txt2h);
		}
	}
}

# ======== combined aircraft and airport section ===================
var apt = nil;
var aiac = nil;
settimer(apt_loop,2);

setlistener("sim/signals/reinit", func {
	apt = nil;
	aiac = nil;
});

settimer(apt_update,3);
#settimer(ac_update,3);

# ======== screen-3R ==============================================
var screen_3R_on = 0;
setlistener("instrumentation/display-screens/enabled-3R", func {
	screen_3R_on = getprop("instrumentation/display-screens/enabled-3R");
	setprop("instrumentation/display-screens/t3R-1", "position/ground-elev  geo-ground    difference   contact-altitude");
}, 1);

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

# ===== text screen functions for version 1.0 and OSG =====
# ===== for Bluebird Explorer Hovercraft version 7.0 =====

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

var apt = nil;
settimer(apt_loop,2);

setlistener("sim/signals/reinit", func {
	apt = nil;
});

var asin = func(y) { math.atan2(y, math.sqrt(1-y*y)) }  # radians
var dist_2_conv = [0.000621371192, 0.001];
var dist_conv_units = [" MI"," KM"];
var apt_update = func {
	if (apt != nil) {
		var a_mode = getprop("instrumentation/digital/altitude-mode");
		var c_lat = getprop("position/latitude-deg");
		var y = apt.lat - c_lat;
		var x = apt.lon - getprop("position/longitude-deg");
		var xy_hyp = math.sqrt((x * x) + (y * y));
		var head = (xy_hyp == 0 ? 0 : asin(x / xy_hyp)) * 180 / math.pi;
		while (head >= 360.0) {
			head -= 360.0;
		}
		while (head < 0.0) {
			head += 360.0;
		}
		if (c_lat > apt.lat) {
			head = 180 - head;
			while (head < 0.0) {
				head += 360.0;
			}
		}
		setprop("instrumentation/display-screens/t1R-18a", head);
		var range = walk.distFromCraft(apt.lat, apt.lon) * dist_2_conv[a_mode];
		var txt18 = sprintf("%7.2f",range) ~ dist_conv_units[a_mode];
		setprop("instrumentation/display-screens/t1R-18b", txt18);
	}
	settimer(apt_update,0.25);
}
settimer(apt_update,3);

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

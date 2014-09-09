# ===== Bluebird Explorer Hovercraft  version 10.4 =====

var sin = func(a) { math.sin(a * math.pi / 180.0) }	# degrees
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var asin = func(y) { math.atan2(y, math.sqrt(1-y*y)) }	# radians

# instrumentation ===================================================
var c_heading_deg = props.globals.getNode("orientation/heading-deg", 1);
var vor_callsign = props.globals.getNode("instrumentation/ai-vor/callsign", 1);
var vor_heading = props.globals.getNode("instrumentation/ai-vor/heading-deg", 1);
var vor_elevation = props.globals.getNode("instrumentation/ai-vor/elevation-deg", 1);
var ai_size = props.globals.getNode("instrumentation/tracking/ai-size", 1);
var ai_heading_offset = props.globals.getNode("instrumentation/tracking/ai1-heading-offset-deg", 1);
var ai_dist = props.globals.getNode("instrumentation/tracking/ai1-distance-m", 1);
var ai_elev = props.globals.getNode("instrumentation/tracking/ai1-elevation-deg", 1);
var mp_size = props.globals.getNode("instrumentation/tracking/mp-size", 1);
var mp_heading_offset = props.globals.getNode("instrumentation/tracking/mp1-heading-offset-deg", 1);
var mp_dist = props.globals.getNode("instrumentation/tracking/mp1-distance-m", 1);
var mp_elev = props.globals.getNode("instrumentation/tracking/mp1-elevation-deg", 1);
var ap1_heading_offset = props.globals.getNode("instrumentation/tracking/ap1-heading-offset-deg", 1);
var ap1_dist = props.globals.getNode("instrumentation/tracking/ap1-distance-m", 1);
var ap1_elev = props.globals.getNode("instrumentation/tracking/ap1-elevation-deg", 1);
var ap2_callsign = props.globals.getNode("instrumentation/tracking/ap2-callsign", 1);
var ap2_heading_offset = props.globals.getNode("instrumentation/tracking/ap2-heading-offset-deg", 1);
var ap2_dist = props.globals.getNode("instrumentation/tracking/ap2-distance-m", 1);
var ap2_elev = props.globals.getNode("instrumentation/tracking/ap2-elevation-deg", 1);
var vor_dist = props.globals.getNode("instrumentation/ai-vor/distance-m", 1);

var power_switch = 1;
var ap1_to_factor = 1;
var ai1_to_factor = 1;
var mp1_to_factor = 1;
var ap2_to_factor = 1;
var ap2 = nil;

var ap2_set = 0;
var normheading = func (a) {
	while (a >= 360)
		a -= 360;
	while (a < 0)
		a += 360;
	return a;
}

var normbearing = func (a,c) {
	var h = a - c;
	while (h >= 180)
		h -= 360;
	while (h < -180)
		h += 360;
	return h;
}

var ap2_update = func {
	var c_lat = getprop("position/latitude-deg");
	var c_lon = getprop("position/longitude-deg");
	var c_head_deg = getprop("orientation/heading-deg");
	if (ap2 != nil) {
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
		var new_ho = 0;
		if (power_switch) {
			new_ho = 360 - bearing - c_head_deg;
		}
		setprop("instrumentation/tracking/ap2-heading-offset-deg", new_ho);
		setprop("instrumentation/tracking/ap2-to-factor", displayScreens.bearing_to_factor(bearing));
		var range = walk.distFromCraft(ap2.lat, ap2.lon);
		setprop("instrumentation/tracking/ap2-distance-m", range);
		var c_alt = getprop("position/altitude-ft");
		var e_m = ap2.elevation - (c_alt * 0.3048);
		var xy_hyp = math.sqrt((e_m * e_m) + (range * range));
		var ze = (xy_hyp == 0 ? 0 : asin(e_m / xy_hyp)) * 180 / math.pi;
		ap2_elev.setValue(ze);
	} else {
		setprop("instrumentation/tracking/ap2-heading-offset-deg", 0);
		setprop("instrumentation/tracking/ap2-distance-m", -999999);
	}
}

var vor_mode = 0;

ai_vor_update = func {
	if (power_switch) {
		if (vor_mode == 1) {
			if (ai_size.getValue() > 0) {
				vor_heading.setValue(ai_heading_offset.getValue() + c_heading_deg.getValue());
			} else {
				setprop("instrumentation/ai-vor/mode", 2);
			}
		}
		if (vor_mode == 2) {
			if (mp_size.getValue() > 0) {
				vor_heading.setValue(mp_heading_offset.getValue() + c_heading_deg.getValue());
			} else {
				setprop("instrumentation/ai-vor/mode", 3);
			}
		}
		if (vor_mode == 3) {
			ap2_update();
			vor_heading.setValue(ap2_heading_offset.getValue() + c_heading_deg.getValue());
		}
		if (vor_mode == 0) {
			vor_heading.setValue(ap1_heading_offset.getValue() + c_heading_deg.getValue());
		}
	} else {
		vor_heading.setValue(0.0);
	}
}

var ai_vor_loop_id = 0;
ai_vor_loop = func (id) {
	id == ai_vor_loop_id or return;
	ai_vor_update();
	settimer(func { ai_vor_loop(ai_vor_loop_id += 1) }, 0.2);
}
settimer(func { ai_vor_loop(ai_vor_loop_id += 1) }, 2.2);

var ap1c_L = nil;
var ap1d_L = nil;
var ap1e_L = nil;
var ai1c_L = nil;
var ai1d_L = nil;
var ai1e_L = nil;
var mp1c_L = nil;
var mp1d_L = nil;
var mp1e_L = nil;
var ap2c_L = nil;
var ap2d_L = nil;
var ap2e_L = nil;
ap2_callsign.setValue(getprop("sim/startup/options/airport"));

var id = "";
var node = props.globals.getNode("/sim/gui/dialogs/airports", 1);
if (node.getNode("list") == nil)
	node.getNode("list", 1).setValue("");

node = node.getNode("list");

var listbox_apply = func {
	id = pop(split(" ", node.getValue()));
	id = substr(id, 1, size(id) - 2);  # strip parentheses
	setprop("instrumentation/tracking/ap2-callsign", id);
}

var apply = func {
	id = string.uc(pop(split(" ", node.getValue())));
	setprop("instrumentation/tracking/ap2-callsign", id);
}

var ap2_dialog = nil;
var ap_dialog = func {
	name = "Airport Callsign";
	if (ap2_dialog != nil) {
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
		ap2_dialog = nil;
		return;
	}

	ap2_dialog = gui.Widget.new();
	ap2_dialog.set("layout", "vbox");
	ap2_dialog.set("name", name);
	var x = getprop("/sim/startup/xsize") / 2;
	ap2_dialog.set("x", x);
	ap2_dialog.set("y", "/sim/startup/ysize");

	var titlebar = ap2_dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Select Airport for Homing and Tracking");
	titlebar.addChild("empty").set("stretch", 1);

	var w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 1);
	w.set("keynum", 27);
	w.set("border", 1);
	w.prop().getNode("binding[0]/command", 1).setValue("nasal");
	w.prop().getNode("binding[0]/script", 1).setValue("aiVORinstrument.ap2_dialog = nil");
	w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

	ap2_dialog.addChild("hrule").addChild("dummy");

	var a = ap2_dialog.addChild("airport-list");
	a.set("name", "airport-list");
	a.set("pref-width", 440);
	a.set("pref-height", 160);
	a.set("property", "/sim/gui/dialogs/airports/list");
	a.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	a.prop().getNode("binding[0]/object-name", 1).setValue("airport-list");
	a.prop().getNode("binding[1]/command", 1).setValue("nasal");
	a.prop().getNode("binding[1]/script", 1).setValue("aiVORinstrument.listbox_apply()");
	a.prop().getNode("binding[2]/command", 1).setValue("dialog-close");

	var g = ap2_dialog.addChild("group");
	g.set("layout", "hbox");
	g.addChild("empty").set("pref-width", 8);
	var content = g.addChild("input");
	content.set("name", "input");
	content.set("layout", "hbox");
	content.set("halign", "fill");
	content.set("border", 1);
	content.set("editable", 1);
	content.set("property", "/sim/gui/dialogs/airports/list");
	content.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	content.prop().getNode("binding[0]/object-name", 1).setValue("input");
	content.prop().getNode("binding[1]/command", 1).setValue("dialog-update");
	content.prop().getNode("binding[1]/object-name", 1).setValue("airport-list");

	var box = g.addChild("button");
	box.set("legend", "Search");
	box.set("label", "");
	box.set("pref-height", 18);
	box.set("border", 2);
	box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	box.prop().getNode("binding[0]/object-name", 1).setValue("input");
	box.prop().getNode("binding[1]/command", 1).setValue("dialog-update");
	box.prop().getNode("binding[1]/object-name", 1).setValue("airport-list");

	var box = g.addChild("button");
	box.set("halign", "right");
	box.set("legend", "Set");
	box.set("pref-width", 100);
	box.set("pref-height", 18);
	box.set("border", 2);
	box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
	box.prop().getNode("binding[0]/object-name", 1).setValue("input");
	box.prop().getNode("binding[1]/command", 1).setValue("nasal");
	box.prop().getNode("binding[1]/script", 1).setValue("aiVORinstrument.apply()");
	g.addChild("empty").set("pref-width", 8);

	ap2_dialog.addChild("empty").set("pref-height", "3");
	fgcommand("dialog-new", ap2_dialog.prop());
	gui.showDialog(name);
}

var init = func {
	setlistener("sim/model/bluebird/systems/power-switch", func(n) { power_switch = n.getValue() },,0);

	setlistener("instrumentation/tracking/ap1-to-factor", func(n) { ap1_to_factor = n.getValue() },,0);

	setlistener("instrumentation/tracking/ai1-to-factor", func(n) { ai1_to_factor = n.getValue() },,0);

	setlistener("instrumentation/tracking/mp1-to-factor", func(n) { mp1_to_factor = n.getValue() },,0);

	setlistener("instrumentation/tracking/ap2-to-factor", func(n) { ap2_to_factor = n.getValue() },,0);

	setlistener("instrumentation/ai-vor/mode", func(n) {
		if (vor_mode == 0) {
			removelistener(ap1c_L);
			removelistener(ap1d_L);
			removelistener(ap1e_L);
		} elsif (vor_mode == 1) {
			removelistener(ai1c_L);
			removelistener(ai1d_L);
			removelistener(ai1e_L);
		} elsif (vor_mode == 2) {
			removelistener(mp1c_L);
			removelistener(mp1d_L);
			removelistener(mp1e_L);
		} elsif (vor_mode == 3) {
			removelistener(ap2c_L);
			removelistener(ap2d_L);
			removelistener(ap2e_L);
		}
		vor_mode = n.getValue();
		if (vor_mode == 0) {
			ap1c_L = setlistener("instrumentation/tracking/ap1-callsign", func(n) vor_callsign.setValue(n.getValue()), 1);
			ap1d_L = setlistener("instrumentation/tracking/ap1-distance-m", func(n) {
				vor_dist.setValue(n.getValue() * ap1_to_factor);
			});
			ap1e_L = setlistener("instrumentation/tracking/ap1-elevation-deg", func(n) {
				vor_elevation.setValue(n.getValue());
			});
		} elsif (vor_mode == 1) {
			ai1c_L = setlistener("instrumentation/tracking/ai1-callsign", func(n) {
				vor_callsign.setValue(n.getValue());
			}, 1);
			ai1d_L = setlistener("instrumentation/tracking/ai1-distance-m", func(n) {
				vor_dist.setValue(n.getValue() * ai1_to_factor);
			});
			ai1e_L = setlistener("instrumentation/tracking/ai1-elevation-deg", func(n) {
				vor_elevation.setValue(n.getValue());
			});
		} elsif (vor_mode == 2) {
			mp1c_L = setlistener("instrumentation/tracking/mp1-callsign", func(n) {
				vor_callsign.setValue(n.getValue());
			}, 1);
			mp1d_L = setlistener("instrumentation/tracking/mp1-distance-m", func(n) {
				vor_dist.setValue(n.getValue() * mp1_to_factor);
			});
			mp1e_L = setlistener("instrumentation/tracking/mp1-elevation-deg", func(n) {
				vor_elevation.setValue(n.getValue());
			});
		} elsif (vor_mode == 3) {
			var ap2_cs = nil;
			while (ap2_cs == nil and ap2_set == 0) {
				ap_dialog();
				ap2_cs = ap2_callsign.getValue();
				ap2_set = ap2_cs;
			}
			ap2c_L = setlistener("instrumentation/tracking/ap2-callsign", func(n) {
				var ap2_cs = n.getValue();
				ap2 = airportinfo(ap2_cs);
				ap2_update();
				vor_callsign.setValue(ap2_cs);
			}, 1);
			ap2d_L = setlistener("instrumentation/tracking/ap2-distance-m", func(n) {
				vor_dist.setValue(n.getValue() * ap2_to_factor);
			});
			ap2e_L = setlistener("instrumentation/tracking/ap2-elevation-deg", func(n) {
				vor_elevation.setValue(n.getValue());
			});
		}
	},,0);

	ap1c_L = setlistener("instrumentation/tracking/ap1-callsign", func(n) {
		vor_callsign.setValue(n.getValue());
	},,0);
	ap1d_L = setlistener("instrumentation/tracking/ap1-distance-m", func(n) {
		vor_dist.setValue(n.getValue() * ap1_to_factor);
	},,0);
	ap1e_L = setlistener("instrumentation/tracking/ap1-elevation-deg", func(n) {
		vor_elevation.setValue(n.getValue());
	},,0);
}
settimer(init,0);

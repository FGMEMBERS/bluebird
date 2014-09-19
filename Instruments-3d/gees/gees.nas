# ===== Bluebird Explorer Hovercraft  version 10.9 =====

# instrumentation ===================================================
var vsi_float = props.globals.getNode("instrumentation/gees/vsi-float", 1);
var gees_string = props.globals.getNode("instrumentation/gees/gees-string", 1);
var gees_float = props.globals.getNode("instrumentation/gees/gees-float", 1);
var gees_deg = props.globals.getNode("instrumentation/gees/gees-deg", 1);
var max1_refresh_sec = getprop("instrumentation/gees/peak-refresh-sec");
var max1_digital = 0;	# only update digital every 1sec
var max2_digital = 0;
var gees_mode = 1;	# 0 = Vertical Slope Indicator, in multiples of (32 ft/sec or 10 m/sec) 
			#     or relative gees from flat and level without time factor
			# 1 = Gees updated every 50 ms
			# 2 = Peak gees over last second, updated every 1 sec
			# 3 = Max gees, holds until reset by clicking on display

setlistener("instrumentation/gees/mode", func(n) {
	gees_mode = n.getValue();
	digital_update();
},,0);

setlistener("instrumentation/gees/peak-refresh-sec", func(n) {
	max1_refresh_sec = n.getValue();
	if (max1_refresh_sec < 0.24) {	# bounds check, not Peak Hold below 1/4 sec.
		setprop("instrumentation/gees/peak-refresh-sec", 0.25);
	}
},,0);

instrumentation_update = func {
	if (getprop("sim/current-view/view-number") == 0) {
		if (gees_mode > 0) {
			var gees = gees_float.getValue();
			if (gees > max2_digital) {
				max2_digital = gees;
			}
			if (gees > max1_digital) {
				if (gees_mode >= 2 and max1_digital > -999) {
					max1_digital = gees;
					digital_update();
				} else {
					max1_digital = gees;
				}
			}
		} else {
			var gees = vsi_float.getValue();
		}
		if (abs(gees) <= 1) {
			var dd = gees * 36;
		} else {
			var dd = (math.log10(abs(gees)) * 84.757235) + 36;
			if (dd > 170) {
				dd = 170;
			}
			if (gees < 0) {
				dd = 0 - dd;
			}
		}
		gees_deg.setValue(dd);
	}
}

instrumentation_loop = func {
	instrumentation_update();
	settimer(instrumentation_loop, 0);
}

digital_update = func {
	if (getprop("sim/current-view/view-number") == 0) {
		if (gees_mode == 0) {
			gees_string.setValue("   ");
		} elsif (gees_mode == 2) {
			if (max1_digital == -999) {
				var xx = "Pk";
			} else {
				var xx = sprintf("Pk %6.1f",max1_digital);
			}
			gees_string.setValue(xx);
			max1_digital = -999;
		} elsif (gees_mode == 3) {
			if (max2_digital == -999) {
				var xx = "Max";
			} else {
				var xx = sprintf("Max%6.1f",max2_digital);
			}
			gees_string.setValue(xx);
		} else {
			var xx = sprintf("%9.1f",gees_float.getValue());
			gees_string.setValue(xx);
		}
	}
}

digital_loop = func {
	if (bluebird.power_switch) {
		digital_update();
		if (gees_mode == 2) {
			settimer(digital_loop, max1_refresh_sec);
		} elsif (gees_mode == 1) {
			settimer(digital_loop, 0.05);
		} else {
			settimer(digital_loop, 5);
		}
	} else {
		settimer(digital_loop, 5);
	}
}

tapDisplay = func {
	if (gees_mode == 3) {
		max2_digital = -999;
		digital_update();
	}
}

settimer(instrumentation_loop, 2);
settimer(digital_loop, 2.5);

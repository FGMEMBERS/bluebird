# ===== walking functions for FlightGear version 0.9.10 ===== version 2.3 =====
# ===== outside walker is not supported =====
# == customized for Bluebird Explorer Hovercraft =====

var calc_heading = func {
	var w_forward = getprop("sim/walker/key-triggers/forward");
	var w_left = getprop("sim/walker/key-triggers/slide");
	var walk_heading = -999;
	if (w_forward > 0) {
		if (w_left < 0) {
			walk_heading = 45;
		} elsif (w_left > 0) {
			walk_heading = -45;
		} else {
			walk_heading = 0;
		}
	} elsif (w_forward < 0) {
		if (w_left < 0) {
			walk_heading = 135;
		} elsif (w_left > 0) {
			walk_heading = -135;
		} else {
			walk_heading = 180;
		}
	} else {
		if (w_left < 0) {
			walk_heading = 90;
		} elsif (w_left > 0) {
			walk_heading = -90;
		}
	}
	if (walk_heading != -999) {
		var c_view = getprop("sim/current-view/view-number");
		if (c_view == 0) {
			# inside aircraft
			bluebird.walk_about_cabin(0.1, walk_heading);
		}
	}
}

setlistener("sim/walker/key-triggers/forward", func {
	calc_heading();
}, 0);

setlistener("sim/walker/key-triggers/slide", func {
	calc_heading();
}, 0);

var get_out = func (loc) {
	gui.popupTip("Can not go outside. Please upgrade to FlightGear version 1.0 or newer.");

}

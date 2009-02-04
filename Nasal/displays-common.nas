# ===== common base for text screen functions        =====
# ===== for Bluebird Explorer Hovercraft version 8.9 =====

var tracking_on = 0;
# ======== update details for screen-1L =============================
var mps_2_conv = [1, 1.9438445, 2.2369363, 3.6, 1.9438445];
var mps_conv_units = [" MPS"," KNOTS"," MPH"," KMPH"," KNOTS"];

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

var init_common = func {
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
settimer(init_common,0);

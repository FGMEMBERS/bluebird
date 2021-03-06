# ===== Bluebird Explorer Hovercraft  version 13.7 =====

# instrumentation ===================================================
var lat_whole = props.globals.getNode("instrumentation/digital/lat-whole", 1);
var lat_fraction = props.globals.getNode("instrumentation/digital/lat-fraction", 1);
var lon_whole = props.globals.getNode("instrumentation/digital/lon-whole", 1);
var lon_fraction = props.globals.getNode("instrumentation/digital/lon-fraction", 1);
var heading_whole = props.globals.getNode("instrumentation/digital/heading-whole", 1);
var pitch_whole = props.globals.getNode("instrumentation/digital/pitch-whole", 1);
var pitch_neg = props.globals.getNode("instrumentation/digital/pitch-neg", 1);
var vel_whole = props.globals.getNode("instrumentation/digital/velocity-whole", 1);
var alt_whole = props.globals.getNode("instrumentation/digital/altitude-whole", 1);
var agl_whole = props.globals.getNode("instrumentation/digital/agl-whole", 1);
var throttle_whole = props.globals.getNode("instrumentation/digital/throttle-whole", 1);
var head_mode = props.globals.getNode("instrumentation/digital/heading-mode", 1);
var vel_mode = props.globals.getNode("instrumentation/digital/velocity-mode", 1);
var gps_mode = props.globals.getNode("sim/lon-lat-format", 1);
var altitude_mode = props.globals.getNode("instrumentation/digital/altitude-mode", 1);
var knots_2_conv = [0.514444444, 1.0, 1.150779448, 1.852, 1.524];
	# MPS , Kts , MPH , KmPH , MACH
var clock_node = props.globals.getNode("instrumentation/digital/clock-mode", 1);
var clock_mode = 0;
var clock_hh = props.globals.getNode("instrumentation/digital/clock-hh", 1);
var clock_mm = props.globals.getNode("instrumentation/digital/clock-mm", 1);
var clock_ss = props.globals.getNode("instrumentation/digital/clock-ss", 1);

instrumentation_update = func {
	if (getprop("sim/current-view/view-number") == 0) {
		#===== gps digital module ===================================
		var gpsmode = gps_mode.getValue();
		var xx = abs(getprop("position/latitude-deg"));
		lat_whole.setValue(int(xx));
		if (gpsmode == 2) {
			var gm = (xx - int(xx)) * 60;
			var gs = (gm - int(gm)) * 60;
			var ii = (int(gm) * 100) + int(gs);
			lat_fraction.setValue(ii);
		} elsif (gpsmode == 1) {
			var gm = (xx - int(xx)) * 6000;
			lat_fraction.setValue(int(gm));
		} else {
			var gm = (xx - int(xx)) * 10000;
			lat_fraction.setValue(int(gm));
		}
		var xx = abs(getprop("position/longitude-deg"));
		lon_whole.setValue(int(xx));
		if (gpsmode == 2) {
			var gm = (xx - int(xx)) * 60;
			var gs = (gm - int(gm)) * 60;
			var ii = (int(gm) * 100) + int(gs);
			lon_fraction.setValue(ii);
		} elsif (gpsmode == 1) {
			var gm = (xx - int(xx)) * 6000;
			lon_fraction.setValue(int(gm));
		} else {
			var gm = (xx - int(xx)) * 10000;
			lon_fraction.setValue(int(gm));
		}
		#===== heading digital module ===============================
		var hm = head_mode.getValue();
		var xx = getprop("orientation/heading-deg") * 10.0;
		if (xx < -0.5) { xx += 3600.0; }
		if (xx > 3599.5) { xx -= 3600.0; }
		heading_whole.setValue(int(xx + 0.5));
		var xx = getprop("orientation/groundsloped-pitch-deg") * 10.0;
		if (hm == 1) {
			if (xx < -0.5) { 
				xx += 3600.5; 
			} else {
				xx += 0.5;
			}
			pitch_whole.setValue(int(xx));
		} else {
			pitch_whole.setValue(int(abs(xx) + 0.5));
		}
		if (xx < 0) {
			pitch_neg.setValue(-1);
		} else {
			pitch_neg.setValue(1);
		}
		#===== velocity digital module ==============================
		var vm = vel_mode.getValue();
		var xx = int(abs(getprop("velocities/airspeed-kt")));		# Kts
		var ii = xx * knots_2_conv[vm];
		# calculating mach at fixed pressure and temperature for 755mph
		# actual speed of sound at: 60F = 760mph , -80F at 65,000ft = 650mph , at 100,000ft = 480mph
		vel_whole.setValue(ii);
		#===== altitude digital module ==============================
		var am = altitude_mode.getValue();
		var xx = abs(getprop("position/altitude-ft"));
		if (xx < 0) {
			var xx = 0;
		}
		if (am == 1) {
			var ii = xx * 0.3048;
			alt_whole.setValue(int(ii));
		} elsif (am == 2) {
			var ii = xx * 0.0003048;
			alt_whole.setValue(int(ii));
		} elsif (am == 3) {
			var ii = xx * 0.000189393939;
			alt_whole.setValue(int(ii));
		} else {
			alt_whole.setValue(int(xx));
		}
			# unique property location for ufo model, 
			# change to /position/altitude-agl-ft for yasim or jsbsim
		var xx = abs(getprop("sim/model/bluebird/position/altitude-agl-ft"));
		if (xx < 0) {
			xx = 0;
		}
		if (am == 1) {
			var ii = xx * 0.3048;
			agl_whole.setValue(int(ii));
		} elsif (am == 2) {
			var ii = xx * 0.0003048;
			agl_whole.setValue(int(ii));
		} elsif (am == 3) {
			var ii = xx * 0.000189393939;
			agl_whole.setValue(int(ii));
		} else {
			agl_whole.setValue(int(xx));
		}
		#===== throttle digital module ==============================
		var xx = abs(getprop("controls/engines/engine/throttle")) * 100;
		throttle_whole.setValue(int(xx));
		#===== clock digital module =================================
		if (clock_mode) {
			var cu = getprop("sim/time/local-day-seconds");
			var xh = int(cu / 3600);
			var xm = int((cu - (xh * 3600)) / 60);
			var xs = cu - (xh* 3600) - (xm * 60);
		} else {
			var xh = getprop("sim/time/utc/hour");
			var xm = getprop("sim/time/utc/minute");
			var xs = getprop("sim/time/utc/second");
		}
		clock_hh.setValue(xh);
		clock_mm.setValue(xm);
		clock_ss.setValue(xs);
		#===================================
	}
}

instrumentation_loop = func {
	instrumentation_update();
	settimer(instrumentation_loop, 0);
}
settimer(instrumentation_loop, 2);

setlistener("instrumentation/digital/clock-mode", func(n) { clock_mode = n.getValue(); }, 1);

# 1L autopilot instruments ======================================

var m_ap1_lock = props.globals.getNode("autopilot/locks/heading", 1);
var m_ap2_lock = props.globals.getNode("autopilot/locks/altitude", 1);
var map1lock = 0;	# 1=true-heading 2=dg-heading
var map2lock = 0;	# 1=altitude-hold 2=agl-hold 3=vertical-speed-hold
var mapstate = 0;	# master autopilot state
var ap_state = props.globals.getNode("instrumentation/digital/ap-state", 1);
var m_ap1_mag = props.globals.getNode("autopilot/settings/heading-bug-deg", 1);
var m_ap1_true = props.globals.getNode("autopilot/settings/true-heading-deg", 1);
var m_ap2_ft = props.globals.getNode("autopilot/settings/target-altitude-ft", 1);
var m_ap2_fpm = props.globals.getNode("autopilot/settings/vertical-speed-fpm", 1);
var m_ap2_agl = props.globals.getNode("autopilot/settings/target-agl-ft", 1);
var ap1_mode = props.globals.getNode("instrumentation/digital/ap1-mode", 1);
var ap2_mode = props.globals.getNode("instrumentation/digital/ap2-mode", 1);
var ap1_entry = props.globals.getNode("instrumentation/digital/ap1-entry-deg", 1);
var ap2_entry = props.globals.getNode("instrumentation/digital/ap2-entry", 1);
var ap2_entry_ft = props.globals.getNode("instrumentation/digital/ap2-entry-ft", 1);
var ap2_entry_fpm = props.globals.getNode("instrumentation/digital/ap2-entry-fpm", 1);
var ap2_entry_agl = props.globals.getNode("instrumentation/digital/ap2-entry-agl-ft", 1);
var ap1_whole = props.globals.getNode("instrumentation/digital/ap1-whole", 1);
var ap2_whole = props.globals.getNode("instrumentation/digital/ap2-whole", 1);
var ap1_user_input = 0;	# did the pilot press the button
var ap2_user_input = 0;
var ap3_user_input = 0;
var map3lock = 0;
var ap3_chasing = 0;
var m_ap3_lock = props.globals.getNode("instrumentation/digital/ap3-lock-state", 1);
var m_ap3_kt = props.globals.getNode("autopilot/settings/target-speed-kt", 1);
var m_ap3_pct = props.globals.getNode("instrumentation/digital/ap3-target-throttle", 1);
var ap3_mode = props.globals.getNode("instrumentation/digital/ap3-mode", 1);
var ap3_entry = props.globals.getNode("instrumentation/digital/ap3-entry", 1);
var ap3_entry_kt = 0;
var ap3_entry_pct = 0;	# store as integer x10000 100.00
var ap3_whole = props.globals.getNode("instrumentation/digital/ap3-whole", 1);
var max_mps = props.globals.getNode("engines/engine/speed-max-mps", 1);
var max_changing = 0;	# unrestricted adjusting throttle when changing wave1 power level (gearing)
var last_max_mps = max_mps.getValue();
var now_max_mps = last_max_mps;
var loopid3 = 0;
var roc_thr = 0.0025;

autopilot_update = func (n) {
	#===== autopilot heading select digital module ==============
	var ii = ap1_entry.getValue();
	var ap1mode = ap1_mode.getValue();
	var ap2mode = ap2_mode.getValue();
	var jj = ap2_entry.getValue();
	var kk = ap3_entry.getValue();
	if (map1lock > 0) {
		var mi = ii;
		if (map1lock == 1) {
			if (ap1mode != 1) {
				if (ap1_user_input == 0) {
					ap1_mode.setValue(1);
					ap1mode=1;
					mi = -1;
				}
			} else {
				var ii = m_ap1_true.getValue();
			}
			var mi = m_ap1_true.getValue();
		} elsif (map1lock == 2) {
			if (ap1mode != 2) {
				if (ap1_user_input == 0) {
					ap1_mode.setValue(2);
					ap1mode=2;
					mi = -1;
				}
			} else {
				var ii = m_ap1_mag.getValue();
			}
			var mi = m_ap1_mag.getValue();
		}
		if (ii != mi) {
			ap1_entry.setValue(ii);
		}
	}
	if (ii == nil) {
		ii = 0;
	}
	if (ii < -0.05) { ii += 360.0; }
	if (ii > 360.05) { ii -= 360.0; }
	ap1_whole.setValue(int(ii + 0.5));
	# detect change in dialog entry
	if (ap1_user_input == 0) {
		var dfi = -1;
		var snm = -1;
		if (map1lock == 1) {
			var dfi = m_ap1_true.getValue();
			snm = 1;
		} elsif (map1lock == 2) {
			var dfi = m_ap1_mag.getValue();
			snm = 2;
		} elsif (map1lock > 0) {
			snm = 0;
		} else {
			if (ap1mode == 1) {
				var dfi = m_ap1_true.getValue();
			} elsif (ap1mode == 2) {
				var dfi = m_ap1_mag.getValue();
			}
		}
		if (snm >= 0 and snm != ap1mode) {
			ap1_mode.setValue(snm);
			ap1mode = snm;
		}
		if (dfi != nil and dfi != -1 and dfi != ii) {
			ap1_entry.setValue(dfi);
			ap1_whole.setValue(int(dfi + 0.5));
		}
	}
	#===== autopilot altitude hold digital module ===============
	ii = ap2_entry.getValue();
	if (ii == nil) {
		ii = 0;
	}
	if (ap2mode != nil and ap2mode != 0) {
		if (ap2mode == 1) {
			ap2_entry_ft.setValue(ii);
		} elsif (ap2mode == 2) {
			ap2_entry_agl.setValue(ii);
		} elsif (ap2mode == 3) {
			ap2_entry_fpm.setValue(ii);
		}
	}
	ap2_whole.setValue(int(abs(ii) + 0.5));
	# detect change in dialog entry
	if (ap2_user_input == 0) {
		var dfi = -1;
		var snm = -1;
		if (map2lock == 1) {
			var dfi = m_ap2_ft.getValue();
			snm = 1;
		} elsif (map2lock == 2) {
			var dfi = m_ap2_agl.getValue();
			snm = 2;
		} elsif (map2lock == 3) {
			var dfi = m_ap2_fpm.getValue();
			snm = 3;
		} elsif (map2lock > 0) {
			snm = 0;
		} else {
			if (ap2mode == 1) {
				var dfi = m_ap2_ft.getValue();
			} elsif (ap2mode == 2) {
				var dfi = m_ap2_agl.getValue();
			} elsif (ap2mode == 3) {
				var dfi = m_ap2_fpm.getValue();
			}
		}
		if (dfi == nil) {
			dfi = 0;
		}
		if (snm >= 0 and snm != ap2mode) {
			ap2_mode.setValue(snm);
			ap2mode = snm;
		}
		if (dfi != -1 and dfi != ii) {
			ap2_entry.setValue(dfi);
			ap2_whole.setValue(int(dfi + 0.5));
		}
	}
	#===== autopilot throttle hold digital module ===============
	kk = ap3_entry.getValue();
	if (kk == nil) {
		kk = 0;
	}
	var ap3mode = ap3_mode.getValue();
	if (ap3mode != nil and ap3mode != 0) {
		if (ap3mode == 1) {
			ap3_entry_kt = kk;
			ap3_whole.setValue(int(abs(kk) + 0.5));
		} elsif (ap3mode == 2) {
			if (kk > 10000) {
				kk = 10000;
			} elsif (kk < 0) {
				kk = 0;
			}
			ap3_entry_pct = kk;
			ap3_whole.setValue(int(abs(kk) + 0.5));
		}
	} else {
		ap3_whole.setValue(int(abs(kk) + 0.5));
	}
	if (ap3_user_input == 0) {
		var dfi = -1;
		var snm = -1;
		if (map3lock == 1) {
			var dfi = m_ap3_kt.getValue();
			snm = 1;
		} elsif (map3lock != 0) {
			snm = 0;
		} else {
			if (ap3mode == 1) {
				var dfi = m_ap3_kt.getValue();
			} elsif (ap3mode == 2) {
				var dfi = m_ap3_pct.getValue();
			}
		}
		if (snm >= 0 and snm != ap3mode) {
			ap3mode = snm;
			ap3_mode.setValue(snm);
		}
		if (dfi == nil) {
			dfi = -1;
		}
		if (dfi != -1 and dfi != kk) {
			ap3_entry.setValue(dfi);
			if (ap3mode == 2) {
				ap3_whole.setValue(int((dfi*100) + 0.5));
			} else {
				ap3_whole.setValue(int(dfi + 0.5));
			}
		}
	}
}

setlistener("autopilot/settings/heading-bug-deg", func(n) {
	autopilot_update(3);
}, 1);

setlistener("autopilot/settings/true-heading-deg", func(n) {
	autopilot_update(4);
}, 1);

setlistener("autopilot/settings/target-altitude-ft", func(n) {
	autopilot_update(5);
}, 1);

setlistener("autopilot/settings/vertical-speed-fpm", func(n) {
	autopilot_update(6);
}, 1);

setlistener("autopilot/settings/target-agl-ft", func(n) {
	autopilot_update(7);
}, 1);

setlistener("instrumentation/digital/ap1-mode", func(n) {
	if (map1lock > 0) {
		ap1_user_input = 2;
		toggle_ap1cmd(1);
		ap1_user_input = 0;
	}
}, 1);

var refresh_mapstate = func {
	if (map1lock or map2lock or map3lock) {
		if (mapstate != 1) {
			ap_state.setValue(1);
			mapstate = 1;
		}
	} else {
		if (mapstate != 0) {
			ap_state.setValue(0);
			mapstate = 0;
		}
	}
}

setlistener("autopilot/locks/heading", func(n) {	# m_ap1_lock
	var map1string = n.getValue();
	if (map1string != nil and map1string != "") {
		if (map1string == "true-heading-hold") {
			map1lock = 1;
		} elsif (map1string == "dg-heading-hold") {
			map1lock = 2;
		} else {
			map1lock = 9;
		}
	} else {
		map1lock = 0;
	}
	autopilot_update(1);
	refresh_mapstate();
}, 1);

setlistener("autopilot/locks/altitude", func(n) {
	var map2string = n.getValue();
	if (map2string != nil and map2string != "") {
		if (map2string == "altitude-hold") {
			map2lock = 1;
		} elsif (map2string == "agl-hold") {
			map2lock = 2;
		} elsif (map2string == "vertical-speed-hold") {
			map2lock = 3;
		}
	} else {
		map2lock = 0;
	}
	autopilot_update(2);
	refresh_mapstate();
}, 1);

setlistener("instrumentation/digital/ap3-lock-state", func(n) {
	map3lock = n.getValue();
	refresh_mapstate();
}, 1);

setlistener("instrumentation/digital/ap1-entry-deg", func(n) {
	var ii = n.getValue();
	if (map1lock == 2) {
		setprop("autopilot/settings/heading-bug-deg", ii);
	} elsif (map1lock == 1) {
		setprop("autopilot/settings/true-heading-deg", ii);
	}
	if (ap1_user_input) {
		if (ap1_mode.getValue() == 1) {
			m_ap1_true.setValue(ii);
		} elsif (ap1_mode.getValue() == 2) {
			m_ap1_mag.setValue(ii);
		}
		ap1_user_input = 0;
	}
}, 1);

toggle_ap1cmd = func(n) {
	if (n == -1) {
		if (map1lock > 0 and abs(getprop("orientation/roll-deg")) > 0.02) {
			setprop("sim/model/bluebird/systems/alarm3-state", 1);
		}
		m_ap1_lock.setValue("");
	} elsif (map1lock == 0 or n > 0) {
		var ap1mode = ap1_mode.getValue();
		var ap1entry = ap1_entry.getValue();
		if (ap1entry == nil) { ap1entry = 0; }
		if (ap1mode == 1) {
			m_ap1_true.setValue(ap1entry);
			m_ap1_lock.setValue("true-heading-hold");
		} elsif (ap1mode == 2) {
			m_ap1_mag.setValue(ap1entry);
			m_ap1_lock.setValue("dg-heading-hold");
		}
	} else {
		if (map1lock > 0 and abs(getprop("orientation/roll-deg")) > 0.02) {
			setprop("sim/model/bluebird/systems/alarm3-state", 1);
		}
		m_ap1_lock.setValue("");
	}
}

init_ap2 = func (ia) {
	var ii = getprop("position/altitude-ft");
	if (ia != nil and ia > 0) {
		ii = ia;
	}
	return (int((abs(ii) * 0.01) + 0.5) * 100);
}

setlistener("instrumentation/digital/ap2-entry", func(n) {
	var ii = n.getValue();
	if (map2lock == 1) {
		setprop("autopilot/settings/target-altitude-ft", ii);
	} elsif (map2lock == 2) {
		setprop("autopilot/settings/target-agl-ft", ii);
	} elsif (map2lock == 3) {
		setprop("autopilot/settings/vertical-speed-fpm", ii);
	}
	if (ap2_user_input) {
		if (ap2_mode.getValue() == 1) {
			m_ap2_ft.setValue(ii);
		} elsif (ap2_mode.getValue() == 2) {
			m_ap2_agl.setValue(ii);
		} elsif (ap2_mode.getValue() == 3) {
			m_ap2_fpm.setValue(ii);
		}
		ap2_user_input = 0;
	}
}, 1);

press_ap2mode = func (n) {
	var ap2mode = ap2_mode.getValue();
	var mb = ap2mode;
	var ii = ap2_entry.getValue();
	var savenew = 0;
	if (ap2mode == 0) {
		ap2mode = 1;
		var dfi = m_ap2_ft.getValue();
		ii = init_ap2(dfi);
	} else {
		ap2mode = ((ap2mode + 1) > 3 ? 1 : (ap2mode + 1));
		if (map2lock > 0) {
			# built-in AP does not work right if this is changed while AP CMD is on. Pressing mode disconnects the autopilot.
			toggle_ap2cmd(-1);
		}
		var dfi = -1;
		if (ap2mode == 1) {
			dfi = m_ap2_ft.getValue();
		} elsif (ap2mode == 2) {
			dfi = m_ap2_agl.getValue();
		} elsif (ap2mode == 3) {
			dfi = m_ap2_fpm.getValue();
		}
		if (dfi == nil) {
			dfi = 0;
		}
		if (dfi > 0 and dfi != ii) {
			savenew = 1;
			ii=dfi;
		}
		if (ap2mode == 1) {
			ii = ap2_entry_ft.getValue();
		} elsif (ap2mode == 2) {
			ii = ap2_entry_agl.getValue();
			if (ii == 0) {
				ii = int((abs(getprop("sim/model/bluebird/position/altitude-agl-ft")) * 0.01) + 0.5) * 100;
			}
		} elsif (ap2mode == 3) {
			ii = ap2_entry_fpm.getValue();
		}
	}
	ap2_user_input = 2;
	ap2_mode.setValue(ap2mode);
	ap2_entry.setValue(ii);
	if (savenew) {
		if (ap2mode == 1) {
			ap2_entry_ft.setValue(ii);
		} elsif (ap2mode == 2) {
			ap2_entry_agl.setValue(ii);
		} elsif (ap2mode == 3) {
			ap2_entry_fpm.setValue(ii);
		}
	}
	ap2_user_input = 0;
}

toggle_ap2cmd = func(n) {
	if (n == -1) {
		if (map2lock > 0 and (abs(getprop("orientation/pitch-deg")) > 0.02 or abs(getprop("controls/flight/elevator-trim")) > 0.02)) {
			setprop("sim/model/bluebird/systems/alarm3-state", 1);
		}
		m_ap2_lock.setValue("");
		setprop("controls/flight/elevator-trim", 0);
	} elsif (map2lock == 0 or n > 0) {
		var ap2mode = ap2_mode.getValue();
		var ap2entry = ap2_entry.getValue();
		if (ap2entry == nil) { ap2entry = 0; }
		if (ap2mode == 1) {
			m_ap2_ft.setValue(ap2entry);
			m_ap2_lock.setValue("altitude-hold");
		} elsif (ap2mode == 2) {
			m_ap2_agl.setValue(ap2entry);
			m_ap2_lock.setValue("agl-hold");
		} elsif (ap2mode == 3) {
			m_ap2_fpm.setValue(ap2entry);
			m_ap2_lock.setValue("vertical-speed-hold");
		}
	} else {
		m_ap2_lock.setValue("");
		setprop("controls/flight/elevator-trim", 0);
	}
}

#====== AP3 ==========
setlistener("autopilot/locks/throttle", func(n) {
	autopilot_update(8);
}, 1);

setlistener("autopilot/settings/target-speed-kt", func(n) {
	autopilot_update(9);
}, 1);

setlistener("instrumentation/digital/ap3-roc", func(n) {
	roc_thr = n.getValue();
}, 1);

setlistener("sim/model/bluebird/systems/wave1-request", func(n) {
	if (n.getValue()) {
		setprop("instrumentation/digital/ap3-roc", 0.0025);
	} else {
		setprop("instrumentation/digital/ap3-roc", 0.0002);
	}
}, 1);

init_ap3 = func (ia) {
	var ii = getprop("velocities/airspeed-kt");
	if (ia != nil and ia > 0 and ia < 100000) {
		ii = ia;
	}
	return int(abs(ii) + 0.5);
}

ap3_speed_update = func {
	var ap3mode = ap3_mode.getValue();
	var maxmps = max_mps.getValue();
	var maxkts = maxmps / knots_2_conv[0];
	var fromthrottle = getprop("controls/engines/engine/throttle");
	var fromkts = getprop("velocities/airspeed-kt");
	var tokts = fromkts;
	var tothrottle = fromthrottle;
	if (ap3mode == 1) {
		tokts = ap3_entry.getValue();
		tothrottle = ((tokts + 0.01) / maxkts);
	} elsif (ap3mode == 2) {
		tothrottle = ap3_entry.getValue();
		tothrottle = tothrottle * 0.0001;
		tokts = tothrottle * maxkts;
	}
	var gomore = 0;
	var nextthrottle = 0.0001;
	if (now_max_mps != last_max_mps) {
		max_changing = 1;
	} else {
		max_changing = 0;
	}
	last_max_mps = now_max_mps;
	if (max_changing) {
		nextthrottle = tothrottle;
	} else {
		if (fromkts > tokts) {
			nextthrottle = fromthrottle - roc_thr;
		} else {
			nextthrottle = fromthrottle + roc_thr;
		}
		if (nextthrottle > 1.0) {
			nextthrottle = 1.0;
			tothrottle = 1.0;
		} elsif (nextthrottle < 0.0) {
			nextthrottle = 0.0;
			tothrottle = 0.0;
		} elsif (abs(tothrottle - nextthrottle) <= roc_thr) {
			nextthrottle = tothrottle;
		} else {
			gomore = 1;
		}
	}
	setprop("controls/engines/engine/throttle", nextthrottle);
	if (gomore > 0) {
		ap3_chasing = 1;
	} else {
		ap3_chasing = 0;
	}
	return gomore;
}

ap3_loop = func {
	if (map3lock > 0) {
		if (ap3_speed_update() > 0) {
			loopid3 += 1;
			settimer(ap3_loop, 0.05);
		}
	}
}

setlistener("engines/engine/speed-max-mps", func(n) {
	var now_max_mps = max_mps.getValue();
	loopid3 += 1;
	settimer(ap3_loop, 0.05);
}, 1);

setlistener("instrumentation/digital/ap3-entry", func(n) {
	var ii = n.getValue();
	var ap3mode = ap3_mode.getValue();
	if (map3lock == 1) {
		if (ap3mode == 1) {
			setprop("autopilot/settings/target-speed-kt", ii);
		} elsif (ap3mode == 2) {
			if (ii > 10000) {
				ii = 10000;
			} elsif (ii < 0) {
				ii = 0;
			}
			n.setValue(ii);
			setprop("instrumentation/digital/target-speed-throttle", ii);
		}
		loopid3 += 1;
		settimer(ap3_loop, 0.05);
	}
	if (ap3_user_input) {
		if (ap3mode == 1) {
			m_ap3_kt.setValue(ii);
		} elsif (ap3mode == 2) {
			m_ap3_pct.setValue(ii);
		}
	}
	autopilot_update(10);
	ap3_user_input = 0;
}, 1);

press_ap3mode = func (n) {
	var ap3mode = ap3_mode.getValue();
	var ii = ap3_entry.getValue();
	var savenew = 0;
	if (ap3mode == 0) {
		ap3mode = 1;
		var dfi = m_ap3_kt.getValue();
		ii = init_ap3(dfi);
	} else {
		ap3mode = ((ap3mode + 1) > 2 ? 0 : (ap3mode + 1));
		if (map3lock != 0) {
			toggle_ap3cmd(-1);
		}
		var dfi = -1;
		if (ap3mode == 1) {
			var dfi = m_ap3_kt.getValue();
		} elsif (ap3mode == 2) {
			var dfi = m_ap3_pct.getValue();
		}
		if (dfi == nil) {
			dfi = 0;
		}
		if (dfi > 0 and dfi != ii) {
			savenew = 1;
			ii=dfi;
		}
		if (ap3mode == 1) {
			ii = ap3_entry_kt;
		} elsif (ap3mode == 2) {
			ii = ap3_entry_pct;
			if (ii == 0) {
				ii = (getprop("controls/engines/engine/throttle") * 10000);
			}
		}
	}
	ap3_user_input = 2;
	ap3_mode.setValue(ap3mode);
	ap3_entry.setValue(ii);
	if (savenew) {
		if (ap3mode == 1) {
			ap3_entry_kt = ii;
		} elsif (ap3mode == 2) {
			ap3_entry_pct = ii;
		}
	}
	ap3_user_input = 0;
}

toggle_ap3cmd = func(n) {
	if (n == -1) {
		if (map3lock > 0 and ap3_chasing) {
			setprop("sim/model/bluebird/systems/alarm3-state", 1);
		}
		m_ap3_lock.setValue(0);
	} elsif ((map3lock == 0) or n > 0) {
		var ap3mode = ap3_mode.getValue();
		if (ap3mode == 1) {
			var tokts = ap3_entry.getValue();
			if (tokts == nil) { tokts = 0; }
			m_ap3_kt.setValue(tokts);
		} elsif (ap3mode == 2) {
			var topct = ap3_entry.getValue();
			if (topct == nil) { topct = (getprop("controls/engines/engine/throttle") * 10000); }
			m_ap3_pct.setValue(topct);
		}
		if (ap3mode > 0) {
			m_ap3_lock.setValue(1);
			loopid3 += 1;
			settimer(ap3_loop, 0.05);
		}
	} else {
		if (map3lock > 0 and ap3_chasing) {
			setprop("sim/model/bluebird/systems/alarm3-state", 1);
		}
		m_ap3_lock.setValue(0);
	}
}

setlistener("autopilot/locks/speed", func(n) {	#intercept system autopilot and replace it with our own.
	n.setValue("");
	toggle_ap3cmd(1);
}, 1);

turn_ap1knob = func (v) {
	var ap1mode = ap1_mode.getValue();
	if (ap1mode == 0) {
		ap1_mode.setValue(1);
		var ii = getprop("orientation/heading-deg");
		var oi = int(ii + 0.5);
	} else {
		var ii = ap1_entry.getValue();
		if (map1lock > 0) {
			var ni = ii + (v<0?-1:1);
		} else {
			var ni = ii + v;
		}
		var oi = (ni<0?ni+360:(ni>360?ni-360:ni));
	}
	ap1_user_input = 1;
	ap1_entry.setValue(oi);
}

turn_ap2knob = func (v) {
	var ap2mode = ap2_mode.getValue();
	var ii = ap2_entry.getValue();
	if (ap2mode == 0) {
		ap2_mode.setValue(1);
		var ni = init_ap2(-1);
	} elsif (ap2mode == 1) {
		var ni = ii + v;
		ni = int(ni * 0.01) * 100;
	} elsif (ap2mode == 3) {
		var ni = ii + (v * 0.1);
	} else {
		var ni = ii + v;
	}
	ap2_user_input = 1;
	ap2_entry.setValue(ni);
}

turn_ap3knob = func (v) {
	var ap3mode = ap3_mode.getValue();
	var ii = ap3_entry.getValue();
	if (ap3mode == 0) {
		ap3_mode.setValue(1);
		var ni = init_ap3(-1);
	} elsif (ap3mode == 2) {
		var ni = int(abs(ii) + (v * 10));
	} else {
		var ni = int(abs(ii) + v);
	}
	ap3_user_input = 1;
	ap3_entry.setValue(ni);
}

# 2C coms equipment =============================================

var comm1a_whole = props.globals.getNode("instrumentation/digital/comm1a-whole", 1);
var comm1s_whole = props.globals.getNode("instrumentation/digital/comm1s-whole", 1);
var comm2a_whole = props.globals.getNode("instrumentation/digital/comm2a-whole", 1);
var comm2s_whole = props.globals.getNode("instrumentation/digital/comm2s-whole", 1);
var comm1_mhz_state = props.globals.getNode("instrumentation/digital/comm1-mhz-state", 1);
var comm2_mhz_state = props.globals.getNode("instrumentation/digital/comm2-mhz-state", 1);
var m_comm1a = props.globals.getNode("instrumentation/comm/frequencies/selected-mhz", 1);
var m_comm1s = props.globals.getNode("instrumentation/comm/frequencies/standby-mhz", 1);
var m_comm2a = props.globals.getNode("instrumentation/comm[1]/frequencies/selected-mhz", 1);
var m_comm2s = props.globals.getNode("instrumentation/comm[1]/frequencies/standby-mhz", 1);
var comm1_volume_Node = props.globals.getNode("instrumentation/comm[0]/volume", 1);
var comm2_volume_Node = props.globals.getNode("instrumentation/comm[1]/volume", 1);
var msp_Node = props.globals.getNode("sim/model/bluebird/systems/power-switch", 1);
var comm1_p_Node = props.globals.getNode("instrumentation/comm[0]/power-btn", 1);
var comm2_p_Node = props.globals.getNode("instrumentation/comm[1]/power-btn", 1);
var mfi = 0;	# master freq in
var wfi = 0;	# whole freq before update, define temp vars just once
var wfn = 0;	# new whole freq
var currTimer1 = 0;
var currTimer2 = 0;
var currTimer3 = 0;
var currTimer4 = 0;
var comvol = [0.6 , 0.6];
var commute = [0, 0];

tune_freq = func (sf, add, d) {
	var f2 = int(((sf + add) * 1000) + 0.2);
	if (f2 > 137975) {
		f2 = 118000;
	} elsif (f2 < 118000) {
		f2 = 137975;
	}
	if (d) {
		return (f2 * 0.001);
	} else {
		return f2;
	}
}

coms_update = func (r) {
	if (r == 1) {	#===== comm1 active digital module ===========================
		mfi = m_comm1a.getValue();
		if (mfi == nil) {
			wfn = 0;
		} else {
			wfn = tune_freq(mfi, 0.00, 0);
			wfi = comm1a_whole.getValue();
			if (wfi != nil) {
				if (wfi != wfn) {
					m_comm1a.setValue(mfi);
				}
			}
		}
		comm1a_whole.setValue(int(wfn));
	}
	if (r == 2) {	#===== comm1 standby digital module ===========================
		mfi = m_comm1s.getValue();
		if (mfi == nil) {
			wfn = 0;
		} else {
			wfn = tune_freq(mfi, 0.00, 0);
			wfi = comm1s_whole.getValue();
			if (wfi != nil) {
				if (wfi != wfn) {
					m_comm1s.setValue(mfi);
				}
			}
		}
		comm1s_whole.setValue(int(wfn));
	}
	if (r == 3) {	#===== comm2 active digital module ===========================
		mfi = m_comm2a.getValue();
		if (mfi == nil) {
			wfn = 0;
		} else {
			wfn = tune_freq(mfi, 0.00, 0);
			wfi = comm2a_whole.getValue();
			if (wfi != nil) {
				if (wfi != wfn) {
					m_comm2a.setValue(mfi);
				}
			}
		}
		comm2a_whole.setValue(int(wfn));
	}
	if (r == 4) {	#===== comm2 standby digital module ===========================
		mfi = m_comm2s.getValue();
		if (mfi == nil) {
			wfn = 0;
		} else {
			wfn = tune_freq(mfi, 0.00, 0);
			wfi = comm2s_whole.getValue();
			if (wfi != nil) {
				if (wfi != wfn) {
					m_comm2s.setValue(mfi);
				}
			}
		}
		comm2s_whole.setValue(int(wfn));
	}
}

setlistener("instrumentation/comm/frequencies/selected-mhz", func(n) {
	coms_update(1);
}, 1);

setlistener("instrumentation/comm/frequencies/standby-mhz", func(n) {
	coms_update(2);
}, 1);

setlistener("instrumentation/comm[1]/frequencies/selected-mhz", func(n) {
	coms_update(3);
}, 1);

setlistener("instrumentation/comm[1]/frequencies/standby-mhz", func(n) {
	coms_update(4);
}, 1);

coms_lighting_update = func {
	var power_switch = msp_Node.getValue();
	var comm1_power_switch = comm1_p_Node.getValue();
	var comm2_power_switch = comm2_p_Node.getValue();
	if (power_switch and comm1_power_switch) {
		setprop("sim/model/bluebird/lighting/buttons/comm1-backlit", 1);
	} else {
		setprop("sim/model/bluebird/lighting/buttons/comm1-backlit", 0);
	}
	if (power_switch and comm2_power_switch) {
		setprop("sim/model/bluebird/lighting/buttons/comm2-backlit", 1);
	} else {
		setprop("sim/model/bluebird/lighting/buttons/comm2-backlit", 0);
	}
}

setlistener("sim/model/bluebird/systems/power-switch", func {
	coms_lighting_update();
}, 1);

setlistener("instrumentation/comm[0]/power-btn", func {
	coms_lighting_update();
}, 1);

setlistener("instrumentation/comm[1]/power-btn", func {
	coms_lighting_update();
}, 1);

turn_comm1aknob = func (v) {
	var cf = m_comm1a.getValue();
	if (cf != nil) {
		m_comm1a.setValue(tune_freq(cf,v,1));
	}
	comm1_mhz_state.setValue(1);
	currTimer1 = currTimer1 + 2.0;
	var thisTimer1 = currTimer1;
	settimer(func { if(currTimer1 == thisTimer1) { comm1_mhz_state.setValue(0); } }, 2.0, 1);
}

turn_comm1sknob = func (v) {
	var cf = m_comm1s.getValue();
	if (cf != nil) {
		m_comm1s.setValue(tune_freq(cf,v,1));
	}
	comm1_mhz_state.setValue(1);
	currTimer2 = currTimer2 + 2.0;
	var thisTimer2 = currTimer2;
	settimer(func { if(currTimer2 == thisTimer2) { comm1_mhz_state.setValue(0); } }, 2.0, 1);
}

turn_comm2aknob = func (v) {
	var cf = m_comm2a.getValue();
	if (cf != nil) {
		m_comm2a.setValue(tune_freq(cf,v,1));
	}
	comm2_mhz_state.setValue(1);
	currTimer3 = currTimer3 + 2.0;
	var thisTimer3 = currTimer3;
	settimer(func { if(currTimer3 == thisTimer3) { comm2_mhz_state.setValue(0); } }, 2.0, 1);
}

turn_comm2sknob = func (v) {
	var cf = m_comm2s.getValue();
	if (cf != nil) {
		m_comm2s.setValue(tune_freq(cf,v,1));
	}
	comm2_mhz_state.setValue(1);
	currTimer4 = currTimer4 + 2.0;
	var thisTimer4 = currTimer4;
	settimer(func { if(currTimer4 == thisTimer4) { comm2_mhz_state.setValue(0); } }, 2.0, 1);
}

press_com_swap = func (cc) {
	if (cc == 1) {
		var ftmp = m_comm1a.getValue();
		m_comm1a.setValue(m_comm1s.getValue());
		m_comm1s.setValue(ftmp);
		comm1_mhz_state.setValue(1);
		currTimer1 = currTimer1 + 3.0;
		var thisTimer1 = currTimer1;
		settimer(func { if(currTimer1 == thisTimer1) { comm1_mhz_state.setValue(0); } }, 3.0, 1);
	} elsif (cc == 2) {
		var ftmp = m_comm2a.getValue();
		m_comm2a.setValue(m_comm2s.getValue());
		m_comm2s.setValue(ftmp);
		comm2_mhz_state.setValue(1);
		currTimer3 = currTimer3 + 3.0;
		var thisTimer3 = currTimer3;
		settimer(func { if(currTimer3 == thisTimer3) { comm2_mhz_state.setValue(0); } }, 3.0, 1);
	}
}

press_com_mute = func(rn) {
	var cv = 0;
	if (rn == 0) {
		cv = comm1_volume_Node.getValue();
	} else {
		cv = comm2_volume_Node.getValue();
	}
	if (commute[rn] == 0) {
		comvol[rn] = cv;
		if (rn == 0) {
			comm1_volume_Node.setValue(0);
		} else {
			comm2_volume_Node.setValue(0);
		}
		commute[rn] = 1;
	} else {
		if (rn == 0) {
			comm1_volume_Node.setValue(comvol[rn]);
		} else {
			comm2_volume_Node.setValue(comvol[rn]);
		}
		commute[rn] = 0;
	}
}

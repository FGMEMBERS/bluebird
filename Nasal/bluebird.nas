# ===== Bluebird Explorer Hovercraft  version 8.9 for FlightGear v1.0 (PLIB and OSG) =====

# strobes -----------------------------------------------------------
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
var strobe_light = aircraft.light.new("sim/model/bluebird/lighting/strobe1", [0.1, 0.2, 0.1, 1.4], strobe_switch);
strobe_light.interval = 0.1;
strobe_light.switch( 1 );

# beacons -----------------------------------------------------------
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/bluebird/lighting/beacon1", [0.25, 1.55], beacon_switch);

# interior lighting -------------------------------------------------
var alert_switch_Node = props.globals.getNode("controls/lighting/alert", 1);
aircraft.light.new("sim/model/bluebird/lighting/alert1", [2.0, 0.75], alert_switch_Node);
# /sim/model/bluebird/lighting/alert1/state is destination, alert_level drifts to chase alert_state

# Hull and fuselage colors and livery ====================================
aircraft.livery.init("Aircraft/bluebird/Models/Liveries");
aircraft.livery.select(getprop("sim/model/livery/name"));

var doorProximityVolume = func (current_view, door,x,y) {
	if (current_view) {	# outside view
		if (current_view == view.indexof("Walk View")) {
			var distToDoor_m = walk.distFromCraft(getprop("sim/walker/latitude-deg"),getprop("sim/walker/longitude-deg")) - 10;
			if (distToDoor_m < 0) {
				distToDoor_m = 0;
			}
			if (door >=2 and door <= 4) {
				distToDoor_m = distToDoor_m * 3;
			}
		} else {
			if (door >=2 and door <=4) {
				return 0.1;
			} else {
				return 0.5;
			}
		}
	} else {
		var a = (x - door_coord_x_m[door]);
		var b = (y - door_coord_y_m[door]);
		var distToDoor_m = math.sqrt(a * a + b * b);
	}
	if (distToDoor_m > 50) {
		return 0;
	} elsif (distToDoor_m > 25) {
		return (50 - distToDoor_m) / 250;
	} elsif (distToDoor_m > 10) {
		return (0.1 + ((25 - distToDoor_m) / 60));
	} else {
		return (0.35 + ((10 - distToDoor_m) / 15.3846));
	}
}

var ignite = func {
	var desc = getprop("sim/description");
	if (substr(desc, size(desc) - 3, 3) != "1.0") {
		var lat_deg = getprop("position/latitude-deg");
		var lon_deg = getprop("position/longitude-deg");
		var alt_ft = ground_elevation_ft.getValue();
		wildfire.ignite(geo.Coord.new().set_latlon(lat_deg,lon_deg,alt_ft), 1);
	}
}

#==========================================================================
#                 === initial calls at startup ===
 setlistener("sim/signals/fdm-initialized", func {

 update_main();  # starts continuous loop
 settimer(interior_lighting_loop, 0.25);
 settimer(interior_lighting_update, 0.5);
 settimer(nav_light_loop, 0.5);
 if (getprop("sim/ai-traffic/enabled") or getprop("sim/multiplay/rxport")) {
 	setprop("instrumentation/tracking/enabled", 1);
 }

 var t = getprop("/sim/description");
 print (t);
 var v = getprop("/sim/aircraft-version");
 print ("  version ",v,"  release date 2009.Feb.03  by Stewart Andreason");
});

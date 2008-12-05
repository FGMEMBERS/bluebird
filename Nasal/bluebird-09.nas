# ===== Bluebird Explorer Hovercraft  version 8.1 for FlightGear v0.9.10 ======

# strobes -----------------------------------------------------------
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
var strobe_light = aircraft.light.new("sim/model/bluebird/lighting/strobe1", 0.1, 1.4, strobe_switch);
strobe_light.interval = 0.1;
strobe_light.switch( 1 );

# beacons -----------------------------------------------------------
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/bluebird/lighting/beacon1", 0.25, 1.25, beacon_switch);

# interior lighting -------------------------------------------------
var alert_switch_Node = props.globals.getNode("controls/lighting/alert", 1);
aircraft.light.new("sim/model/bluebird/lighting/alert1", 2.0, 0.75, alert_switch_Node);

var doorProximityVolume = func (current_view, door,x,y) {
	return 1.0;
}

#==========================================================================
#                 === initial calls at startup ===
update_main();  # starts continuous loop
settimer(interior_lighting_loop, 0.25);
settimer(interior_lighting_update, 0.5);
settimer(nav_light_loop, 0.5);

var t = getprop("/sim/description");
print (t);
print ("  version 8.3  release date 2008.Dec.05  by Stewart Andreason");

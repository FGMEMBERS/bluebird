# ===== Bluebird Explorer Hovercraft  version 6.1 for FlightGear v1.0 (PLIB and OSG) =====

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
aircraft.livery.init("Aircraft/bluebird/Models/Liveries",
	"sim/model/livery/variant");
aircraft.livery.select(getprop("sim/model/livery/variant"));

#==========================================================================
#                 === initial calls at startup ===
 setlistener("sim/signals/fdm-initialized", func {

 update_main();  # starts continuous loop
 settimer(interior_lighting_loop, 0.25);
 settimer(interior_lighting_update, 0.5);
 settimer(nav_light_loop, 0.5);

 print ("Bluebird Explorer Hovercraft  by Stewart Andreason");
 print ("  version 6.4  release date 2008.May.20  for FlightGear 1.0 and OSG");
});

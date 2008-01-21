# ===== Bluebird Explorer Hover Flyer  version 5.0 for FlightGear v1.0  =====

# Add second popupTip to avoid being overwritten by primary joystick messages ===
var tipArg2 = props.Node.new({ "dialog-name" : "PopTip2" });
var currTimer2 = 0;
var popupTip2 = func {
  var delay2 = if(size(arg) > 1) {arg[1]} else {1.5};
  var tmpl2 = { name : "PopTip2", modal : 0, layout : "hbox",
           y: gui.screenHProp.getValue() - 110,
           text : { label : arg[0], padding : 6 } };

  fgcommand("dialog-close", tipArg2);
  fgcommand("dialog-new", props.Node.new(tmpl2));
  fgcommand("dialog-show", tipArg2);

  currTimer2 = currTimer2 + 1.5;
  var thisTimer2 = currTimer2;

    # Final argument is a flag to use "real" time, not simulated time
  settimer(func { if(currTimer2 == thisTimer2) { fgcommand("dialog-close", tipArg2); } }, 1.5, 1);
}

#==========================================================================
#             === define global nodes and constants ===

# define damage variables -------------------------------------------
  # significant damage occurs above 50 impacts, each exceeding 600 fps per clock cycle
  # changing this number also requires changing <value> and <ind> in both xml files.
var destruction_threshold = 50;

# view nodes and offsets --------------------------------------------
var zNoseNode = props.globals.getNode("sim/view/config/y-offset-m", 1);
var xViewNode = props.globals.getNode("sim/current-view/z-offset-m", 1);
var yViewNode = props.globals.getNode("sim/current-view/x-offset-m", 1);
var hViewNode = props.globals.getNode("sim/current-view/heading-offset-deg", 1);
var vertical_offset = 0.5830;  
  # keep shadow off ground at expense of keeping wheels and gear
  # at ground level. Also adjust bluebird.xml line# 9564 with negative
  # of change. Default offset in model = 0.483 feet for gear on ground
  # or 0.583 feet to match with shadow at offset of -0.1 meters.

# strobes -----------------------------------------------------------
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/bluebird/lighting/strobe1", [0.1, 1.4], strobe_switch);

# beacons -----------------------------------------------------------
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/bluebird/lighting/beacon1", [0.25, 1.25], beacon_switch);

# nav lights --------------------------------------------------------
var nav_lights_state = props.globals.getNode("sim/model/bluebird/lighting/nav-lights-state", 1);
var nav_light_switch = props.globals.getNode("sim/model/bluebird/lighting/nav-light-switch", 1);

# landing lights ----------------------------------------------------
var landing_light_switch = props.globals.getNode("sim/model/bluebird/lighting/landing-lights", 1);

# doors -------------------------------------------------------------
var doors = [];
var doortiming = [3, 3, 1, 1, 2, 9];  # different timing for different size doors
var door0_pos = props.globals.getNode("sim/model/bluebird/doors/door[0]/position-norm", 1);
var door1_pos = props.globals.getNode("sim/model/bluebird/doors/door[1]/position-norm", 1);
var door5_pos = props.globals.getNode("sim/model/bluebird/doors/door[5]/position-norm", 1);
  # adjusted positions are a workaround for gear up modes, so that doors do not
  #  dig into the ground. Would be better if interpolation could be combined
  #  with max or other property modifier.
var door0_adjpos = props.globals.getNode("sim/model/bluebird/doors/door[0]/position-adj", 1);
var door1_adjpos = props.globals.getNode("sim/model/bluebird/doors/door[1]/position-adj", 1);
var door5_adjpos = props.globals.getNode("sim/model/bluebird/doors/door[5]/position-adj", 1);

# engines glow and main systems -------------------------------------
  # /sim/model/bluebird/lighting/power-glow from fusion reactor under hull cover,
  #   visible only when engine cover is off
  # engine refers to countergrav or hover-fans (your choice), aka fusion reactor
  # /sim/model/bluebird/lighting/engine-glow is a combination of engine sounds
  # counter-grav provides hover capability (exclusively under 100 kts)
  # wave-drive propulsion is based on quantum particle wave physics
  # using the nacelles to create a wave guide.
  # stage 1 covers all forward flight modes up to 3900 kts.
  # stage 2 "increases energy flow" so that orbital velocity can be attained

# movement and position ---------------------------------------------
var airspeed_kt_Node = props.globals.getNode("velocities/airspeed-kt", 1);
var abs_airspeed_Node = props.globals.getNode("velocities/abs-airspeed-kt", 1);

# maximum speed for ufo model at 100% throttle ----------------------
var maxspeed = props.globals.getNode("engines/engine/speed-max-mps", 1);
var speed_mps = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000];
var limit = [1, 5, 6, 7, 2, 5, 6, 11];
var current = props.globals.getNode("engines/engine/speed-max-powerlevel", 1);

# VTOL counter-grav -------------------------------------------------
# ---  expect joystick hat to provide best VTOL control ----
var joystick_elevator = props.globals.getNode("input/joysticks/js/axis[1]/binding/setting", 1);

# ground detection and adjustment -----------------------------------
var altitude_ft_Node = props.globals.getNode("position/altitude-ft", 1);
var ground_elevation_ft = props.globals.getNode("position/ground-elev-ft", 1);
var pitch_deg = props.globals.getNode("orientation/pitch-deg", 1);
var roll_deg = props.globals.getNode("orientation/roll-deg", 1);
var roll_control = props.globals.getNode("controls/flight/aileron", 1);
var pitch_control = props.globals.getNode("controls/flight/elevator", 1);

# interior lighting and emissions -----------------------------------
# surface# color/location SEE LINE# 1043 for location of calculations
#  0       Overhead lights
#  1       Blue        Rug/Floor
#  2       Grey80      Light fixture housing
#  3       Grey60      Buttons
#  4       Grey45      Lower walls and covers
#  5       Grey36      Panel surfaces
#  6       Grey14      Door seals
#  7       Tan         Chairs
#  8       Brown       Rear hatch non-skid flooring
#  9       YELLOW      Hatch Safety marker Lights
#  A       Light blue  Door panels
#  B       WHITE       Door markers/lights
#  U       Tan         Upper walls
var livery_I1R = 0.0;  # material 1 flooring (red, green, blue) calculated
var livery_I1G = 0.0;
var livery_I1B = 0.1;
var livery_I1AR = 0.0;  # ambient for UV textured flooring, livery setting
var livery_I1AG = 0.0;
var livery_I1AB = 1.0;
var livery_I1R_add = 0.5;  # factor to calculate ambient from livery
var livery_I1G_add = 0.0;  #  accounting for alert_level
var livery_I1B_add = -0.25;
var livery_I4R = 0.0;   # material 4 lower walls
var livery_I4G = 0.0;
var livery_I4B = 0.0;
var livery_IAR = 0.0;   # material A door panels
var livery_IAG = 0.0;
var livery_IAB = 0.0;
var livery_IUR = 0.0;   # material U upper walls
var livery_IUG = 0.0;
var livery_IUB = 0.0;

var alert_switch_Node = props.globals.getNode("controls/lighting/alert", 1);
aircraft.light.new("sim/model/bluebird/lighting/alert1", [2.0, 0.75], alert_switch_Node);
# /sim/model/bluebird/lighting/alert1/state is destination, alert_level drifts to chase alert_state

# Hull and fuselage colors and livery ====================================
aircraft.livery.init("Aircraft/bluebird/Models/Liveries",
  "sim/model/livery/variant");

# config file entries ===============================================
aircraft.data.add("sim/model/livery/variant");
 # save livery choice in your config file to autoload next start
aircraft.data.add("sim/model/bluebird/shadow");

#==========================================================================
#    === define nasal non-local variables at startup ===
# ------ components ------
var nacelleL_attached = 1;
var nacelleR_attached = 1;
# -------- damage --------
var damage_count = 0;
var lose_altitude = 0;   # drift or sink when damaged or power shuts down
var damage_blocker = 0;
# ------ nav lights ------
var sun_angle = 0;  # down to 0 at high noon, 2 at midnight, depending on latitude
var visibility = 16000;                # 16Km
# --------- gear ---------
var gear_looping = 0;          # keep track of gear loop, so there is only one instance per call
var gear_position = 1;
var gear_mode = 0;             # 0 = full pressure, stiff gear (or) 1 = lower, settle closer to ground
var active_gear_button = [1, 3];
var gear_height = 2.47;           # Height of gear
    # or, zero when gear down at base of model offset.
var wheel_looping = 0;         # keep track of wheel loop
var wheel_position = 0;
var gear_wheels = 0;           # 0 = not extended, land on skid plates (or) 1 = extend wheels down
var wheel_height = 0;
var contact_altitude = 0;      # the altitude at which the model touches ground (modifiers are gear and pitch/roll with hover_add)
var gear_request = 1;
# --------- doors --------
door0_adjpos.setValue(0);
door1_adjpos.setValue(0);
door5_adjpos.setValue(0);
var door0_position = 0;
var door1_position = 0;
var door5_position = 0;
var active_door = 0;
# -------- engines -------
var power_switch = 1;   # no request in-between. power goes direct to state.

var reactor_request = 1;
var reactor_level = 1;
var wave1_request = 1;
var wave1_level = 1;
var wave2_request = 0;
var wave2_level = 0;
var countergrav_request = 0;
var reactor_state = 0;  # destination level for reactor_level
var reactor_drift = 0;
var wave_state = 0;     # state = destination level
var wave_drift = 0;
# ------- movement -------
airspeed_kt_Node.setValue(0);
abs_airspeed_Node.setValue(0);
var pitch_d = 0;
var airspeed = 0;
var asas = 0;
var engines_lvl = 0;
var hover_add = 0;              # increase in altitude to keep nacelles and nose from touching ground
var hover_reset_timer = 0;      # timer so vtol movement in yoke is not jerky
var hover_target_altitude = 0;  # ground_elevation + hover_ft (not for comparing to contact point)
var h_contact_target_alt = 0;   # adjusted for contact altitude
var skid_last_value = 0;
# ------ submodel control -----
var nacelle_L_venting = 0;
var nacelle_R_venting = 0;
var venting_direction = -2;     # start disabled. -1=backward, 1=forward, 0=both
# --- ground detection ---
var init_agl = 5;     # some airports reported elevation change after movement begins
var ground_near = 1;  # instrument panel indicator lights
var ground_warning = 1;
# ----- maximum speed ----
maxspeed.setValue(500);
current.setValue(5);  # needed for engine-digital panel
var cpl = 5;          # current power level
var current_to = 5;   # distinguishes between change_maximum types. Current or To
var max_drift = 0;    # smoothen drift between maxspeed power levels
var max_lose = 0;     # loss of momentum after shutdown of engines
var max_from = 5;
var max_to = 5;
# -------- sounds --------
var sound_level = 0;
var sound_state = 0;
var alert_level = 0;
# ------- interior -------
var alert_switch = 0;
var int_switch = 1;
# specular: 1 = full reflection, 0 = no reflection from sun
var interior_lighting_base_r = 0;   # base for calculating individual colors inside
var interior_lighting_base_gb = 0;  # Red, and GreenBlue
var cockpitView = 0;
var active_nav_button = [3, 3, 1];
var active_landing_button = [3, 1, 3];
var config_dialog = nil;

var reinit_bluebird = func {   # make it possible to reset the above variables
  damage_blocker = 0;
  damage_count = 0;
  lose_altitude = 0;
  gear_looping = 0;
  gear_position = 1;
  gear_mode = 0;
  active_gear_button = [1, 3];
  gear_request = 1;
  gear_height = 2.47;
  gear_wheels = 0;
  wheel_looping = 0;
  wheel_position = 0;
  wheel_height = 0;
  contact_altitude = 0;
  door0_position = 0;
  door1_position = 0;
  door5_position = 0;
  active_door = 0;
  power_switch = 1;
  reactor_request = 1;
  reactor_level = 1;
  wave1_request = 1;
  wave1_level = 1;
  wave2_request = 0;
  wave2_level = 0;
  countergrav_request = 0;
  reactor_state = 0;
  reactor_drift = 0;
  wave_state = 0;
  wave_drift = 0;
  pitch_d = 0;
  airspeed = 0;
  asas = 0;
  engines_lvl = 0;
  hover_reset_timer = 0;
  hover_add = 0;
  hover_target_altitude = 0;
  h_contact_target_alt = 0;
  skid_last_value = 0;
  nacelle_L_venting = 0;
  nacelle_R_venting = 0;
  venting_direction = -2;
  init_agl = 5;
  cpl = 5;
  current_to = 5;
  max_drift = 0;
  max_lose = 0;
  max_from = 5;
  max_to = 5;
  sound_state = 0;
  alert_level = 0;
  int_switch = 1;
  interior_lighting_base_r = 0;
  interior_lighting_base_gb = 0;
  cockpitView = 0;
  cycle_cockpit(0);
  active_nav_button = [3, 3, 1];
  active_landing_button = [3, 1, 3];
  name = "bluebird-config";
  if (config_dialog != nil) {
    fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
    config_dialog = nil;
  }
}

 setlistener("sim/signals/reinit", func {
   reinit_bluebird();
 });

# door functions ----------------------------------------------------

var init_doors = func {
  var id_i = 0;
  foreach (var id_d; props.globals.getNode("sim/model/bluebird/doors").getChildren("door")) {
    if (doortiming[id_i] == 1) {
      append(doors, aircraft.door.new(id_d, 1.25));
    } elsif (doortiming[id_i] == 2) {
      append(doors, aircraft.door.new(id_d, 1.73));
    } elsif (doortiming[id_i] == 3) {
      append(doors, aircraft.door.new(id_d, 2.255));
    } else {
      append(doors, aircraft.door.new(id_d, 9.0));
    }
    id_i += 1;
  }
}
settimer(init_doors, 0);

var next_door = func { select_door(active_door + 1) }

var previous_door = func { select_door(active_door - 1) }

var select_door = func(sd_number) {
  active_door = sd_number;
  if (active_door < 0) {
    active_door = size(doors) - 1;
  } elsif (active_door >= size(doors)) {
    active_door = 0;
  }
  gui.popupTip("Selecting " ~ doors[active_door].node.getNode("name").getValue());
}

var door_update = func(door_number) {
  if (door_number == 0) {
    var gear_position2 = (gear_position * gear_position * 0.204304) + (gear_position * 0.0627) + 0.733;
    door0_position = door0_pos.getValue();
    if (door0_position > gear_position2) {
      door0_adjpos.setValue(gear_position2);
    } else {
      door0_adjpos.setValue(door0_position);
    }
  } elsif (door_number == 1) {
    var gear_position2 = (gear_position * gear_position * 0.204304) + (gear_position * 0.0627) + 0.733;
    door1_position = door1_pos.getValue();
    if (door1_position > gear_position2) {
      door1_adjpos.setValue(gear_position2);
    } else {
      door1_adjpos.setValue(door1_position);
    }
  } elsif (door_number == 5) {
    var gear_position2 = (gear_position * gear_position * 0.1207) + (gear_position * 0.2299) + 0.79;
    if (gear_position2 > 1.0) {
      gear_position2 = 1.0;
    }
    door5_position = door5_pos.getValue();
    if (door5_position > gear_position2) {
      door5_adjpos.setValue(gear_position2);
    } else {
      door5_adjpos.setValue(door5_position);
    }
  }
}

setlistener("sim/model/bluebird/doors/door[0]/position-norm", func {
  door_update(0);
});

setlistener("sim/model/bluebird/doors/door[1]/position-norm", func {
  door_update(1);
});

setlistener("sim/model/bluebird/doors/door[5]/position-norm", func {
  door_update(5);
});

var toggle_door = func {
  if ((active_door <= 1 and airspeed > 1000) or 
      (active_door == 5 and airspeed > 3900)) {
    if ((active_door == 0 and door0_position == 0) or
        (active_door == 1 and door1_position == 0) or
        (active_door == 5 and door5_position == 0)) {
      popupTip2("Unable to comply. Velocity too fast for safe deployment.");
      return 2;
    }
  }
  doors[active_door].toggle();
  var td_dr = doors[active_door].node.getNode("position-norm").getValue();
  setprop("sim/model/bluebird/sound/door-direction", td_dr);  # attempt to determine direction

  if (active_door <= 1 or active_door == 5) {
    setprop("sim/model/bluebird/sound/hatch-trigger", "true");
  }
  settimer(panel_lighting_loop, 0.05);
  settimer(reset_trigger, 1);
}

# give hatch sound effect one second to play ------------------------
var reset_trigger = func {
  setprop("sim/model/bluebird/sound/hatch-trigger", "false");
}

# systems -----------------------------------------------------------

setlistener("sim/model/bluebird/systems/power-switch", func {
  power_switch = getprop("sim/model/bluebird/systems/power-switch");
  if (damage_count) {
    var ventingL = getprop("ai/submodels/engine-L-venting");
    var ventingR = getprop("ai/submodels/engine-R-venting");
    var flaringL = getprop("ai/submodels/engine-L-flaring");
    var flaringR = getprop("ai/submodels/engine-R-flaring");
    if (ventingL or flaringL) {
      if (power_switch) {
        if (ventingL) {
          setprop ("ai/submodels/engine-L-venting", "false");
          setprop ("ai/submodels/engine-L-flaring", "true");
        }
      } else {
        if (flaringL) {
          setprop ("ai/submodels/engine-L-flaring", "false");
          setprop ("ai/submodels/engine-L-venting", "true");
        }
      }
    }
    if (ventingR or flaringR) {
      if (power_switch) {
        if (ventingR) {
          setprop ("ai/submodels/engine-R-venting", "false");
          setprop ("ai/submodels/engine-R-flaring", "true");
        }
      } else {
        if (flaringR) {
          setprop ("ai/submodels/engine-R-flaring", "false");
          setprop ("ai/submodels/engine-R-venting", "true");
        }
      }
    }
  }
});

setlistener("sim/model/bluebird/systems/reactor-request", func {
  reactor_request = getprop("sim/model/bluebird/systems/reactor-request");
});

setlistener("sim/model/bluebird/systems/reactor-level", func {
  reactor_level = getprop("sim/model/bluebird/systems/reactor-level");
});

setlistener("sim/model/bluebird/lighting/engine-glow", func {
  engines_lvl = getprop("sim/model/bluebird/lighting/engine-glow");
});

setlistener("sim/model/bluebird/systems/wave1-request", func {
  wave1_request = getprop("sim/model/bluebird/systems/wave1-request");
});

setlistener("sim/model/bluebird/systems/wave1-level", func {
  wave1_level = getprop("sim/model/bluebird/systems/wave1-level");
});

setlistener("sim/model/bluebird/systems/wave2-request", func {
  wave2_request = getprop("sim/model/bluebird/systems/wave2-request");
});

# interior ----------------------------------------------------------

setlistener("sim/model/bluebird/lighting/interior-switch", func {
  int_switch = getprop("sim/model/bluebird/lighting/interior-switch");
});

var isodd = func (odd_i) {
  var odd_x = int(odd_i - ((int(odd_i * 0.1)) * 10));
  if (odd_x == 1 or odd_x == 3 or odd_x == 5 or odd_x == 7 or odd_x == 9) {
    return 1;
  }
}

# lighting and texture ----------------------------------------------

setlistener("environment/visibility-m", func {
  visibility = getprop("environment/visibility-m");
}, 1);

var set_I1_ambient = func {
  var calc_amb_R = livery_I1AR + (livery_I1R_add * alert_level * int_switch);
  var calc_amb_G = livery_I1AG + (livery_I1G_add * alert_level * int_switch);
  var calc_amb_B = livery_I1AB + (livery_I1B_add * alert_level * int_switch);
  setprop("sim/model/bluebird/lighting/ambient/I1-A-red", calc_amb_R);
  setprop("sim/model/bluebird/lighting/ambient/I1-A-green", calc_amb_G);
  setprop("sim/model/bluebird/lighting/ambient/I1-A-blue", calc_amb_B);
  livery_I1R = calc_amb_R * 0.1;  # emission calculations base
  livery_I1G = calc_amb_G * 0.1;
  livery_I1B = calc_amb_B * 0.1;
}

var recalc_material_1 = func {
   # calculate emission and ambient base levels upon loading new livery
  var red_amb_flr_R = livery_I1AR * 1.5;     # tint calculations
  var red_amb_flr_G = livery_I1AG * 0.75;
  var red_amb_flr_B = livery_I1AB * 0.75;
  if (red_amb_flr_R > 1.0) {  # bounds checking
    red_amb_flr_R = 1.0;
  } elsif (red_amb_flr_R < 0.5) {
    red_amb_flr_R = 0.5;
  }
  if (red_amb_flr_G < 0.0) {
    red_amb_flr_G = 0.0;
  }
  if (red_amb_flr_B < 0.0) {
    red_amb_flr_B = 0.0;
  }
  livery_I1R_add = red_amb_flr_R - livery_I1AR;  # amount to add when calculating alert_level
  livery_I1G_add = red_amb_flr_G - livery_I1AG;
  livery_I1B_add = red_amb_flr_B - livery_I1AB;

  set_I1_ambient();
}

 setlistener("sim/model/livery/material/interior-flooring/ambient/red", func {
   livery_I1AR = getprop("sim/model/livery/material/interior-flooring/ambient/red");
   setprop("sim/model/bluebird/lighting/ambient/I1-A-red", livery_I1AR);
   recalc_material_1();
 });

 setlistener("sim/model/livery/material/interior-flooring/ambient/green", func {
   livery_I1AG = getprop("sim/model/livery/material/interior-flooring/ambient/green");
   setprop("sim/model/bluebird/lighting/ambient/I1-A-green", livery_I1AG);
   recalc_material_1();
 });

 setlistener("sim/model/livery/material/interior-flooring/ambient/blue", func {
   livery_I1AB = getprop("sim/model/livery/material/interior-flooring/ambient/blue");
   setprop("sim/model/bluebird/lighting/ambient/I1-A-blue", livery_I1AB);
   recalc_material_1();
 });

 setlistener("sim/model/livery/material/interior-lower/ambient/red", func {
   livery_I4R = getprop("sim/model/livery/material/interior-lower/ambient/red") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-lower/ambient/green", func {
   livery_I4G = getprop("sim/model/livery/material/interior-lower/ambient/green") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-lower/ambient/blue", func {
   livery_I4B = getprop("sim/model/livery/material/interior-lower/ambient/blue") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-door-panels/ambient/red", func {
   livery_IAR = getprop("sim/model/livery/material/interior-door-panels/ambient/red") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-door-panels/ambient/green", func {
   livery_IAG = getprop("sim/model/livery/material/interior-door-panels/ambient/green") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-door-panels/ambient/blue", func {
   livery_IAB = getprop("sim/model/livery/material/interior-door-panels/ambient/blue") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-upper/ambient/red", func {
   livery_IUR = getprop("sim/model/livery/material/interior-upper/ambient/red") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-upper/ambient/green", func {
   livery_IUG = getprop("sim/model/livery/material/interior-upper/ambient/green") * 0.1;
 });

 setlistener("sim/model/livery/material/interior-upper/ambient/blue", func {
   livery_IUB = getprop("sim/model/livery/material/interior-upper/ambient/blue") * 0.1;
 });

aircraft.livery.select(getprop("sim/model/livery/variant"));

setlistener("controls/lighting/alert", func {
  alert_switch = alert_switch_Node.getValue();
  alert_level = alert_switch;  # reset brightness to full upon change
  if (!alert_switch) {
    setprop("sim/model/bluebird/lighting/emission/I0-red", 1);
    setprop("sim/model/bluebird/lighting/emission/I0g-0b", 1);
    setprop("sim/model/bluebird/lighting/ambient/I1-A-red", livery_I1AR);
    setprop("sim/model/bluebird/lighting/ambient/I1-A-green", livery_I1AG);
    setprop("sim/model/bluebird/lighting/ambient/I1-A-blue", livery_I1AB);
  }
  recalc_material_1();
  interior_lighting_update();
});

# watch for damage --------------------------------------------------

setlistener("sim/model/bluebird/components/nacelle-L", func {
  nacelleL_attached = getprop("sim/model/bluebird/components/nacelle-L");
  if (!nacelleL_attached) {
    if (nacelle_L_venting) {
      setprop ("sim/model/bluebird/systems/nacelle-L-venting", "false");
      setprop ("ai/submodels/engine-L-flaring", "true");
    }
  }
}, 1);

setlistener("sim/model/bluebird/components/nacelle-R", func {
  nacelleR_attached = getprop("sim/model/bluebird/components/nacelle-R");
  if (!nacelleR_attached) {
    if (nacelle_R_venting) {
      setprop ("sim/model/bluebird/systems/nacelle-R-venting", "false");
      setprop ("ai/submodels/engine-R-flaring", "true");
    }
  }
}, 1);

# make venting submodels appear realistic as wind direction blows them
var update_venting = func(uv_change) {
  var old_direction = venting_direction;
  if (nacelle_L_venting or nacelle_R_venting) {
    if (airspeed > 10) {
      venting_direction = 1;
    } elsif (airspeed < -10) {
      venting_direction = -1;
    } else {
      venting_direction = 0;
    }
    if ((old_direction != venting_direction) or (uv_change)) {
      if (nacelle_L_venting) {
        if (venting_direction == 1) {
          setprop ("ai/submodels/nacelle-LR-venting", "true");
          setprop ("ai/submodels/nacelle-LF-venting", "false");
        } elsif (venting_direction == -1) {
          setprop ("ai/submodels/nacelle-LR-venting", "false");
          setprop ("ai/submodels/nacelle-LF-venting", "true");
        } elsif (venting_direction == 0) {
          setprop ("ai/submodels/nacelle-LR-venting", "true");
          setprop ("ai/submodels/nacelle-LF-venting", "true");
        }
      } elsif (!nacelle_L_venting) {
        setprop ("ai/submodels/nacelle-LR-venting", "false");
        setprop ("ai/submodels/nacelle-LF-venting", "false");
      }
      if (nacelle_R_venting) {
        if (venting_direction == 1) {
          setprop ("ai/submodels/nacelle-RR-venting", "true");
          setprop ("ai/submodels/nacelle-RF-venting", "false");
        } elsif (venting_direction == -1) {
          setprop ("ai/submodels/nacelle-RR-venting", "false");
          setprop ("ai/submodels/nacelle-RF-venting", "true");
        } elsif (venting_direction == 0) {
          setprop ("ai/submodels/nacelle-RR-venting", "true");
          setprop ("ai/submodels/nacelle-RF-venting", "true");
        }
      } elsif (!nacelle_R_venting) {
        setprop ("ai/submodels/nacelle-RR-venting", "false");
        setprop ("ai/submodels/nacelle-RF-venting", "false");
      }
    }
  } else {
    if (uv_change) {
      venting_direction = -3;
      setprop ("ai/submodels/nacelle-LR-venting", "false");
      setprop ("ai/submodels/nacelle-LF-venting", "false");
      setprop ("ai/submodels/nacelle-RR-venting", "false");
      setprop ("ai/submodels/nacelle-RF-venting", "false");
    }
  }
}

setlistener("sim/model/bluebird/systems/nacelle-L-venting", func {
  nacelle_L_venting = getprop("sim/model/bluebird/systems/nacelle-L-venting");
  if (!nacelleL_attached) {
    if (nacelle_L_venting) {
      setprop ("ai/submodels/engine-L-flaring", "true");
      setprop ("sim/model/bluebird/systems/nacelle-L-venting", "false");
    }
  }
  update_venting(1);
}, 1);

setlistener("sim/model/bluebird/systems/nacelle-R-venting", func {
  nacelle_R_venting = getprop("sim/model/bluebird/systems/nacelle-R-venting");
  if (!nacelleR_attached) {
    if (nacelle_R_venting) {
      setprop ("ai/submodels/engine-R-flaring", "true");
      setprop ("sim/model/bluebird/systems/nacelle-R-venting", "false");
    }
  }
  update_venting(1);
}, 1);

#==========================================================================
# loop function #1 called by panel_lighting_loop every 0.05 seconds 
#   only when changes in progress ===================================

var panel_lighting_update = func {
  var plu_return = 0;
  if (power_switch) {
    var int_sp = (int_switch - 1) * -1;  # interior specular
    var int_sp_lit = 0;
    var ipsa = (sun_angle - 1.1) * 3.3;    # instrument panel sun angle
      # ipsa = 1.0 dusk-midnight-dawn  0.33 at high noon
    var iplir = 0.0600 * interior_lighting_base_r;  # Grey60 button Lighting
    var ipligb = 0.0600 * interior_lighting_base_gb;  # alert tint
    if (ipsa < 0) {
      ipsa = 0;       # daytime
    } elsif (ipsa > 1) {
      ipsa = 1.0000;  # nighttime
    }
    var button_lit = ((1 - (ipsa * 0.2)) * (int_switch + 1) * 0.5) + (((1 - ipsa) * (1 - int_switch)) * 0.5);
    var button_unlit = ipsa * (int_switch * 0.1);
  } else {
    var int_sp = 1;      # full reflection
    var int_sp_lit = 1;
    var ipsa = 0;
    var iplir = 0;
    var ipligb = 0;
    var button_lit = 0;
    var button_unlit = 0;
  }  
  # set emissions based on interior lighting
  setprop("sim/model/bluebird/lighting/emission/IG1-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IG2-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IG3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IG4-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/ILT1-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/ILT2-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/ILT8-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/ILT9-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT1-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT2-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT3-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT4-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT5-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT6-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT7-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT8-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IRT9-3-red", iplir);
  setprop("sim/model/bluebird/lighting/emission/IG1-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG2-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG4-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT1-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT2-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT8-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT9-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT1-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT2-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT3-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT4-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT5-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT6-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT7-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT8-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT9-3-green", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG1-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG2-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG4-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT1-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT2-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT8-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/ILT9-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT1-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT2-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT3-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT4-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT5-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT6-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT7-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT8-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IRT9-3-blue", ipligb);
  setprop("sim/model/bluebird/lighting/emission/IG2-specular", int_sp);
  setprop("sim/model/bluebird/lighting/emission/IG4-specular", int_sp);
  setprop("sim/model/bluebird/lighting/emission/IRT4-specular", int_sp);
  setprop("sim/model/material/instruments/factor", ipsa * 0.4);
  # then determine if any buttons should be lit
  # thus changing each R,G, and B to lit or unlit based on desired color
  # unlit is actually a button that is lit, but not in that color spectrum.
  if (gear_position == 0) {
    if (wheel_position == 0) {
      setprop("sim/model/bluebird/lighting/emission/IG1-red", button_unlit);
    } else {
      setprop("sim/model/bluebird/lighting/emission/IG1-red", button_lit);
    }
    setprop("sim/model/bluebird/lighting/emission/IG1-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IG1-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IG1-specular", int_sp_lit);
    setprop("sim/model/bluebird/lighting/emission/IG3-specular", int_sp);
  } elsif (gear_position == 1 or gear_position == 0.41) {
    setprop("sim/model/bluebird/lighting/emission/IG3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IG3-specular", int_sp_lit);
    setprop("sim/model/bluebird/lighting/emission/IG1-specular", int_sp);
    if (wheel_position == 0) {
      setprop("sim/model/bluebird/lighting/emission/IG3-green", button_unlit);
      setprop("sim/model/bluebird/lighting/emission/IG3-blue", button_lit);
    } else {
      setprop("sim/model/bluebird/lighting/emission/IG3-green", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG3-blue", button_unlit);
    }
  } elsif (isodd(gear_position * 6)) {  # increasing factor increases flashing frequency
    plu_return = 1;
    if (!gear_request) {
      setprop("sim/model/bluebird/lighting/emission/IG1-red", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG1-green", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG1-blue", button_unlit);
      setprop("sim/model/bluebird/lighting/emission/IG1-specular", int_sp_lit);
      setprop("sim/model/bluebird/lighting/emission/IG3-specular", int_sp);
    } else {
      setprop("sim/model/bluebird/lighting/emission/IG3-red", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG3-green", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG3-blue", button_unlit);
      setprop("sim/model/bluebird/lighting/emission/IG3-specular", int_sp_lit);
      setprop("sim/model/bluebird/lighting/emission/IG1-specular", int_sp);
    }
  } else {
    plu_return = 1;
  }
  if (gear_mode) {
    setprop("sim/model/bluebird/lighting/emission/IG2-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IG2-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IG2-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IG2-specular", int_sp_lit);
  }
  if (wheel_position == 1) {
    setprop("sim/model/bluebird/lighting/emission/IG4-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IG4-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IG4-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IG4-specular", int_sp_lit);
  } else {
    if (isodd(wheel_position * 6)) {  # increasing factor increases flashing frequency
      plu_return = 1;
      setprop("sim/model/bluebird/lighting/emission/IG4-red", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG4-green", button_lit);
      setprop("sim/model/bluebird/lighting/emission/IG4-blue", button_unlit);
      setprop("sim/model/bluebird/lighting/emission/IG4-specular", int_sp_lit);
    }
    if (wheel_position != 0) {
      plu_return = 1;
    }
  }
  if (door0_position == 0) {
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-specular", int_sp_lit);
  } elsif (door0_position == 1) {
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-green", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-specular", int_sp_lit);
  } elsif (isodd(door0_position * 8)) {
    plu_return = 1;
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT1-specular", int_sp_lit);
  } else {
    plu_return = 1;
    setprop("sim/model/bluebird/lighting/emission/IRT1-specular", int_sp);
  }
  if (door1_position == 0) {
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-specular", int_sp_lit);
  } elsif (door1_position == 1) {
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-green", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-specular", int_sp_lit);
  } elsif (isodd(door1_position * 8)) {
    plu_return = 1;
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT2-specular", int_sp_lit);
  } else {
    plu_return = 1;
    setprop("sim/model/bluebird/lighting/emission/IRT2-specular", int_sp);
  }
  if (door5_position == 0) {
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-specular", int_sp_lit);
  } elsif (door5_position == 1) {
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-green", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-specular", int_sp_lit);
  } elsif (isodd(door5_position * 28.8)) {
    plu_return = 1;
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT3-specular", int_sp_lit);
  } else {
    plu_return = 1;
    setprop("sim/model/bluebird/lighting/emission/IRT3-specular", int_sp);
  }
  var ipll = landing_light_switch.getValue();
  if (ipll) {
    setprop("sim/model/bluebird/lighting/emission/IRT5-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT5-3-green", button_lit * ((ipll * 0.2) + 0.2));
    setprop("sim/model/bluebird/lighting/emission/IRT5-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT5-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/IRT5-specular", int_sp);
  }
  var ipnl = nav_light_switch.getValue();
  if (ipnl) {
    setprop("sim/model/bluebird/lighting/emission/IRT6-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT6-3-green", button_lit * ((ipnl * 0.2) + 0.2));
    setprop("sim/model/bluebird/lighting/emission/IRT6-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT6-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/IRT6-specular", int_sp);
  }
  if (beacon_switch.getValue()) {
    setprop("sim/model/bluebird/lighting/emission/IRT7-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT7-3-green", button_lit * 0.6);
    setprop("sim/model/bluebird/lighting/emission/IRT7-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT7-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/IRT7-specular", int_sp);
  }
  if (strobe_switch.getValue()) {
    setprop("sim/model/bluebird/lighting/emission/IRT8-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT8-3-green", button_lit * 0.6);
    setprop("sim/model/bluebird/lighting/emission/IRT8-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT8-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/IRT8-specular", int_sp);
  }
  var is_rt9 = int_sp;
  if (int_switch) {
    setprop("sim/model/bluebird/lighting/emission/IRT9-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT9-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT9-3-blue", button_unlit);
    is_rt9 = 0;
  }
  if (alert_switch or damage_count) {
    setprop("sim/model/bluebird/lighting/emission/IRT9-3-red", button_lit);
    setprop("sim/model/bluebird/lighting/emission/IRT9-3-green", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/IRT9-3-blue", button_unlit);
    is_rt9 = 0;
  }
  setprop("sim/model/bluebird/lighting/emission/IRT9-specular", is_rt9);
  if (power_switch) {
    setprop("sim/model/bluebird/lighting/emission/ILT1-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT1-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/ILT1-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT1-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/ILT1-specular", int_sp);
  }
  if (reactor_request) {
    setprop("sim/model/bluebird/lighting/emission/ILT2-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT2-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/ILT2-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT2-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/ILT2-specular", int_sp);
  }
  if (wave1_level == 1) {
    setprop("sim/model/bluebird/lighting/emission/ILT8-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT8-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/ILT8-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT8-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/ILT8-specular", int_sp);
  }
  if (wave2_level == 1) {
    setprop("sim/model/bluebird/lighting/emission/ILT9-3-red", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT9-3-green", button_lit);
    setprop("sim/model/bluebird/lighting/emission/ILT9-3-blue", button_unlit);
    setprop("sim/model/bluebird/lighting/emission/ILT9-specular", int_sp_lit);
  } else {
    setprop("sim/model/bluebird/lighting/emission/ILT9-specular", int_sp);
  }
  return plu_return;
}

var panel_lighting_loop = func {
  if (panel_lighting_update() > 0) {
    settimer(panel_lighting_loop, 0.05);
  }
}

#==========================================================================
# loop function #2 called by interior_lighting_loop every 3 seconds
#    or every 0.25 when time warp or every 0.05 during condition red lighting

var interior_lighting_update = func {
  var intli = 0;    # calculate brightness of interior lighting as sun goes down
  var intlir = 0;    # condition lighting tint for green and blue emissions
  sun_angle = getprop("sim/time/sun-angle-rad");  # Tied property, cannot listen
  if (power_switch) {
    if (int_switch) {
      if (visibility < 5000 or sun_angle > 1.4) {
        if (sun_angle < 1.8) {
          intli = (sun_angle - 1.4) * 17.5;
        } else {
          intli = 7;
        }
      }
    }
    if (alert_switch or damage_count > 0) {
      var red_state = getprop("sim/model/bluebird/lighting/alert1/state");  # bring lighting up or down
      if (red_state) {
        alert_level += 0.08;
        if (alert_level > 1.0) {
          alert_level = 1.0;
        }
      } elsif (!red_state) {
        alert_level -= 0.08;
        if (alert_level < 0.25) {
          alert_level = 0.25;
        }
      }
      setprop("sim/model/bluebird/lighting/emission/I0-red", alert_level);  # set red brightness
      setprop("sim/model/bluebird/lighting/emission/I0g-0b", 0);
      intli = intli * alert_level;  # adjust lighting accordingly
      intlir = intli * alert_level * 0.25;
    } else {
      intlir = intli;
    }
     # fade marker lighting when damaged
    setprop("sim/model/bluebird/lighting/emission/I9r-9g", 1.0 - (damage_count * 0.25));
    setprop("sim/model/bluebird/lighting/emission/IBr-Bg", 1.0 - (damage_count * 0.25));
    setprop("sim/model/bluebird/lighting/emission/IB-blue", 1.0 - (damage_count * 0.25));
  } else {
    setprop("sim/model/bluebird/lighting/emission/I9r-9g", 0);
    setprop("sim/model/bluebird/lighting/emission/IBr-Bg", 0);
    setprop("sim/model/bluebird/lighting/emission/IB-blue", 0);
  }
    # 1=rug/floor 2=GREY80 3=GREY60 4=lower 5=Grey36 6=Grey14
    # 7=Tan 8=Brown 9=YELLOW A=Lt.Blue B=WHITE_door_markers
  set_I1_ambient();  # calculate and set flooring ambient levels
    # next calculate emissions for night lighting
  interior_lighting_base_r = intli;
  setprop("sim/model/bluebird/lighting/emission/I1-red", livery_I1R * intli);
  setprop("sim/model/bluebird/lighting/emission/I2-red", 0.0800 * intli);
  setprop("sim/model/bluebird/lighting/emission/I3-red", 0.0600 * intli);
  setprop("sim/model/bluebird/lighting/emission/I4-red", livery_I4R * intli);
  setprop("sim/model/bluebird/lighting/emission/I5-red", 0.0360 * intli);
  setprop("sim/model/bluebird/lighting/emission/I6-red", 0.0147 * intli);
  setprop("sim/model/bluebird/lighting/emission/I7-red", 0.0700 * intli);
  setprop("sim/model/bluebird/lighting/emission/I8-red", 0.0250 * intli);
  setprop("sim/model/bluebird/lighting/emission/IA-red", livery_IAR * intli);
  setprop("sim/model/bluebird/lighting/emission/IU-red", livery_IUR * intli);
  interior_lighting_base_gb = intlir;
  setprop("sim/model/bluebird/lighting/emission/I1-green", livery_I1G * intlir);
  setprop("sim/model/bluebird/lighting/emission/I1-blue", livery_I1B * intlir);
  setprop("sim/model/bluebird/lighting/emission/I2g-2b", 0.0800 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I3g-3b", 0.0600 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I4-green", livery_I4G * intlir);
  setprop("sim/model/bluebird/lighting/emission/I4-blue", livery_I4B * intlir);
  setprop("sim/model/bluebird/lighting/emission/I5-green", 0.0370 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I5-blue", 0.0320 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I6g-6b", 0.0147 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I7-green", 0.0690 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I7-blue", 0.0590 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I8-green", 0.0240 * intlir);
  setprop("sim/model/bluebird/lighting/emission/I8-blue", 0.0170 * intlir);
  setprop("sim/model/bluebird/lighting/emission/IA-green", livery_IAG * intlir);
  setprop("sim/model/bluebird/lighting/emission/IA-blue", livery_IAB * intlir);
  setprop("sim/model/bluebird/lighting/emission/IU-green", livery_IUG * intlir);
  setprop("sim/model/bluebird/lighting/emission/IU-blue", livery_IUB * intlir);

  setprop("sim/model/bluebird/lighting/interior-specular", (int_switch - 1) * - 0.5);

  panel_lighting_update();
}

var interior_lighting_loop = func {
  interior_lighting_update();
  if (alert_switch) {
    settimer(interior_lighting_loop, 0.05);
  } else {
    if (getprop("sim/time/warp-delta")) {
      settimer(interior_lighting_loop, 0.25);
    } else {
      settimer(interior_lighting_loop, 3);
    }
  }
}

#==========================================================================
# loop function #3 called by nav_light_loop every 3 seconds
#    or every 0.5 seconds when time warp ============================

var nav_lighting_update = func {
  var nlu_nav = nav_light_switch.getValue();
  if (nlu_nav == 2) {
    nav_lights_state.setBoolValue(1);
  } else {
    if (nlu_nav == 1) {
      nav_lights_state.setBoolValue(visibility < 5000 or sun_angle > 1.4);
    } else {
      nav_lights_state.setBoolValue(0);
    }
  }

    # window shading factor between 0 transparent and 1 opaque
    #      if lights on   range(0.3-0.9) midnight to noon
    #    else lights off  range(0.6-1.0)
  if (getprop("sim/model/bluebird/lighting/window-opaque")) {
    var wsv = 1.0;
  } else {  
    var wsv = -9999;
    if (visibility < 5000 or sun_angle > 1.2) {  # dawn/dusk bright side
      if (int_switch) {      # lights on
        if (sun_angle < 2.0) {  # dawn/dusk darkest
          wsv = 1.8 - (sun_angle * 0.75);
        } else {
          wsv = 0.3;  # dark night
        }
      } else {            # lights off
        if (sun_angle < 2.0) {
          wsv = 1.6 - (sun_angle * 0.5);
        } else {
          wsv = 0.6;  # dark night
        }
      }
    } else {      # daytime
      if (int_switch) {
        wsv = 0.9;
      } else {
        wsv = 1.0;
      }
    }
  }
  setprop("sim/model/bluebird/lighting/window-factor", wsv);
}

var nav_light_loop = func {
  nav_lighting_update();
  if (getprop("sim/time/warp-delta")) {
    settimer(nav_light_loop, 0.5);
  } else {
    settimer(nav_light_loop, 3);
  }
}

#==========================================================================
var wheel_update = func {    # speed changes depending on system load. Ideal at 60 fps. Need solution based on real time.
  var wu_return = 0;
   # can the wheels be moved
  if (power_switch or gear_wheels < 0.1) {
    if (!gear_wheels) {   # determine destination
      var wu_dest = 0.0;
    } else {
      if (airspeed > 2000) {
        if (current_to > 6) {
          popupTip2("Velocity too fast for safe deployment. Reducing speed");
          change_maximum(cpl, 6, 1); 
        }
      }
      var wu_dest = 1.0;
    }
    if (wheel_position != wu_dest) {
      if (wheel_position < wu_dest) {  # move down
        wheel_position = wheel_position + 0.008;
        if (wheel_position > wu_dest) {
          wheel_position = wu_dest;
        }
        wu_return = 1;
      } elsif (wheel_position > wu_dest) {   # move up
        wheel_position = wheel_position - 0.008;
        if (wheel_position < 0) {
          wheel_position = 0;
        }
        wu_return = 1;
      }
    }
    setprop("gear/wheels/position-norm", wheel_position);
    if (wheel_position > 0) {
      var ppos = gear_position - wheel_position;
      if (ppos < 0) {
        ppos = 0;
      }
      setprop("gear/gear[0]/position-side-pads", ppos);
    } else {
      setprop("gear/gear[0]/position-side-pads", gear_position);
    }
    if (wheel_position > 0.5) {
      if (wheel_position > 0.90) {
        wheel_height = ((wheel_position - 0.9) * 1.31234) + 1.03893;
      } else {
        wheel_height = (wheel_position - 0.5) * 2.59733;
      }
    } else {
      wheel_height = 0;
    }
    gear_height = (gear_position * 2.47) + wheel_height;
    # contact = altitude origin - offset - gear - (keep nacelle and nose from touching)
    contact_altitude = altitude_ft_Node.getValue() - vertical_offset - gear_height - hover_add;
  } else {
    popupTip2("Unable to comply. No power.");
  }
  return wu_return;
}

# loop function during wheel movement =========================
var transit_wheel_loop = func {
  if (wheel_update()) {
    settimer(transit_wheel_loop, 0.01);
    wheel_looping = 1;
  } else {
    wheel_looping = 0;
  }
}

var gear_update = func {    # speed changes depending on system load. Ideal at 60 fps. Need solution based on real time.
  var gu_return = 0;
  if (power_switch or gear_request < 0.5) {  # can the gear be moved
    if (!gear_request) {   # determine destination
      var gu_dest = 0.0;
      if (wheel_position == 1) {
        setprop("sim/model/bluebird/systems/gear-wheels-request", "false");
      }
    } else {
      if (gear_mode) { 
        var gu_dest = 0.41;
      } else {
        if (airspeed > 2000) {
          if (current_to > 6) {
            popupTip2("Velocity too fast for safe deployment. Reducing speed");
            change_maximum(cpl, 6, 1); 
          }
        }
        var gu_dest = 1.0;
      }
    }
    if (gear_position != gu_dest) {
      if (gear_position < gu_dest) {  # move down
        gear_position = gear_position + 0.01;
        if (gear_position > gu_dest) {
          gear_position = gu_dest;
        }
        gu_return = 1;
      } elsif (gear_position > gu_dest) {   # move up
        gear_position = gear_position - 0.01;
        if (gear_position < 0) {
          gear_position = 0;
        }
        gu_return = 1;
      }
    }
    setprop("gear/gear[0]/position-norm", gear_position);
    if (wheel_position > 0) {
      var ppos = gear_position - wheel_position;
      if (ppos < 0) {
        ppos = 0;
      }
      setprop("gear/gear[0]/position-side-pads", ppos);
    } else {
      setprop("gear/gear[0]/position-side-pads", gear_position);
    }
    gear_height = (gear_position * 2.47) + wheel_height;
    if (door0_position > 0.7) {
      door_update(0);
    }
    if (door1_position > 0.7) {
      door_update(1);
    }
    if (door5_position > 0.7) {
      door_update(5);
    }
    contact_altitude = altitude_ft_Node.getValue() - vertical_offset - gear_height - hover_add;
  } else {
    popupTip2("Unable to comply. No power.");
  }
  return gu_return;
}

# loop function #4 during gear movement =========================
var transit_gear_loop = func {
  if (gear_update()) {
    settimer(transit_gear_loop, 0.01);
    gear_looping = 1;
  } else {
    gear_looping = 0;
  }
}

controls.gearDown = func(direction) {
  if (direction < 0) {   # up requested
    gear_request = 0;
    if (!gear_looping) {
      settimer(transit_gear_loop, 0);
      settimer(panel_lighting_loop, 0.05);
    }
  } elsif (direction > 0) {  # down
    if (airspeed > 2000 and !gear_mode) {
      if (cpl > 6) {
        popupTip2("Velocity too fast for safe deployment. Reducing speed");
        change_maximum(cpl, 6, 1); 
      }
    }
    gear_request = 1;
    if (!gear_looping) {
      settimer(transit_gear_loop, 0);
      settimer(panel_lighting_loop, 0.05);
    }
  }
}

var toggle_gear_mode = func(gm_request) {
  if (gm_request == 1) {          # extend fully
    gear_mode = 1;
    active_gear_button = [ 3, 1];
  } elsif (gm_request == 0) {    # crouch low
    gear_mode = 0;
    active_gear_button = [ 1, 3];
  } else {                    # toggle
    if (gear_mode) {
      gear_mode = 0;
      active_gear_button = [ 1, 3];
    } else {
      gear_mode = 1;
      active_gear_button = [ 3, 1];
    }
  }
  if (!gear_looping) {
    settimer(transit_gear_loop, 0);
    settimer(panel_lighting_loop, 0.05);
  }
  reloadDialog();
}

setlistener("sim/model/bluebird/systems/gear-wheels-request", func {
  gear_wheels = getprop("sim/model/bluebird/systems/gear-wheels-request");
  if (!wheel_looping) {
    settimer(transit_wheel_loop, 0);
    settimer(panel_lighting_loop, 0.05);
  }
});

var toggle_wheel_mode = func() {
  if (gear_wheels) {
    setprop("sim/model/bluebird/systems/gear-wheels-request", "false");
  } else {
    setprop("sim/model/bluebird/systems/gear-wheels-request", "true");
  }
}

#==========================================================================

var change_maximum = func(cm_from, cm_to, cm_type) {
  var lmt = limit[(reactor_level + (wave1_level* 2) + (wave2_level* 4))] - damage_count ;
  if (lmt < 0) {
    lmt = 0;
  }
  if (cm_to < 0) {  # shutdown by crash
    cm_to = 0;
  }
  if (max_drift) {   # did not finish last request yet
    if (cm_to > cm_from) {
      if (cm_type < 2) {  # startup from power down. bring systems back online
        cm_to = max_to + 1;
      }
    } else {
      var cm_to_new = max_to - 1;
      if (cm_to_new < 0) {  # midair shutdown
        cm_to_new = 0;
      }
      cm_to = cm_to_new;
    }
    if (cm_to >= size(speed_mps)) { 
      cm_to = size(speed_mps) - 1;
    }
    if (cm_to >= lmt) {
      cm_to = lmt;
    }
    if (cm_to < 0) {
      cm_to = 0;
    }
  } else {
    max_from = cm_from;
  }
  max_to = cm_to;
  max_drift = abs(speed_mps[cm_from] - speed_mps[cm_to]) / 20;
  if (cm_type > 1) {  
    # separate new maximum from limit. by engine shutdown/startup
    current_to = cpl;
  } else { 
    # by joystick flaps request
    current_to = cm_to;
  }
}

# modify flaps to change maximum speed --------------------------

controls.flapsDown = func(fd_d) {  # 1 decrease speed gearing -1 increases by default
  var fd_return = 0;
  if(power_switch) {
    if (!fd_d) {
      return;
    } elsif (fd_d > 0 and cpl > 0) {    # reverse joystick buttons direction by exchanging < for >
      change_maximum(cpl, (cpl-1), 1);
      fd_return = 1;
    } elsif (fd_d < 0 and cpl < size(speed_mps) - 1) {    # reverse joystick buttons direction by exchanging < for >
      if (cpl >= limit[(reactor_level + (wave1_level* 2) + (wave2_level* 4))]) {
        if (wave1_level) {
          if (reactor_level) {
            popupTip2("Unable to comply. Orbital velocities requires higher energy setting");
          } else {
            popupTip2("Unable to comply. Requested velocity requires fusion reactor to be online");
          }
        } else {  
          popupTip2("Unable to comply. Primary Wave-guide engine OFF LINE");
        }
      } elsif (cpl > 5 and gear_position > 0.5) {
        popupTip2("Unable to comply. Gear is down");
      } elsif (cpl > 5 and wheel_position > 0.5) {
        popupTip2("Unable to comply. Gear wheels are down");
      } elsif (cpl > 4 and door0_position > 0) {
        popupTip2("Unable to comply. Side hatch is open");
      } elsif (cpl > 4 and door1_position > 0) {
        popupTip2("Unable to comply. Side hatch is open");
      } elsif (cpl > 6 and door5_position > 0) {
        popupTip2("Unable to comply. Rear hatch is open");
      } elsif (cpl > 6 and contact_altitude < 10000) {
        popupTip2("Unable to comply below 10,000 ft.");
      } elsif (cpl > 7 and contact_altitude < 20000) {
        popupTip2("Unable to comply below 20,000 ft.");
      } elsif (cpl > 8 and contact_altitude < 40000) {
        popupTip2("Unable to comply below 40,000 ft.");
      } elsif (cpl > 9 and contact_altitude < 70000) {
        popupTip2("Unable to comply below 70,000 ft.");
      } else {
        change_maximum(cpl, (cpl + 1), 1);
        fd_return = 1;
      }
    }
    if (fd_return) {
      var ss = speed_mps[max_to];
      popupTip2("Max. Speed " ~ ss ~ " m/s");
    }
    current.setValue(cpl);
  } else {
    popupTip2("Unable to comply. Main power is off.");
  }
}


# position adjustment function =====================================

var reset_impact = func {
  damage_blocker = 0;
}

var settle_to_level = func {
  var hg_roll = roll_deg.getValue() * 0.75;
  roll_deg.setValue(hg_roll);  # unless on hill... doesn't work right with ufo model
  var hg_roll = roll_control.getValue() * 0.75;
  roll_control.setValue(hg_roll);
  var hg_pitch = pitch_deg.getValue() * 0.75;
  pitch_deg.setValue(hg_pitch);
  var hg_pitch = pitch_control.getValue() * 0.75;
  pitch_control.setValue(hg_pitch);
}

#==========================================================================
# -------- MAIN LOOP called by itself every cycle --------

var update_main = func {
  var gnd_elev = ground_elevation_ft.getValue();  # ground elevation
  var altitude = altitude_ft_Node.getValue();  # aircraft altitude
  if (gnd_elev == nil) {    # startup check
    gnd_elev = 0;
  }
  if (altitude == nil) {
    altitude = -9999;
  }
  if (altitude > -9990) {   # wait until program has started
  	  pitch_d = pitch_deg.getValue();   # update variables used by everybody
  	  airspeed = airspeed_kt_Node.getValue();
  	  asas = abs(airspeed);
  	  abs_airspeed_Node.setDoubleValue(asas);
  	   # ----- initialization checks -----
  	  if (init_agl > 0) {
  	     # trigger rumble sound to be on
  	    setprop("controls/engines/engine/throttle",0.01);
  	     # find real ground level
  	    altitude = gnd_elev + init_agl;
  	    altitude_ft_Node.setDoubleValue(altitude);
  	    if (init_agl > 1) {
  	      init_agl -= 0.75;
  	    } elsif (init_agl > 0.25) {
  	      init_agl -= 0.25;
  	    } else {
  	      init_agl -= 0.05;
  	    }
  	    if (init_agl <= 0) { 
  	      setprop("controls/engines/engine/throttle",0);
  	    }
  	  }
  	  var hover_ft = 0;
  	  contact_altitude = altitude - vertical_offset - gear_height - hover_add;   # adjust calculated altitude for gear up and nacelle/nose dip

  	   # ----- only check hover if near ground ------------------
  	  var new_ground_near = 0;   # see if indicator lights can be turned off
  	  var new_ground_warning = 0;
  	  var check_agl = (asas * 0.05) + 40;
  	  if (check_agl < 50) {
  	    check_agl = 50;
  	  }
  	  if (contact_altitude < (gnd_elev + check_agl)) {
  	    new_ground_near = 1;
  	    var rolld = abs(roll_deg.getValue()) / 3.5;
  	    var skid_w2 = 0;
  	    var skid_altitude_change = 0;
  	    if (pitch_d > 0) {    # calculations optimized for gear Down
  	      if (pitch_d < 7.6) {  # try to keep rear of nacelles from touching ground
  	        hover_add = pitch_d / 2.8;
  	      } elsif (pitch_d < 25) {
  	        hover_add = ((pitch_d - 7.6) / 1.65) + 2.714;
  	      } elsif (pitch_d < 52) {
  	        hover_add = ((pitch_d - 25) / 1.8) + 13.259;  # ((25-7.6)/1.65)+2.714
  	      } elsif (pitch_d < 75) {
  	        hover_add = ((pitch_d - 52) / 3.25) + 28.259;
  	      } else {
  	        hover_add = ((pitch_d - 75) / 7.0) + 35.336;
  	      }
  	    } else {
  	      if (pitch_d > -7.6) {  # try to keep nose from touching ground
  	        hover_add = abs(pitch_d / 2.2);
  	      } elsif (pitch_d > -14) {
  	        hover_add = abs((pitch_d + 7.6) / 2.05 ) + 3.455;
  	      } elsif (pitch_d > -32) {
  	        hover_add = abs((pitch_d + 14) / 1.6) + 6.576;
  	      } elsif (pitch_d > -43) {
  	        hover_add = abs((pitch_d + 32) / 1.8) + 17.826;
  	      } elsif (pitch_d > -60) {
  	        hover_add = abs((pitch_d + 43) / 2.2) + 23.937;
  	      } elsif (pitch_d > -73) {
  	        hover_add = abs((pitch_d + 60) / 3.0) + 31.664;
  	      } else {
  	        hover_add = abs((pitch_d + 73) / 6.5) + 35.997;
  	      }
  	    }
  	      # 1st threshold rolld @ 27 degrees = 7.71
  	    if (rolld > 7.71) {  # keep nacelles from touching ground
  	      rolld = ((rolld - 7.71) / 0.6) + 7.71;
  	    }
  	    hover_add = hover_add + rolld;   # total clearance for model above gnd_elev
  	      # add to hover_add the airspeed calculation to increase ground separation with airspeed
  	    if (asas < 100) {  # near ground hovering altitude calculation
  	      hover_ft = gear_height + (engines_lvl * asas * 0.03);
  	    } elsif (asas > 1000) {  # increase separation from ground
  	      hover_ft = gear_height + (engines_lvl * ((asas * 0.02) + 28));
  	    } else {    # hold altitude above ground, increasing with velocity
  	      hover_ft = gear_height + (engines_lvl * ((asas * 0.05) - 2));
  	    }

  	    if (gnd_elev < 0) {   
  	      # likely over ocean water
  	      gnd_elev = 0;  # keep above water until there is ocean bottom
  	    }
  	    hover_target_altitude = gnd_elev + hover_ft + hover_add + vertical_offset;  # includes gear_height
  	    h_contact_target_alt = hover_target_altitude - gear_height - hover_add - vertical_offset;

  	    if (altitude < hover_target_altitude) {
  	       # below ground/flight level
  	      if (altitude > 0) {            # check for skid, smoothen sound effects
  	        if (contact_altitude < gnd_elev) {
  	          skid_w2 = (gnd_elev - contact_altitude);  # depth
  	          if (skid_w2 < skid_last_value) {  # abrupt impact or
  	            skid_w2 = (skid_w2 + skid_last_value) * 0.75; # smoothen ascent
  	           }
  	          # below ground, contact should skid
  	        }
  	      }
  	      skid_altitude_change = hover_target_altitude - altitude;
  	      if (skid_altitude_change > 0.5) {
  	        new_ground_warning = 1;
  	        if (skid_altitude_change < hover_ft) {
  	          # hover increasing altitude, but still above ground
  	          # add just enough skid to create the sound of 
  	          # emergency counter-grav to increase elevation
  	          if (skid_w2 < 1.0) {
  	            skid_w2 = 1.0;
  	          }
  	        }
  	        if (skid_altitude_change > skid_w2) {
  	           # keep skid sound going and dig in if bounding up large hill
  	          var impact_factor = (skid_altitude_change / asas * 25);
  	           # vulnerability to impact. Increasing from 25 increases vulnerability
  	          if (skid_altitude_change > impact_factor) {  # but not if on flat ground
  	            new_ground_warning = 2;
  	            skid_w2 = skid_altitude_change;  # choose the larger skid value
  	          }
  	        }
  	      }
  	      if (hover_ft < 0) {  # separate skid effects from actual impact
  	        altitude = hover_target_altitude - hover_ft;
  	      } else {
  	        altitude = hover_target_altitude;
  	      }

  	      altitude_ft_Node.setDoubleValue(altitude);  # force above ground elev to hover elevation at contact
  	      contact_altitude = altitude - vertical_offset - gear_height - hover_add;
  	      if (pitch_d > 0 or pitch_d < -0.5) {
  	         # If aircraft hits ground, then nose/tail gets thrown up
  	        if (asas > 500) {  # new pitch adjusted for airspeed
  	          var airspeed_pch = 0.2;
  	        } else {
  	          var airspeed_pch = asas / 500 * 0.2;
  	        }
  	        if (airspeed > 0.1) {
  	          if (pitch_d > 0) {
  	            # going uphill
  	            pitch_d = pitch_d * (1.0 + airspeed_pch);
  	            pitch_deg.setDoubleValue(pitch_d);
  	          } else {
  	            # nose down
  	            pitch_d = pitch_d * (1.0 - airspeed_pch);
  	            pitch_deg.setDoubleValue(pitch_d);
  	          }
  	        } elsif (airspeed < -0.1) {    # reverse direction
  	          if (pitch_d < 0) {  # uphill
  	            pitch_d = pitch_d * (1.0 + airspeed_pch);
  	            pitch_deg.setDoubleValue(pitch_d);
  	          } else {
  	            pitch_d = pitch_d * (1.0 - airspeed_pch);
  	            pitch_deg.setDoubleValue(pitch_d);
  	          }
  	        }
  	      }
  	    } else {  
  	      # smoothen to zero
  	      var skid_w2 = (skid_last_value) / 2;
  	    }
  	    if (skid_w2 < 0.001) {
  	      skid_w2 = 0;
  	    }
  	     # threshold for determining a damage Hit
  	    if (skid_w2 > 10 and asas > 100) {   
  	       # impact greater than 600 feet per second
  	      var dmg_factor = int(skid_w2 * 0.025 * (abs(pitch_d) * 0.011) + 1.0);  # vulnerability to impact
  	        # increasing number from 0.025 increases damage per hit
  	      if (dmg_factor < 1) {  # if impact, then at least one damage unit
  	        dmg_factor = 1;
  	      } else {
  	        var angle_of_damage_max = ((abs(pitch_d) * 0.67) + 30);
  	        if (dmg_factor > angle_of_damage_max) {  # maximum damage per major impact
  	          dmg_factor = angle_of_damage_max;
  	        }
  	      }
  	      var dmg = getprop("sim/model/bluebird/damage/hits-counter") + dmg_factor;
  	      setprop("sim/model/bluebird/damage/hits-counter", dmg);
  	      if (dmg > destruction_threshold) { 
  	        # set condition-red damage
  	        alert_switch_Node.setBoolValue(1);
  	        if (damage_blocker == 0) {
  	          damage_blocker = 1;
  	          damage_count += 1;
  	          settimer(reset_impact, 2);
  	          setprop("sim/model/bluebird/position/crash-wow", "true");
  	          settimer(reset_crash, 5);
  	          setprop("sim/model/bluebird/damage/major-counter", damage_count);
  	          strobe_switch.setValue(0);
  	          zNoseNode.setValue(2.4);
  	          setprop("sim/model/bluebird/systems/nacelle-L-venting", "true");
  	          setprop("sim/model/bluebird/systems/nacelle-R-venting", "true");
  	          set_cockpit(cockpitView);
  	          interior_lighting_update();
  	          if (int(100 * rand()) > 80 or dmg > (destruction_threshold * 1.5)) {  # 80% chance a nacelle is destroyed
  	            setprop("sim/model/bluebird/components/nacelle-L", 0);
  	            setprop("sim/model/bluebird/components/engine-cover1", 0);
  	            setprop("sim/model/bluebird/systems/nacelle-L-venting", "false");
  	            setprop("ai/submodels/engine-L-flaring", "true");
  	            if (int(100 * rand()) > 90 or dmg > (destruction_threshold * 2)) {  # how likely both were
  	              setprop("sim/model/bluebird/components/nacelle-R", 0);
  	              setprop("sim/model/bluebird/components/engine-cover4", 0);
  	              setprop("sim/model/bluebird/systems/nacelle-R-venting", "false");
  	              setprop("ai/submodels/engine-R-flaring", "true");
  	            }
  	          }
  	        }
  	      }
  	    }
  	    var skid_w_vol = skid_w2 * 0.1;  # factor for volume usage
  	    if (skid_w_vol > 1.0) {
  	      skid_w_vol = 1.0;
  	    }
  	    if (!damage_count and (skid_altitude_change < 5)) {
  	      if (abs(pitch_d) < 3.75) {
  	        skid_w_vol = skid_w_vol * (abs(pitch_d + 0.25)) * 0.25;
  	      }
  	    }
  	    setprop("sim/model/bluebird/position/skid-wow", skid_w_vol);
  	    skid_last_value = skid_w2;
  	  } else { 
  	    # not near ground, skipping hover
  	    setprop("sim/model/bluebird/position/skid-wow", 0);
  	    skid_last_value = 0;
  	    hover_add = 0;
  	    h_contact_target_alt = 0;
  	  }
  	  # update instrument warning lights if changed
  	  if (new_ground_near != ground_near) {
  	    if (new_ground_near) {
  	      setprop("sim/model/bluebird/lighting/ground-near", "true");
  	    } else {
  	      setprop("sim/model/bluebird/lighting/ground-near", "false");
  	    }
  	    ground_near = new_ground_near;
  	  }
  	  if (new_ground_warning != ground_warning) {
  	    setprop("sim/model/bluebird/lighting/ground-warning", new_ground_warning);
  	    ground_warning = new_ground_warning;
  	  }

  	   # ----- lose altitude -----
  	  if (damage_count > 0 or engines_lvl < 0.2 or power_switch == 0) {
  	    if ((contact_altitude - 0.0001) < h_contact_target_alt) {
  	      # already on/near ground
  	      if (lose_altitude > 0.2) {
  	        lose_altitude = 0.2;  # avoid bouncing by simulating gravity
  	      }
  	      if (!countergrav_request) {
  	        if (!reactor_request) {
  	          settle_to_level();
  	        }
  	      } else {
  	        lose_altitude = 0;
  	      }
  	    } else {
  	      # not on/near ground
  	      if (!(wave1_level and asas > 150)) {
  	        # Wave-guide off and not fast enough to fly without counter-grav
  	        lose_altitude += 0.01;
  	        if ((contact_altitude - h_contact_target_alt) < 3) {   # really close to ground but not below it
  	          if (!reactor_request) {
  	            settle_to_level();
  	          }
  	        }
  	      } else { # fast enough to fly without counter-grav
  	        lose_altitude = lose_altitude * 0.5;
  	        if (lose_altitude < 0.001) { lose_altitude = 0; }
  	      }
  	    }
  	    if (lose_altitude > 0) {
  	      hover_grav(-1, lose_altitude, 0);
  	    }
  	  } else {
  	    lose_altitude = 0;
  	  }

  	   # ----- also calculate altitude-agl since ufo model doesn't -----
  	  var aa = altitude - gnd_elev;
  	  setprop("sim/model/bluebird/position/shadow-alt-agl-ft", aa);  # shadow doesn't need adjustment for gear
  	  var agl = contact_altitude - gnd_elev + hover_add;
  	  setprop("sim/model/bluebird/position/altitude-agl-ft", agl);

  	   # ----- handle traveling backwards and update movement variables ------
  	   #       including updating sound based on airspeed
  	   # === speed up or slow down from engine level ===
  	  var max = maxspeed.getValue();
  	  if ((damage_count > 0) or
  	    (!nacelleL_attached and wave1_request > 0) or 
  	    (!nacelleR_attached and wave1_request > 0) or
  	    (!power_switch)) { 
  	    if (wave1_request) {   # deny Wave-guide drive request
  	      setprop("sim/model/bluebird/systems/wave1-request", "false");
  	      wave1_request = 0;
  	    }
  	    if (wave2_request) {
  	      setprop("sim/model/bluebird/systems/wave2-request", "false");
  	      wave2_request = 0;
  	    }
  	    if (damage_count > 2) {
  	      setprop("sim/model/bluebird/systems/reactor-request", "false");
  	      reactor_request = 0;
  	      setprop("sim/model/bluebird/systems/power-switch", "false");
  	    }
  	  }
  	  if (cpl > 6) {
  	    if (cpl > 10 and contact_altitude < 70000 and max_to > 10) {
  	      popupTip2("Entering lower atmosphere. Reducing speed");
  	      change_maximum(cpl, 10, 1); 
  	    } elsif (cpl > 9 and contact_altitude < 40000 and max_to > 9) {
  	      popupTip2("Entering lower atmosphere. Reducing speed");
  	      change_maximum(cpl, 9, 1); 
  	    } elsif (cpl > 8 and contact_altitude < 20000 and max_to > 8) {
  	      popupTip2("Entering lower atmosphere. Reducing speed");
  	      change_maximum(cpl, 8, 1); 
  	    } elsif (cpl > 7 and contact_altitude < 10000 and max_to > 7) {
  	      popupTip2("Entering lower atmosphere. Reducing speed");
  	      change_maximum(cpl, 7, 1); 
  	    }
  	  }
  	  if (!power_switch) {
  	    change_maximum(cpl, 0, 2);
  	    if (wave1_level) {
  	      setprop("sim/model/bluebird/systems/wave1-level", 0);
  	    }
  	    if (wave2_level) {
  	      wave2_level = 0;
  	    }
  	    if (agl > 10) {   # not in ground contact, glide
  	      max_lose = max_lose + (0.005 * abs(pitch_d));
  	    } else {     # rapid deceleration
  	      max_lose = asas * 0.2;
  	    }
  	    if (max_lose > 10) {  # don't decelerate too quickly
  	      if (agl > 10) {
  	        max_lose = 10;
  	      } else {
  	        if (max_lose > 75) {
  	          max_lose = 75;
  	        }
  	      }
  	    }
  	    max_drift = max_lose;
  	  } else {  # power is on
  	    if (reactor_request != reactor_level) {
  	      change_maximum(cpl, limit[(reactor_request + (wave1_level * 2) + (wave2_level * 4))] - damage_count, 2);
  	      setprop("sim/model/bluebird/systems/reactor-level", reactor_request);
  	    }
  	    if (wave1_request != wave1_level) {
  	      change_maximum(cpl, limit[(reactor_level + (wave1_request * 2) + (wave2_level * 4))] - damage_count, 2);
  	      setprop("sim/model/bluebird/systems/wave1-level", wave1_request);
  	    }
  	    if (wave2_request != wave2_level) {
  	      change_maximum(cpl, limit[(reactor_level + (wave1_level * 2) + (wave2_request * 4))] - damage_count, 2);
  	      wave2_level = wave2_request;
  	    }
  	  }
  	  if (max > 1 and max_to < max_from) {      # decelerate smoothly
  	    max -= (max_drift / 2);
  	    if (max <= speed_mps[max_to]) {     # destination reached
  	      cpl = max_to;
  	      max_from = max_to;
  	      max = speed_mps[max_to];
  	      max_drift = 0;
  	      max_lose = 0;
  	      if (!power_switch) {       # override if no power
  	        max = 1;
  	      }
  	    }
  	    maxspeed.setDoubleValue(max);
  	  }
  	  if (max_to > max_from) {         # accelerate
  	    if (current_to == max_to) {   # normal request to change power-maxspeed
  	      max += max_drift;
  	      if (max >= speed_mps[max_to]) { 
  	        # destination reached
  	        cpl = max_to;
  	        max_from = max_to;
  	        max = speed_mps[max_to];
  	        max_drift = 0;
  	        max_lose = 0;
  	      }
  	      maxspeed.setDoubleValue(max);
  	    } else {    # only change maximum, as when turning on an engine
  	      max_from = max_to;
  	      max_drift = 0;
  	      max_lose = 0;
  	      if (cpl == 0 and current_to == 0) {     # turned on power from a complete shutdown
  	        maxspeed.setDoubleValue(speed_mps[2]);
  	        current_to = max_to;
  	        cpl = 2;
  	      }
  	    }
  	  }
  	  current.setValue(cpl);

  	    # vtol control in cockpit yoke
  	  var rh_t = hover_reset_timer;
  	  if (rh_t > 0) {
  	    if (rh_t < 0.7) {
  	      var rh_x = (getprop("sim/model/bluebird/position/hover-rise") * 0.5);
  	      if (abs(rh_x) < 0.1) {
  	        setprop("sim/model/bluebird/position/hover-rise", 0);
  	        rh_t = 0.1;
  	      } else {
  	        setprop("sim/model/bluebird/position/hover-rise", rh_x);
  	      }
  	    }
  	    hover_reset_timer = rh_t - 0.1;
  	  }

  	    # === sound section based on position/airspeed/altitude ===
  	  var slv = sound_level;
  	  if (power_switch) {
  	    if (reactor_drift < 1 and slv > 1) {  # shutdown reactor before timer shutdown of standby power
  	      slv = 0.99;
  	    }
  	    if (asas < 1 and agl < 2 and !countergrav_request) {
  	      if (sound_state and slv > 0.999) {  # shutdown request by landing has 2.5 sec delay
  	        slv = 2.5;
  	      }
  	      sound_state = 0;
  	    } else {
  	      if (((reactor_state < reactor_drift) or (!reactor_state)) and asas < 5 and !countergrav_request) {  # countergrav shutdown
  	        sound_state = 0;
  	        countergrav_request = 0;
  	        if (slv >= 1) {
  	          slv = 0.99;
  	        }
  	      } else {
  	        if (asas > 5 or agl >= 2 or countergrav_request) {
  	          sound_state = 1;
  	        } else {
  	          sound_state = 0;
  	        }
  	      }
  	    }
  	  } else {
  	    if (sound_state) {  # power shutdown with reactor on. single entry.
  	      slv = 0.99;
  	      sound_state = 0;
  	      countergrav_request = 0;
  	    }
  	  }
  	  if (sound_state != slv) {  # ramp up reactor sound fast or down slow
  	    if (sound_state) { 
  	      slv += 0.02;
  	    } else {
  	      slv -= 0.00625;
  	    }
  	    if (sound_state and slv > 1.0) {  # bounds check
  	      slv = 1.000;
  	      countergrav_request = 0;
  	    }
  	    if (slv > 0.5 and countergrav_request > 0) {
  	      if (countergrav_request <= 1) {
  	        countergrav_request -= 0.025;  # reached sufficient power to turn off trigger
  	        slv -= 0.02;  # hold this level for a couple seconds until either another
  	         # keyboard/joystick request confirms startup, or time expires and shutdown
  	        if (countergrav_request < 0.1) {
  	          countergrav_request = 0;  # holding time expired
  	        }
  	      }
  	    }
  	    if (slv < 0.0) {
  	      slv = 0.000;
  	    }
  	    sound_level = slv;
  	  }

  	  var a1 = (asas * 0.0001);
  	  if (a1 < 0.1) {
  	    a1 = 0.1;
  	  }
  	  var a3 = (asas * 0.000187) + 0.25;
  	  if (a3 > 0.75) {
  	    a3 = ((asas - 4000) / 384000) + 0.75;
  	  }
  	  if (slv > 1.0) {    # timer to shutdown
  	    var a2 = a1;
  	    var a6 = 1;
  	  } else {      # shutdown progressing
  	    var a2 = a1 * slv;
  	    a3 = a3 * slv;
  	    var a6 = slv;
  	  }
  	  if (wave1_level) {
  	    if (asas > 1 or slv == 1.0 or slv > 2.0) {
  	      wave_state = (asas * 0.0004) + 0.2;
  	    } elsif (slv > 1.6) {
  	      wave_state = ((slv * 3) - 5) * ((asas * 0.0004) + 0.2);
  	    } else {
  	      wave_state = 0;
  	    }
  	  } else {
  	    wave_state = 0;
  	  }
  	  if (reactor_level) {
  	    if (damage_count) {
  	      reactor_state = a6 * 0.5;
  	    } else {
  	      reactor_state = a6;
  	    }
  	  } else {
  	    reactor_state = 0;
  	  }
  	  if (power_switch) {
  	    if (reactor_state > reactor_drift) {
  	      reactor_drift += 0.04;
  	      if (reactor_drift > reactor_state) {
  	        reactor_drift = reactor_state;
  	      }
  	    } elsif (reactor_state < reactor_drift) {
  	      if (reactor_level) {
  	        reactor_drift = reactor_state;
  	      } else {
  	        reactor_drift -= 0.02;
  	      }
  	    }
  	  } else {
  	    reactor_drift -= 0.02;
  	  }
  	  if (reactor_drift < 0) {  # bounds check
  	    reactor_drift = 0;
  	  }
  	  if (wave_state > wave_drift) {
  	    wave_drift += 0.1;
  	    if (wave_drift > wave_state) {
  	      wave_drift = wave_state;
  	    }
  	  } elsif (wave_state < wave_drift) {
  	    if (wave1_level) {
  	      wave_drift -= 0.1;
  	    } else {
  	      wave_drift -= 0.02;
  	    }
  	    if (wave_drift < wave_state) {
  	      wave_drift = wave_state;
  	    }
  	  }
  	  var a4 = wave_drift;
  	  if (a2 > 0.5) {
  	    a2 = 0.5;    # sound dampening
  	  }
  	  if (!reactor_level and !wave1_level) {
  	    a2 = a2 / 2;
  	  }
  	  if (a3 > 2.0) {  # upper limit of pitch factoring
  	    a3 = 2.0;
  	  }
  	  if (a4 > 1.75) {
  	    a4 = 1.75;
  	  }
  	  setprop("sim/model/bluebird/sound/engines-volume-level", a2);
  	  setprop("sim/model/bluebird/sound/pitch-level", a3);
  	  setprop("sim/model/bluebird/lighting/engine-glow", reactor_drift);
  	  if (!power_switch) {
  	    setprop("sim/model/bluebird/lighting/power-glow", reactor_drift);
  	  }
  	  if (reactor_level) {
  	    if (!reactor_drift and !power_switch and !slv) {
  	      setprop("sim/model/bluebird/systems/reactor-level", 0);
  	    }
  	  }
  	  setprop("sim/model/bluebird/lighting/wave-guide-glow", a4);
  	  var a7 = getprop("sim/model/bluebird/lighting/wave-guide-halo-spin");
  	  var a8 = a7 + (airspeed * 0.00017);
  	  if (a8 < 0) {
  	    a8 = abs(1 + a8);
  	  }
  	  a7 = abs(a8 - int(a8));
  	  setprop("sim/model/bluebird/lighting/wave-guide-halo-spin", a7);

  	  # nacelle venting
  	  if (venting_direction >= -1) {
  	    update_venting(0);
  	  }
  }
  settimer(update_main, 0);
}

# VTOL counter-grav functions ---------------------------------------

controls.elevatorTrim = func(et_d) {
  if (!et_d) {
    return;
  } else {
    var js1pitch = abs(joystick_elevator.getValue());
    if (et_d < 0) {
      hover_grav(-1, js1pitch, 1);
    } elsif (et_d > 0) {
      hover_grav(1, js1pitch, 1);
    }
  }
}

var reset_landing = func {
  setprop("sim/model/bluebird/position/landing-wow", "false");
}

setlistener("sim/model/bluebird/position/landing-wow", func {
  if (getprop("sim/model/bluebird/position/landing-wow")) {
    settimer(reset_landing, 0.4);
  }
 });

var reset_squeal = func {
  setprop("sim/model/bluebird/position/squeal-wow", "false");
}

setlistener("sim/model/bluebird/position/squeal-wow", func {
  if (getprop("sim/model/bluebird/position/squeal-wow")) {
    settimer(reset_squeal, 0.3);
  }
 });

var reset_crash = func {
  setprop("sim/model/bluebird/position/crash-wow", "false");
}

var hover_grav = func(hg_dir, hg_thrust, hg_mode) {  # d=direction p=thrust_power m=source of request
  var entry_altitude = altitude_ft_Node.getValue();
  var altitude = entry_altitude;
  contact_altitude = altitude - vertical_offset - gear_height - hover_add;
    # set counter-grav power level below here. default= *4
    # Future plan to link this multiplier to the collective lever next to the throttle.
  var hg_rise = hg_thrust * 4 * hg_dir;
  var contact_rise = contact_altitude + hg_rise;
  if (hg_dir < 0) {    # down requested by drift, fall, or VTOL down buttons
    if (contact_rise < h_contact_target_alt) {  # too low
      contact_rise = h_contact_target_alt + 0.0001;
      if ((contact_rise < contact_altitude) and !countergrav_request) {
        if (asas < 40) {  # ground contact by landing or falling fast
          if (lose_altitude > 0.2 or hg_rise < -0.5) {
            var already_landed = getprop("sim/model/bluebird/position/landing-wow");
            if (!already_landed) {
              setprop("sim/model/bluebird/position/landing-wow", "true");
            }
            lose_altitude = 0;
            if (!reactor_request) {
              settle_to_level();
            }
          } else {
            lose_altitude = lose_altitude * 0.5;
          }
        } elsif (lose_altitude > 0.26 and hg_rise < -1.1) {  # ground contact by skidding slowly
          setprop("sim/model/bluebird/position/squeal-wow", "true");
            lose_altitude = lose_altitude * 0.5;
          if (!reactor_request) {
            settle_to_level();
          }
        }
      } else {
        lose_altitude = lose_altitude * 0.5;
      }
    }
    if (!countergrav_request) {  # fall unless countergrav just requested
      altitude = contact_rise + vertical_offset + gear_height + hover_add;
      altitude_ft_Node.setDoubleValue(altitude);
      contact_altitude = contact_rise;
    }
  } elsif (hg_dir > 0) {  # up
    if (engines_lvl < 0.5 and reactor_level) {  # on standby, power up requested for hover up
      if (power_switch) {
        setprop("sim/model/bluebird/systems/reactor-request", "true");
        countergrav_request += 1;   # keep from forgetting until reactor powers up over 0.5
      }
    }
    if (engines_lvl > 0.2 and reactor_level) {  # sufficient power to comply and lift
      contact_rise = contact_altitude + (engines_lvl * hg_rise);
      altitude = contact_rise + vertical_offset + gear_height + hover_add;
      altitude_ft_Node.setDoubleValue(altitude);
      contact_altitude = contact_rise;
    }
  }
  if (hg_mode == 1) {  # keyboard or joystick request
    setprop("sim/model/bluebird/position/hover-rise", hg_rise);
    hover_reset_timer = 1.0;
  }
  if ((entry_altitude + hg_rise + 0.01) < altitude) {  # did not achieve full request. must've touched ground
    if (lose_altitude > 0.2) {
      lose_altitude = 0.2;
    }
  }
}

# keyboard and 3-d functions ----------------------------------------

var toggle_power = func(tp_mode) {
  if (tp_mode == 9) {  # clicked from dialog box
    if (!power_switch) {
      setprop("sim/model/bluebird/systems/reactor-request", "false");
      setprop("sim/model/bluebird/systems/wave1-request", "false");
    }
  } else {   # clicked from 3d-panel
    if (power_switch) {
      setprop("sim/model/bluebird/systems/power-switch", "false");
      setprop("sim/model/bluebird/systems/reactor-request", "false");
      setprop("sim/model/bluebird/systems/wave1-request", "false");
    } else {
      setprop("sim/model/bluebird/systems/power-switch", "true");
      setprop("sim/model/bluebird/lighting/power-glow", 1);
    }
  }
  interior_lighting_update();
}

var toggle_fusion = func {
  if (reactor_request) {
    setprop("sim/model/bluebird/systems/reactor-request", "false");
  } else {
    if (power_switch) {
      setprop("sim/model/bluebird/systems/reactor-request", "true");
    } else {
      popupTip2("Unable to comply. Main power is off.");
    }
  }
  settimer(panel_lighting_loop, 0.05);
}

var toggle_wave1 = func {
  if (wave1_request) {
    setprop("sim/model/bluebird/systems/wave1-request", "false");
  } else {
    if (power_switch) {
      setprop("sim/model/bluebird/systems/wave1-request", "true");
    } else {
      popupTip2("Unable to comply. Main power is off.");
    }
  }
  settimer(panel_lighting_loop, 0.05);
}

var toggle_wave2 = func {
  if (wave2_request) {
    setprop("sim/model/bluebird/systems/wave2-request", "false");
  } else {
    if (power_switch) {
      if (wave1_request) {
        setprop("sim/model/bluebird/systems/wave2-request", "true");
      } else {
        popupTip2("Unable to comply. Wave-guide drive is off.");
      }
    } else {
      popupTip2("Unable to comply. Main power is off.");
    }
  }
  settimer(panel_lighting_loop, 0.05);
}

var toggle_lighting = func(tl_button_num) {
  if (tl_button_num == 5) {
    if (landing_light_switch.getValue() == 2) {
      landing_light_switch.setValue(0);
    } elsif (landing_light_switch.getValue() == 0) {
      landing_light_switch.setValue(1);
    } else {
      landing_light_switch.setValue(2);
    }
  } elsif (tl_button_num == 6) {
    set_nav_lights(-1);
  } elsif (tl_button_num == 7) {
    if (beacon_switch.getValue()) {
      beacon_switch.setBoolValue(0);
    } else {
      beacon_switch.setBoolValue(1);
    }
  } elsif (tl_button_num == 8) {
    if (strobe_switch.getValue()) {
      strobe_switch.setBoolValue(0);
    } else {
      strobe_switch.setBoolValue(1);
    }
  } elsif (tl_button_num == 9) {
    if (int_switch) {
      int_switch = 0;
    } else {
      int_switch = 1;
    }
    setprop("sim/model/bluebird/lighting/interior-switch", int_switch);
    interior_lighting_update();
  }
  settimer(panel_lighting_loop, 0.05);
}

var delayed_panel_update = func {
  if (!power_switch) {
    setprop("sim/model/bluebird/systems/reactor-request", "false");
    setprop("sim/model/bluebird/systems/wave1-request", "false");
    setprop("sim/model/bluebird/systems/wave2-request", "false");
    popupTip2("Unable to comply. Main power is off.");
  } else {
    settimer(panel_lighting_loop, 0.1);
  }
}

var set_cockpit = func(cockpitPosition) {
  if (getprop("sim/current-view/view-number") == 0) {
    if (cockpitPosition > 2) { cockpitPosition = 0; }
    if (cockpitPosition < 0) { cockpitPosition = 2; }
    if (cockpitPosition == 0) {
      if (getprop("sim/current-view/view-number") == 0) {
        setprop("sim/current-view/x-offset-m", 0.0);
        if (damage_count == 0) {
          setprop("sim/current-view/z-offset-m", -7.35);
          setprop("sim/current-view/y-offset-m", 1.47);
        } else {
          setprop("sim/current-view/z-offset-m", -7.6);
          if (damage_count == 1) {
            setprop("sim/current-view/y-offset-m", 1.70);
          } else {
            setprop("sim/current-view/y-offset-m", 1.83);
          }
        }
      }
    } elsif (cockpitPosition == 1) {
      if (getprop("sim/current-view/view-number") == 0) {
        setprop("sim/current-view/x-offset-m", 0.0);
        setprop("sim/current-view/z-offset-m", -5.8);
        if (damage_count == 0) {
          setprop("sim/current-view/y-offset-m", 2.1);
        } elsif (damage_count == 1) {
          setprop("sim/current-view/y-offset-m", 2.33);
        } else {
          setprop("sim/current-view/y-offset-m", 2.47);
        }
      }
    } else {
      if (getprop("sim/current-view/view-number") == 0) {
        setprop("sim/current-view/x-offset-m", 0.0);
        setprop("sim/current-view/z-offset-m", -3.3);
        if (damage_count == 0) {
          setprop("sim/current-view/y-offset-m", 2.1);
        } elsif (damage_count == 1) {
          setprop("sim/current-view/y-offset-m", 2.32);
        } else {
          setprop("sim/current-view/y-offset-m", 2.43);
        }
      }
    }
    cockpitView = cockpitPosition;
  }
}

var cycle_cockpit = func(cc_i) {
  cockpitView += cc_i;
  set_cockpit(cockpitView);
}

var walk_about = func(wa_distance) {
  if (getprop("sim/current-view/view-number") == 0) {
    var wa_heading_rad = hViewNode.getValue() * 0.01745329252;
    var new_x_position = xViewNode.getValue() - (math.cos(wa_heading_rad) * wa_distance);
    var new_y_position = yViewNode.getValue() - (math.sin(wa_heading_rad) * wa_distance);
    xViewNode.setValue(new_x_position);
    yViewNode.setValue(new_y_position);
  }
}

# dialog functions --------------------------------------------------

var set_nav_lights = func(snl_i) {
  var snl_new = nav_light_switch.getValue();
  if (snl_i == -1) {
    snl_new += 1;
    if (snl_new > 2) {
      snl_new = 0;
    }
  } else {
    snl_new = snl_i;
  }
  nav_light_switch.setValue(snl_new);
  active_nav_button = [ 3, 3, 3];
  if (snl_new == 0) {
    active_nav_button[0]=1;
  } elsif (snl_new == 1) {
    active_nav_button[1]=1;
  } else {
    active_nav_button[2]=1;
  }
  nav_lighting_update();
}

var set_landing_lights = func(sll_i) {
  var sll_new = landing_light_switch.getValue();
  if (sll_i == -1) {
    sll_new += 1;
    if (sll_new > 2) {
      sll_new = 0;
    }
  } else {
    sll_new = sll_i;
  }
  landing_light_switch.setValue(sll_new);
  active_landing_button = [ 3, 3, 3];
  if (sll_new == 0) {
    active_landing_button[0]=1;
  } elsif (sll_new == 1) {
    active_landing_button[1]=1;
  } else {
    active_landing_button[2]=1;
  }
  nav_lighting_update();
}

var toggle_venting_both = func {
  if (nacelle_L_venting) {
    setprop("sim/model/bluebird/systems/nacelle-R-venting", "true");
  } else {
    setprop("sim/model/bluebird/systems/nacelle-R-venting", "false");
  }
}

var reloadDialog = func {
  name = "bluebird-config";
  interior_lighting_update();
  if (config_dialog != nil) {
    fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
    config_dialog = nil;
    showDialog();
    return;
  }
}

var showDialog = func {
  name = "bluebird-config";
  if (config_dialog != nil) {
    fgcommand("dialog-close", props.Node.new({ "dialog-name" : name }));
    config_dialog = nil;
    return;
  }

  config_dialog = gui.Widget.new();
  config_dialog.set("layout", "vbox");
  config_dialog.set("name", name);
  config_dialog.set("x", -40);
  config_dialog.set("y", -40);

 # "window" titlebar
  titlebar = config_dialog.addChild("group");
  titlebar.set("layout", "hbox");
  titlebar.addChild("empty").set("stretch", 1);
  titlebar.addChild("text").set("label", "Bluebird Explorer configuration");
  titlebar.addChild("empty").set("stretch", 1);

  config_dialog.addChild("hrule").addChild("dummy");

  w = titlebar.addChild("button");
  w.set("pref-width", 16);
  w.set("pref-height", 16);
  w.set("legend", "");
  w.set("default", 1);
  w.set("keynum", 27);
  w.set("border", 1);
  w.prop().getNode("binding[0]/command", 1).setValue("nasal");
  w.prop().getNode("binding[0]/script", 1).setValue("bluebird.config_dialog = nil");
  w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

  var checkbox = func {
    group = config_dialog.addChild("group");
    group.set("layout", "hbox");
    group.addChild("empty").set("pref-width", 4);
    box = group.addChild("checkbox");
    group.addChild("empty").set("stretch", 1);

    box.set("halign", "left");
    box.set("label", arg[0]);
    box;
  }

 # master power switch
  w = checkbox("master power");
  w.set("property", "sim/model/bluebird/systems/power-switch");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.toggle_power(9)");

 # fusion reactor and countergrav glow
  w = checkbox("countergrav fusion reactor");
  w.set("property", "sim/model/bluebird/systems/reactor-request");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.delayed_panel_update()");

 # Wave-guide drive glow and halos
  w = checkbox("Primary wave-guide engine");
  w.set("property", "sim/model/bluebird/systems/wave1-request");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.delayed_panel_update()");

 # for orbital velocities
  w = checkbox("Enable upper atmosphere velocities");
  w.set("property", "sim/model/bluebird/systems/wave2-request");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.delayed_panel_update()");

  config_dialog.addChild("hrule").addChild("dummy");

 # lights
  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);
  w = g.addChild("text");
  w.set("halign", "left");
  w.set("label", "nav lights:");
  g.addChild("empty").set("stretch", 1);

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);

  box = g.addChild("button");
  g.addChild("empty").set("stretch", 1);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 100);
  box.set("pref-height", 18);
  box.set("legend", "Stay On");
  box.set("border", active_nav_button[2]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_nav_lights(2)");
  box.prop().getNode("binding[1]/command", 1).setValue("nasal");
  box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog()");
  box;

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 130);
  box.set("pref-height", 18);
  box.set("legend", "Dusk to Dawn");
  box.set("border", active_nav_button[1]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_nav_lights(1)");
  box.prop().getNode("binding[1]/command", 1).setValue("nasal");
  box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog()");
  box;

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 50);
  box.set("pref-height", 18);
  box.set("legend", "Off");
  box.set("border", active_nav_button[0]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_nav_lights(0)");
  box.prop().getNode("binding[1]/command", 1).setValue("nasal");
  box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog()");
  box;

  w = checkbox("beacons");
  w.set("property", "controls/lighting/beacon");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

  w = checkbox("strobes");
  w.set("property", "controls/lighting/strobe");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);
  w = g.addChild("text");
  w.set("halign", "left");
  w.set("label", "landing lights:");
  g.addChild("empty").set("stretch", 1);

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);

  box = g.addChild("button");
  g.addChild("empty").set("stretch", 1);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 100);
  box.set("pref-height", 18);
  box.set("legend", "Stay On");
  box.set("border", active_landing_button[2]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_landing_lights(2)");
  box.prop().getNode("binding[1]/command", 1).setValue("nasal");
  box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog()");
  box;

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 130);
  box.set("pref-height", 18);
  box.set("legend", "Dusk to Dawn");
  box.set("border", active_landing_button[1]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_landing_lights(1)");
  box.prop().getNode("binding[1]/command", 1).setValue("nasal");
  box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog()");
  box;

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 50);
  box.set("pref-height", 18);
  box.set("legend", "Off");
  box.set("border", active_landing_button[0]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_landing_lights(0)");
  box.prop().getNode("binding[1]/command", 1).setValue("nasal");
  box.prop().getNode("binding[1]/script", 1).setValue("bluebird.reloadDialog()");
  box;

 # interior
  w = checkbox("interior lights");
  w.set("property", "sim/model/bluebird/lighting/interior-switch");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.nav_lighting_update()");
  w.prop().getNode("binding[2]/command", 1).setValue("nasal");
  w.prop().getNode("binding[2]/script", 1).setValue("bluebird.reloadDialog()");

 # red-alert and damage
  w = checkbox("Condition Red");
  w.set("property", "controls/lighting/alert");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

  config_dialog.addChild("hrule").addChild("dummy");

 # landing gear mode
  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);
  w = g.addChild("text");
  w.set("halign", "left");
  w.set("label", "Landing Gear deployment mode:");
  g.addChild("empty").set("stretch", 1);

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);

  box = g.addChild("button");
  g.addChild("empty").set("stretch", 1);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 150);
  box.set("pref-height", 18);
  box.set("legend", "Extend fully");
  box.set("border", active_gear_button[0]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.toggle_gear_mode(0)");
  box;

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 150);
  box.set("pref-height", 18);
  box.set("legend", "Cargo loading");
  box.set("border", active_gear_button[1]);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.toggle_gear_mode(1)");
  box;

  w = checkbox("Wheels down");
  w.set("property", "sim/model/bluebird/systems/gear-wheels-request");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

  config_dialog.addChild("hrule").addChild("dummy");

  w = checkbox("Black opaque windows");
  w.set("property", "sim/model/bluebird/lighting/window-opaque");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.nav_lighting_update()");
  w.prop().getNode("binding[2]/command", 1).setValue("nasal");
  w.prop().getNode("binding[2]/script", 1).setValue("bluebird.reloadDialog()");

  w = checkbox("Simple 2D shadow");
  w.set("property", "sim/model/bluebird/shadow");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");

 # venting/contrails
  w = checkbox("Nacelle venting/contrails");
  w.set("property", "sim/model/bluebird/systems/nacelle-L-venting");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w.prop().getNode("binding[1]/command", 1).setValue("nasal");
  w.prop().getNode("binding[1]/script", 1).setValue("bluebird.toggle_venting_both()");

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);
  w = g.addChild("text");
  w.set("halign", "left");
  w.set("label", "Reactor maintenance covers:");
  w = g.addChild("checkbox");
  w.set("halign", "left");
  w.set("label", "");
  w.set("property", "sim/model/bluebird/components/engine-cover1");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w = g.addChild("checkbox");
  w.set("halign", "left");
  w.set("label", "");
  w.set("property", "sim/model/bluebird/components/engine-cover2");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w = g.addChild("checkbox");
  w.set("halign", "left");
  w.set("label", "");
  w.set("property", "sim/model/bluebird/components/engine-cover3");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  w = g.addChild("checkbox");
  w.set("halign", "left");
  w.set("label", "");
  w.set("property", "sim/model/bluebird/components/engine-cover4");
  w.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
  g.addChild("empty").set("stretch", 1);

  config_dialog.addChild("hrule").addChild("dummy");

 # walk around cabin
  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 4);
  w = g.addChild("text");
  w.set("halign", "left");
  w.set("label", "Move around cockpit:");
  g.addChild("empty").set("stretch", 1);

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("pref-width", 40);
  w = g.addChild("text");
  w.set("halign", "left");
  w.set("label", "Jump to:");
  g.addChild("empty").set("stretch", 1);

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 130);
  box.set("pref-height", 19);
  box.set("legend", "Pilot's chair");
  box.set("border", 3);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(0)");
  box;

  g = config_dialog.addChild("group");
  g.set("layout", "hbox");
  g.addChild("empty").set("stretch", 1);

  box = g.addChild("button");
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 130);
  box.set("pref-height", 19);
  box.set("legend", "Behind pilot");
  box.set("border", 3);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(1)");
  box;

  box = g.addChild("button");
  g.addChild("empty").set("pref-width", 4);
  box.set("halign", "left");
  box.set("label", "");
  box.set("pref-width", 130);
  box.set("pref-height", 19);
  box.set("legend", "Between doors");
  box.set("border", 3);
  box.prop().getNode("binding[0]/command", 1).setValue("nasal");
  box.prop().getNode("binding[0]/script", 1).setValue("bluebird.set_cockpit(2)");
  box;

 # finale
  config_dialog.addChild("empty").set("pref-height", "3");
  fgcommand("dialog-new", config_dialog.prop());
  gui.showDialog(name);
}

#==========================================================================
#                 === initial calls at startup ===
 setlistener("sim/signals/fdm-initialized", func {

 update_main();  # starts continuous loop
 settimer(interior_lighting_loop, 0.25);
 settimer(interior_lighting_update, 0.5);
 settimer(nav_light_loop, 0.5);

 print ("Bluebird Explorer Flyer  by Stewart Andreason");
 print ("  version 5.0  release date 2008.Jan.19 for FlightGear 1.0");
});
Read this First:
After unzipping this file into your $FGBASE/data/Aircraft directory,
Choose your aircraft:
 start Flightgear with the following parameter:

If you are running FlightGear version 0.9.10
--aircraft=bluebird-09

If you are running FlightGear version 1.0 (with Plib)
--aircraft=bluebird

If you are running FlightGear OSG version:
--aircraft=bluebird-osg
which only works with FG cvs built with Openscenegraph, and osgview option.

After the simulator starts up, you are powered up and ready to throttle up.
Press [?] for help with keyboard shortcuts.

-------------------------------------------------
2008 by Stewart Andreason for FlightGear

Release version 6.4   2008.May.20
   23337 vertices, 19664 polygon faces, 427 objects (in primary model)

Send Suggestions? Comments? Problems? or Encouragement to:
  sandreas41 <at> yahoo <dot> com
Stay current with latest version. This model came from: 
  http://seahorse.10gbfreehost.com/flightgear_aircraft.html

Highlights in this model:
  Hover capable
    Counter-Grav or Turbo-Fan (you imagine the technology)
  Capable of Orbital velocities
    (but remember FlightGear is for flying near the ground, not in space)  :)
    Trans-oceanic flights in minutes.
  Variable Interior lighting at night.
  Digital cockpit.
  Lots of buttons and lights in cockpit.
  Varying flight modes with different combinations of engines when
    one or the other is turned off.
  Crashing can degrade performance until you blow the nacelles off.
    New venting and sparking effects.
    After the 3rd crash, you will have to make repairs (and reset)
  Large cockpit with unobstructed view.
  Landing Gear has 4 deployment modes.
  Open hatches respond to gear height.
  Landing lights and nav lights have "On at Dusk" and "Stay On" modes.
  Windows can be polarized.
  Plenty of glows and sound effects.
  Customizable color and/or textures for most surfaces.
    To create new colors or apply images to the fuselage,
    Create a new file in the Models/Liveries directory by copying an existing one,
     then change the colors as desired.
    See the livery-template.rgb file in the Models/Textures directory, edit with
     an editor capable of writing SGI and RGB files (like GIMP)
     Draw in the non-black areas, following the dots that correspond to the 
     fuselage surface, then save as a new filename.RGB

  Capable of walking around cockpit and around aircraft,
   out the doors or hatches to ground, 
   or jump when airborne like a sky diver.
  Free fall with or without a parachute at terminal velocity.

  Support for next OSG version:
     start with aircraft=bluebird-osg
  Compatibility with previous Flightgear version 0.9.10:
     start with aircraft=bluebird-09

Current development level is: Early-Production
 All significant bugs within my model are (believed to be) fixed.
 Some further development is always likely or unavoidable.

 Wish list:  Synchronize door sounds when gear is not down fully.
              sound.xml seems limited in select and property conditions.

 Known bugs that seem to be unique to the ufo flight model:
             Looped sounds stay off until forward trottle.
               Have made a workaround to get rumble sound on at startup with hover.
             Flight controls (throttle, elevator, roll)
               still work after a power shutdown.
             Standard Attitude indicator does not work. 
               ufo model writes "power off" numbers to standard location.
                 workaround is in place, see ufo-ai.xml
             Can not land or drive on hills. Flight attitude is hard linked to 
               joystick controls.


 ___________ This model is released under the terms of the GPLv2 ___________
 #    This program is free software; you can redistribute it and/or modify  #
 #    it under the terms of the GNU General Public License as published by  #
 #    the Free Software Foundation; either version 2 of the License, or     #
 #    (at your option) any later version.                                   #
 #                                                                          #
 #    This program is distributed in the hope that it will be useful,       #
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
 #    GNU General Public License for more details.                          #
 ---------------------------------------------------------------------------

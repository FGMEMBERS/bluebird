# == walking functions for FlightGear versions 1.0 and OSG == version 2.1 ==

setlistener("sim/walker/walking", func {
	var wdir = getprop("sim/walker/walking");
	if (wdir) {	# repetitive input or bug in mod-up keeps triggering
		walk_dir = wdir;	# remember current direction
		if (walk_watch == 0) {
			walk_watch = 3;	# start or reset timer for countdown
			momentum_walk();	# starting from rest, start new loop
		} else {
			walk_watch = 3;	# reset watcher
		}
	} else {
		# last heard was zero
		walk_watch -= 1;
		if (walk_watch < 0) {
			walk_watch = 0;
		}
	}
});

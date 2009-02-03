# == walking functions v3.0 for FlightGear versions 1.0 and OSG == version 8.8 ==

setlistener("sim/current-view/view-number", func {
	if (getprop("sim/current-view/view-number") == view.indexof("Walk View")) {
		yViewNode.setValue(0);
		zViewNode.setValue(2.0);	# matches person height when inside due to aircraft offsets
		xViewNode.setValue(0);
	}
});

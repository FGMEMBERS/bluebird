# == walking functions v3.11 for FlightGear versions 1.0 and OSG == version 8.9 ==

setlistener("sim/current-view/view-number", func(n) {
	if (n.getValue() == view.indexof("Walk View")) {
		yViewNode.setValue(0);
		zViewNode.setValue(2.0);	# matches person height when inside due to aircraft offsets
		xViewNode.setValue(0);
	}
});

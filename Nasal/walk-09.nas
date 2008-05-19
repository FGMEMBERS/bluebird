# ===== walking functions for FlightGear version 0.9.10 ===== version 2.1 =====
# ===== outside walker is not supported =====
# == customized for Bluebird Explorer Hovercraft  version 6.27 =====

setlistener("sim/walker/walking", func {
	var c_view = getprop ("sim/current-view/view-number");
	if (c_view == 0) {
		# inside aircraft
		bluebird.walk_about_cabin(getprop ("sim/walker/walking")* 0.1);
	}
});

var get_out = func (loc) {
	gui.popupTip("Can not go outside. Please upgrade to FlightGear version 1.0 or newer.");

}

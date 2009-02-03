# == pilot animation v1.1 for FlightGear version 1.9 with OSG ==
# ===== for Bluebird Explorer Hovercraft version 8.8 =====

var walker0Node = props.globals.getNode("sim/model/walker[0]", 1);
var animateNode = props.globals.getNode("sim/model/walker[0]/animate", 1);
var listNode = props.globals.getNode("sim/model/walker[0]/animate/list", 1);
var sequenceNode = listNode.getNode("sequence[" ~ animateNode.getNode("sequence-selected", 1).getValue() ~ "]", 1);
#var triggered_seqNode = nil;
var seqNode_now = nil;
var content_modified = props.globals.getNode("sim/gui/dialogs/position-modified", 1);
var pilot_dialog1 = nil;
var pilot_dialog2 = nil;
var sequence_count = 0;
var position_count = 0;
var anim_enabled = 0;
#var anim_running = 0;
#var triggers_enabled = 0;
#var triggers_list = [];
var animate_time_start = 0;
var animate_current_position = 0.0;
var animate_time_length = 0.0;
var loop_enabled = 0;
var loop_to = 0;
var loop_start_sec = 0.0;
var loop_length_sec = 0.0;
var time_chart = [];
var am_L_id = nil;

var interpolate_limb = func (a, b, p) {
	if (a == nil or b == nil or p == nil){
		print ("Undefined input error at pilot-animate.interpolate_limb a= ",a," b= ",b," p= ",p);
	} else {
		return (a + ((b - a) * p));
	}
}

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var gui_listNode = props.globals.getNode("/sim/gui/dialogs/anim-sequence", 1);
if (gui_listNode.getNode("list", 1) == nil)
	gui_listNode.getNode("list", 1).setValue("");

gui_listNode = gui_listNode.getNode("list", 1);
var listbox_apply = func {
	var id = pop(split(" ",gui_listNode.getValue()));
	id = substr(id, 1, size(id) - 2);  # strip parentheses
	setprop("sim/model/walker[0]/animate/sequence-selected", int(id));
	sequenceNode = listNode.getNode("sequence[" ~ int(animateNode.getNode("sequence-selected", 1).getValue()) ~ "]", 1);
}

var apply = func {
	return gui_listNode.getValue();
}

var sequence = {
	new_animation:	func (name) {
		if (pilot_dialog2 != nil) {
			fgcommand("dialog-close", props.Node.new({ "dialog-name" : "pilot-config" }));
			pilot_dialog2 = nil;
			return;
		}
		var s = "";
		for (var i = 0; i < size(name); i += 1) {
			if (string.isascii(name[i]) and (!string.ispunct(name[i]) or chr(name[i]) == 95)) {
				s ~= chr(name[i]);
			}
		}
		s = string.trim(s, 0);
		if (s == nil or s == "" or s == " ") {
			return 0;
		}
		var new_sequence = props.globals.getNode("sim/model/walker[0]/animate/list/sequence[" ~ size(listNode.getChildren("sequence")) ~ "]", 1);
		sequence_count = size(listNode.getChildren("sequence"));
		setprop("sim/model/walker[0]/animate/sequence-selected", int(sequence_count - 1));
		sequenceNode = new_sequence;
		new_sequence.getNode("name", 1).setValue(s);
		new_sequence.getNode("loop-enabled", 1).setBoolValue("false");
		new_sequence.getNode("loop-to", 1).setIntValue(0);
#		new_sequence.getNode("trigger-upon", 1).setValue("Disabled");
	},
	edit_animation:	func {
		sequenceNode = listNode.getNode("sequence[" ~ int(animateNode.getNode("sequence-selected", 1).getValue()) ~ "]", 1);
		position_count = size(sequenceNode.getChildren("position"));
		if (position_count == 0) {
			animate.reset_position();
			setprop("sim/model/walker[0]/animate/dialog-position", -1);
		} else {
			setprop("sim/model/walker[0]/animate/dialog-position", 0);
			animate.copy_position(sequenceNode.getNode("position[0]", 1), walker0Node);
			walker0Node.getNode("loop-enabled", 1).setBoolValue(sequenceNode.getNode("loop-enabled", 1).getValue());
			walker0Node.getNode("loop-to", 1).setIntValue(sequenceNode.getNode("loop-to", 1).getValue());
#			walker0Node.getNode("trigger-upon", 1).setValue(sequenceNode.getNode("trigger-upon", 1).getValue());
		}
		setprop("sim/model/walker[0]/animate/enabled-current", 0);
#		setprop("sim/model/walker[0]/animate/enabled-triggers", 0);
		fgcommand("dialog-close", props.Node.new({ "dialog-name" : "pilot-sequences" }));
		pilot_dialog1 = nil;
		animate.showDialog();
	},
	load_animation:	func {
		var load_sel = nil;
		var load = func(n) {
			print ("Loading from ",n.getValue());
			var new_sequence = props.globals.getNode("sim/model/walker[0]/animate/list/sequence[" ~ size(listNode.getChildren("sequence")) ~ "]", 1);
			io.read_properties(n.getValue(), new_sequence);
			var s = new_sequence.getNode("name", 1).getValue();
			if (s != nil) {
				sequenceNode = new_sequence;
				sequence_count = size(listNode.getChildren("sequence"));
				setprop("sim/model/walker[0]/animate/sequence-selected", int(sequence_count - 1));
				sequence.reloadDialog();
			} else {
				listNode.removeChild("sequence", (size(listNode.getChildren("sequence")) - 1));
			}
		}
		load_sel = gui.FileSelector.new(load, "Load Pilot Sequence", "Load",
			["pilot-*.xml"], getprop("/sim/fg-home") ~ "/aircraft-data", "");
		load_sel.open();
	},
	save_animation:	func {
		var data_path = getprop("/sim/fg-home") ~ "/aircraft-data/pilot-" ~ sequenceNode.getNode("name", 1).getValue() ~ ".xml";
		print ("Saving to ",data_path);
		io.write_properties(data_path, sequenceNode);
	},
	showDialog: func {
		var name1 = "pilot-sequences";
		if (pilot_dialog1 != nil) {
			fgcommand("dialog-close", props.Node.new({ "dialog-name" : name1 }));
			pilot_dialog1 = nil;
			return;
		}

		pilot_dialog1 = gui.Widget.new();
		pilot_dialog1.set("layout", "vbox");
		pilot_dialog1.set("name", name1);
		pilot_dialog1.set("x", -40);
		pilot_dialog1.set("y", -40);

		# "window" titlebar
		titlebar = pilot_dialog1.addChild("group");
		titlebar.set("layout", "hbox");
		titlebar.addChild("empty").set("stretch", 1);
		titlebar.addChild("text").set("label", "Pilot posing animations");
		titlebar.addChild("empty").set("stretch", 1);

		w = titlebar.addChild("button");
		w.set("pref-width", 16);
		w.set("pref-height", 14);
		w.set("legend", "");
		w.set("keynum", 27);
		w.set("border", 1);
		w.prop().getNode("binding[0]/command", 1).setValue("nasal");
		w.prop().getNode("binding[0]/script", 1).setValue("pilot.pilot_dialog1 = nil");
		w.prop().getNode("binding[1]/command", 1).setValue("dialog-close");

		pilot_dialog1.addChild("hrule").addChild("dummy");

		var g = pilot_dialog1.addChild("group");
		g.set("layout", "hbox");
		g.addChild("empty").set("pref-width", 8);
		var content = g.addChild("input");
		content.set("name", "input");
		content.set("layout", "hbox");
		content.set("halign", "fill");
		content.set("border", 1);
		content.set("editable", 1);
		content.set("property", "/sim/gui/dialogs/anim-sequence/list");
		content.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		content.prop().getNode("binding[0]/object-name", 1).setValue("input");
		content.prop().getNode("binding[1]/command", 1).setValue("dialog-update");
		content.prop().getNode("binding[1]/object-name", 1).setValue("sequence-list");
		var box2 = g.addChild("button");
		box2.set("halign", "left");
		box2.set("label", "");
		box2.set("pref-width", 50);
		box2.set("pref-height", 18);
		box2.set("border", 2);
		box2.set("legend", "New");
		box2.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box2.prop().getNode("binding[0]/object-name", 1).setValue("input");
		box2.prop().getNode("binding[1]/command", 1).setValue("nasal");
		box2.prop().getNode("binding[1]/script", 1).setValue("pilot.sequence.new_animation(pilot.apply())");
		box2.prop().getNode("binding[2]/command", 1).setValue("dialog-update");
		box2.prop().getNode("binding[2]/object-name", 1).setValue("sequence-list");
		box2.prop().getNode("binding[3]/command", 1).setValue("nasal");
		box2.prop().getNode("binding[3]/script", 1).setValue("pilot.sequence.reloadDialog()");
		box2.prop().getNode("binding[4]/command", 1).setValue("nasal");
		box2.prop().getNode("binding[4]/script", 1).setValue("pilot.sequence.edit_animation()");
		g.addChild("empty").set("stretch", 1);

		var a = pilot_dialog1.addChild("list");
		a.set("name", "sequence-list");
		a.set("pref-width", 300);
		a.set("pref-height", 160);
		a.set("slider", 18);
		a.set("property", "/sim/gui/dialogs/anim-sequence/list");
		sequence_count = size(listNode.getChildren("sequence"));
		var sList = [];
		for (var i = 0 ; i < sequence_count ; i += 1) {
			var name_in = listNode.getNode("sequence[" ~ i ~ "]", 1).getNode("name", 1).getValue();
			if (name_in != nil) {
				append(sList, { index: i , name: name_in,
					comb: listNode.getNode("sequence[" ~ i ~ "]", 1).getNode("name", 1).getValue() ~ " (" ~ i ~ ")" });
			}
		}
		sList = sort(sList, func(a,b) {cmp(a.name, b.name)});
		for (var i = 0 ; i < size(sList) ; i += 1) {
			a.set("value[" ~ i ~ "]", sList[i].comb);
		}
		a.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		a.prop().getNode("binding[0]/object-name", 1).setValue("sequence-list");
		a.prop().getNode("binding[1]/command", 1).setValue("nasal");
		a.prop().getNode("binding[1]/script", 1).setValue("pilot.listbox_apply()");

		var g = pilot_dialog1.addChild("group");
		g.set("layout", "hbox");
		g.addChild("empty").set("pref-width", 8);
		var box2 = g.addChild("button");
		box2.set("halign", "left");
		box2.set("label", "");
		box2.set("pref-width", 60);
		box2.set("pref-height", 18);
		box2.set("border", 2);
		box2.set("default", 1);
		box2.set("legend", "Edit/Run");
		box2.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box2.prop().getNode("binding[0]/script", 1).setValue("pilot.sequence.edit_animation()");
		g.addChild("empty").set("stretch", 1);

		g.addChild("empty").set("pref-width", 8);
		g.addChild("text").set("label", "File:");
		var box4 = g.addChild("button");
		box4.set("halign", "right");
		box4.set("legend", "Load");
		box4.set("pref-width", 50);
		box4.set("pref-height", 18);
		box4.set("border", 2);
		box4.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box4.prop().getNode("binding[0]/script", 1).setValue("pilot.sequence.load_animation()");
		var box5 = g.addChild("button");
		box5.set("halign", "right");
		box5.set("legend", "Save");
		box5.set("pref-width", 50);
		box5.set("pref-height", 18);
		box5.set("border", 2);
		box5.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box5.prop().getNode("binding[0]/script", 1).setValue("pilot.sequence.save_animation()");
		g.addChild("empty").set("pref-width", 8);

#		pilot_dialog1.addChild("hrule").addChild("dummy");
#		var g = pilot_dialog1.addChild("group");
#		g.set("layout", "hbox");
#		g.addChild("empty").set("pref-width", 8);
#		var box = g.addChild("checkbox");
#		box.set("halign", "left");
#		box.set("live", "true");
#		box.set("label", "Enable animations upon Trigger");
#		box.set("property", "sim/model/walker[0]/animate/enabled-triggers");
#		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
#		g.addChild("empty").set("stretch", 1);

		# finale
		pilot_dialog1.addChild("empty").set("pref-height", "3");
		fgcommand("dialog-new", pilot_dialog1.prop());
		gui.showDialog(name1);
	},
	reloadDialog: func {
		if (pilot_dialog1 != nil) {
			fgcommand("dialog-close", props.Node.new({ "dialog-name" : "pilot-sequences" }));
			pilot_dialog1 = nil;
			sequence.showDialog();
		}
	},
};

var animate = {
	add_position:	func {	# add to the end of list and fill with current values
		var new_position = sequenceNode.getNode("position[" ~ size(sequenceNode.getChildren("position")) ~ "]", 1);
		position_count = size(sequenceNode.getChildren("position"));
		setprop("sim/model/walker[0]/animate/dialog-position", (position_count - 1));
		if (position_count == 0) {
			animate.reset_position();
		} else {
			animate.copy_position(walker0Node, new_position);
		}
		content_modified.setValue(5);
		return new_position;
	},
	ins_position:	func {
		var dialog_position = getprop("sim/model/walker[0]/animate/dialog-position");
		i = position_count;
		while (i > dialog_position) {
			animate.copy_position(sequenceNode.getNode("position[" ~ (i - 1) ~ "]", 1), 
				sequenceNode.getNode("position[" ~ i ~ "]", 1));
			i -= 1;
		}
		animate.save_position();
		position_count = size(sequenceNode.getChildren("position"));
		content_modified.setValue(5);
	},
	del_position:	func {
		position_count = size(sequenceNode.getChildren("position"));
		var dialog_position = getprop("sim/model/walker[0]/animate/dialog-position");
		var i = dialog_position;
		while (i < (position_count - 1)) {
			animate.copy_position(sequenceNode.getNode("position[" ~ (i + 1) ~ "]", 1), 
				sequenceNode.getNode("position[" ~ i ~ "]", 1));
			i += 1;
		}
		sequenceNode.removeChild("position", (position_count - 1));
		position_count = size(sequenceNode.getChildren("position"));
		if (position_count == 0) {
			setprop("sim/model/walker[0]/animate/dialog-position", (position_count - 1));
			animate.reset_position();
		} else {
			if (dialog_position >= position_count) {
				setprop("sim/model/walker[0]/animate/dialog-position", (position_count - 1));
			}
			animate.load_position();
		}
		content_modified.setValue(0);
	},
	copy_position:	func (fromNode, toNode) {
		toNode.getNode("name", 1).setValue(fromNode.getNode("name", 1).getValue());
		toNode.getNode("rest-sec", 1).setValue(fromNode.getNode("rest-sec", 1).getValue());
		var t = fromNode.getNode("transit-sec", 1);
		if (t.getValue() == 0) {
			t.setValue(0.1);
		}
		toNode.getNode("transit-sec", 1).setValue(t.getValue());
		toNode.getNode("limb[0]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[0]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[0]", 1).getNode("z-m", 1).setValue(fromNode.getNode("limb[0]", 1).getNode("z-m", 1).getValue());
		toNode.getNode("limb[1]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[1]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[1]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[1]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[2]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[2]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[2]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[2]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[3]", 1).getNode("x-deg", 1).setValue(fromNode.getNode("limb[3]", 1).getNode("x-deg", 1).getValue());
		toNode.getNode("limb[3]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[3]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[3]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[3]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[4]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[4]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[4]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[4]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[5]", 1).getNode("x-deg", 1).setValue(fromNode.getNode("limb[5]", 1).getNode("x-deg", 1).getValue());
		toNode.getNode("limb[5]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[5]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[6]", 1).getNode("x-deg", 1).setValue(fromNode.getNode("limb[6]", 1).getNode("x-deg", 1).getValue());
		toNode.getNode("limb[6]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[6]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[6]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[6]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[7]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[7]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[7]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[7]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[8]", 1).getNode("x-deg", 1).setValue(fromNode.getNode("limb[8]", 1).getNode("x-deg", 1).getValue());
		toNode.getNode("limb[8]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[8]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[9]", 1).getNode("x-deg", 1).setValue(fromNode.getNode("limb[9]", 1).getNode("x-deg", 1).getValue());
		toNode.getNode("limb[9]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[9]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[9]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[9]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[10]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[10]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[11]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[11]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[12]", 1).getNode("x-deg", 1).setValue(fromNode.getNode("limb[12]", 1).getNode("x-deg", 1).getValue());
		toNode.getNode("limb[12]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[12]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[12]", 1).getNode("z-deg", 1).setValue(fromNode.getNode("limb[12]", 1).getNode("z-deg", 1).getValue());
		toNode.getNode("limb[13]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[13]", 1).getNode("y-deg", 1).getValue());
		toNode.getNode("limb[14]", 1).getNode("y-deg", 1).setValue(fromNode.getNode("limb[14]", 1).getNode("y-deg", 1).getValue());
	},
	incr_position:	func {
		if (position_count > 0) {
			var dialog_position = getprop("sim/model/walker[0]/animate/dialog-position") + 1;
			if (dialog_position <= (position_count - 1)) {
				setprop("sim/model/walker[0]/animate/dialog-position", dialog_position);
				animate.load_position();
			}
			content_modified.setValue(2);
		}
	},
	decr_position:	func {
		var dialog_position = getprop("sim/model/walker[0]/animate/dialog-position") - 1;
		if (dialog_position >= 0) {
			setprop("sim/model/walker[0]/animate/dialog-position", dialog_position);
			animate.load_position();
		}
		content_modified.setValue(3);
	},
	reset_position:	func {
		setprop("sim/model/walker[0]/name", "");
		setprop("sim/model/walker[0]/limb[0]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[0]/z-m", 0.0);
		setprop("sim/model/walker[0]/limb[1]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[1]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[2]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[2]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[3]/x-deg", 0.0);
		setprop("sim/model/walker[0]/limb[3]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[3]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[4]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[4]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[5]/x-deg", 0.0);
		setprop("sim/model/walker[0]/limb[5]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[6]/x-deg", 0.0);
		setprop("sim/model/walker[0]/limb[6]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[6]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[7]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[7]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[8]/x-deg", 0.0);
		setprop("sim/model/walker[0]/limb[8]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[9]/x-deg", 0.0);
		setprop("sim/model/walker[0]/limb[9]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[9]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[10]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[11]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[12]/x-deg", 0.0);
		setprop("sim/model/walker[0]/limb[12]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[12]/z-deg", 0.0);
		setprop("sim/model/walker[0]/limb[13]/y-deg", 0.0);
		setprop("sim/model/walker[0]/limb[14]/y-deg", 0.0);
		setprop("sim/model/walker[0]/loop-enabled", "true");
		setprop("sim/model/walker[0]/loop-to", 0);
		setprop("sim/model/walker[0]/rest-sec", 0.0);
		setprop("sim/model/walker[0]/transit-sec", 1.0);
#		setprop("sim/model/walker[0]/trigger-upon", "Disabled");
		content_modified.setValue(1);
	},
	save_position:	func {
		var dialog_position = getprop("sim/model/walker[0]/animate/dialog-position");
		if (position_count == 0) {
			animate.add_position();
			setprop("sim/model/walker[0]/animate/dialog-position", 0);
		} else {
			animate.copy_position(walker0Node, sequenceNode.getNode("position[" ~ dialog_position ~ "]", 1));
		}
		sequenceNode.getNode("loop-enabled", 1).setBoolValue(walker0Node.getNode("loop-enabled", 1).getValue());
		sequenceNode.getNode("loop-to", 1).setIntValue(walker0Node.getNode("loop-to", 1).getValue());
#		var t = walker0Node.getNode("trigger-upon", 1).getValue();
#		if (t != sequenceNode.getNode("trigger-upon", 1).getValue()) {
#			sequenceNode.getNode("trigger-upon", 1).setValue(t);
#			discover_triggers(0);
#		}
		content_modified.setValue(6);
	},
	load_position:	func {
		var dialog_position = int(getprop("sim/model/walker[0]/animate/dialog-position"));
		if (dialog_position >= 0) {
			animate.copy_position(sequenceNode.getNode("position[" ~ dialog_position ~ "]", 1), walker0Node);
			var i1 = sequenceNode.getNode("loop-enabled", 1).getValue();
			if (i1 == nil) {
				i1 = "false";
			}
			walker0Node.getNode("loop-enabled", 1).setBoolValue(i1);
			var i2 = sequenceNode.getNode("loop-to", 1).getValue();
			if (i2 == nil) {
				i2 = 0;
			}
			walker0Node.getNode("loop-to", 1).setIntValue(i2);
#			var i3 = sequenceNode.getNode("trigger-upon", 1).getValue();
#			if (i3 == nil) {
#				i3 = "Disabled";
#			}
#			walker0Node.getNode("trigger-upon", 1).setValue(i3);
			content_modified.setValue(7);
		}
	},
	check_loop: func {
		var i = walker0Node.getNode("loop-to", 1).getValue();
		if (i > position_count or i < 0 or i == "") {
			walker0Node.getNode("loop-to", 1).setValue(0);
		}
	},
	showDialog: func {
		var name2 = "pilot-config";
		if (pilot_dialog2 != nil) {
			fgcommand("dialog-close", props.Node.new({ "dialog-name" : name2 }));
			pilot_dialog2 = nil;
			return;
		}

		pilot_dialog2 = gui.Widget.new();
		pilot_dialog2.set("layout", "vbox");
		pilot_dialog2.set("name", name2);
		pilot_dialog2.set("x", -10);
		pilot_dialog2.set("y", -3);

		# "window" titlebar
		titlebar = pilot_dialog2.addChild("group");
		titlebar.set("layout", "hbox");
		titlebar.addChild("empty").set("stretch", 1);
		titlebar.addChild("text").set("label", "Pilot position config -- " ~ sequenceNode.getNode("name", 1).getValue());
		titlebar.addChild("empty").set("stretch", 1);

		pilot_dialog2.addChild("hrule").addChild("dummy");

		w = titlebar.addChild("button");
		w.set("pref-width", 16);
		w.set("pref-height", 14);
		w.set("legend", "");
		w.set("keynum", 27);
		w.set("border", 1);
		w.prop().getNode("binding[0]/command", 1).setValue("nasal");
		w.prop().getNode("binding[0]/script", 1).setValue("pilot.sequence.showDialog()");
		w.prop().getNode("binding[1]/command", 1).setValue("nasal");
		w.prop().getNode("binding[1]/script", 1).setValue("pilot.pilot_dialog2 = nil");
		w.prop().getNode("binding[2]/command", 1).setValue("dialog-close");

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "Position");
		var content = g.addChild("input");
		content.set("name", "position");
		content.set("layout", "hbox");
		content.set("halign", "fill");
		content.set("label", "");
		content.set("default-padding", 1);
		content.set("pref-width", 40);
		content.set("editable", "true");
		content.set("live", "true");
		content.set("property", "sim/model/walker[0]/animate/dialog-position");
		content.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		content.prop().getNode("binding[0]/object-name", 1).setValue("position");
		content.prop().getNode("binding[1]/command", 1).setValue("nasal");
		content.prop().getNode("binding[1]/script", 1).setValue("walker.animate.load_position()");
		var gv = g.addChild("group");
		gv.set("layout", "table");
		gv.set("default-padding", 1);
		var box1 = gv.addChild("button");
		box1.set("row", 1);
		box1.set("column", 0);
		box1.set("halign", "left");
		box1.set("label", "");
		box1.set("pref-width", 20);
		box1.set("pref-height", 14);
		var pos_children_size = size(sequenceNode.getChildren("position"));
		var dia_pos = getprop("sim/model/walker[0]/animate/dialog-position");
		box1.set("border", (pos_children_size > 1 ? (dia_pos > 0 ? 2 : 0) : 0));
		box1.set("legend", "-");
		box1.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box1.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.decr_position()");
		var box2 = gv.addChild("button");
		box2.set("row", 0);
		box2.set("column", 0);
		box2.set("halign", "left");
		box2.set("label", "");
		box2.set("pref-width", 20);
		box2.set("pref-height", 14);
		box2.set("border", (pos_children_size > 1 ? (dia_pos < (pos_children_size - 1) ? 2 : 0) : 0));
		box2.set("legend", "+");
		box2.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box2.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.incr_position()");
		g.addChild("empty").set("stretch", 1);
		var t = g.addChild("text");
		t.set("label", "Desc.");
		var content = g.addChild("input");
		content.set("name", "input");
		content.set("layout", "hbox");
		content.set("halign", "fill");
		content.set("label", "");
		content.set("default-padding", 1);
		content.set("pref-width", 200);
		content.set("editable", "true");
		content.set("live", "true");
		content.set("property", "sim/model/walker[0]/name");
		content.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		content.prop().getNode("binding[0]/object-name", 1).setValue("input");
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var box3 = g.addChild("button");
		box3.set("halign", "left");
		box3.set("label", "");
		box3.set("pref-width", 50);
		box3.set("pref-height", 18);
		box3.set("legend", "Insert");
		if (dia_pos < 0) {
			box3.setColor(0.44, 0.31, 0.31);
		}
		box3.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box3.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.ins_position()");
		var box4 = g.addChild("button");
		box4.set("halign", "left");
		box4.set("label", "");
		box4.set("pref-width", 50);
		box4.set("pref-height", 18);
		box4.set("legend", "Add");
		box4.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box4.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.add_position()");
		var box5 = g.addChild("button");
		box5.set("halign", "left");
		box5.set("label", "");
		box5.set("pref-width", 50);
		box5.set("pref-height", 18);
		box5.set("legend", "Delete");
		if (dia_pos < 0) {
			box5.setColor(0.44, 0.31, 0.31);
		}
		box5.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box5.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.del_position()");
		var box6 = g.addChild("button");
		box6.set("halign", "left");
		box6.set("label", "");
		box6.set("pref-width", 50);
		box6.set("pref-height", 18);
		box6.set("legend", "Reset");
		box6.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box6.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.reset_position()");
		var box7 = g.addChild("button");
		box7.set("halign", "left");
		box7.set("label", "");
		box7.set("pref-width", 50);
		box7.set("pref-height", 18);
		box7.set("border", (content_modified.getValue() == 1 ? 2 : 1));
		if (dia_pos < 0) {
			box7.setColor(0.44, 0.31, 0.31);
		}
		box7.set("legend", "Revert");
		box7.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box7.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.load_position()");
		var box8 = g.addChild("button");
		box8.set("name", "save");
		box8.set("halign", "left");
		box8.set("label", "");
		box8.set("pref-width", 50);
		box8.set("pref-height", 18);
		box8.set("border", (content_modified.getValue() == 1 ? 2 : 1));
		box8.set("legend", "Save");
		box8.prop().getNode("binding[0]/command", 1).setValue("nasal");
		box8.prop().getNode("binding[0]/script", 1).setValue("pilot.animate.save_position()");

		pilot_dialog2.addChild("hrule").addChild("dummy");

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "0.y");
		t.set("pref-width", 15);
		g.addChild("empty").set("pref-width", 3);
		var box = g.addChild("slider");
		box.set("name", "Hip 0y");
		box.set("property", "sim/model/walker[0]/limb[0]/y-deg");
		box.set("legend", "Hip forward  < >  backward   ");
		box.set("pref-width", 300);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -180);
		box.set("max", 180);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Hip 0y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[0]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "1.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 26);
		var box = g.addChild("slider");
		box.set("name", "Chest 1y");
		box.set("property", "sim/model/walker[0]/limb[1]/y-deg");
		box.set("legend", "    Chest forward  < >  backward");
		box.set("pref-width", 200);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -110);
		box.set("max", 70);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Chest 1y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[1]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "1.z");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 16);
		var box = g.addChild("slider");
		box.set("name", "Chest 1z");
		box.set("property", "sim/model/walker[0]/limb[1]/z-deg");
		box.set("legend", "Chest left  < >  right        ");
		box.set("pref-width", 264);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -30);
		box.set("max", 30);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Chest 1z");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[1]/z-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "2.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 58);
		var box = g.addChild("slider");
		box.set("name", "Head 2y");
		box.set("property", "sim/model/walker[0]/limb[2]/y-deg");
		box.set("legend", "Head forward  < >  backward    ");
		box.set("pref-width", 170);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -80.5);
		box.set("max", 72.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Head 2y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[2]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "2.z");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 48);
		var box = g.addChild("slider");
		box.set("name", "Head 2z");
		box.set("property", "sim/model/walker[0]/limb[2]/z-deg");
		box.set("legend", "Head left  < >  right       ");
		box.set("pref-width", 200);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -90);
		box.set("max", 90);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Head 2z");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[2]/z-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "3.x");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 102);
		var box = g.addChild("slider");
		box.set("name", "Arm1R 3x");
		box.set("property", "sim/model/walker[0]/limb[3]/x-deg");
		box.set("legend", "Right Arm1 down  < >  up                                                 ");
		box.set("pref-width", 200);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -10);
		box.set("max", 170);
		box.setColor(0.5, 1, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Arm1R 3x");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[3]/x-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "3.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 62);
		var box = g.addChild("slider");
		box.set("name", "Arm1R 3y");
		box.set("property", "sim/model/walker[0]/limb[3]/y-deg");
		box.set("legend", "counter-clockwise < > clockwise                               ");
		box.set("pref-width", 240);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -80);
		box.set("max", 190);
		box.setColor(0.5, 1, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Arm1R 3y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[3]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "3.z");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 51);
		var box = g.addChild("slider");
		box.set("name", "Arm1R 3z");
		box.set("property", "sim/model/walker[0]/limb[3]/z-deg");
		box.set("legend", "Right Arm1 forward left  < >  back right                          ");
		box.set("pref-width", 220);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -86);
		box.set("max", 112);
		box.setColor(0.5, 1, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Arm1R 3z");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[3]/z-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "4.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 2);
		var box = g.addChild("slider");
		box.set("name", "Arm2R 4y");
		box.set("property", "sim/model/walker[0]/limb[4]/y-deg");
		box.set("legend", "Right Arm2 counter-clockwise < > clockwise                                ");
		box.set("pref-width", 300);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -87);
		box.set("max", 93);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Arm2R 4y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[4]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "4.z");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 67);
		var box = g.addChild("slider");
		box.set("name", "Arm2R 4z");
		box.set("property", "sim/model/walker[0]/limb[4]/z-deg");
		box.set("legend", "Right Arm2 straighten  < >  bend                         ");
		box.set("pref-width", 165);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -73);
		box.set("max", 77);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Arm2R 4z");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[4]/z-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "5.x");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 51);
		var box = g.addChild("slider");
		box.set("name", "HandR 5x");
		box.set("property", "sim/model/walker[0]/limb[5]/x-deg");
		box.set("legend", "Right Hand down  < >  up                 ");
		box.set("pref-width", 176);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -88);
		box.set("max", 72);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("HandR 5x");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[5]/x-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "5.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 55);
		var box = g.addChild("slider");
		box.set("name", "HandR 5y");
		box.set("property", "sim/model/walker[0]/limb[5]/y-deg");
		box.set("legend", "counter-clockwise < > clockwise                         ");
		box.set("pref-width", 233);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -106);
		box.set("max", 164);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("HandR 5y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[5]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "6-8");
		t.set("pref-width", 20);
		var t = g.addChild("text");
		t.set("label", "Left Arm is Linked to Throttle");
		g.addChild("empty").set("stretch", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "9.x");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 53);
		var box = g.addChild("slider");
		box.set("name", "Leg1R 9x");
		box.set("property", "sim/model/walker[0]/limb[9]/x-deg");
		box.set("legend", "   Right Leg1 out  < >  in");
		box.set("pref-width", 100);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -90.0);
		box.set("max", 0.0);
		box.setColor(0.5, 1, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg1R 9x");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[9]/x-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "9.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 62);
		var box = g.addChild("slider");
		box.set("name", "Leg1R 9y");
		box.set("property", "sim/model/walker[0]/limb[9]/y-deg");
		box.set("legend", "Right Leg1 forward  < >  back                                      ");
		box.set("pref-width", 240);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -65);
		box.set("max", 151);
		box.setColor(0.5, 1, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg1R 9y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[9]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "9.z");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 59);
		var box = g.addChild("slider");
		box.set("name", "Leg1R 9z");
		box.set("property", "sim/model/walker[0]/limb[9]/z-deg");
		box.set("legend", "counter-clockwise in < > clockwise out   ");
		box.set("pref-width", 140);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -81);
		box.set("max", 45);
		box.setColor(0.5, 1, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg1R 9z");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[9]/z-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "10.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 132);
		var box = g.addChild("slider");
		box.set("name", "Leg2R 10y");
		box.set("property", "sim/model/walker[0]/limb[10]/y-deg");
		box.set("legend", "Right Leg2 straighten  < >  bend                                             ");
		box.set("pref-width", 115);
		box.set("pref-height", -29);
		box.set("live", 1);
		box.set("min", -14);
		box.set("max", 130);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg2R 10y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[10]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "11.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 106);
		var box = g.addChild("slider");
		box.set("name", "FootR 11y");
		box.set("property", "sim/model/walker[0]/limb[11]/y-deg");
		box.set("legend", "Right Foot down  < >  up                         ");
		box.set("pref-width", 100);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -36);
		box.set("max", 54);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("FootR 11y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[11]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "12.x");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 53);
		var box = g.addChild("slider");
		box.set("name", "Leg1R 12x");
		box.set("property", "sim/model/walker[0]/limb[12]/x-deg");
		box.set("legend", "     Left Leg1 out  < >  in");
		box.set("pref-width", 100);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -90.0);
		box.set("max", 0.0);
		box.setColor(1, 0.5, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg1R 12x");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[12]/x-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "12.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 62);
		var box = g.addChild("slider");
		box.set("name", "Leg1L 12y");
		box.set("property", "sim/model/walker[0]/limb[12]/y-deg");
		box.set("legend", "Left Leg1 forward  < >  back                                    ");
		box.set("pref-width", 240);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -65.0);
		box.set("max", 151.0);
		box.setColor(1, 0.5, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg1L 12y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[12]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "12.z");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 96);
		var box = g.addChild("slider");
		box.set("name", "Leg1L 12z");
		box.set("property", "sim/model/walker[0]/limb[12]/z-deg");
		box.set("legend", "counter-clockwise out < > clockwise in                         ");
		box.set("pref-width", 140);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -45);
		box.set("max", 81);
		box.setColor(1, 0.5, 0.5);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg1L 12z");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[12]/z-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "13.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 81);
		var box = g.addChild("slider");
		box.set("name", "Leg2L 13y");
		box.set("property", "sim/model/walker[0]/limb[13]/y-deg");
		box.set("legend", "Left Leg2 straighten  < >  bend                             ");
		box.set("pref-width", 160);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -59);
		box.set("max", 85);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("Leg2L 13y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[13]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		var t = g.addChild("text");
		t.set("label", "14.y");
		t.set("pref-width", 20);
		g.addChild("empty").set("pref-width", 107);
		var box = g.addChild("slider");
		box.set("name", "FootL 14y");
		box.set("property", "sim/model/walker[0]/limb[14]/y-deg");
		box.set("legend", "Left Foot down  < >  up                        ");
		box.set("pref-width", 100);
		box.set("pref-height", 16);
		box.set("live", 1);
		box.set("min", -35);
		box.set("max", 55);
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[0]/object-name", 1).setValue("FootL 14y");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("stretch", 1);
		var number = g.addChild("text");
		number.set("property", "sim/model/walker[0]/limb[14]/y-deg");
		number.set("pref-width", 32);
		number.set("format", "%6.1f");
		number.set("live", 1);
		g.addChild("empty").set("pref-width", 4);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 4);
		g.addChild("text").set("label", "Rest here");
		var content1 = g.addChild("input");
		content1.set("name", "rest");
		content1.set("layout", "hbox");
		content1.set("halign", "fill");
		content1.set("label", "sec.");
		content1.set("default-padding", 1);
		content1.set("pref-width", 40);
		content1.set("editable", "true");
		content1.set("live", "true");
		content1.set("property", "sim/model/walker[0]/rest-sec");
		content1.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		content1.prop().getNode("binding[0]/object-name", 1).setValue("rest");
		g.addChild("empty").set("stretch", 1);
		g.addChild("text").set("label", "Transit time to next");
		var content2 = g.addChild("input");
		content2.set("name", "transit");
		content2.set("layout", "hbox");
		content2.set("halign", "fill");
		content2.set("label", "");
		content2.set("default-padding", 1);
		content2.set("pref-width", 40);
		content2.set("editable", "true");
		content2.set("live", "true");
		content2.set("property", "sim/model/walker[0]/transit-sec");
		content2.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		content2.prop().getNode("binding[0]/object-name", 1).setValue("transit");
		g.addChild("text").set("label", "seconds");
		g.addChild("empty").set("pref-width", 4);

		pilot_dialog2.addChild("hrule").addChild("dummy");

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 0);
		g.addChild("empty").set("pref-width", 11);
		var box = g.addChild("checkbox");
		box.set("halign", "left");
		box.set("label", "Loop to position");
		box.set("live", "true");
		box.set("property", "sim/model/walker[0]/loop-enabled");
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		box.prop().getNode("binding[1]/command", 1).setValue("property-assign");
		box.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
		box.prop().getNode("binding[1]/value", 1).setValue(1);
		var content = g.addChild("input");
		content.set("name", "loop-input");
		content.set("layout", "hbox");
		content.set("halign", "fill");
		content.set("label", "");
		content.set("default-padding", 1);
		content.set("pref-width", 40);
		content.set("editable", "true");
		content.set("live", "false");
		content.set("property", "sim/model/walker[0]/loop-to");
		content.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		content.prop().getNode("binding[0]/object-name", 1).setValue("loop-input");
		content.prop().getNode("binding[1]/command", 1).setValue("nasal");
		content.prop().getNode("binding[1]/script", 1).setValue("pilot.animate.check_loop()");
		g.addChild("empty").set("stretch", 1);
#		g.addChild("text").set("label", "Trigger");
#		var combo = g.addChild("combo");
#		combo.set("default-padding", 1);
#		combo.set("pref-width", 130);
#		combo.set("property", "sim/model/walker[0]/trigger-upon");
#		combo.prop().getNode("value[0]", 1).setValue("Disabled");
#		combo.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
#		combo.prop().getNode("binding[1]/command", 1).setValue("property-assign");
#		combo.prop().getNode("binding[1]/property", 1).setValue("sim/gui/dialogs/position-modified");
#		combo.prop().getNode("binding[1]/value", 1).setValue(1);
		g.addChild("empty").set("pref-width", 8);

		var g = pilot_dialog2.addChild("group");
		g.set("layout", "hbox");
		g.set("default-padding", 2);
		g.addChild("empty").set("pref-width", 5);
		var box = g.addChild("checkbox");
		box.set("halign", "left");
		box.set("label", "Enable This Animation Now");
		box.set("property", "sim/model/walker[0]/animate/enabled-current");
		box.prop().getNode("binding[0]/command", 1).setValue("dialog-apply");
		g.addChild("empty").set("stretch", 1);

		pilot_dialog2.addChild("empty").set("pref-height", "3");
		fgcommand("dialog-new", pilot_dialog2.prop());
		gui.showDialog(name2);
	},
	reloadDialog: func {
		if (pilot_dialog2 != nil) {
			fgcommand("dialog-close", props.Node.new({ "dialog-name" : "pilot-config" }));
			pilot_dialog2 = nil;
			animate.showDialog();
		}
	}
};

var animate_update = func (seqNode) {
	var current_time = getprop("sim/time/elapsed-sec");
	var time_elapsed = current_time - animate_time_start;
	var i = 0;
	if (time_elapsed >= animate_time_length) {
		if (getprop("sim/model/walker[0]/loop-enabled")) {
			animate_current_position -= position_count;
			animate_current_position += loop_to;
			animate_time_start += loop_length_sec;
			time_elapsed -= loop_length_sec;
		} else {
			animate_current_position = position_count - 1;
			animate_current_position = int(animate_current_position);
			i = 99;
		}
	}
	animate_current_position = clamp(animate_current_position, 0.0, position_count);
	var move_percent = 0.0;
	if (i < 99) {
		while ((time_elapsed > time_chart[int(animate_current_position)].transit_until) and (animate_current_position < position_count)) {
			animate_current_position = int(animate_current_position) + 1;
		}
		if (animate_current_position >= position_count) {
			animate_current_position = loop_to;
		}
		if (time_elapsed <= time_chart[int(animate_current_position)].rest_until) {
			animate_current_position = int(animate_current_position) + ((time_elapsed - time_chart[int(animate_current_position)].time0) / (time_chart[int(animate_current_position)].transit_until - time_chart[int(animate_current_position)].time0));
		} elsif (time_elapsed <= time_chart[int(animate_current_position)].transit_until) {
			move_percent = (time_elapsed - time_chart[int(animate_current_position)].rest_until) / time_chart[int(animate_current_position)].transit;
			animate_current_position = int(animate_current_position) + ((time_elapsed - time_chart[int(animate_current_position)].time0) / (time_chart[int(animate_current_position)].transit_until - time_chart[int(animate_current_position)].time0));
		}
		animate_current_position = clamp(animate_current_position, 0.0, position_count);
	}
	setprop("sim/model/walker[0]/animate/dialog-position", int(animate_current_position));
	var s = "position[" ~ int(animate_current_position) ~ "]";
	var fromNode = seqNode.getNode(s, 1);
	walker0Node.getNode("name", 1).setValue(fromNode.getNode("name", 1).getValue());
	walker0Node.getNode("rest-sec", 1).setValue(fromNode.getNode("rest-sec", 1).getValue());
	walker0Node.getNode("transit-sec", 1).setValue(fromNode.getNode("transit-sec", 1).getValue());
	if (i == 99) {
		var next_position = int(animate_current_position);
		var toNode = seqNode.getNode("position[" ~ (position_count - 1) ~ "]", 1);
	} else {
		var next_position = int(animate_current_position) + 1;
		if (next_position > (position_count - 1)) {
			var toNode = seqNode.getNode("position[" ~ loop_to ~ "]", 1);
		} else {
			var toNode = seqNode.getNode("position[" ~ next_position ~ "]", 1);
		}
	}
	walker0Node.getNode("limb[0]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[0]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[0]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[0]", 1).getNode("z-m", 1).setValue(interpolate_limb(fromNode.getNode("limb[0]", 1).getNode("z-m", 1).getValue(), toNode.getNode("limb[0]", 1).getNode("z-m", 1).getValue(), move_percent));
	walker0Node.getNode("limb[1]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[1]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[1]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[1]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[1]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[1]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[2]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[2]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[2]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[2]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[2]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[2]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[3]", 1).getNode("x-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[3]", 1).getNode("x-deg", 1).getValue(), toNode.getNode("limb[3]", 1).getNode("x-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[3]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[3]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[3]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[3]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[3]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[3]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[4]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[4]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[4]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[4]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[4]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[4]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[5]", 1).getNode("x-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[5]", 1).getNode("x-deg", 1).getValue(), toNode.getNode("limb[5]", 1).getNode("x-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[5]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[5]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[5]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[6]", 1).getNode("x-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[6]", 1).getNode("x-deg", 1).getValue(), toNode.getNode("limb[6]", 1).getNode("x-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[6]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[6]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[6]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[6]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[6]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[6]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[7]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[7]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[7]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[7]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[7]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[7]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[8]", 1).getNode("x-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[8]", 1).getNode("x-deg", 1).getValue(), toNode.getNode("limb[8]", 1).getNode("x-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[8]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[8]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[8]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[9]", 1).getNode("x-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[9]", 1).getNode("x-deg", 1).getValue(), toNode.getNode("limb[9]", 1).getNode("x-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[9]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[9]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[9]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[9]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[9]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[9]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[10]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[10]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[10]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[11]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[11]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[11]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[12]", 1).getNode("x-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[12]", 1).getNode("x-deg", 1).getValue(), toNode.getNode("limb[12]", 1).getNode("x-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[12]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[12]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[12]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[12]", 1).getNode("z-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[12]", 1).getNode("z-deg", 1).getValue(), toNode.getNode("limb[12]", 1).getNode("z-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[13]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[13]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[13]", 1).getNode("y-deg", 1).getValue(), move_percent));
	walker0Node.getNode("limb[14]", 1).getNode("y-deg", 1).setValue(interpolate_limb(fromNode.getNode("limb[14]", 1).getNode("y-deg", 1).getValue(), toNode.getNode("limb[14]", 1).getNode("y-deg", 1).getValue(), move_percent));
	if (i == 99) {
		if (anim_enabled) {
			setprop("sim/model/walker[0]/animate/enabled-current", "false");
		}
		seqNode_now = nil;
		settimer(func { animate.reloadDialog() }, 0.1);
	}

}

var animate_loop_id = 0;
var animate_loop = func (id, seqNode) {
	id == animate_loop_id or return;
	if (anim_enabled) {
		if (seqNode == seqNode_now) {
			animate_update(seqNode);
			settimer(func { animate_loop(animate_loop_id += 1, seqNode) }, 0.01);
		}
	}
}

var start_animation = func (seqNode) {
	seqNode_now = seqNode;
	position_count = size(seqNode.getChildren("position"));
	if (getprop("logging/pilot-debug")) {
		print ("starting animation: ", seqNode.getNode("name", 1).getValue()," id= ",animate_loop_id," position_count= ",position_count);
	}
	setprop("sim/model/walker[0]/animate/dialog-position", 0);
	loop_enabled = seqNode.getNode("loop-enabled", 1).getValue();
	walker0Node.getNode("loop-enabled", 1).setValue(loop_enabled);
	if (position_count >= 2) {
		animate_current_position = 0.0;
		time_chart = [];
		var t = 0.0;
		loop_to = (loop_enabled ? seqNode.getNode("loop-to", 1).getValue() : position_count - 1);
		for (var i = 0 ; i < position_count ; i += 1) {
			var iNode = seqNode.getNode("position[" ~ i ~ "]", 1);
			var rest_sec = iNode.getNode("rest-sec", 1).getValue();
			var transit_sec = iNode.getNode("transit-sec", 1).getValue();
			if (i == loop_to) {
				loop_start_sec = t;
			}
			append(time_chart, { position: i, time0: t , rest_until: (t + rest_sec), 
				transit_until: (t + rest_sec + transit_sec),
				transit: transit_sec });
			if (loop_enabled or i < (position_count - 1)) {
				t += rest_sec;
				t += transit_sec;
			}
		}
		animate_time_length = t;
		loop_length_sec = t - loop_start_sec;
		if (t > 0.0) {
#			anim_running = 1;
			animate_time_start = getprop("sim/time/elapsed-sec");
			settimer(func { animate_loop(animate_loop_id += 1, seqNode) }, 0);
		}
	}
}

var stop_animation = func {
	if (anim_enabled) {
		settimer(func { setprop("sim/model/walker[0]/animate/enabled-current", "false") }, 0.1);
	}
#	anim_running = 0;
}

#var discover_triggers = func (verbose) {
#	var a = size(listNode.getChildren("sequence"));
#	triggers_list = [0, 0, 0, 0, 0, 0, 0, 0];
#	var trig_c = 0;
#}

var init_pilot = func {
	sequenceNode = listNode.getNode("sequence[" ~ int(animateNode.getNode("sequence-selected", 1).getValue()) ~ "]", 1);
	position_count = size(sequenceNode.getChildren("position"));
	setprop("sim/model/walker[0]/animate/dialog-position", 0);
#	setlistener("sim/model/walker[0]/animate/enabled-triggers", func {
#		triggers_enabled = getprop("sim/model/walker[0]/animate/enabled-triggers");
#		stop_animation();
#		if (triggers_enabled) {
#			animate.reset_position();
#		}
#	}, 1, 0);

	am_L_id = setlistener("sim/gui/dialogs/position-modified", func {
		if (!anim_enabled) {
			animate.reloadDialog();
		}
	}, 0, 0);

	setlistener("sim/model/walker[0]/animate/enabled-current", func {
		anim_enabled = getprop("sim/model/walker[0]/animate/enabled-current");
		if (anim_enabled) {
			start_animation(sequenceNode);
#		} else {
#			if (anim_running) {
#				stop_animation();
#			}
		}
	}, 1, 0);

#	discover_triggers(1);
}
settimer(init_pilot,0);

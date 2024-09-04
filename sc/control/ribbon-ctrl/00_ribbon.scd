/* 00_ribbon.scd */

var print = false;
var min = 364;
var max = 16380;
// var bus, gate, bend, control;

var step = 0.5;
var last_bend_val = 0;
var last_gate = 0;
var idleTime = 2*60;

var updateSubj = { |val|
	var subj = Subject.topics[\zoom];
		subj.state.zoom = val;
		subj.notify;
};

var bend_func = { |val, press, gate|
	var nudge_val = val-last_bend_val;
	var step_inc = 0;
	(last_gate != 0).if{step_inc = nudge_val.clip2(0.5)*([1e-1, 5, \lin].asSpec.map(press));};
	last_bend_val = val;
	last_gate = gate;
	step = step + step_inc;
	step = step.clip(0, 1);
	updateSubj.(step);
	step;
};

var ribbon =  Environment.with(
	\controlVal-> 0.5,
	\bendSpec -> ControlSpec(min, max),
	\gate -> 0,
	\bend -> 0,
	\control->0,
	\onGateFunc->{|env| env.idleOffFunc.value;env.idleRoutine.stop; print.if{env.gate.postln}},
	\offGateFunc->{|env| env.idleRoutine.reset.play; print.if{env.gate.postln}},
	\bendFunc->{|env| env.controlVal = bend_func.(env.bend, env.control, env.gate); print.if{env.controlVal.postln;}},//{|env| print.if{env.bend.postln}},
	\pressureFunc->nil;//{|env| env.control.postln},
	\idleOnFunc -> {
		var subj = Subject.topics[\idleMode];
		subj.state.isIdle = true;
		subj.notify;
	},
	\idleOffFunc -> {
		var subj = Subject.topics[\idleMode];
		subj.state.isIdle.if{
			subj.state.isIdle = false;
			subj.notify;
		}
	},
);

Subject.addSubjectTopic(\idleMode, (isIdle: true));
Subject.addSubjectTopic(\zoom, (zoom: 0.5));

ribbon.know_(true);

p.k.putAll((
	ribbon: ribbon
	));

if(MIDIClient.sources.includes(MIDIIn.findPort("iConnectMIDI2+", "DIN 1")).not){
// if(MIDIClient.sources.includes(MIDIIn.findPort("U2MIDI Pro", "U2MIDI Pro")).not){
		"could not find R2M MIDI port".postln;
	}{
		MIDIIn.connect(device: MIDIIn.findPort("iConnectMIDI2+", "DIN 1"));
		// MIDIIn.connect(device: MIDIIn.findPort("U2MIDI Pro", "U2MIDI Pro"));
		"R2M connected!".postln;
	};

ribbon.use{ |env|
	MIDIFunc.noteOn({env.gate = 1;env.onGateFunc.value},chan:0);
	MIDIFunc.noteOff({env.gate = 0; last_gate = env.gate; env.offGateFunc.value},chan:0);
	MIDIFunc.bend({|val|
		env.bend = env.bendSpec.unmap(val);env.bendFunc.value}, chan:0);
	MIDIFunc.cc({|val| env.control = \midi.asSpec.unmap(val);env.pressureFunc.value },chan:0, ccNum:0);
	env.idleRoutine = Routine.new(
	{
		// env.idleOffFunc !? env.idleOffFunc.value;
		idleTime.wait;
		env.idleOnFunc.value;
	});
};

defer{
var bounds = Rect(1000, 800, 600, 300);
var window = Window("screen", bounds, border: false).front;
var user_view  = UserView(window, Rect(0,  0, bounds.width, bounds.height));
var view = View(parent: user_view, bounds: Rect(0,  0, bounds.width, bounds.height));
var plotter = Plotter("plot",
	Rect(0,  0, bounds.width, bounds.height),
	parent: view);//.plotColor_([Color.red]);

var d = (Array.fill(128*5, {0.5})).bubble;

// user_view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
    // if (unicode == 16r001B, { defer{view.parent.close; }});
// };
var cnt = 0;
window.front;

AppClock.sched(0, {
	d.unbubble.wrapPut(cnt, ribbon.controlVal);
	plotter.setValue(d, findSpecs: true, separately: true, minval: 0.0, maxval: 1.0);
	cnt = cnt+1;
	// histo.value_(delta.histo(100));
	0.032;//30fps
});

};

/*
p.ribbon.gate
p.ribbon.put(\pressureFunc, nil)
*/
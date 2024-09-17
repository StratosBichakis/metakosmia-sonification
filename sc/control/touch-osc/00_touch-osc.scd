/*00_touch-osc.scd*/
var forward_addr = NetAddr("localhost", 10000);
var midiEnable = false;
var port = MIDIIn.findPort("iConnectMIDI2+", "USB 1");
var touchOSC =  Environment.with(
	\todLabelList -> List[\midnight, \dusk, \earlymorning, \morning, \midday, \afternoon, \evening, \night],
	\epochLabelList -> List[\predrought, \earlydrought, \severedrought, \deeprewet, \rainrewet, \longtermrecovery],
	\todFilterSwitch -> List.newUsing(1.dup(8)),
	\epochFilterSwitch -> List.newUsing(1.dup(6)),
	);

touchOSC.know_(true);

p.k.putAll((
	touchOSC: touchOSC,
	));

midiEnable.if{
	Task{
		if(MIDIClient.sources.includes(port).not){
			"could not find TouchOSC MIDI port".postln;
		}{
			MIDIIn.connect(device: port);
			"TOUCH-OSC connected!".postln;
		};

		touchOSC.use{ | env |
			MIDIFunc.noteOn({"noteOn".postln},noteNum:0, chan:0);
			MIDIFunc.noteOff({"noteOff".postln},noteNum:0, chan:0);
			MIDIFunc.cc({| midiVal | var val = \midi.asSpec.unmap(midiVal);val.postln},chan:0, ccNum:0);
		};
	}.play(AppClock);
};

Subject.addSubjectTopic(\filterChange, 	(
		todFilterSwitch:   touchOSC.[\todFilterSwitch], 
		epochFilterSwitch: touchOSC.[\epochFilterSwitch]
	)
);

thisProcess.openUDPPort(8000);

touchOSC.use{ | env |
	var subj = (type: \subj_filterChange);//Subject.topics[\filterChange];
	var idleJob = {
		var job = TimeOut.jobs[\idleWatch];
		// "#".postln;
		job.isRunning.if{
			(type:\job_idleWatch, jobcmd:\procrastinate).play;	
		}{
			(type:\job_idleWatch, jobcmd:\reschedule).play;
		};
		(type: \subj_idleMode, isIdle: false).play;
	};
	
	~todLabelList.do{|label, i|
		OSCFunc({| msg | 
			var val = msg.drop(1).unbubble.asInteger;
			env.todFilterSwitch.put(i, val);
			// subj.notify; 
			subj.play; 
			idleJob.value;
			forward_addr.sendMsg(*msg);
			
		}, '/sonify/filter/timeofday/'++label);
	};
	~epochLabelList.do{|label, i|
		OSCFunc({| msg | 
			var val = msg.drop(1).unbubble.asInteger;
			env.epochFilterSwitch.put(i, val);
			// subj.notify;
			subj.play; idleJob.value;
			forward_addr.sendMsg(*msg);
		}, '/sonify/filter/epoch/'++label);
	};
	OSCFunc({| msg | 
		var val = msg.drop(1).unbubble;
		idleJob.value;
		forward_addr.sendMsg(*msg);
	}, '/sonify/colorby/epoch');
};


/*
-TODO
move lists to context
send back information to the controller to clear filters
*/
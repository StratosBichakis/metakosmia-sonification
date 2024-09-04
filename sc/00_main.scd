/* 00_main.scd */
var alive;
var path = thisProcess.nowExecutingPath !? (_.dirname) ?? "~/workspace/ongoing/Nina Fischer - Resilience/code/sc".standardizePath;

p = Project.new(\resilience, path);

Task {
	LoadMe.start;
	LoadMe(p.dir +/+ "control/control.scd");
	LoadMe(p.dir +/+ "context/context.scd");
	
	LoadMe(p.dir +/+ "01_settings.scd");
	LoadMe(p.dir +/+ "lib/synth-lib.scd");
	LoadMe(p.dir +/+ "02_load-buffers.scd");
	
	s.waitForBoot{
		p.synth.init.value;
		p.buffers.init.value;
		s.sync;
		LoadMe(p.dir +/+ "view/view.scd");
		LoadMe(p.dir +/+ "player/player.scd");
		// loop{
			// (type: \biosphera_data).play;
			// 1.wait;
		// }
	};




	LoadMe.end;
}.play(AppClock);

// AppClock.sched(2, {
		// ".".post;1;
// });

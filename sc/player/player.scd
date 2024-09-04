/*player.scd*/

p.add(\player->Environment.new.know_(true));

"00_sequential.scd".loadRelative;
"01_kd-tree.scd".loadRelative;

p.player.putAll((
	stream: p.player.kdtree.routine,
	last_id: 0,
	obs_id: Observer(\player_id, Subject.topics[\idChange], { |state|
		p.player.last_id = state.[\id];
	})
	obs_idle: Observer(\player_idle, Subject.topics[\idleMode], { |state|
		state.[\isIdle].if{
			// "*".postln;
			p.player.kdtree.routine.stop;
			p.player.sequential.routine.reset.(0);
			p.player.sequential.routine.play;
		} {
			// "_".postln;
			p.player.sequential.routine.stop;
			p.player.kdtree.routine.reset.(p.player.last_id);
		}
	}),
	seqAtBoot: r{
		s.sync;
		// 5.wait;
		p.player.sequential.routine.reset.(0);
		p.player.sequential.routine.play;
	},
	kdtreeAtBoot: r {
		s.sync;
		p.player.kdtree.routine.reset.(0);
		p.player.kdtree.routine.play;
	}
));



p.player.seqAtBoot.play;




/*
p.player.kdtree.routine.reset.(p.player.last_id);
p.player.sequential.routine.stop;

*/

/*
p.player.kdtree.routine.stop;
p.player.sequential.routine.reset.(0);

*/



/*00_fixed_duration.scd*/

var fixedDurIds = {
	var dur = 0.07;
/*	var e_dur = [ //[min, sec, millis]
		[0, 0, 0],
		[0, 0, 0],
		[1, 0, 0],
		[0, 20, 000],
		[0, 20, 551],
		[0, 20, 587]
	];*/
	var e_dur = [ //[min, sec, millis]
		[1, 18, 400],
		[1, 26, 50],
		[1, 47, 419],
		[0, 50, 390],
		[1, 18, 551],
		[0, 19, 587]
	];


	var e_ids_num = p.context.epochLabelSet.collect{|filter| p.context.epochLabelList.selectIndices({|item| filter.bubble.includes(item)}).size};

	var getSec = {
		arg min, sec, millis;
		var val = min*60;
		val = val+sec;
		val = millis*1e-3+val;
		val;
	};
	
	var rate = 100/70;
	var e_dur_sec = e_dur.collect(getSec.(*_)*rate.reciprocal);
	var e_mod = e_ids_num/e_dur_sec*dur;

	var e_start_id = p.context.epochLabelSet.collect{|filter| p.context.epochLabelList.selectIndices({|item| filter.bubble.includes(item)}).first};

	var fixed_id_list = e_ids_num.collectAs({|item, i|
		var id_range = (0..item-1);
		id_range.selectIndicesAs({|id|((id%e_mod[i].round(1e-4)).floor==0)}, List)+e_start_id[i];
	}, List).flatten;
	fixed_id_list;
};

// fixedDurIds.value.post;

var e = Environment.with(
	\ids-> fixedDurIds.value,
	\offset->0
	);

p.player.add(\sequential->e);

e.know_(true);

e.use{ |env|
	env.stream = Pser(env.ids, inf, env.offset).asStream;
	env.routine = 	r {
		arg start_id = 0;
		env.stream.reset;
		env.offset = start_id; 
		inf.do{
			var id = env.stream.next;
			id !? {
				// postf("id: %\n", id.asString.padLeft(5, " "));
				// ".".post;
				(type: \biosphera_data, id: id).play;
				s.sync;
				0.07.wait;
			};
		}
	};
};

// postf("id: %, Daily id: %\t % - % - % \n", id.asString.padLeft(5, " "), id_d.asString.padLeft(3, " "), labelData[0].padLeft(13, " "), labelData[1].padLeft(20, " "), labelData[2]);
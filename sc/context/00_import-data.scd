/*00_import-data.scd*/

var force_init_path, dest_file_path;

var d = Environment.new;
d.know_(true);

dest_file_path = thisProcess.nowExecutingPath.dirname+/+"data/collections/data-dict.scd";
force_init_path = thisProcess.nowExecutingPath.dirname+/+"data/collections/force-init.scd";

d.putAll(
	(
		init: { |env|
			env.put(\quarterHourStampList, env.dateStampList());
			env.put(\dailyStampList, env.dateStampList(thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_Daily.txt"));
			env.put(\epochLabelList, env.labelList());
			// env.put(\dailyLabelList, env.dataLabelList(thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_Daily.txt"));
			env.put(\timeOfDayLabelList, env.timeOfDayList());
			env.put(\epochLabelSet, env.epochLabelList.asSet.asArray.sort);
		},

		export: { |env|
			var j = Dictionary.with(*[\quarterHourStampList, \dailyStampList, \epochLabelList, \timeOfDayLabelList, \epochLabelSet].collect{ |item| env.associationAt(item)});
			File.use(dest_file_path, "w", { | output_file |
				output_file.putAll(j.asCompileString);
			});
		},

		import: { |env|
			var j = thisProcess.interpreter.executeFile(dest_file_path);

			env.putAll(j);
		},

		dataSetLabels: Array.with('Daily', '15min'),

		timeOfDayLabelSet: List[\midnight, \dusk, \early_morning, \morning, \mid_day, \afternoon, \evening, \night],

		prepareSigFile: {  | env, path|
			var o_path, f, dateLength;

			path = path ? (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt");
			o_path = path.drop(-4)++".sig";

			if(path == (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt")){
				dateLength = 2
			}{
				dateLength = 1
			};

			f = File(path, "r");

			File.use(o_path, "wb",
				{ | output_file |
					var l, d_l;

					//reset reading point
					f.pos = 0;f.getLine;
					l = f.getLine;

					//initiate default state
					d_l = l.split(separator: $,).drop(dateLength).collectAs({ | item, i |
						var t_item = item;
						f.pos = 0;
						f.getLine;
						while {
							t_item.isEmpty || (t_item == "NA")
						}{
							t_item = f.getLine.split(separator: $,).drop(dateLength).[i];
							// t_item.postln;
						};
						t_item.asFloat;
					}, FloatArray);

					//reset reading point
					f.pos = 0; f.getLine;//getRid of labels
					l = f.getLine;

					//place numeric data to signal file
					while {
						l.notNil
					}{
						var floatArray = l.split(separator: $,).drop(dateLength).collectAs({ | item, i |
							(item.isEmpty.not && (item != "NA")).if({d_l[i] = item.asFloat});d_l[i];
						}, FloatArray);
						output_file.putAll(floatArray);
						l = f.getLine;
					};
					postf("done creating signal file at %", o_path);
				}
			);
		},

		prepareConsolidatedSigFile: { |env|
			var path = thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_consolidated.sig";

			var qhData = File(thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.sig", "rb").readAllSignal.clump(21);
			var dailyData = File(thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_Daily.sig", "rb").readAllSignal.clump(11);
			var floatArray = FloatArray.newFrom(
				qhData.collect({ |sig, i|
					sig++j[d.getDailyIdFrom15minId(i)];
				}).flatten;
			);

			File.use(path, "wb",
				{ | output_file |
					output_file.putAll(floatArray);
					postf("done creating signal file at %", path);
			});

		},

		dataList: { | env, path |
			var l, d_l, dateLength, f;
			var list = List.new;
			path = path ? (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt");

			if(path == (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt")){
				dateLength = 2 }{
				dateLength = 1 };

			f = File(path, "r");
			//reset reading point
			f.pos = 0;f.getLine;
			l = f.getLine;

			//initiate default state
			d_l = l.split(separator: $,).drop(dateLength).collectAs({ | item, i |
				var t_item = item;
				f.pos = 0;
				f.getLine;
				while {
					t_item.isEmpty || (t_item == "NA")
				}{
					t_item = f.getLine.split(separator: $,).drop(dateLength).[i];
					// t_item.postln;
				};
				t_item.asFloat;
			}, FloatArray);
			// d_l.size.postln;

			//reset reading point
			f.pos = 0;f.getLine;//getRid of labels
			l = f.getLine;

			//place numeric data to signal file
			while {
				l.notNil
			}{
				var floatArray = l.split(separator: $,).drop(dateLength).collectAs({ | item, i |
					(item.isEmpty.not && (item != "NA")).if({d_l[i] = item.asFloat});d_l[i];
				}, FloatArray);
				list = list.add(floatArray);
				l = f.getLine;
			};
			list;
		},

		dataLabelList:{ | env, path, dateLength |
			var l, f;
			var list = List.new;
			path = path ? (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt");
			if(path == (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt")){
				dateLength = 2 }{
				dateLength = 1 };

			f = File(path, "r");
			l = f.getLine;

			list.addAll(l.split(separator: $,).drop(dateLength));
		},

		getDailyIdFrom15minId:{ |env, id| //TODO:<----move
			var i = id.asInteger;
			var b_id;

			// b_id = env.quarterHourStampList.selectIndices(_ < env.dailyStampList[i]).last;
			b_id = env.dailyStampList.selectIndices(_ < env.quarterHourStampList[i]).last;
			// d.dataList(thisProcess.nowExecutingPath.dirname+/+"logs/B2_WALD_Data_Daily.txt")[b_id];
			b_id ? 0;
		},

		labelList: { | env, path |
			var list = List.new;
			path = path ? (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt");
			// path.postln;
			f = File(path, "r");

			//reset reading point
			f.pos = 0;f.getLine;
			l = f.getLine;

			//place numeric data to signal file
			while {
				l.notNil;
			}{
				var label = l.split(separator: $,).keep(2).last;
				list = list.add(label.asSymbol);
				l = f.getLine;
			};
			list;
		},

		dateList: { | env, path |
			var list = List.new;
			path = path ? (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt");
			// path.postln;
			f = File(path, "r");

			//reset reading point
			f.pos = 0;f.getLine;
			l = f.getLine;

			//place numeric data to signal file
			while {
				l.notNil;
			}{
				var label = l.split(separator: $,).first;
				list.add(label);
				l = f.getLine;
			};
			list;
		},

		dateStampList: { | env, path|
			var list = List.new;
			var timeList = List.new;
			path = path ? (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt");
			list = env.dateList(path).collectAs({|date| date.split(separator: $ ).first.split(separator: $/).rotate(1).inject("", _++_)}, List);

			if(path == (thisProcess.nowExecutingPath.dirname+/+"data/logs/B2_WALD_Data_15min.txt")){
				timeList = env.dateList(path).collect({|stamp, i|
					if(stamp.split(separator: $ ).last == "AM"){
						var timeStamp = stamp.split(separator: $ )[1].split($:);
						if(timeStamp.first == "12") {
							timeStamp.put(0,"0");
						};
						if(timeStamp.first.asInteger < 10) {
							timeStamp.put(0, timeStamp.first.padLeft(2, "0"));
						};

						timeStamp.inject("", _++_).padRight(6, "0");
					}
					{
						var timeStamp = (stamp.split(separator: $ )[1].split($:));
						timeStamp.put(0, (timeStamp.first.asInteger+12).asString);
						if(timeStamp.first == 24) {
							timeStamp.put(0, 12);
						};
						timeStamp.inject("", _++_).padRight(6, "0");
					};
				});
				list = list.collectAs({ |date, i| date++timeList[i]}, List);
			};
			list;
		},
		timeOfDayList: { | env |
			var list = List.new;

			var timeOfDay = { |time|
				var times = ((0..7)*24/8);
				var index;
				var labels = [\midnight, \dusk, \early_morning, \morning, \mid_day, \afternoon, \evening, \night];
				index = times.indexInBetween(time.keep(2).asInteger);
				labels[index];
			};

			list = env.dateStampList.collectAs({ |item, i| timeOfDay.(item.keep(-6)).asSymbol}, List);
		}
	)
);

File.exists(force_init_path).if{
	thisProcess.interpreter.executeFile(force_init_path).if{
		File.use(force_init_path, "w", { | output_file |
			output_file.putAll(false.asCompileString);
		});
		d.init;
		d.export;
		"data initialized!".postln;
	}{

		File.exists(dest_file_path).if{
			"data loaded from file".postln;
			d.import;
		}{
			d.init;
			d.export;
			"data initialized!".postln;
		}
	}
}{
	"create force init file".postln;
	File.use(force_init_path, "w", { | output_file |
		output_file.putAll(false.asCompileString);
	});
	d.init;
};

p.k.putAll((
	context: d,
));
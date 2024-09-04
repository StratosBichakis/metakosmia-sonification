/*00_kd-tree.scd*/
var getIdsFromEpochSwitchFunc, getIdsFromTodSwitchFunc, hasSwitchedEpochIds = false, hasSwitchedTodIds = false;

var e = Environment.with(
	\server -> s,
	\filter->Environment.with(
		\last_e_fs->List[1, 1, 1, 1, 1, 1],
		\last_t_fs->List[1, 1, 1, 1, 1, 1, 1, 1],
		\epoch_ids -> p.context.epochLabelList,
		\tod_ids -> p.context.timeOfDayLabelList,
	).know_(true),
);
e.know_(true);
p.player.add(\kdtree->e);

getIdsFromEpochSwitchFunc = {
	var e_fl = p.context.epochLabelSet.copy;
	e.filter.epoch_ids = p.context.epochLabelList.selectIndices{|item| e_fl.putEach(p.touchOSC.epochFilterSwitch.selectIndices{|switch| switch!=1}, nil).includes(item)};
};

getIdsFromTodSwitchFunc = {
	var t_fl = p.context.timeOfDayLabelSet.copy;
	e.filter.tod_ids = p.context.timeOfDayLabelList.selectIndices{|item| t_fl.putEach(p.touchOSC.todFilterSwitch.selectIndices{|switch| switch!=1}, nil).includes(item)};
};

e.filter.use{ |env|
	env.obs = Observer(\kdtree_filter, Subject.topics[\filterChange], { |state|
		var verbose = false;
		verbose.if{
			state.postln;
		};
		(state.epochFilterSwitch != env.last_e_fs).if{
			verbose.if{".".postln};
			hasSwitchedEpochIds = false;
			env.last_e_fs = state.epochFilterSwitch.copy;
		};
		(state.todFilterSwitch != env.last_t_fs).if{
			verbose.if{"*".postln};
			hasSwitchedTodIds = false;
			env.last_t_fs = state.todFilterSwitch.copy;
		};
	});
};

e.use{ | env |
	var size = 60;
	env.tree = FluidKDTree(env.server, size, 0).fit(p.fluidSet.ds, {
		var xyzbuf = Buffer.alloc(env.server, 3);

		env.routine = r {
			arg id = 0;
			var last_id = Array.newClear(40);
			var weights = Array.interpolation(size).normalizeSum;
			var filtered_ids;
			inf.do{ |cnt|
				
				hasSwitchedEpochIds = CallOnlyOnce(hasSwitchedEpochIds, getIdsFromEpochSwitchFunc);
				hasSwitchedTodIds = CallOnlyOnce(hasSwitchedTodIds, getIdsFromTodSwitchFunc);
				filtered_ids = env.filter.epoch_ids.sect(env.filter.tod_ids);

				if(filtered_ids.includes(id).not){
					var index = filtered_ids.indexInBetween(id);
					index = index ? 0;// "*".postln;index.postln;
					id = filtered_ids.wrapAt(index.floor);
					id = id ? 0;
				};

				p.fluidSet.ds.getPoint(id.asString, xyzbuf, {
					xyzbuf.getn(0, 3, { |vals|
						var ctrlVal = p.ribbon.controlVal;
						var step = {[0.08, 0.001].asSpec.map(ctrlVal).rand2}.dup(3);
						xyzbuf.setn(0, vals+step);

						env.tree.kNearest(xyzbuf, size, action: { | ids |
							id = ids.asInteger.wchoose(weights);
								while{
									last_id.includes(id).and(filtered_ids.includes(id).not)
									}{
									id = ids.wchoose(weights);
								};

							last_id.wrapPut(cnt, id);

							filtered_ids.includes(id).if{
								// postf("id: %, Daily id: %\t % - % - % \n", id.asString.padLeft(5, " "), id_d.asString.padLeft(3, " "), labelData[0].padLeft(13, " "), labelData[1].padLeft(20, " "), labelData[2]);
								// postf("id: %\n", id.asString.padLeft(5, " "));
								// ",".post;
								(type: \biosphera_data, id: id).play;
							};
						});//env.tree.kNearest
					}); //xyzbuf.getn
				});//p.fluidSet.ds.getPoint
			env.server.sync;
			filtered_ids.includes(id).if{0.07.wait;};
			};//do
		};//r
	});
};
/*

p.touchOSC.put(\epochFilterSwitch, List[1, 1, 1, 0, 0, 0])
p.touchOSC.put(\epochFilterSwitch, List[1, 0, 0, 0, 0, 0])
p.touchOSC.put(\todFilterSwitch, List[1, 1, 1, 1, 1, 1, 1, 1])
p.touchOSC.put(\todFilterSwitch, List[1, 1, 1, 0, 0, 0, 0, 0])
p.touchOSC.put(\epochFilterSwitch, List[0, 0, 0, 0, 0, 0])
*/

/*01_import-flucoma-data.scd*/

var fluid_set = Environment.new;
var server = s;

fluid_set.know_(true);

p.k.putAll((
	fluidSet: fluid_set
));

server.doWhenBooted({
	fluid_set.use{ |env|
		env.ds = FluidDataSet(server).read(thisProcess.nowExecutingPath.dirname+/+"data/fluid-set/umap_3d_dataset_consolidated_202407251717.json");
		env.ls = FluidLabelSet(server).read(thisProcess.nowExecutingPath.dirname+/+"data/fluid-set/labelset_wday_wdates_15min.json");
		env.ds10d_15min = FluidDataSet(server).read(thisProcess.nowExecutingPath.dirname+/+"data/fluid-set/pca_10d_dataset_15min.json");
		env.ds6d_daily = FluidDataSet(server).read(thisProcess.nowExecutingPath.dirname+/+"data/fluid-set/pca_6d_dataset_Daily.json");
	};
	}, onFailure:{
		"fluid sets not loadded".postln;false;
	});

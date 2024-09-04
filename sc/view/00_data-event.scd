var labelData;

p.fluidSet.ls.dump{
	arg labels;
	labelData = labels.at("data");
};

Event.addEventType(\biosphera_data, { |env|
	var vals = Array.newClear(2);
	var postSpecVals = Array.new(16);
	var subj = Subject.topics[\idChange];

	~day = labelData.at(~id.asString).[0].asInteger;

	r{
		p.buffers.dataBuf6d.getn(~day*6, 6, { | v |
			vals.put(1, v);
		});
	
		p.buffers.dataBuf10d.getn(~id*10, 10, { | v |
			vals.put(0, v);
		});
	
		~epoch = labelData.at(~id.asString).[2].split("$-").first.asInteger;
		s.sync;
	
		subj.state.id = ~id;
		subj.state.preSpecVals = vals.flat;
		subj.notify;
		
		postSpecVals = vals.flat.collect{|item, i| (\klmxspec_++i).asSymbol.asSpec.map(item)};
		
	
		p.buffers.dataBuf16d.setn(0, postSpecVals);
	
		s.sync;
	
		~type = \note;
		~instrument = \smear_experimental;
		~soundBufnum = p.buffers.soundBuf[~epoch-1];
		currentEnvironment.play;
	}.play;
}, (bufnum: p.buffers.fftBuf, dataBuf16d: p.buffers.dataBuf16d)++(id:0, day: 0, epoch:1));


/*
(type: \biosphera_data, id: 12032).play
*/

// thisProcess.openUDPPort(10000);
// OSCFunc.trace(hideStatusMsg: true);

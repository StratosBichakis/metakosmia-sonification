/*observers.scd*/
var td, dataOut;

Subject.addSubjectTopic(\idChange, (id: 0, \preSpecVals: Array.newClear(16)));

td = Environment.with(
	\addr->NetAddr("localhost", 10000),
	\obs_id->Observer(\touchDesignerId, Subject.topics[\idChange], { |state|
		td.addr.sendMsg('sonify/nodeId', state.[\id]);
	}),
	\obs_idle->Observer(\touchDesignerIdle, Subject.topics[\idleMode], { |state|
		td.addr.sendMsg('sonify/isIdle', state.[\isIdle].asInteger);
	}),
	\obs_zoom->Observer(\touchDesignerZoom, Subject.topics[\zoom], { |state|
		td.addr.sendMsg('sonify/zoom', state.[\zoom]);
	}),
).know_(true);

/* for live performance
dataOut = Environment.with(
	\obs->Observer(\dataOutId, Subject.topics[\idChange], { | state |
		dataOut.addr.sendMsg('sonify/data', *state.[\preSpecVals]);
	}),
	\addr->NetAddr("192.168.0.255", 57120),
).know_(true);
*/
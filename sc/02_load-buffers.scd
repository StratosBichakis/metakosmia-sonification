/*02_load-buffers.scd*/
var b = Environment.new;
b.know_(true);

p.k.putAll((
	buffers: b,
));

b.putAll((
	init: { | env, server |
		server = server ? Server.default;
		env.fftBuf = Buffer.alloc(server, 2.pow(14));
		env.dataBuf10d = Buffer.alloc(server, 1, 10);
		env.dataBuf6d = Buffer.alloc(server, 1, 6);
		env.dataBuf16d = Buffer.alloc(server, 1, 16);
		
		env.soundBuf = PathName(thisProcess.nowExecutingPath.dirname+/+"buffers").files.collect{ |path|
			Buffer.readChannel(channels: [0], path: path.asAbsolutePath);
		};
		s.sync;
		p.fluidSet.ds10d_15min.toBuffer(env.dataBuf10d);
		p.fluidSet.ds6d_daily.toBuffer(env.dataBuf6d);
	};
	)
)

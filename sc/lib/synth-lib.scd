/*synth-lib.scd*/
var e = Environment.with(
	\init-> { | env, server |
		server = server ? s;
		SynthDef(\smear_old, { | out = 0, bufnum = 0, soundBufnum = 2, rate = 1, dataBuf10d, dataBuf6d, id, id_d|
			var sig, chain;
			var data10d = BufRd.kr(10, dataBuf10d, id, 0);
			var data6d  = BufRd.kr(6, dataBuf6d, id_d, 0);

			var dur = rate.abs.reciprocal*BufRateScale.ir(soundBufnum)*BufSamples.ir(soundBufnum)/SampleRate.ir;
			var doneDur = Line.ar(0, BufSamples.ir(soundBufnum), 10/**dur*/, doneAction: Done.freeSelf);
			var env = EnvGen.kr(Env([0, 1.2, 0.8, 0.2], [0.05, 1.5, 8], \sin));

			var windowSize = 2.pow(13);
			var oct = [2, 5].asSpec.map(data10d[0]);//2.1234;
			var offset = [0, BufSamples.ir(soundBufnum)/5].asSpec.map(data6d[0]+data10d[1]*0.5);
			// var kernel_phs = Sweep.ar(1, rate: BufRateScale.ir(soundBufnum)*SampleRate.ir);
			var kernel_sig = PlayBuf.ar(1, bufnum, 1.0*BufRateScale.kr(bufnum), 1, 0);

			var phs;

			rate = rate*[0.4, 2.6].asSpec.map(data6d[1]);
			phs = Sweep.ar(1, rate: rate*BufRateScale.ir(soundBufnum)*SampleRate.ir)+offset;
			sig = BufRd.ar(1, soundBufnum, phs, 0);
			chain = FFT(bufnum, sig*3, hop: 0.5, wintype: 0, winsize: windowSize);

			chain  = PV_BinShift(chain, 0.38, windowSize / 2.pow(11 - oct), interp: 1);
			chain = PV_BrickWall(chain, 0.009);
			// chain = PV_BrickWall(chain, -0.92);
			// chain = PV_SpectralEnhance(chain, 0.8, 1.12, 2);
			// chain = PV_MagMulAdd(chain, 2); //TODO: Reduce dominant frequency amplitude

			chain = PV_MagSmooth(chain, env);
			chain = PV_MagSmear(chain, 2.pow(1));
			// chain = PV_MagNoise(chain);
			// chain = PV_BrickWall(chain, -0.708);
			// chain = PV_BrickWall(chain, 0.016);
			// chain = PV_Freeze(chain, ToggleFF.ar(Impulse.ar(dur.reciprocal, -0.08)).poll);
			sig = 0.5*IFFT(chain);
			sig = XFade2.ar(sig, Convolution.ar(sig, 8*kernel_sig, 2.pow(12)), 0.2) ;
			Out.ar(out, sig.dup);
		}).add;//(s,[\out, 0, \bufnum, b.bufnum, \soundBufnum, c.bufnum, \rate, 0.72]);

		SynthDef(\smear_experimental, { | out = 0, bufnum = 0, soundBufnum = 2, rate = 1, dataBuf16d|
			var sig, chain;
			var data16d = BufRd.kr(16, dataBuf16d);

			var dur = rate.abs.reciprocal*BufRateScale.ir(soundBufnum)*BufSamples.ir(soundBufnum)/SampleRate.ir;
			var doneDur = Line.ar(0, BufSamples.ir(soundBufnum), 3/**dur*/, doneAction: Done.freeSelf);
			var env = EnvGen.kr(Env([0, 1.2, 0.7, 0.2], [0.05, 1.2, 4], \sin));

			var windowSize = 2.pow(13);
			var oct = [1, 5].asSpec.map(data16d[0]);//2.1234;
			var offset = [0, BufSamples.ir(soundBufnum)/5].asSpec.map(data16d[10]+data16d[1]*0.5);
			// var kernel_phs = Sweep.ar(1, rate: BufRateScale.ir(soundBufnum)*SampleRate.ir);
			var kernel_sig = PlayBuf.ar(1, bufnum, 1.0*BufRateScale.kr(bufnum), 1, 0);

			var phs;
			var conv_mix = [-0.2, 0.4].asSpec.map(data16d[0]);

			rate = rate*[0.4, 2.6].asSpec.map(data16d[11]);
			phs = Sweep.ar(1, rate: rate*BufRateScale.ir(soundBufnum)*SampleRate.ir)+offset;
			sig = BufRd.ar(1, soundBufnum, phs, 0);
			chain = FFT(bufnum, sig*3, hop: 0.5, wintype: 0, winsize: windowSize);

			chain  = PV_BinShift(chain, 0.28, windowSize / 2.pow(10 - oct), interp: 1);
			chain = PV_BrickWall(chain, 0.003);
			// chain = PV_BrickWall(chain, -0.92);
			chain = PV_SpectralEnhance(chain, 0.7, 1.012, 4);
			chain = PV_MagMulAdd(chain, 0.98); //TODO: Reduce dominant frequency amplitude

			chain = PV_MagSmooth(chain, env);
			chain = PV_MagSmear(chain, 2.pow(2));
			chain = Select.kr(data16d[12]>0.6, [chain, PV_MagNoise(chain)]);
			// chain = PV_BrickWall(chain, -0.708);
			// chain = PV_BrickWall(chain, 0.016);
			// chain = PV_Freeze(chain, ToggleFF.ar(Impulse.ar(dur.reciprocal, -0.08)).poll);
			sig = IFFT(chain);
			sig = XFade2.ar(sig, Convolution.ar(sig, 8*kernel_sig, 2.pow(12)), [conv_mix, (conv_mix.neg)]+0.3) ;
			Out.ar(out, (10.dbamp*sig.tanh)*(-12.dbamp));
			// Out.ar(out, ([-10, 10, -2].asSpec.map(data16d[8]).dbamp*sig.tanh)*(-12.dbamp));
		}).add;//(s,[\out, 0, \bufnum, b.bufnum, \soundBufnum, c.bufnum, \rate, 0.72]);

		SynthDef(\smear_live, { | out = 0, bufnum = 0, soundBufnum = 2, dataBuf16d = 3|
			var sig, chain;
			var data16d = BufRd.kr(16, dataBuf16d);
			var rate = 1;
			var dur = rate.abs.reciprocal*BufRateScale.ir(soundBufnum)*BufSamples.ir(soundBufnum)/SampleRate.ir;
			var doneDur = Line.ar(0, BufSamples.ir(soundBufnum), 10/**dur*/, doneAction: Done.freeSelf);

			var env_l0 = [0, 1].asSpec.map(data16d[4]);
			var env_l1 = data16d[2].clip(0.7, 1.6);
			var env_l2 = data16d[3].clip(0.5, 0.8);
			var env_l3 = data16d[5].clip(0.0, 0.5);
			var env_t0 = data16d[6].clip(0.0, 0.2);
			var env_t1 = data16d[7].clip(0.6, 3);
			var env_t2 = data16d[8].clip(0.6, 12);
			var xfade = data16d[9].clip(0, 1);
			var f_hpf = data16d[12].clip(-1, 0);
			var f_lpf = data16d[13].clip(0, 1);

			var env = EnvGen.kr(Env([env_l0, env_l1, env_l2, env_l3], [env_t0, env_t1, 8], \sin));

			var windowSize = 2.pow(13);
			var oct = [2, 5].asSpec.map(data16d[0]);//2.1234;
			var offset = [0, BufSamples.ir(soundBufnum)/5].asSpec.map(data16d[10]+data16d[1]*0.5);
			// var kernel_phs = Sweep.ar(1, rate: BufRateScale.ir(soundBufnum)*SampleRate.ir);
			var kernel_sig = PlayBuf.ar(1, bufnum, 1.0*BufRateScale.kr(bufnum), 1, 0);
			var phs;


			rate = rate*[0.4, 2.6].asSpec.map(data16d[11]);

			phs = Sweep.ar(1, rate: rate*BufRateScale.ir(soundBufnum)*SampleRate.ir)+offset;
			sig = BufRd.ar(1, soundBufnum, phs, 0);
			chain = FFT(bufnum, sig*3, hop: 0.5, wintype: 0, winsize: windowSize);

			chain  = PV_BinShift(chain, 0.38, windowSize / 2.pow(11 - oct), interp: 1);
			chain = PV_BrickWall(chain, 0.009);
			// chain = PV_BrickWall(chain, -0.92);
			// chain = PV_SpectralEnhance(chain, 0.8, 1.12, 2);
			// chain = PV_MagMulAdd(chain, 2); //TODO: Reduce dominant frequency amplitude


			chain = PV_MagSmooth(chain, env);
			chain = PV_MagSmear(chain, 2.pow(1));
			// chain = PV_MagNoise(chain);
			// chain = PV_BrickWall(chain, f_hpf);
			// chain = PV_BrickWall(chain, f_lpf);
			// chain = PV_Freeze(chain, ToggleFF.ar(Impulse.ar(dur.reciprocal, -0.08)).poll);
			sig = 0.5*IFFT(chain);
			sig = XFade2.ar(sig, Convolution.ar(sig, 8*kernel_sig, 2.pow(12)), data16d[2]) ;
			Out.ar(out, sig.dup);
		}).add;//(s,[\out, 0, \bufnum, b.bufnum, \soundBufnum, c.bufnum, \rate, 0.72]);

		"synths loadded".postln;

	}
	);

e.know_(true);

p.k.putAll((
	synth: e,
));

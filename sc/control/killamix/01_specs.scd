/* 01_specs.scd */

var print = false;

Spec.specs.putAll(
	16.collectAs({|i| (\klmxspec_++i).asSymbol -> [0, 1].asSpec},IdentityDictionary);
);

Killamix.mktl.elAt(\kn, \all, [0, 2, 4, 6, 9]).do{ | pg, ch |
	pg.do{ | clmn, i |
		clmn.do{ | enc |
			var i_enc = enc.key.asInteger-1;
			Killamix.value[ch][i_enc] = 0;
			enc.deviceValue = 0;
		}
	}
};

Killamix.mktl.elAt(\kn, \all, [0, 2, 4, 6]+1).do{ | pg, ch |
	pg.do{ | clmn, i |
		clmn.do{ | enc |
			var i_enc = enc.key.asInteger-1;
			Killamix.value[ch][i_enc] = 1.0;
			Killamix.defaultValue[ch][i_enc] = 1.0;
			enc.deviceValue = \midi.asSpec.map(1);
		}
	}
};

(0..3).do{ |enc_offset|
	Killamix.mktl.elAt(\kn, \all, [0, 4]+enc_offset).do({ |  pg, ch |
		pg.do{ | clmn, i |
			clmn.addAction({ |enc|
				if(Killamix.mktl.elAt(\enc_bt, ch, i).value == 0 ) {
					var i_enc = enc.key.asInteger-1;
					var spec = (\klmxspec_++i).asSymbol;
					var t_spec = ([Killamix.value[ch][i_enc-enc_offset], Killamix.value[ch][i_enc-enc_offset+1]]++[0.0, 0.0, 0.0]).asSpec;
					var shift_val = Killamix.value[ch][i_enc-enc_offset+2];
					var zoom_val = Killamix.value[ch][i_enc-enc_offset+3];
					spec.asSpec.setFrom(t_spec.zoom(zoom_val).shift(shift_val));
					print.if{spec.asSpec.postln};
				};
			});
		};
	});
};

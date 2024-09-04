/* 02_state.scd */

Killamix.k.putAll(
	(
		saveState:{
			| env |
			var j = Dictionary.with(*[Killamix.k.associationAt(\step), Killamix.k.associationAt(\defaultValue), (\value->Killamix.value)]);
			var f = File.use(p.dir+/+"control/killamix/state.json", "w",
				{ | output_file |
					output_file.write(JSON.stringify(j));
			});
		},
		recallState:{
			| env |
			var j = parseYAMLFile(p.dir+/+"control/killamix/state.json");
			Killamix.value.size.do{ | i |
				Killamix.value.put(i, j.at("value")[i].asFloat);
			};
			Killamix.value.size.do{ | i |
				Killamix.step.put(i, j.at("step")[i].asFloat);
			};
			Killamix.value.size.do{ | i |
				Killamix.defaultValue.put(i, j.at("defaultValue")[i].asFloat);
			};

			Killamix.mktl.elAt(\kn, \all, \all).do{ | pg, ch |
				pg.do{ | clmn, i |
					clmn.do{ | kn |
						kn.deviceValue = \midi.asSpec.map(Killamix.value[ch][i]);
					}
				}
			};
		}
	)
);

Killamix.recallState;


/*
Killamix.saveState
Killamix.recallState
*/


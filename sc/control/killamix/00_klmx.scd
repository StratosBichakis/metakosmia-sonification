/*00_klmx.scd*/
r{
	p.put(\klmx, Killamix.start(true));

	"01_specs.scd".loadRelative;
	"02_state.scd".loadRelative;
}.play(AppClock)



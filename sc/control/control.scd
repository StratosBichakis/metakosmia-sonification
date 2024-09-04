/*control.scd*/
r{

if(MIDIClient.initialized.not){
	MIDIClient.init;
};

"killamix/00_klmx.scd".loadRelative;
"ribbon-ctrl/00_ribbon.scd".loadRelative;
"touch-osc/00_touch-osc.scd".loadRelative;
}.play(AppClock);
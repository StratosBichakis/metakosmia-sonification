/*control.scd*/
var idleWaitTime = 2*60;
Subject.addSubjectTopic(\idleMode, (isIdle: true));
Subject.addSubjectTopic(\zoom, (zoom: 0.5));

TimeOut.addTimeOutJob(\idleWatch, idleWaitTime, {(type:\subj_idleMode, isIdle:true).play}, tick:1).quit;

r{
if(MIDIClient.initialized.not){
	MIDIClient.init;
};
"killamix/00_klmx.scd".loadRelative;
"ribbon-ctrl/00_ribbon.scd".loadRelative;
"touch-osc/00_touch-osc.scd".loadRelative;
}.play(AppClock);
package com.ociweb.main;

import com.ociweb.TheJoveExpress;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.network.ClientConnection;
import com.ociweb.pronghorn.stage.scheduling.FixedThreadsScheduler;
import com.ociweb.pronghorn.stage.scheduling.GraphManager;
import com.ociweb.pronghorn.stage.scheduling.ScriptedFixedThreadsScheduler;
import com.ociweb.pronghorn.stage.scheduling.ScriptedNonThreadScheduler;

public class FogLight {

	public static void main(String[] args) {
		GraphManager.showThreadIdOnTelemetry = true;
		FogRuntime.run(new TheJoveExpress(), args);
	}
	
}

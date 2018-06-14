package com.ociweb.main;

import com.ociweb.TheJoveExpress;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.stage.scheduling.GraphManager;

public class FogLight {

	public static void main(String[] args) {

		GraphManager.combineCommonEdges = false;
		FogRuntime.run(new TheJoveExpress(), args);
	}
	
}

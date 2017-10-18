package com.ociweb.main;

import com.ociweb.Thermometer;
import com.ociweb.iot.maker.FogRuntime;

	public class FogLight {
	
		public static void main(String[] args) {
			FogRuntime.run(new Thermometer(),args);
		}
	
}

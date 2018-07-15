package com.ociweb.main;

import com.ociweb.TheJoveExpress;
import com.ociweb.iot.maker.FogRuntime;

public class FogLight {
	public static void main(String[] args) {
		FogRuntime.run(new TheJoveExpress(), args);
	}
}

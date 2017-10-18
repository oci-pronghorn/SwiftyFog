package com.ociweb.behaviors;

import com.ociweb.iot.maker.AnalogListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;

public class TempSensorBehavior implements AnalogListener {
	private final FogCommandChannel channel;
	private String publishTopic;
	private Port sensorPort; 
	private int oldValue = 0;
	
	/* TODO: magic numbers, what do they mean!? */
    private final int B = 4275;
    private final int R0 = 100000; 
    
	public TempSensorBehavior(FogRuntime runtime, Port sensorPort, String publishTopic) { 
		 this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
	     this.sensorPort = sensorPort;
	     this.publishTopic = publishTopic;
    }
    
    @Override
    public void analogEvent(Port port, long time, long durationMillis, int average, int value) {
        if(this.sensorPort == port) {
	       
	        double R =  (1023.0/value-1.0);
	        R = R0*R;
	        double preciseTemperature =1.0/(Math.log(R/R0)/B+1/298.15)-273.15; //TODO int->double?
	        int temperature = (int)preciseTemperature;
	        
	        System.out.printf("*** Analog event received with value %.8f (-> %d Celsius)", preciseTemperature, temperature);
	        
        		if(temperature != oldValue) {
        			oldValue = temperature;
        			if(!channel.publishTopic(publishTopic, writer->{ writer.writeInt(value); })) {
        				System.out.println("**** Temperature Reading Change Failed to Publish ****");
        			}
        		}
        }
    }
	
}

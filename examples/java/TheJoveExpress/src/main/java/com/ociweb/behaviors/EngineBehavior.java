package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.MotionFaults;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

/**
    EngineBehavior encapsulates all the business logic for managing the interaction
    between the actuator, and external commands.
    It broadcasts feedback whenever state changes.

    The actuator behaviors perform the hardware tasks.
 */
public class EngineBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService actuatorService;
    private final PubSubFixedTopicService engineStateService;
    private final PubSubFixedTopicService powerService;
    private final PubSubFixedTopicService calibrationService;
    
    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final RationalPayload enginePower = new RationalPayload(0, 100);
    private final RationalPayload calibration;
    private final MotionFaults motionFaults = new MotionFaults();
    private int engineState = 0;

    public EngineBehavior(FogRuntime runtime, int calibration, String actuatorTopic, ActuatorDriverPort port, String enginePoweredTopic, String engineCalibratedTopic, String engineStateTopic) {
        this.calibration = new RationalPayload(calibration, 100);

        FogCommandChannel newCommandChannel = runtime.newCommandChannel();
		this.actuatorService = newCommandChannel.newPubSubService(actuatorTopic);
        this.engineStateService = newCommandChannel.newPubSubService(engineStateTopic);
        this.powerService = newCommandChannel.newPubSubService(enginePoweredTopic);
        this.calibrationService = newCommandChannel.newPubSubService(engineCalibratedTopic);

        this.actuatorPayload.port = port;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.powerService.hasRoomFor(1)
    	   	 && this.calibrationService.hasRoomFor(1)
    	   	 && this.engineStateService.hasRoomFor(1) ) {
	        this.powerService.publishTopic( writer -> writer.write(enginePower));
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
	        return true;
    	}
    	return false;
    }

    public boolean onFault(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.powerService.hasRoomFor(1)
    	    	 && this.actuatorService.hasRoomFor(1)
    	    	 && this.engineStateService.hasRoomFor(1) ) {
    		
	        messageReader.readInto(motionFaults);
	        if (motionFaults.hasFault()) {
	            enginePower.num = 0;
	            actuate();
	            this.powerService.publishTopic( writer -> writer.write(enginePower));
	        }
	        return true;
	    } else {
	    	return false;
	    }
	}

    public boolean onPower(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.powerService.hasRoomFor(1)
   	    	 && this.actuatorService.hasRoomFor(1)
   	    	 && this.engineStateService.hasRoomFor(1)
   	    			) { 
	        messageReader.readInto(enginePower);
	        actuate();
	        this.powerService.publishTopic( writer -> writer.write(enginePower));
	        return true;
    	}
    	return false;
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.calibrationService.hasRoomFor(1)
   	    	 && this.actuatorService.hasRoomFor(1)
   	    	 && this.engineStateService.hasRoomFor(1)
   	    			) { 
	        messageReader.readInto(calibration);
	        actuate();	
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        return true;
    	}
    	return false;
    }

    private void actuate() {
        double actualPower = enginePower.ratio();
        double calibrationLimit = calibration.ratio();
        if (Math.abs(actualPower) < calibrationLimit) {
            actualPower = 0.0;
        }
        int state = Double.compare(actualPower, 0.0);
        if (actualPower != actuatorPayload.power) {
            actuatorPayload.power = actualPower;
            this.actuatorService.publishTopic( writer -> writer.write(actuatorPayload));
        }
        if (state != engineState) {
            engineState = state;
            this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
        }
    }
}

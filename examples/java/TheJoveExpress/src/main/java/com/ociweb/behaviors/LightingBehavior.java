package com.ociweb.behaviors;

import static com.ociweb.behaviors.AmbientLightBehavior.maxSensorReading;
import static com.ociweb.iot.maker.TriState.latent;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.api.TimeListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.TriState;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

/*
    LightingBehavior encapsulates all the business logic for managing the interaction
    between the light sensor, the light, actuator, and external commands.
    It broadcasts feedback whenever state changes.

    The actuator behaviors perform the hardware tasks.
 */

public class LightingBehavior implements PubSubMethodListener, TimeListener, StartupListener {
	private final PubSubFixedTopicService actuatorService;
    private final PubSubFixedTopicService overrideService;
    private final PubSubFixedTopicService powerService;    
    private final PubSubFixedTopicService calibrationService;
    
    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();

    private final RationalPayload calibration = new RationalPayload(maxSensorReading/2, maxSensorReading);
    private final RationalPayload ambient = new RationalPayload(maxSensorReading, maxSensorReading);

    private double determinedPower = -1.0;
    private Double overridePower = null;

    private int flashCount = 1;
    private long flashStamp = 0;

    public LightingBehavior(FogRuntime runtime, String actuatorTopic, ActuatorDriverPort port, String overrideTopic, String powerTopic, String calibrationTopic) {
        FogCommandChannel newCommandChannel = runtime.newCommandChannel();
		this.actuatorService = newCommandChannel.newPubSubService(actuatorTopic);
        this.overrideService = newCommandChannel.newPubSubService(overrideTopic);
        this.powerService = newCommandChannel.newPubSubService(powerTopic);
        this.calibrationService = newCommandChannel.newPubSubService(calibrationTopic);
        
        this.actuatorPayload.port = port;
        this.actuatorPayload.power = -1.0;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
    	
    	if (this.overrideService.hasRoomFor(1)
    	   && this.powerService.hasRoomFor(1)
    	   && this.calibrationService.hasRoomFor(1)) {
    	
	        boolean isOn = this.actuatorPayload.power > 0.0;
	        TriState lightsOn = overridePower == null ? latent : overridePower == 0.0 ? TriState.on : TriState.off;
	        this.overrideService.publishTopic( writer -> writer.writeInt(lightsOn.ordinal()));
	        this.powerService.publishTopic( writer -> writer.writeBoolean(isOn));
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        return true;
    	}
    	return false;
    }

    @Override
	// Is there a better way to flash the lights on system ready?
    public void startup() {
        flashCount = 2;
    }

    public boolean onOverride(CharSequence charSequence, ChannelReader messageReader) {

    	if (this.overrideService.hasRoomFor(1)
    	   && this.powerService.hasRoomFor(1)
    	   && this.actuatorService.hasRoomFor(1)) {
    		
	        int state = messageReader.readInt();
	        TriState lightsOn = TriState.values()[state];
	        switch (lightsOn) {
	            case on:
	                overridePower = 1.0;
	                break;
	            case off:
	                overridePower = 0.0;
	                break;
	            case latent:
	                overridePower = null;
	                break;
	        }
	        this.overrideService.publishTopic( writer -> writer.writeInt(lightsOn.ordinal()));
	        actuate();
	        return true;
    	}
		return false;
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
    	
    	if (this.calibrationService.hasRoomFor(1)
    	   && this.powerService.hasRoomFor(1)
    	   && this.actuatorService.hasRoomFor(1)) {
    	    	
	        messageReader.readInto(this.calibration);
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        if (ambient.num >= calibration.num) {
	            determinedPower = 0.0;
	        } else {
	            determinedPower = 1.0;
	        }
	        actuate();
	        return true;
    	}
    	return false;
    }

    public boolean onDetected(CharSequence charSequence, ChannelReader messageReader) {

    	if (this.powerService.hasRoomFor(1) && this.actuatorService.hasRoomFor(1)) {
	    	messageReader.readInto(ambient);
	        if (ambient.num >= calibration.num) {
	            determinedPower = 0.0;
	        } else {
	            determinedPower = 1.0;
	        }
	        actuate();
	        return true;
	    }
		return false;
	}

    @Override
    public void timeEvent(long time, int iteration) {
        if (flashCount > 1 ) {
            if ((time - flashStamp) >= 1000) {
                flashStamp = time;
                actuate();
                flashCount++;
                if (flashCount > 9) {
                    flashCount = 1;
                }
            }
        }
    }

    private void actuate() {
        Double updatePower;
        if (flashCount > 1 )  {
            updatePower = (flashCount % 2 == 0) ? 1.0 : 0.0;
        }
        else {
            updatePower = overridePower != null ? overridePower : determinedPower;
        }
        if (updatePower != this.actuatorPayload.power) {
            this.actuatorPayload.power = updatePower;
            this.actuatorService.publishTopic( writer -> writer.write(actuatorPayload));
            boolean isOn = this.actuatorPayload.power > 0.0;
            this.powerService.publishTopic( writer -> writer.writeBoolean(isOn));
        }
    }
}

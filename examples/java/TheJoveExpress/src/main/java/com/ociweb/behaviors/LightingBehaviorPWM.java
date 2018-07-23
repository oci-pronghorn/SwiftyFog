package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.api.TimeListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.PinService;
import com.ociweb.iot.maker.Port;
import com.ociweb.iot.maker.TriState;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.behaviors.AmbientLightBehavior.maxSensorReading;
import static com.ociweb.iot.maker.TriState.latent;

public class LightingBehaviorPWM implements PubSubMethodListener, TimeListener, StartupListener {

    private final PubSubFixedTopicService overrideService;
    private final PubSubFixedTopicService powerService;    
    private final PubSubFixedTopicService calibrationService;
    private final PinService pwmService;

    private final RationalPayload calibration = new RationalPayload(maxSensorReading/2, maxSensorReading);
    private final RationalPayload ambient = new RationalPayload(maxSensorReading, maxSensorReading);

    private double determinedPower = -1.0;
    private Double overridePower = null;

    private int flashCount = 1;
    private long flashStamp = 0;
    private boolean isOn;
    
    private Port port;    
    private int twigRange = 1024;
    

    public LightingBehaviorPWM(FogRuntime runtime, Port port, String overrideTopic, String powerTopic, String calibrationTopic) {

        this.overrideService = runtime.newCommandChannel().newPubSubService(overrideTopic);
        this.powerService = runtime.newCommandChannel().newPubSubService(powerTopic);
        this.calibrationService = runtime.newCommandChannel().newPubSubService(calibrationTopic);
        this.pwmService = runtime.newCommandChannel().newPinService();
        this.port = port;
        
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
     
        TriState lightsOn = overridePower == null ? latent : overridePower == 0.0 ? TriState.on : TriState.off;
        if (overrideService.hasRoomFor(1) && powerService.hasRoomFor(1) && calibrationService.hasRoomFor(1)) {        
	        this.overrideService.publishTopic( writer -> writer.writeInt(lightsOn.ordinal()));
	        this.powerService.publishTopic( writer -> writer.writeBoolean(isOn));
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        return true;
        } else {
        	return false;
        }
    }

    @Override
    public void startup() {
        flashCount = 2;
    }

    public boolean onOverride(CharSequence charSequence, ChannelReader messageReader) {
    	
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

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
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

    public boolean onDetected(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(ambient);
        if (ambient.num >= calibration.num) {
            determinedPower = 0.0;
        } else {
            determinedPower = 1.0;
        }
        actuate();
        return true;
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
                
		if (!this.pwmService.setValue(port, (int)(twigRange*updatePower))) {;
		
			if (isOn != (updatePower>0)) {
				this.isOn = (updatePower>0);
				this.powerService.publishTopic( writer -> writer.writeBoolean(isOn));
			}
		}
        
        
    }
}

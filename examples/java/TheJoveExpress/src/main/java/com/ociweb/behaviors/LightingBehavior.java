package com.ociweb.behaviors;

import static com.ociweb.behaviors.AmbientLightBehavior.maxSensorReading;
import static com.ociweb.iot.maker.TriState.latent;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.api.TimeListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.iot.maker.TriState;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class LightingBehavior implements PubSubMethodListener, TimeListener, StartupListener {
    
	private final PubSubFixedTopicService actuatorService;
    private final PubSubFixedTopicService overrideService;
    private final PubSubFixedTopicService powerService;    
    private final PubSubFixedTopicService calibrationService;
    
    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
   // private final PinService ledPinService;

    private final Port ledPort;

    private final RationalPayload calibration = new RationalPayload(maxSensorReading/2, maxSensorReading);
    private final RationalPayload ambient = new RationalPayload(maxSensorReading, maxSensorReading);

    private double determinedPower = -1.0;
    private Double overridePower = null;

    private int flashCount = 1;
    private long flashStamp = 0;

    public LightingBehavior(FogRuntime runtime, String actuatorTopic, ActuatorDriverPort port, Port ledPort, String overrideTopic, String powerTopic, String calibrationTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        //this.ledPinService = channel.newPinService();
        this.ledPort = ledPort;
        this.actuatorService = channel.newPubSubService(actuatorTopic);
        this.overrideService = channel.newPubSubService(overrideTopic);
        this.powerService = channel.newPubSubService(powerTopic);
        this.calibrationService = channel.newPubSubService(calibrationTopic);
        
        this.actuatorPayload.port = port;
        this.actuatorPayload.power = -1.0;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        boolean isOn = this.actuatorPayload.power > 0.0;
        TriState lightsOn = overridePower == null ? latent : overridePower == 0.0 ? TriState.on : TriState.off;
        this.overrideService.publishTopic( writer -> writer.writeInt(lightsOn.ordinal()));
        this.powerService.publishTopic( writer -> writer.writeBoolean(isOn));
        this.calibrationService.publishTopic( writer -> writer.write(calibration));
        return true;
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
        //System.out.println("Asked to actuate on LED.");
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

            //ledPinService.setValue(ledPort, isOn);

            this.powerService.publishTopic( writer -> writer.writeBoolean(isOn));

            //System.out.println("Updating LED to " + isOn + "...");

        }
        //ledPinService.setValue(ledPort, updatePower == 1.0);
    }
}

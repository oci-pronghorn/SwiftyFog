package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.api.TimeListener;
import com.ociweb.iot.maker.*;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.behaviors.AmbientLightBehavior.maxSensorReading;
import static com.ociweb.iot.maker.TriState.latent;

public class LightingBehavior implements PubSubMethodListener, TimeListener, StartupListener {
    private final FogCommandChannel channel;
    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final String actuatorTopic;
    private final String overrideTopic;
    private final String powerTopic;
    private final String calibrationTopic;

    private final RationalPayload calibration = new RationalPayload(maxSensorReading/2, maxSensorReading);
    private final RationalPayload ambient = new RationalPayload(maxSensorReading, maxSensorReading);

    private double determinedPower = -1.0;
    private Double overridePower = null;

    private int flashCount = 1;
    private long flashStamp = 0;

    public LightingBehavior(FogRuntime runtime, String actuatorTopic, ActuatorDriverPort port, String overrideTopic, String powerTopic, String calibrationTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.actuatorTopic = actuatorTopic;
        this.overrideTopic = overrideTopic;
        this.powerTopic = powerTopic;
        this.calibrationTopic = calibrationTopic;
        this.actuatorPayload.port = port;
        this.actuatorPayload.power = -1.0;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        boolean isOn = this.actuatorPayload.power > 0.0;
        TriState lightsOn = overridePower == null ? latent : overridePower == 0.0 ? TriState.on : TriState.off;
        this.channel.publishTopic(overrideTopic, writer -> writer.writeInt(lightsOn.ordinal()));
        this.channel.publishTopic(powerTopic, writer -> writer.writeBoolean(isOn));
        this.channel.publishTopic(calibrationTopic, writer -> writer.write(calibration));
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
        this.channel.publishTopic(overrideTopic, writer -> writer.writeInt(lightsOn.ordinal()));
        actuate();
        return true;
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(this.calibration);
        this.channel.publishTopic(calibrationTopic, writer -> writer.write(calibration));
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
        if (updatePower != this.actuatorPayload.power) {
            this.actuatorPayload.power = updatePower;
            this.channel.publishTopic(actuatorTopic, writer -> writer.write(actuatorPayload));
            boolean isOn = this.actuatorPayload.power > 0.0;
            this.channel.publishTopic(powerTopic, writer -> writer.writeBoolean(isOn));
        }
    }
}

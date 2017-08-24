package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.*;
import com.ociweb.model.ActuatorDriverPayLoad;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.BlobReader;

import static com.ociweb.behaviors.AmbientLightBroadcast.maxSensorReading;

public class LightingBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final ActuatorDriverPayLoad payload = new ActuatorDriverPayLoad();
    private final String publishTopic;
    private final String lightCalibratedTopic;
    private final String actuatorControlTopic;

    private final RationalPayload calibration = new RationalPayload(-1, maxSensorReading);
    private final RationalPayload ambient = new RationalPayload(-1, maxSensorReading);

    private Double determinedPower = null;
    private Double overridePower = null;

    public LightingBehavior(FogRuntime runtime, String actuatorControlTopic, ActuatorDriverPort port, String publishTopic, String lightCalibratedTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.publishTopic = publishTopic;
        this.lightCalibratedTopic = lightCalibratedTopic;
        this.payload.port = port;
        this.payload.power = -1.0;
        this.actuatorControlTopic = actuatorControlTopic;
    }

    public boolean onMqttConnected(CharSequence charSequence, BlobReader messageReader) {
        boolean isOn = this.payload.power != 0.0;
        this.channel.publishTopic(lightCalibratedTopic, writer -> writer.write(calibration));
        this.channel.publishTopic(publishTopic, writer -> writer.writeBoolean(isOn));
        return true;
    }

    public boolean onCalibrate(CharSequence charSequence, BlobReader messageReader) {
        messageReader.readInto(this.calibration);
        this.channel.publishTopic(lightCalibratedTopic, writer -> writer.write(calibration));
        return true;
    }

    public boolean onOverride(CharSequence charSequence, BlobReader messageReader) {
        int state = messageReader.readInt();
        TriState lightsOn = TriState.values()[state];
        Double newPower;
        if (lightsOn == TriState.latent) {
            newPower = null;
        }
        else if (lightsOn == TriState.on) {
            newPower = 1.0;
        }
        else {
            newPower = 0.0;
        }
        overridePower = newPower;
        issuePower();
        return true;
    }

    public boolean onDetected(CharSequence charSequence, BlobReader messageReader) {
        messageReader.readInto(ambient);

        Double newPower;
        if (calibration.num == -1) {
            calibration.num = ambient.num / 2;
            this.channel.publishTopic(lightCalibratedTopic, writer -> writer.write(calibration));
            newPower = 0.0;
        } else if (ambient.num >= calibration.num) {
            newPower = 0.0;
        } else {
            newPower = 1.0;
        }
        determinedPower = newPower;
        issuePower();
        return true;
    }

    private void issuePower() {
        Double updatePower = overridePower != null ? overridePower : determinedPower;
        if (updatePower != null) {
            if (updatePower != this.payload.power) {
                this.payload.power = updatePower;
                boolean isOn = this.payload.power != 0.0;
                this.channel.publishTopic(actuatorControlTopic, writer -> writer.write(payload));
                this.channel.publishTopic(publishTopic, writer -> writer.writeBoolean(isOn));
            }
        }
    }
}

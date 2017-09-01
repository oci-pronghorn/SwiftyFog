package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.*;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.BlobReader;

import static com.ociweb.behaviors.AmbientLightBroadcast.maxSensorReading;

public class LightingBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final String actuatorTopic;
    private final String overrideTopic;
    private final String powerTopic;
    private final String calibrationTopic;

    private final RationalPayload calibration = new RationalPayload(maxSensorReading, maxSensorReading);
    private final RationalPayload ambient = new RationalPayload(maxSensorReading, maxSensorReading);

    private Double determinedPower = null;
    private Double overridePower = null;

    public LightingBehavior(FogRuntime runtime, String actuatorTopic, ActuatorDriverPort port, String overrideTopic, String powerTopic, String calibrationTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.actuatorTopic = actuatorTopic;
        this.overrideTopic = overrideTopic;
        this.powerTopic = powerTopic;
        this.calibrationTopic = calibrationTopic;
        this.actuatorPayload.port = port;
        this.actuatorPayload.power = -1.0;
    }

    public boolean onMqttConnected(CharSequence charSequence, BlobReader messageReader) {
        boolean isOn = this.actuatorPayload.power > 0.0;
        TriState lightsOn = overridePower == null ? TriState.latent : overridePower == 0.0 ? TriState.on : TriState.off;
        this.channel.publishTopic(overrideTopic, writer -> writer.writeInt(lightsOn.ordinal()));
        this.channel.publishTopic(powerTopic, writer -> writer.writeBoolean(isOn));
        this.channel.publishTopic(calibrationTopic, writer -> writer.write(calibration));
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
        this.channel.publishTopic(overrideTopic, writer -> writer.writeInt(lightsOn.ordinal()));
        actuate();
        return true;
    }

    public boolean onCalibration(CharSequence charSequence, BlobReader messageReader) {
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

    public boolean onDetected(CharSequence charSequence, BlobReader messageReader) {
        messageReader.readInto(ambient);

        Double newPower;
        if (calibration.num == maxSensorReading) {
            calibration.num = ambient.num / 2;
            this.channel.publishTopic(calibrationTopic, writer -> writer.write(calibration));
            newPower = 0.0;
        } else if (ambient.num >= calibration.num) {
            newPower = 0.0;
        } else {
            newPower = 1.0;
        }
        determinedPower = newPower;
        actuate();
        return true;
    }

    private void actuate() {
        Double updatePower = overridePower != null ? overridePower : determinedPower;
        if (updatePower != null) {
            if (updatePower != this.actuatorPayload.power) {
                this.actuatorPayload.power = updatePower;
                this.channel.publishTopic(actuatorTopic, writer -> writer.write(actuatorPayload));
                boolean isOn = this.actuatorPayload.power > 0.0;
                this.channel.publishTopic(powerTopic, writer -> writer.writeBoolean(isOn));
            }
        }
    }
}

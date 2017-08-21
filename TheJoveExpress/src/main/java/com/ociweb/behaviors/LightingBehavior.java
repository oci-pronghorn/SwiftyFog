package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.*;
import com.ociweb.model.ActuatorDriverPayLoad;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.BlobReader;

public class LightingBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final ActuatorDriverPayLoad payload = new ActuatorDriverPayLoad();
    private final String publishTopic;
    private final String actuatorControlTopic;

    private Integer threshold = null;
    private Double determinedPower = null;
    private Double overridePower = null;
    private RationalPayload ambient = new RationalPayload();

    public LightingBehavior(FogRuntime runtime, String actuatorControlTopic, ActuatorDriverPort port, String publishTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.publishTopic = publishTopic;
        this.payload.port = port;
        this.payload.power = -1.0;
        this.actuatorControlTopic = actuatorControlTopic;
    }

    public boolean onMqttConnected(CharSequence charSequence, BlobReader messageReader) {
        return true;
    }


    public boolean onCalibrate(CharSequence charSequence, BlobReader messageReader) {
        this.threshold = null;
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
        if (threshold == null) {
            threshold = (int)ambient.num / 2;
            newPower = 0.0;
        } else if (ambient.num >= threshold) {
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

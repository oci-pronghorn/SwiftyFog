package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.BlobReader;

public class EngineBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final String actuatorControlTopic;
    private final String enginePoweredTopic;
    private final String engineCalibratedTopic;

    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final RationalPayload calibration = new RationalPayload(15, 100);
    private final RationalPayload enginePower = new RationalPayload(0, 100);

    public EngineBehavior(FogRuntime runtime, String actuatorControlTopic, ActuatorDriverPort port, String enginePoweredTopic, String engineCalibratedTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.actuatorPayload.port = port;
        this.actuatorControlTopic = actuatorControlTopic;
        this.enginePoweredTopic = enginePoweredTopic;
        this.engineCalibratedTopic = engineCalibratedTopic;
    }

    public boolean onMqttConnected(CharSequence charSequence, BlobReader messageReader) {
        this.channel.publishTopic(engineCalibratedTopic, writer -> writer.write(calibration));
        this.channel.publishTopic(enginePoweredTopic, writer -> writer.write(actuatorPayload));
        return true;
    }

    public boolean onCalibrate(CharSequence charSequence, BlobReader messageReader) {
        messageReader.readInto(this.calibration);
        double actualPower = enginePower.ratio();
        this.channel.publishTopic(engineCalibratedTopic, writer -> writer.write(calibration));
        issuePower(actualPower);
        return true;
    }

    public boolean onPower(CharSequence charSequence, BlobReader messageReader) {
        messageReader.readInto(enginePower);
        double actualPower = enginePower.ratio();
        this.channel.publishTopic(enginePoweredTopic, writer -> writer.write(enginePower));
        issuePower(actualPower);
        return true;
    }

    private void issuePower(double actualPower) {
        if (Math.abs(actualPower) < calibration.ratio()) actualPower = 0.0;
        if (actualPower != actuatorPayload.power) {
            actuatorPayload.power = actualPower;
            this.channel.publishTopic(actuatorControlTopic, writer -> writer.write(actuatorPayload));
        }
    }
}

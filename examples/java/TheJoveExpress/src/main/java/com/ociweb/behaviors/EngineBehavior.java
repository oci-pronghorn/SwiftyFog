package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class EngineBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final String actuatorTopic;
    private final String powerTopic;
    private final String calibrationTopic;

    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final RationalPayload enginePower = new RationalPayload(0, 100);
    private final RationalPayload calibration = new RationalPayload(15, 100);

    public EngineBehavior(FogRuntime runtime, String actuatorTopic, ActuatorDriverPort port, String enginePoweredTopic, String engineCalibratedTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.actuatorTopic = actuatorTopic;
        this.actuatorPayload.port = port;
        this.powerTopic = enginePoweredTopic;
        this.calibrationTopic = engineCalibratedTopic;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        this.channel.publishTopic(powerTopic, writer -> writer.write(enginePower));
        this.channel.publishTopic(calibrationTopic, writer -> writer.write(calibration));
        return true;
    }

    public boolean onPower(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(enginePower);
        actuate();
        this.channel.publishTopic(powerTopic, writer -> writer.write(enginePower));
        return true;
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(this.calibration);
        actuate();
        this.channel.publishTopic(calibrationTopic, writer -> writer.write(calibration));
        return true;
    }

    private void actuate() {
        double actualPower = enginePower.ratio();
        double calibrationLimit = calibration.ratio();
        if (Math.abs(actualPower) < calibrationLimit) {
            actualPower = 0.0;
        }
        if (actualPower != actuatorPayload.power) {
            actuatorPayload.power = actualPower;
            this.channel.publishTopic(actuatorTopic, writer -> writer.write(actuatorPayload));
        }
    }
}

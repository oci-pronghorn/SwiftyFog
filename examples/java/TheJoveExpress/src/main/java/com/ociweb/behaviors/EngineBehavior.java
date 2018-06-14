package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.MotionFaults;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class EngineBehavior implements PubSubMethodListener {
    private final PubSubService pubSubService;
    private final String actuatorTopic;
    private final String engineStateTopic;
    private final String powerTopic;
    private final String calibrationTopic;

    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final RationalPayload enginePower = new RationalPayload(0, 100);
    private final RationalPayload calibration = new RationalPayload(30, 100);
    private final MotionFaults motionFaults = new MotionFaults();
    private int engineState = 0;

    public EngineBehavior(FogRuntime runtime, String actuatorTopic, ActuatorDriverPort port, String enginePoweredTopic, String engineCalibratedTopic, String engineStateTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService();
        this.actuatorTopic = actuatorTopic;
        this.engineStateTopic = engineStateTopic;
        this.actuatorPayload.port = port;
        this.powerTopic = enginePoweredTopic;
        this.calibrationTopic = engineCalibratedTopic;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        this.pubSubService.publishTopic(powerTopic, writer -> writer.write(enginePower));
        this.pubSubService.publishTopic(calibrationTopic, writer -> writer.write(calibration));
        this.pubSubService.publishTopic(engineStateTopic, writer -> writer.writeInt(engineState));
        return true;
    }

    public boolean onFault(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(motionFaults);
        if (motionFaults.hasFault()) {
            enginePower.num = 0;
            actuate();
            this.pubSubService.publishTopic(powerTopic, writer -> writer.write(enginePower));
        }
        return true;
    }

    public boolean onPower(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(enginePower);
        actuate();
        this.pubSubService.publishTopic(powerTopic, writer -> writer.write(enginePower));
        return true;
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(calibration);
        actuate();
        this.pubSubService.publishTopic(calibrationTopic, writer -> writer.write(calibration));
        return true;
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
            this.pubSubService.publishTopic(actuatorTopic, writer -> writer.write(actuatorPayload));
        }
        if (state != engineState) {
            engineState = state;
            this.pubSubService.publishTopic(engineStateTopic, writer -> writer.writeInt(engineState));
        }
    }
}

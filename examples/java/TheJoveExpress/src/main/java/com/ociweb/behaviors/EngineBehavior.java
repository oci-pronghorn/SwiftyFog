package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.model.MotionFaults;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class EngineBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService actuatorService;
    private final PubSubFixedTopicService engineStateService;
    private final PubSubFixedTopicService powerService;
    private final PubSubFixedTopicService calibrationService;
    
    private final ActuatorDriverPayload actuatorPayload = new ActuatorDriverPayload();
    private final RationalPayload enginePower = new RationalPayload(0, 100);
    private final RationalPayload calibration;
    private final MotionFaults motionFaults = new MotionFaults();
    private int engineState = 0;

    public EngineBehavior(FogRuntime runtime, int calibration, String actuatorTopic, ActuatorDriverPort port, String enginePoweredTopic, String engineCalibratedTopic, String engineStateTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.calibration = new RationalPayload(calibration, 100);
        this.actuatorService = channel.newPubSubService(actuatorTopic);
        this.engineStateService = channel.newPubSubService(engineStateTopic);
        this.powerService = channel.newPubSubService(enginePoweredTopic);
        this.calibrationService = channel.newPubSubService(engineCalibratedTopic);
                
        this.actuatorPayload.port = port;

    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        this.powerService.publishTopic( writer -> writer.write(enginePower));
        this.calibrationService.publishTopic( writer -> writer.write(calibration));
        this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
        return true;
    }

    public boolean onFault(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(motionFaults);
        if (motionFaults.hasFault()) {
            enginePower.num = 0;
            actuate();
            this.powerService.publishTopic( writer -> writer.write(enginePower));
        }
        return true;
    }

    public boolean onPower(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(enginePower);
        actuate();
        this.powerService.publishTopic( writer -> writer.write(enginePower));
        return true;
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
        messageReader.readInto(calibration);
        actuate();	
        this.calibrationService.publishTopic( writer -> writer.write(calibration));
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
            this.actuatorService.publishTopic( writer -> writer.write(actuatorPayload));
        }
        if (state != engineState) {
            engineState = state;
            this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
        }
    }
}

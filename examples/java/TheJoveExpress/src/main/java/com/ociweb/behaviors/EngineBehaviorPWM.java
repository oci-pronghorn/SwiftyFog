package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.PinService;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.MotionFaults;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class EngineBehaviorPWM implements PubSubMethodListener {

    private final int twigRange = 1024;
    private final Port enginePowerPort; 
    private final Port engineDirectionPort;
    
    
	private final PubSubFixedTopicService engineStateService;
    private final PubSubFixedTopicService powerService;
    private final PubSubFixedTopicService calibrationService;
    
    private final RationalPayload enginePower = new RationalPayload(0, 100);
    private final RationalPayload calibration = new RationalPayload(30, 100);
    private final MotionFaults motionFaults = new MotionFaults();
    private int engineState = 0;
	private final PinService pwmService;

    public EngineBehaviorPWM(FogRuntime runtime, Port enginePowerPort, Port engineDirectionPort, 
    		                 String enginePoweredTopic, String engineCalibratedTopic, String engineStateTopic) {

        this.engineStateService = runtime.newCommandChannel().newPubSubService(engineStateTopic);
        this.powerService = runtime.newCommandChannel().newPubSubService(enginePoweredTopic);
        this.calibrationService = runtime.newCommandChannel().newPubSubService(engineCalibratedTopic);
                
        this.pwmService = runtime.newCommandChannel().newPinService();
        this.enginePowerPort = enginePowerPort;
        this.engineDirectionPort = engineDirectionPort;       

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

        pwmService.setValue(engineDirectionPort, actualPower>=0);
        if (pwmService.setValue(enginePowerPort, (int)(twigRange*Math.abs(actualPower)))) {

	        if (state != engineState) {
	            engineState = state;
	            this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
	        }
        }
    }
}

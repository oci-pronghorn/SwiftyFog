package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.PinService;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.MotionFaults;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

// TODO: use existing EngineBehavior with PWNActuatorDriverBehavior instead of this class
public class EngineBehaviorPWM implements PubSubMethodListener, StartupListener {

    private final Port enginePowerPort; 
    private final Port engineDirectionPort;
    private final int powerMax;
    
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

        FogCommandChannel newCommandChannel = runtime.newCommandChannel();
		this.engineStateService = newCommandChannel.newPubSubService(engineStateTopic);
        this.powerService = newCommandChannel.newPubSubService(enginePoweredTopic);
        this.calibrationService = newCommandChannel.newPubSubService(engineCalibratedTopic);
                
        this.pwmService = newCommandChannel.newPinService();
        this.enginePowerPort = enginePowerPort;
        this.engineDirectionPort = engineDirectionPort; 
        
        this.powerMax = runtime.builder.getConnectedDevice(enginePowerPort).range()-1;
        
        

    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.powerService.hasRoomFor(1)
    	 && this.calibrationService.hasRoomFor(1)
    	 && this.engineStateService.hasRoomFor(1)
    			) {    	
	        this.powerService.publishTopic( writer -> writer.write(enginePower));
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
	        
	        return true;
    	} else {
    		return false;
    	}
    }

    public boolean onFault(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.pwmService.hasRoomFor(1)
    		&& this.engineStateService.hasRoomFor(1)) {
    		
    		messageReader.readInto(motionFaults);
    		if (motionFaults.hasFault()) {
    			enginePower.num = 0;
    			actuate();
    			return this.powerService.publishTopic( writer -> writer.write(enginePower));
    		}
    		return true;    		
    	} else {
    		return false;
    	}
    }

    public boolean onPower(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.pwmService.hasRoomFor(1)
        	&& this.engineStateService.hasRoomFor(1)
        	&& this.powerService.hasRoomFor(1)) {
	        messageReader.readInto(enginePower);
	        actuate();
	        this.powerService.publishTopic( writer -> writer.write(enginePower));
	        return true;
    	} else {
    		return false;
    	}
    }

    public boolean onCalibration(CharSequence charSequence, ChannelReader messageReader) {
    	if (this.pwmService.hasRoomFor(1)
       		&& this.engineStateService.hasRoomFor(1)
       		&& this.calibrationService.hasRoomFor(1)
    	   ) {
	        messageReader.readInto(calibration);
	        actuate();	
	        this.calibrationService.publishTopic( writer -> writer.write(calibration));
	        return true;
    	} else {
    		return false;
    	}
    }

    private void actuate() {
        double actualPower = enginePower.ratio();
        double calibrationLimit = calibration.ratio();
        if (Math.abs(actualPower) < calibrationLimit) {
            actualPower = 0.0;
        } 
        int state = Double.compare(actualPower, 0.0);
        int p = (int)(powerMax* Math.abs(actualPower));

        pwmService.setValue(engineDirectionPort,actualPower<0?0:255);        
        
        if (pwmService.setValue(enginePowerPort, p)) {

	        if (state != engineState) {
	            engineState = state;
	            this.engineStateService.publishTopic( writer -> writer.writeInt(engineState));
	        }
        }
    }

	@Override
	public void startup() {
		
		//must be zero on startup or hardware will report an error, (double blink)
		pwmService.setValue(enginePowerPort, 0);
		pwmService.setValue(engineDirectionPort,0);
	}
}

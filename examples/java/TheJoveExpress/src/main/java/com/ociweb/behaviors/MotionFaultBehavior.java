package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerValues;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.MotionFaults;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class MotionFaultBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService pubSubService;

    private final MotionFaults motionFaults = new MotionFaults();
    private final AccelerometerValues accel = new AccelerometerValues();

    public MotionFaultBehavior(FogRuntime runtime, String faultChangeTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(faultChangeTopic);
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader channelReader) {
        return pubSubService.publishTopic( writer -> writer.write(motionFaults));
    }

    public boolean onForceFault(CharSequence charSequence, ChannelReader channelReader) {
    	if (pubSubService.publishTopic( writer -> writer.write(motionFaults))) {    	
	        motionFaults.derailed = !motionFaults.derailed;
	        return true;
    	} else {
    		return false;
    	}
    }

    public boolean onEngineState(CharSequence charSequence, ChannelReader channelReader) {
        int state = channelReader.readInt();
        if (motionFaults.accept(state)) {
            return pubSubService.publishTopic( writer -> writer.write(motionFaults));
        }
        return true;
    }

    public boolean onAccelerometer(CharSequence charSequence, ChannelReader channelReader) {
        channelReader.readInto(accel);
        if (motionFaults.accept(accel)) {
            return pubSubService.publishTopic( writer -> writer.write(motionFaults));
        }
        return true;
    }
}



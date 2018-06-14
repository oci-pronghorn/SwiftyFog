package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerValues;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.MotionFaults;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class MotionFaultBehavior implements PubSubMethodListener {
    private final PubSubService pubSubService;
    private final String faultChangeTopic;
    private final MotionFaults motionFaults = new MotionFaults();
    private final AccelerometerValues accel = new AccelerometerValues();

    public MotionFaultBehavior(FogRuntime runtime, String faultChangeTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService();
        this.faultChangeTopic = faultChangeTopic;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader channelReader) {
        pubSubService.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        return true;
    }

    public boolean onForceFault(CharSequence charSequence, ChannelReader channelReader) {
        motionFaults.derailed = !motionFaults.derailed;
        pubSubService.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        return true;
    }

    public boolean onEngineState(CharSequence charSequence, ChannelReader channelReader) {
        int state = channelReader.readInt();
        if (motionFaults.accept(state)) {
            pubSubService.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        }
        return true;
    }

    public boolean onAccelerometer(CharSequence charSequence, ChannelReader channelReader) {
        channelReader.readInto(accel);
        if (motionFaults.accept(accel)) {
            pubSubService.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        }
        return true;
    }
}



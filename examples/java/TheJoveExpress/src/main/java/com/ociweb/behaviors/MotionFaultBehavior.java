package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerValues;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.MotionFaults;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class MotionFaultBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final String faultChangeTopic;
    private final MotionFaults motionFaults = new MotionFaults();
    private final AccelerometerValues accel = new AccelerometerValues();

    public MotionFaultBehavior(FogRuntime runtime, String faultChangeTopic) {
        this.channel = runtime.newCommandChannel();
        this.channel.ensureDynamicMessaging();
        this.faultChangeTopic = faultChangeTopic;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader channelReader) {
        channel.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        return true;
    }

    public boolean onForceFault(CharSequence charSequence, ChannelReader channelReader) {
        motionFaults.derailed = !motionFaults.derailed;
        channel.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        return true;
    }

    public boolean onEngineState(CharSequence charSequence, ChannelReader channelReader) {
        int state = channelReader.readInt();
        if (motionFaults.accept(state)) {
            channel.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        }
        return true;
    }

    public boolean onAccelerometer(CharSequence charSequence, ChannelReader channelReader) {
        channelReader.readInto(accel);
        if (motionFaults.accept(accel)) {
            channel.publishTopic(faultChangeTopic, writer -> writer.write(motionFaults));
        }
        return true;
    }
}



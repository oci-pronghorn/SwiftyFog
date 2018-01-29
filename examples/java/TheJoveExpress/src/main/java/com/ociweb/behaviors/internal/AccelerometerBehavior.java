package com.ociweb.behaviors.internal;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;

public class AccelerometerBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final String stateTopic;
    private final SixAxisAccelerometer_Transducer accSensor;

    public AccelerometerBehavior(FogRuntime runtime, String stateTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.stateTopic = stateTopic;

        AccelerometerListener listener = new AccelerometerListener() {
            public void onChange(AccelerometerValues values, AccelerometerListener.Changed changed) {
                valueChange(values, changed);
            }
        };

        this.accSensor = new SixAxisAccelerometer_Transducer(runtime.newCommandChannel(
                FogRuntime.I2C_WRITER, 200), listener, listener, null);
    }

    private void valueChange(AccelerometerValues values, AccelerometerListener.Changed changed) {
        channel.publishTopic(stateTopic, writer -> writer.write(values));
    }
}

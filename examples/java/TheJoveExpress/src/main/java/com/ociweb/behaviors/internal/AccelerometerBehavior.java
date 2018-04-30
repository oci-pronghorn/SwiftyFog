package com.ociweb.behaviors.internal;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.iot.grove.six_axis_accelerometer.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;

public class AccelerometerBehavior implements PubSubMethodListener {
    private final PubSubService pubSubService;
    private final String stateTopic;
    private final SixAxisAccelerometer_Transducer accSensor;

    public AccelerometerBehavior(FogRuntime runtime, String stateTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        pubSubService = channel.newPubSubService();
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
        pubSubService.publishTopic(stateTopic, writer -> writer.write(values));
    }
}

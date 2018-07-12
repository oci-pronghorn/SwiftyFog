package com.ociweb.behaviors.internal;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerListener;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerValues;
import com.ociweb.iot.grove.six_axis_accelerometer.SixAxisAccelerometer_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;

public class AccelerometerBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService stateTopicService;

    private final SixAxisAccelerometer_Transducer accSensor;

    public AccelerometerBehavior(FogRuntime runtime, String stateTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        stateTopicService = channel.newPubSubService(stateTopic);


        AccelerometerListener listener = new AccelerometerListener() {
            public void onChange(AccelerometerValues values, AccelerometerListener.Changed changed) {
                valueChange(values, changed);
            }
        };

        this.accSensor = new SixAxisAccelerometer_Transducer(runtime.newCommandChannel(
                FogRuntime.I2C_WRITER, 200), listener, listener, null);
    }

    private void valueChange(AccelerometerValues values, AccelerometerListener.Changed changed) {
        stateTopicService.publishTopic(writer -> writer.write(values));
    }
}

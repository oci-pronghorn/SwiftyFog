package com.ociweb.behaviors.internal;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;

public class AccelerometerBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final String stateTopic;
    private final SixAxisAccelerometer_Transducer accSensor;
    private final AccelerometerValues magValues;

    public AccelerometerBehavior(FogRuntime runtime, String stateTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.stateTopic = stateTopic;
        this.magValues = new AccelerometerValues() {
            @Override
            public void onChange(Changed change) {
                valueChange();
            }
        };
        this.accSensor = new SixAxisAccelerometer_Transducer(runtime.newCommandChannel(FogRuntime.I2C_WRITER, 200), magValues, magValues, null);
    }

    private void valueChange() {
        channel.publishTopic(stateTopic, writer -> writer.write(magValues));
    }

}

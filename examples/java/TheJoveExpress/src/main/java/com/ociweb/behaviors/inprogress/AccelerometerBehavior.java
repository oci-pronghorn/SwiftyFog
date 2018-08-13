package com.ociweb.behaviors.inprogress;

import com.ociweb.FeatureEnabled;
import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerListener;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerValues;
import com.ociweb.iot.grove.six_axis_accelerometer.SixAxisAccelerometerTwig;
import com.ociweb.iot.grove.six_axis_accelerometer.SixAxisAccelerometer_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;

public class AccelerometerBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService stateTopicService;

    private final SixAxisAccelerometer_Transducer accSensor;

    public static void configure(Hardware hardware, FeatureEnabled enabled, int accelerometerReadFreq) {
        if (enabled == FeatureEnabled.full) {
            hardware.connect(SixAxisAccelerometerTwig.SixAxisAccelerometer.readAccel, accelerometerReadFreq);
        }
    }

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

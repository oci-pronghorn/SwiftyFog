package com.ociweb.behaviors;

import com.ociweb.gl.api.Behavior;
import com.ociweb.iot.grove.six_axis_accelerometer.AccelValsListener;
import com.ociweb.iot.grove.six_axis_accelerometer.MagValsListener;
import com.ociweb.iot.grove.six_axis_accelerometer.SixAxisAccelerometer_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.BlobReader;

public class AccelerometerBehavior implements Behavior, AccelValsListener, MagValsListener {
    private final FogCommandChannel channel;
    private final SixAxisAccelerometer_Transducer accSensor;
    private final String headingTopic;
    private final String accelerateTopic;

    public AccelerometerBehavior(FogRuntime runtime, String publishTopic) {
        this.channel = runtime.newCommandChannel();
        accSensor = new SixAxisAccelerometer_Transducer(channel, this, this);
        headingTopic = publishTopic + "/" + "heading";
        accelerateTopic = publishTopic + "/" + "accelerate";
    }

    public boolean onMqttConnected(CharSequence charSequence, BlobReader messageReader) {
        return true;
    }

    @Override
    public void accelerationValues(int x, int y, int z) {
     //   this.channel.publishTopic(headingTopic, writer -> {
     //       writer.writeInt(x);
     //       writer.writeInt(y);
     //       writer.writeInt(z);
     //   });
    }

    @Override
    public void magneticValues(int x, int y, int z) {
        double heading = 180.0 * Math.atan2(y, x) / Math.PI;
        if (heading < 0) heading += 360.0;
        final double finalHeading = heading;
        // this.channel.publishTopic(accelerateTopic, writer -> {
        //     writer.writeDouble(finalHeading);
        // });
    }
}

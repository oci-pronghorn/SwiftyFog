package com.ociweb.behaviors;

import com.ociweb.gl.api.Behavior;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.six_axis_accelerometer.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class AccelerometerBehavior implements Behavior, MagValsListener, StartupListener {
    private final FogCommandChannel channel;
    private final SixAxisAccelerometer_Transducer accSensor;
    private final String headingTopic;
    private final RationalPayload heading = new RationalPayload(0, 360);

    public AccelerometerBehavior(FogRuntime runtime, String headingTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.accSensor = new SixAxisAccelerometer_Transducer(runtime.newCommandChannel(), null, this);
        this.headingTopic = headingTopic;
    }

    @Override
    public void startup() {
        accSensor.setAccelScale(6);
        accSensor.setMagScale(8);
    }

    @Override
    public AccelerometerMagDataRate getMagneticDataRate() {
        return AccelerometerMagDataRate.hz50;
    }

    @Override
    public AccelerometerMagScale getMagneticScale() {
        return AccelerometerMagScale.gauss8;
    }

    @Override
    public void magneticValues(int x, int y, int z) {
        double value = 180.0 * Math.atan2(y, x) / Math.PI;
        if (value < 0) {
            value += 360.0;
        }
        long rounded = (long)value;
        if (rounded != heading.num) {
            heading.num = rounded;
            this.channel.publishTopic(headingTopic, writer -> writer.write(heading));
        }
    }
}

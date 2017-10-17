package com.ociweb.behaviors;

import com.ociweb.gl.api.Behavior;
import com.ociweb.iot.grove.six_axis_accelerometer.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.RationalPayload;

public class LocationBehavior implements Behavior {
    private final FogCommandChannel channel;
    private final SixAxisAccelerometer_Transducer accSensor;
    private final AccerometerValues magValues;
    private final String headingTopic;
    private final RationalPayload heading = new RationalPayload(0, 360);

    public LocationBehavior(FogRuntime runtime, String headingTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.magValues = new AccerometerValues() {
            @Override
            public void onChange(Changed change) {
                headingChange();
            }
        };

        this.accSensor = new SixAxisAccelerometer_Transducer(runtime.newCommandChannel(FogRuntime.I2C_WRITER, 200), null, magValues, null);
        this.headingTopic = headingTopic;
    }

    public void headingChange() {
        long rounded = (long)magValues.getHeading();
        if (rounded != heading.num) {
            heading.num = rounded;
            this.channel.publishTopic(headingTopic, writer -> writer.write(heading));
        }
    }
}

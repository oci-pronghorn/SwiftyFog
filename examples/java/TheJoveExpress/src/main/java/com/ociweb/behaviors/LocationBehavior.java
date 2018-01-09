package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.six_axis_accelerometer.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class LocationBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final String isMovingTopic;
    private final SixAxisAccelerometer_Transducer accSensor;
    private final AccerometerValues magValues;

    private final RationalPayload heading = new RationalPayload(0, 3600);
    private final boolean isMoving = false;

    public LocationBehavior(FogRuntime runtime, String headingTopic, String isMovingTopic, String accelTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.isMovingTopic = isMovingTopic;
        this.magValues = new AccerometerValues() {
            @Override
            public void onChange(Changed change) {
                headingChange();
            }
        };

        this.accSensor = new SixAxisAccelerometer_Transducer(runtime.newCommandChannel(FogRuntime.I2C_WRITER, 200), magValues, magValues, null);
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        this.channel.publishTopic(isMovingTopic, writer -> writer.writeBoolean(isMoving));
        return true;
    }

    public void headingChange() {
        /*
        long rounded = (long)(magValues.getHeading() * 10.0);
        if (rounded != heading.num) {
            heading.num = rounded;
            this.channel.publishTopic(headingTopic, writer -> writer.write(heading));
        }*/
        // TODO: calc isMoving and retransmit on change
    }
}

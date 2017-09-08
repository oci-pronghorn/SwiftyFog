package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.AnalogListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.BlobReader;

public class AmbientLightBroadcast implements PubSubMethodListener, AnalogListener {
    private final FogCommandChannel channel;
    private final Port lightSensorPort;
    private final String publishTopic;
    public static final long maxSensorReading = 255;
    private final RationalPayload oldValue = new RationalPayload(-1, maxSensorReading);

    public AmbientLightBroadcast(FogRuntime runtime, Port lightSensorPort, String publishTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.lightSensorPort = lightSensorPort;
        this.publishTopic = publishTopic;
    }

    public boolean onAllFeedback(CharSequence charSequence, BlobReader messageReader) {
        channel.publishTopic(publishTopic, writer -> writer.write(oldValue));
        return true;
    }

    @Override
    public void analogEvent(Port port, long time, long durationMillis, int average, int value) {
        System.out.print(String.format("p: %d t:%d d:%d a:%d v:%d\n", port.port, time, durationMillis, average, value));
        if (port == lightSensorPort) {
            if (value != oldValue.num) {
                oldValue.num = value;
                channel.publishTopic(publishTopic, writer -> writer.write(oldValue));
            }
        }
    }
}

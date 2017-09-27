package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.WaitFor;
import com.ociweb.iot.maker.AnalogListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class AmbientLightBehavior implements PubSubMethodListener, AnalogListener {
    private final FogCommandChannel channel;
    private final Port lightSensorPort;
    private final String publishTopic;
    // TODO: is this the transducer?
    public static final long maxSensorReading = 255;
    private final RationalPayload oldValue = new RationalPayload(-1, maxSensorReading);

    private boolean endOfTheWorld = false;

    public AmbientLightBehavior(FogRuntime runtime, Port lightSensorPort, String publishTopic) {
        this.channel = runtime.newCommandChannel();
        this.channel.ensureDynamicMessaging();
        this.lightSensorPort = lightSensorPort;
        this.publishTopic = publishTopic;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        channel.publishTopic(publishTopic, writer -> writer.write(oldValue));
        return true;
    }

    @Override
    public void analogEvent(Port port, long time, long durationMillis, int average, int value) {
        //if (endOfTheWorld) return;
        //System.out.print(String.format("p: %d t:%d d:%d a:%d v:%d\n", port.port, time, durationMillis, average, value));
        if (port == lightSensorPort) {
            if (value != oldValue.num) {
                oldValue.num = value;
                if (!channel.publishTopic(publishTopic, writer -> writer.write(oldValue), WaitFor.None)) {
                    endOfTheWorld = true;
                    System.out.println("**** Ambient Reading Change Failed to Publish ****");
                }
            }
        }
    }
}

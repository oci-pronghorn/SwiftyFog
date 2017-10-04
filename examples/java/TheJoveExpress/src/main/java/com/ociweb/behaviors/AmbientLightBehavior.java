package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.WaitFor;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
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
    public static final long maxSensorReading = SimpleAnalogTwig.LightSensor.range();
    private final RationalPayload oldValue = new RationalPayload(-1, maxSensorReading);

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
        if (port == lightSensorPort) {
            if (value != oldValue.num) {
                oldValue.num = value;
                if (!channel.publishTopic(publishTopic, writer -> writer.write(oldValue), WaitFor.None)) {
                    System.out.println("**** Ambient Reading Change Failed to Publish ****");
                }
            }
        }
    }
}

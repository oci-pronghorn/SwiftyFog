package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
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
    private final PubSubFixedTopicService pubSubService;
    public static final int maxSensorReading = SimpleAnalogTwig.LightSensor.range();
    private final RationalPayload oldValue = new RationalPayload(-1, maxSensorReading);
	private final Port lightSensorPort;

    public AmbientLightBehavior(FogRuntime runtime, Port lightSensorPort, String publishTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(publishTopic);
        this.lightSensorPort = lightSensorPort;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        return pubSubService.publishTopic(writer -> writer.write(oldValue));
    }

    @Override
    public void analogEvent(Port port, long time, long durationMillis, int average, int value) {
        if (port == lightSensorPort) {
            if (value != oldValue.num) {
                oldValue.num = value;
                if (!pubSubService.publishTopic(writer -> writer.write(oldValue), WaitFor.None)) {
                    System.out.println("**** Ambient Reading Change Failed to Publish ****");
                }
            }
        }
    }
}

package com.ociweb.behaviors;

import com.ociweb.FeatureEnabled;
import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.WaitFor;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.maker.*;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

/**
 * Broadcast the ambient light sensor
 */
public class AmbientLightBehavior implements PubSubMethodListener, AnalogListener {
    private final PubSubFixedTopicService pubSubService;
    static final int maxSensorReading = SimpleAnalogTwig.LightSensor.range();
    private final RationalPayload oldValue = new RationalPayload(0, maxSensorReading);
	private static Port lightSensorPort;
	private static boolean useReasonableTestValue = false;

	public static void configure(Hardware hardware, FeatureEnabled enabled, Port lightSensorPort, int lightDetectFreq) {
        AmbientLightBehavior.lightSensorPort = lightSensorPort;
        switch (enabled) {
            case full:
            case simuatedHardware:
                // Works regardless of hardware.isTestHardware
                hardware.connect(SimpleAnalogTwig.LightSensor, lightSensorPort, lightDetectFreq);
                break;
            case noHardware:
            case nothing:
                useReasonableTestValue = true;
                break;
        }
    }

    public AmbientLightBehavior(FogRuntime runtime, String publishTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(publishTopic);
        oldValue.num = useReasonableTestValue ? maxSensorReading / 2 : -1;
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

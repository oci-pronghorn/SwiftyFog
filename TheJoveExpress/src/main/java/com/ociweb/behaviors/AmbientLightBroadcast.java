package com.ociweb.behaviors;

import com.ociweb.iot.maker.AnalogListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.RationalPayload;

public class AmbientLightBroadcast implements AnalogListener {
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

    @Override
    public void analogEvent(Port port, long l, long l1, int i, int i1) {
        if (port == lightSensorPort) {
            // TODO: only broadcast if significant change...
            if (l != oldValue.num) {
                System.out.println(String.format("%d -> %d", oldValue.num, i));
                oldValue.num = i;
                channel.publishTopic(publishTopic, writer -> writer.write(oldValue));
            }
        }
    }
}

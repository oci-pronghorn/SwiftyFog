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
    private final RationalPayload oldValue = new RationalPayload(-1, 1024);

    public AmbientLightBroadcast(FogRuntime runtime, Port lightSensorPort, String publishTopic) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.lightSensorPort = lightSensorPort;
        this.publishTopic = publishTopic;
    }

    @Override
    public void analogEvent(Port port, long l, long l1, int i, int i1) {
        if (port == lightSensorPort) {
            if (l != oldValue.num) {
                oldValue.num = i;
                // TODO: only broadcast non-noise averaged per second changes
                channel.publishTopic(publishTopic, writer -> writer.write(oldValue));
            }
        }
    }
}

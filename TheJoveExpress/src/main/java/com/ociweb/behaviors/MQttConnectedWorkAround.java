package com.ociweb.behaviors;

import com.ociweb.gl.api.TimeListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ConnectedState;

// TODO delete
public class MQttConnectedWorkAround implements TimeListener {
    private final FogCommandChannel channel;
    private final String publishTopic;
    private boolean sent = false;
    private final long start;

    public MQttConnectedWorkAround(FogRuntime runtime, String publishTopic) {
        this.publishTopic = publishTopic;
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        start = System.currentTimeMillis();
    }

    @Override
    public void timeEvent(long now, int i) {
        if (!sent) {
            if (now - start >= 1000) {
                channel.publishTopic(publishTopic, writer -> writer.writeInt(ConnectedState.connecting.ordinal()));
                sent = true;
            }
        }
    }
}


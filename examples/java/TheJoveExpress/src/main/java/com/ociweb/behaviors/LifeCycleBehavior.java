package com.ociweb.behaviors;

import com.ociweb.gl.api.MQTTConnectionFeedback;
import com.ociweb.gl.api.MQTTConnectionStatus;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class LifeCycleBehavior implements PubSubMethodListener {
    private final FogRuntime runtime;
    private final FogCommandChannel channel;
    private final String trainAliveFeedback;
    private final MQTTConnectionFeedback connected = new MQTTConnectionFeedback();

    public LifeCycleBehavior(FogRuntime runtime, String trainAliveFeedback) {
        this.runtime = runtime;
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.trainAliveFeedback = trainAliveFeedback;
    }

    public boolean onShutdown(CharSequence topic, ChannelReader payload) {
        runtime.shutdownRuntime();
        return true;
    }

    public boolean onMQTTConnect(CharSequence topic, ChannelReader payload) {
        payload.readInto(connected);
        if (connected.status == MQTTConnectionStatus.connected) {
            channel.publishTopic(trainAliveFeedback, writer -> writer.writeBoolean(true));
        }
        return true;
    }
}

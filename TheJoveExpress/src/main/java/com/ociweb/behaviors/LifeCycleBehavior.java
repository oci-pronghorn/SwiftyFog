package com.ociweb.behaviors;

import com.ociweb.gl.api.MQTTConnectionStatus;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.MQTTConnectResult;
import com.ociweb.pronghorn.pipe.BlobReader;

public class LifeCycleBehavior implements PubSubMethodListener, ShutdownListener {
    private final FogRuntime runtime;
    private final FogCommandChannel channel;
    private final String trainAliveFeedback;
    private final MQTTConnectResult connected = new MQTTConnectResult();

    public LifeCycleBehavior(FogRuntime runtime, String trainAliveFeedback) {
        this.runtime = runtime;
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.trainAliveFeedback = trainAliveFeedback;
    }

    public boolean onShutdown(CharSequence topic, BlobReader payload) {
        runtime.shutdownRuntime();
        return true;
    }

    @Override
    public boolean acceptShutdown() {
        return true;
    }

    public boolean onMQTTConnect(CharSequence topic, BlobReader payload) {
        payload.readInto(connected);
        if (connected.status == MQTTConnectionStatus.connected) {
            channel.publishTopic(trainAliveFeedback, writer -> {
                writer.writeBoolean(true);
            });
        }
        return true;
    }
}

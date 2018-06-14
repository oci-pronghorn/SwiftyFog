package com.ociweb.behaviors;

import com.ociweb.gl.api.MQTTConnectionFeedback;
import com.ociweb.gl.api.MQTTConnectionStatus;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class LifeCycleBehavior implements PubSubMethodListener {
    private final FogRuntime runtime;
    private final PubSubService pubSubService;
    private final String trainAliveFeedback;
    private final MQTTConnectionFeedback connected = new MQTTConnectionFeedback();

    public LifeCycleBehavior(FogRuntime runtime, String trainAliveFeedback) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService();
        this.runtime = runtime;
        this.trainAliveFeedback = trainAliveFeedback;
    }

    public boolean onShutdown(CharSequence topic, ChannelReader payload) {
        runtime.shutdownRuntime();
        /*
        TODO:After all behaviors have had a chance to accept shutdown
        if not test hardware
            Runtime.getRuntime().exec("sudo reboot now");
         */
        return true;
    }

    public boolean onMQTTConnect(CharSequence topic, ChannelReader payload) {
        payload.readInto(connected);
        if (connected.status == MQTTConnectionStatus.connected) {
            pubSubService.publishTopic(trainAliveFeedback, writer -> writer.writeBoolean(true));
        }
        return true;
    }
}

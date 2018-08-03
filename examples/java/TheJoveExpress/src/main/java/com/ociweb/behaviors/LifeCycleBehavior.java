package com.ociweb.behaviors;

import com.ociweb.gl.api.MQTTConnectionFeedback;
import com.ociweb.gl.api.MQTTConnectionStatus;
import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

/**
 * Handles lifecycle feedback for the train.
 */
public class LifeCycleBehavior implements PubSubMethodListener {

    private final PubSubFixedTopicService pubSubService;

    private final MQTTConnectionFeedback connected = new MQTTConnectionFeedback();
    private final String displayName;

    public LifeCycleBehavior(FogRuntime runtime, String displayName, String trainAliveFeedback) {
        this.displayName = displayName;
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(trainAliveFeedback);
    }

    public boolean onShutdown(CharSequence topic, ChannelReader payload) {
    	pubSubService.requestShutdown();
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
            return pubSubService.publishTopic( writer -> {
                writer.writeBoolean(true);
                writer.writeUTF(displayName);
            });
        }
        return true;
    }
}

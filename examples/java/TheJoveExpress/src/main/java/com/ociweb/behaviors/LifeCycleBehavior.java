package com.ociweb.behaviors;

import com.ociweb.gl.api.MQTTConnectionFeedback;
import com.ociweb.gl.api.MQTTConnectionStatus;
import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class LifeCycleBehavior implements PubSubMethodListener {

    private final PubSubFixedTopicService pubSubService;

    private final MQTTConnectionFeedback connected = new MQTTConnectionFeedback();

    public LifeCycleBehavior(FogRuntime runtime, String trainAliveFeedback) {
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
            pubSubService.publishTopic( writer -> writer.writeBoolean(true));
        }
        return true;
    }
}

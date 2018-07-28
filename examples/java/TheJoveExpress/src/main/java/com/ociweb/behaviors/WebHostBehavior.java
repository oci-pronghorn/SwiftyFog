package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class WebHostBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService pubSubService;
    private static boolean enabled;
    // A Train has many different names...
    // - display name
    // - DNS name
    // - mqtt topic name
    // The client uses mqtt topic name to control the train.
    // The topic name is not the same as the DNS name.
    // Debugging in localhost should be easy.
    // -- we can enforce dns == mqtttopic.local
    // -- we can broadcast the ip address on feedback
    // -- we can add yet another variable to config for web DNS name

    // Let us pick one.
    private static final String webHost = "https://10.0.1.60:8089";

    public static void enable(Hardware hardware, boolean enabled, int appServerPort) {
        // TODO: test heap problem on Pi0
        WebHostBehavior.enabled = enabled;
        if (enabled) {
            hardware.useHTTP1xServer(appServerPort);
        }
    }

    public WebHostBehavior(FogRuntime runtime, String resourceRoot, String resourceDefaultPath, String feedbackTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(feedbackTopic);
        runtime.addResourceServer(resourceRoot, resourceDefaultPath).includeAllRoutes();
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        // Feedback needs at least "isEnabled"
        return pubSubService.publishTopic(writer-> writer.writeUTF(enabled ? webHost : ""));
    }
}

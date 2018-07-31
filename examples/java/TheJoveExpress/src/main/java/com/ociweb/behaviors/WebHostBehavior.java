package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.pronghorn.network.HTTPServerConfig;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class WebHostBehavior implements PubSubMethodListener {
    private final PubSubFixedTopicService pubSubService;
    private static boolean enabled;
    // TODO
    // A Train has many different names...
    // - display name (default billboard display and broadcasted to client)
    // - DNS name (The zeroconf name of the PI for telemetry and http server- MQTT Broker may be on different device)
    // - IP address DNS name is routed to
    // - mqtt topic name (The topic scope for this specific instance)
    // The client application needs to have a variable for DNS name or IP address
    // -- we can enforce DNS name == <mqtttopic>.local
    // -- we can broadcast the ip address on feedback
    // -- we can add yet another variable to config for Web DNS name to broadcast on feedback

    // We need to pick a strategy. For now I am broadcasting this ip to the client.
    private static final String webHost = "https://10.0.1.60:8089";

    public static void enable(Hardware hardware, boolean enabled, int appServerPort) {
        // TODO: test heap problem on Pi0
        WebHostBehavior.enabled = enabled;
        if (enabled) {
            HTTPServerConfig config = 
            		hardware.useHTTP1xServer(appServerPort)
            		        .setMaxResponseSize(1<<19); //big enough to hold the largest resource in joveSite
            
            config.useInsecureServer();
            config.setConcurrentChannelsPerEncryptUnit(4);
            config.setConcurrentChannelsPerDecryptUnit(4);
        }
    }

    public WebHostBehavior(FogRuntime runtime, String resourceRoot, String resourceDefaultPath, String feedbackTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(feedbackTopic);
        runtime.addResourceServer(resourceRoot, resourceDefaultPath).includeAllRoutes();
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        // Feedback needs at least "isEnabled" encoded
        // Could be port if enforcing DNS name == <mqtttopic>.local
        // Could be URL output to the console for "Server is now ready on ..."
        return pubSubService.publishTopic(writer-> writer.writeUTF(enabled ? webHost : ""));
    }
}

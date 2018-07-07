package com.ociweb.behaviors.location;

import com.ociweb.behaviors.CameraBehavior;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.maker.*;

public class LocationBehavior implements LocationListener, StartupListener {
    private final PubSubService pubSubService;
    private final String locationFeedbackTopic;
    private final String accuracyFeedbackTopic;

    public LocationBehavior(FogRuntime runtime, String locationFeedbackTopic, String accuracyFeedbackTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService();
        this.locationFeedbackTopic = locationFeedbackTopic;
        this.accuracyFeedbackTopic = accuracyFeedbackTopic;
    }

    @Override
    public void startup() {
        System.out.println("Started location provider.");
    }

    @Override
    public boolean location(int location, long oddsOfRightLocation, long totalSum) {
        System.out.printf("Location: %d | Accuracy: %d | Total Sum: %d", location, oddsOfRightLocation, totalSum);
        this.pubSubService.publishTopic(locationFeedbackTopic, writer -> writer.writeInt(location));
        this.pubSubService.publishTopic(accuracyFeedbackTopic, writer -> writer.writeLong(oddsOfRightLocation));
        return true;
    }
}
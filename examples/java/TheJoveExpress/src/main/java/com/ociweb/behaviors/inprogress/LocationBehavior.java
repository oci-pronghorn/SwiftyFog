package com.ociweb.behaviors.inprogress;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.LocationListener;

public class LocationBehavior implements LocationListener, StartupListener {
    private final PubSubFixedTopicService locationService;
    private final PubSubFixedTopicService accuracyService;
    

    public LocationBehavior(FogRuntime runtime, String locationFeedbackTopic, String accuracyFeedbackTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.locationService = channel.newPubSubService(locationFeedbackTopic);
        this.accuracyService = channel.newPubSubService(accuracyFeedbackTopic);
    }

    @Override
    public void startup() {
        System.out.println("Started location provider.");
    }

    @Override
    public boolean location(int location, long oddsOfRightLocation, long totalSum) {
        System.out.printf("Location: %d | Accuracy: %d | Total Sum: %d", location, oddsOfRightLocation, totalSum);
        this.locationService.publishTopic(writer -> writer.writeInt(location));
        this.accuracyService.publishTopic(writer -> writer.writeLong(oddsOfRightLocation));
        return true;
    }
}
package com.ociweb.behaviors.inprogress;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.maker.CalibrationListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.LocationModeService;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class TrainingBehavior implements CalibrationListener, PubSubMethodListener {

    LocationModeService locationModeService;

    public TrainingBehavior(FogRuntime runtime) {
        System.out.println("In training behavior...");
        FogCommandChannel channel = runtime.newCommandChannel();

        this.locationModeService = channel.newLocationModeSerivce();
    }

    public boolean onTrainingStart(CharSequence topic, ChannelReader channelReader) {
        System.out.println("Beginning training!");
        locationModeService.learnCycle(100_000, 10_000);

        return true;
    }

    @Override
    public boolean finishedCalibration(int start, int units) {
        System.out.println("Calibration has finished. Units=" + units);
        return true;
    }

}

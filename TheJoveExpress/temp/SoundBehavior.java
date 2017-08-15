package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubListener;
import com.ociweb.iot.maker.FogApp;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.BlobReader;

/**
 * Play sounds on MP3 player
 * Created by dave on 7/4/17.
 */
public class SoundBehavior implements PubSubListener {
    private final FogCommandChannel channel;

    public SoundBehavior(FogRuntime runtime) {
        channel = runtime.newCommandChannel(FogApp.DYNAMIC_MESSAGING);
    }

    @Override
    public boolean message(CharSequence charSequence, BlobReader messageReader) {
        return false;
    }
}

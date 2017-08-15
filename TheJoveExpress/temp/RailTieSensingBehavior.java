package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubListener;
import com.ociweb.iot.maker.FogApp;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.BlobReader;

/**
 * Determine speed by sensing rail tie changes
 * Created by dave on 7/5/17.
 */
public class RailTieSensingBehavior implements PubSubListener {
    private final FogCommandChannel channel;

    public RailTieSensingBehavior(FogRuntime runtime) {
        channel = runtime.newCommandChannel(FogApp.DYNAMIC_MESSAGING);
    }

    @Override
    public boolean message(CharSequence charSequence, BlobReader messageReader) {
        return false;
    }
}

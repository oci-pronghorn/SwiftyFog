package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubListener;
import com.ociweb.iot.maker.FogApp;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.BlobReader;

/**
 * Mork with Motor behavior to slow down, take picture, resume speed, then send picture okk
 * Created by dave on 7/4/17.
 */
public class CameraBehavior implements PubSubListener {
    private final FogCommandChannel channel;

    public CameraBehavior(FogRuntime runtime) {
        channel = runtime.newCommandChannel(FogApp.DYNAMIC_MESSAGING);
    }

    @Override
    public boolean message(CharSequence charSequence, BlobReader messageReader) {
        return false;
    }
}

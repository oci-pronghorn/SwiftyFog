package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.simple_analog.SimpleAnalogTwig;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.RationalPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

public class SoundBehavior implements PubSubMethodListener {
    private final FogCommandChannel channel;
    private final Port port;
   // private final RationalPayload level = new RationalPayload(0, SimpleAnalogTwig.Buzzer.range());

    public SoundBehavior(FogRuntime runtime, Port port) {
        this.channel = runtime.newCommandChannel(DYNAMIC_MESSAGING);
        this.port = port;
        channel.ensurePinWriting();
    }

    public boolean onLevel(CharSequence charSequence, ChannelReader messageReader) {
        //messageReader.readInto(level);
       // channel.setValue(port, (int)level.getNumForDen(SimpleAnalogTwig.Buzzer.range()));
        return true;
    }
}

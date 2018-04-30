package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.gl.api.Writable;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Port;
import com.ociweb.iot.maker.SerialService;
import com.ociweb.pronghorn.pipe.ChannelReader;
import com.ociweb.pronghorn.pipe.ChannelWriter;

public class SoundBehavior implements PubSubMethodListener, StartupListener {
    private final SerialService serialService;
    private final Port port;
    private int value = 0;
   // private final RationalPayload level = new RationalPayload(0, SimpleAnalogTwig.Buzzer.range());

    public SoundBehavior(FogRuntime runtime, Port port) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.port = port;
        serialService = channel.newSerialService();
    }

    @Override
    public void startup() {
        serialService.publishSerial(writable);
    }

    final Writable writable = writer -> writer.writeByte(0);

    public void sendTick() {

    }

    public boolean onLevel(CharSequence charSequence, ChannelReader messageReader) {
        //messageReader.readInto(level);
       // channel.setValue(port, (int)level.getNumForDen(SimpleAnalogTwig.Buzzer.range()));
        if (!serialService.publishSerial(writable)) {
        }

        return true;
    }
}

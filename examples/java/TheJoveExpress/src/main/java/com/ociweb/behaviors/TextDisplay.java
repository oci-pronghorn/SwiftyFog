package com.ociweb.behaviors;

import static com.ociweb.iot.grove.oled.OLEDTwig.*;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;

import com.ociweb.iot.grove.oled.OLED_128x64_Transducer;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.maker.FogRuntime.*;

public class TextDisplay implements PubSubMethodListener, StartupListener {

    private final OLED_128x64_Transducer display;
    private final StringBuilder text = new StringBuilder();

    public TextDisplay(FogRuntime rt) {
        display = OLED_128x64.newTransducer(rt.newCommandChannel(I2C_WRITER,20000));
    }

    @Override
    public void startup() {
        display.setTextRowCol(3, 0);
        display.printCharSequence("OpenEdge Train");
    }

    public boolean onText(CharSequence topic, ChannelReader payload) {
        display.setTextRowCol(3, 0);
        String output = payload.readUTF();
        if (output.length() > 16) {
            output = output.substring(0, 16);
        }
        display.printCharSequence(output);
        return true;
    }
}

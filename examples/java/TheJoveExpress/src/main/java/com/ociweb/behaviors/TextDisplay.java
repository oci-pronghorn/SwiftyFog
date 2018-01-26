package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.oled.OLED_128x64_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_128x64;
import static com.ociweb.iot.maker.FogRuntime.I2C_WRITER;

public class TextDisplay implements PubSubMethodListener, StartupListener {
    private final FogCommandChannel channel;
    private final String textFeedbackTopic;
    private final OLED_128x64_Transducer display;
    private String output = "OpenEdge Train";

    public TextDisplay(FogRuntime runtime, String textFeedbackTopic) {
        this.channel = runtime.newCommandChannel();
        this.textFeedbackTopic = textFeedbackTopic;
        this.channel.ensureDynamicMessaging();
        display = OLED_128x64.newTransducer(runtime.newCommandChannel(I2C_WRITER,20000));
    }

    @Override
    public void startup() {
        display.setTextRowCol(3, 0);
        display.printCharSequence(output);
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        this.channel.publishTopic(textFeedbackTopic, writer -> writer.writeUTF(output));
        return true;
    }

    public boolean onText(CharSequence topic, ChannelReader payload) {
        display.setTextRowCol(3, 0);
        // TODO: make garbage free
        output = payload.readUTF();
        if (output.length() > 16) {
            output = output.substring(0, 16);
        }
        else {
            output = String.format("%1$-" + 16 + "s", output);
        }
        display.printCharSequence(output);
        String finalOutput = output;
        this.channel.publishTopic(textFeedbackTopic, writer -> writer.writeUTF(finalOutput));
        return true;
    }
}

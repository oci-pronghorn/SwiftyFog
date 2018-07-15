package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.oled.OLED_128x64_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_128x64;
import static com.ociweb.iot.maker.FogRuntime.I2C_WRITER;

public class TextDisplay implements PubSubMethodListener, StartupListener, ShutdownListener {
    private final PubSubFixedTopicService pubSubService;
    private final OLED_128x64_Transducer display;
    private final String initialText;
    private String displayed;

    private final String blank = "                ";
    private String[] oldStrs = { "", "", "", "", "", "", "", ""};
    private String[] newStrs = { "", "", "", "", "", "", "", ""};

    public TextDisplay(FogRuntime runtime, String initialText, String textFeedbackTopic) {
        this.initialText = initialText;
        FogCommandChannel channel = runtime.newCommandChannel();

        this.pubSubService = channel.newPubSubService(textFeedbackTopic);
        display = OLED_128x64.newTransducer(runtime.newCommandChannel(I2C_WRITER,20000));
    }

    @Override
    public void startup() {
       /* String s =
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "0123456789ABCDEF" +
                "garbage";
        displayText(s);*/
        displayText(initialText);
    }

    @Override
    public boolean acceptShutdown() {
        displayText("");
        return true;
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        this.pubSubService.publishTopic( writer -> writer.writeUTF(displayed));
        return true;
    }

    public boolean onText(CharSequence topic, ChannelReader payload) {
        String s = payload.readUTF();
        displayText(s);
        return true;
    }

    public boolean onLightsPower(CharSequence topic, ChannelReader payload) {
        boolean powered = payload.readBoolean();
        if (powered) {
            display.inverseOn();
        }
        else {
            display.inverseOff();
        }
        return true;
    }

    private void displayText(String s) {
        final int c = blank.length();
        final int r = oldStrs.length;
        final int m = c * r;
        int length = s.length();

        if (length > m) {
            int o = length - m;
            s = s.substring(o, o + m);
            length = c * r;
        }

        int rows = (int)Math.ceil((double)length / (double)c);
        int beginRow = (int)Math.floor((((double)r)/2.0) - (((double)rows)/2.0));
        if (beginRow < 0 ) beginRow = 0;
        int endRow = beginRow + rows;

        for (int i = 0; i < beginRow; i++) {
            newStrs[i] = blank;
        }

        for (int i = beginRow; i < endRow; i++) {
            int begin = (i-beginRow) * c;
            int remaining = length - begin;
            if (remaining > c) remaining = 16;
            String rowStr = s.substring(begin, begin + remaining);
            if (remaining < c) {
                rowStr = String.format("%1$-" + c + "s", rowStr);
            }
            newStrs[i] = rowStr;
        }

        for (int i = endRow; i < r; i++) {
            newStrs[i] = blank;
        }

        //System.out.println("+----------------+");
        for (int i = 0; i < newStrs.length; i++) {
            if (!oldStrs[i].equals(newStrs[i])) {
                oldStrs[i] = newStrs[i];
                display.setTextRowCol(i, 0);
                display.printCharSequence(newStrs[i]);
                //System.out.println("[" + newStrs[i] + "]");
            }
            /*else {
                System.out.println("|" + newStrs[i] + "|");
            }*/
        }
        //System.out.println("+----------------+");

        displayed = s;
        this.pubSubService.publishTopic( writer -> writer.writeUTF(displayed));
    }
}

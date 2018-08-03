package com.ociweb.behaviors;

import com.ociweb.FeatureEnabled;
import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.oled.OLED_128x64_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_128x64;
import static com.ociweb.iot.maker.FogRuntime.I2C_WRITER;

public class TextDisplayBehavior implements PubSubMethodListener, StartupListener, ShutdownListener {
    private final PubSubFixedTopicService pubSubService;
    private final OLED_128x64_Transducer display;
    private final String initialText;
    private String displayed;
    private static boolean consoleOut = false;

    private final String blank = "                ";
    private String[] oldStrs = { "", "", "", "", "", "", "", ""};
    private String[] newStrs = { "", "", "", "", "", "", "", ""};

    public static void configure(Hardware hardware, FeatureEnabled enabled) {
        if (enabled == FeatureEnabled.full) {
            hardware.connect(OLED_128x64);/*c.connect(OLED_96x96);*/
        }
        else if (enabled == FeatureEnabled.simuatedHardware) {
            consoleOut = true;
        }
    }

    public TextDisplayBehavior(FogRuntime runtime, String initialText, String textFeedbackTopic) {
        this.initialText = initialText;
        FogCommandChannel channel = runtime.newCommandChannel();

        this.pubSubService = channel.newPubSubService(textFeedbackTopic);
        display = OLED_128x64.newTransducer(runtime.newCommandChannel(I2C_WRITER,20000));
    }

    @Override
    public void startup() {
        displayText(initialText);
    }

    @Override
    public boolean acceptShutdown() {
        return displayText("");
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        return this.pubSubService.publishTopic( writer -> writer.writeUTF(displayed));
    }

    public boolean onText(CharSequence topic, ChannelReader payload) {
        return displayText(payload.readUTF());
    }

    public boolean onLightsPower(CharSequence topic, ChannelReader payload) {
        boolean powered = payload.readBoolean();
        if (powered) {
            return display.inverseOn();
        }
        else {
            return display.inverseOff();
        }
    }

    private boolean displayText(String s) {
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

        if (consoleOut) System.out.println("+----------------+");
        for (int i = 0; i < newStrs.length; i++) {
            if (!oldStrs[i].equals(newStrs[i])) {
                oldStrs[i] = newStrs[i];
                if (!display.setTextRowCol(i, 0)) {
                	return false;
                };
                if (!display.printCharSequence(newStrs[i])) {
                	return false;
                };
                if (consoleOut) System.out.println("[" + newStrs[i] + "]");
            }
            else if (consoleOut) {
                System.out.println("|" + newStrs[i] + "|");
            }
        }
        if (consoleOut)System.out.println("+----------------+");

        displayed = s;
        return this.pubSubService.publishTopic( writer -> writer.writeUTF(displayed));
    }
}

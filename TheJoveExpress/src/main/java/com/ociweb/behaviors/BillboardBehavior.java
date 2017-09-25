package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.oled.oled2.OLED96x96Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.image.FogBitmap;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_96x96_2;

public class BillboardBehavior implements PubSubMethodListener, StartupListener {
    private final String publishTopic;
    private final FogCommandChannel bufferChannel;
    private final FogCommandChannel displayChannel;
    private final OLED96x96Transducer display;
    private final FogBitmap bmp;

    public BillboardBehavior(FogRuntime rt, String publishTopic) {
        this.publishTopic = publishTopic;
        bufferChannel = rt.newCommandChannel();

        displayChannel = rt.newCommandChannel();
        display = OLED_96x96_2.newTransducer(displayChannel);

        bmp = display.newEmptyBmp();
        bufferChannel.ensureDynamicMessaging(5, bmp.messageSize());

        double scale = (double) bmp.getWidth() * bmp.getHeight();
        for (int x = 0; x < bmp.getWidth(); x++) {
            for (int y = 0; y < bmp.getHeight(); y++) {
                bmp.setValue(x, y, 0, ((double)(x * y) / scale));
            }
        }
    }

    @Override
    public void startup() {
        sendTestImage();
    }

    public boolean onAllFeedback(CharSequence charSequence, ChannelReader messageReader) {
        bufferChannel.publishTopic(publishTopic, writer->{writer.write(display.newBmpLayout());});
        return true;
    }

    private void sendTestImage() {
        bufferChannel.publishTopic("billboard/image/control", writer->{writer.write(bmp);});
    }

    public boolean onImage(CharSequence charSequence, ChannelReader ChannelReader) {
        ChannelReader.readInto(bmp);
        display.display(display.newPreferredBmpScanner(bmp));
        return true;
    }
}

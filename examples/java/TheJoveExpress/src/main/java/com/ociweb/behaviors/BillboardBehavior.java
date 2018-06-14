package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.PubSubService;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.oled.oled2.OLED96x96Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.image.FogBitmap;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_96x96_2;

public class BillboardBehavior implements PubSubMethodListener, StartupListener {
    private final String publishTopic;
    private final PubSubService pubSubService;
    private final OLED96x96Transducer display;
    private final FogBitmap bmp;

    public BillboardBehavior(FogRuntime runtime, String publishTopic) {
        FogCommandChannel bufferChannel = runtime.newCommandChannel();
        FogCommandChannel displayChannel = runtime.newCommandChannel();
        display = OLED_96x96_2.newTransducer(displayChannel);
        this.bmp = display.newEmptyBmp();
        this.pubSubService = bufferChannel.newPubSubService(5, bmp.messageSize());
        this.publishTopic = publishTopic;

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
        pubSubService.publishTopic(publishTopic, writer-> writer.write(display.newBmpLayout()));
        return true;
    }

    private void sendTestImage() {
        pubSubService.publishTopic("billboard/image/control", writer-> writer.write(bmp));
    }

    public boolean onImage(CharSequence charSequence, ChannelReader ChannelReader) {
        ChannelReader.readInto(bmp);
        //display.display(display.newPreferredBmpScanner(bmp));
        return true;
    }
}

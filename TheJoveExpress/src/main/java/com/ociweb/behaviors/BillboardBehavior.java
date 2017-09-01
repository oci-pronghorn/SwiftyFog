package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.oled.OLED_96x96_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.image.FogBitmap;
import com.ociweb.pronghorn.pipe.BlobReader;

import static com.ociweb.iot.grove.oled.OLEDTwig.OLED_96x96;

public class BillboardBehavior implements PubSubMethodListener {
    private final String publishTopic;
    private final FogCommandChannel bufferChannel;
    private final FogCommandChannel displayChannel;
    private final OLED_96x96_Transducer display;
    private final FogBitmap bmp;

    public BillboardBehavior(FogRuntime rt, String publishTopic) {
        this.publishTopic = publishTopic;
        bufferChannel = rt.newCommandChannel();

        displayChannel = rt.newCommandChannel();
        display = OLED_96x96.newTransducer(displayChannel);

        bmp = display.newEmptyBmp();
        bufferChannel.ensureDynamicMessaging(5, bmp.messageSize());
    }

    public boolean onMqttConnected(CharSequence charSequence, BlobReader messageReader) {
        bufferChannel.publishTopic(publishTopic, writer->{writer.write(display.newBmpLayout());});
        sendTestImage();
        return true;
    }

    private void sendTestImage() {
        double scale = (double) bmp.getWidth() * bmp.getHeight();
        for (int x = 0; x < bmp.getWidth(); x++) {
            for (int y = 0; y < bmp.getHeight(); y++) {
                bmp.setValue(x, y, 0, ((double)(x * y) / scale));
            }
        }
        bufferChannel.publishTopic("billboard/image", writer->{writer.write(bmp);});
    }

    public boolean onImage(CharSequence charSequence, BlobReader blobReader) {
        blobReader.readInto(bmp);
        // TODO: have display use bitmap model
        //display.display(new FogPixelProgressiveScanner(bmp));

        int[][] c = new int[bmp.getWidth()][bmp.getHeight()];
        for (int x = 0; x < bmp.getWidth(); x++) {
            for (int y = 0; y < bmp.getHeight(); y++) {
                c[x][y] = bmp.getComponent(x, y, 0);
            }
        }

        // TODO: Optimize/throttle display updates in transducer
        display.display(c);
        return true;
    }
}

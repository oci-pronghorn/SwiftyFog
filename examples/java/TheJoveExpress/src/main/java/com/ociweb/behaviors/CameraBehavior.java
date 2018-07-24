package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubFixedTopicService;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.ImageListener;
import com.ociweb.pronghorn.pipe.ChannelReader;

/**
 * Captures from camera on request and writes to file.
 *
 * @author Tobi Schweiger
 * @author Brandon Sanders (capturing logic)
 */

public class CameraBehavior implements ImageListener, PubSubMethodListener, StartupListener {

    private byte[] frameBytes = null;
    private int frameBytesHead = 0;

    private boolean continuousRecording = false;

    private final PubSubFixedTopicService pubSubService;
    private final String outputFormat;

    public CameraBehavior(FogRuntime runtime, String outputFormat, String captureFeedbackTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService(captureFeedbackTopic, 20, 20_000);
        this.outputFormat = outputFormat;
    }

    @Override
    public void startup()
    {
        System.out.println("Started CameraBehavior.");
    }

    public boolean onCapture(CharSequence topic, ChannelReader channelReader) {
        boolean success = false;

        // Here, start the recording.
        if (continuousRecording) {
            System.out.println("Stopped live streaming.");

        } else {
            System.out.println("Started live streaming.");
        }
        continuousRecording = !continuousRecording;

        // Broadcast the status of our capture
        return this.pubSubService.publishTopic(writer -> writer.writeBoolean(success));
    }

    long previousTime = 0;
    private boolean sentFrameStart = false;

    int rowNum = 0;

    /**
     * Captures a new image.
     *
     * @param width
     * @param height
     * @param timestamp
     * @param frameBytesCount
     */
    @Override
    public boolean onFrameStart(int width, int height, long timestamp, int frameBytesCount) {
        if (!continuousRecording) return true;

        sentFrameStart = true;
        System.out.printf("Duration from last header to this header: %d ms%n", timestamp - previousTime);
        previousTime = timestamp;

        frameBytes = new byte[frameBytesCount];
        System.out.printf("Created new frame buffer for frames of size %dW x %dH with %d bytes.\n", width, height, frameBytesCount);

        /*boolean status = this.pubSubService.publishTopic(liveFrameStartTopic, writer -> {
            writer.writeInt(width);
            writer.writeInt(height);
        }, WaitFor.None);

        if(status) {
            frameBytesHead = 0;
            rowNum = 0;
        }*/
        return true;
    }

    /**
     * Writes to the current image.
     *
     * @param frameRowBytes
     */
    @Override
    public boolean onFrameRow(byte[] frameRowBytes) {
        if (!continuousRecording || !sentFrameStart) return true;

        /*
        return this.pubSubService.publishTopic(liveFrameRowTopic + (rowNum++), writer -> writer.write(frameRowBytes), WaitFor.None);*/
        return true;
    }
}

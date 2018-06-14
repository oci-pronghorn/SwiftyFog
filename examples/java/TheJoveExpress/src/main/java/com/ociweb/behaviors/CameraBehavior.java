package com.ociweb.behaviors;

import com.ociweb.gl.api.*;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.ImageListener;
import com.ociweb.pronghorn.pipe.ChannelReader;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Captures from camera on request and writes to file.
 *
 * @author Tobi Schweiger
 * @author Brandon Sanders (capturing logic)
 */
public class CameraBehavior implements ImageListener, PubSubMethodListener, StartupListener {

    File workingFile = null;
    private byte[] frameBytes = null;
    private int frameBytesHead = 0;

    private boolean continuousRecording = false;

    private final PubSubService pubSubService;
    private final String captureFeedbackTopic;
    private final String outputFormat;

    public CameraBehavior(FogRuntime runtime, String outputFormat, String captureFeedbackTopic) {
        FogCommandChannel channel = runtime.newCommandChannel();
        this.pubSubService = channel.newPubSubService();
        this.captureFeedbackTopic = captureFeedbackTopic;
        this.outputFormat = outputFormat;
    }

    public boolean onCapture(CharSequence topic, ChannelReader channelReader) {
        boolean success = false;

        // Here, start the recording.
        if (continuousRecording) {
            System.out.println("Stopped continuous capture.");
        } else {
            System.out.println("Started continuous capture.");
        }
        continuousRecording = !continuousRecording;

        // Broadcast the status of our capture
        this.pubSubService.publishTopic(captureFeedbackTopic, writer -> writer.writeBoolean(success));
        return true;
    }

    @Override
    public void startup() {
        System.out.println("Camera started up.");
    }

    /**
     * Captures a new image.
     * @param width
     * @param height
     * @param timestamp
     * @param frameBytesCount
     */
    @Override
    public void onFrameStart(int width, int height, long timestamp, int frameBytesCount) {
        if(!continuousRecording) return;

        // Prepare file.
        workingFile = new File(String.format(outputFormat, timestamp));

        // Prepare byte array.
        if (frameBytes == null || frameBytes.length != frameBytesCount) {
            frameBytes = new byte[frameBytesCount];
            System.out.printf("Created new frame buffer for frames of size %dW x %dH with %d bytes.\n", width, height, frameBytesCount);
        }

        System.out.printf("Started new frame (%d) @ %d.\n", timestamp, System.currentTimeMillis());

        frameBytesHead = 0;
    }

    /**
     * Writes to the current image.
     * @param frameRowBytes
     */
    @Override
    public void onFrameRow(byte[] frameRowBytes) {
        if(!continuousRecording) return;

        // Copy bytes.
        System.arraycopy(frameRowBytes, 0, frameBytes, frameBytesHead, frameRowBytes.length);
        frameBytesHead += frameRowBytes.length;

        // Flush to disk if we have a full frame.
        if (frameBytesHead >= frameBytes.length) {

            // Write file.
            try {
                workingFile.createNewFile();
                FileOutputStream fos = new FileOutputStream(workingFile);
                fos.write(frameBytes);
                fos.flush();
                fos.close();
                System.out.printf("Captured image to disk (%s) @ %d.\n", workingFile.getName(), System.currentTimeMillis());
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }
}

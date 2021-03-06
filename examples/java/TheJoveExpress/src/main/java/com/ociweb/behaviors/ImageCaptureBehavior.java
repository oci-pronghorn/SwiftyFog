package com.ociweb.behaviors;

import com.ociweb.gl.api.ClientHostPortInstance;
import com.ociweb.gl.api.HTTPRequestService;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.iot.maker.ImageListener;
import com.ociweb.json.encode.JSONRenderer;
import com.ociweb.pronghorn.pipe.util.ISOTimeFormatterLowGC;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Base64;

public class ImageCaptureBehavior implements ImageListener {
	
	private BufferedImage bufferedImage;
	private HTTPRequestService clientService;
	private static ClientHostPortInstance session;
	private long now = -1;
	private int countDownRows;


	//HTTPHeaderDateTimeFormatterLowGC low = new HTTPHeaderDateTimeFormatterLowGC();
	private ISOTimeFormatterLowGC low = new ISOTimeFormatterLowGC();
	private byte[] imageData;
	
	private JSONRenderer<ImageCaptureBehavior> renderer = new JSONRenderer<ImageCaptureBehavior>()
			.startObject() 
				.string("timestamp", (o,t) -> low.write(now, t) )
				.string("image", (o,t) -> t.append(Base64.getEncoder().encodeToString(imageData)))			
			.endObject();

	public static void configure(Hardware hardware, String imageCapturePath) {
		if (!hardware.isTestHardware() && imageCapturePath!=null) {
			URL url;
			try {
				url = new URL(imageCapturePath);
				session = hardware.useInsecureNetClient()
						//.setMaxRequestSize(1<<21)
						//.setMaxResponseSize(200)
						//.setRequestQueueLength(2)
						.newHTTPSession(url.getHost(), url.getPort())
						.finish();

				hardware.setImageSize(640, 480);
				hardware.setImageTriggerRate(40);

			} catch (MalformedURLException e) {
				e.printStackTrace();
				//throw new RuntimeException(e);
			}
		}
	}

	public static Boolean isOperational() {
		return session != null;
	}

	public ImageCaptureBehavior(FogRuntime runtime, int width, int height) {
		this.bufferedImage = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
		this.clientService = runtime.newCommandChannel().newHTTPClientService(2, 1<<21 ); //json encoded image
	}

	@Override
	public boolean onFrameStart(int width, int height, long timestamp, int frameBytesCount) {
		now = timestamp;		
		assert(width == bufferedImage.getWidth()) : "Size of buffer must match";
		assert(height == bufferedImage.getHeight()) : "Size of buffer must match";
		countDownRows = height;
		return true;
	}

	@Override
	public boolean onFrameRow(byte[] frameRowBytes) {
		if (now>=0) {
			if (countDownRows>0) {
			
			    int startY = bufferedImage.getHeight()-countDownRows;
				
				int[] rgbArray = new int[bufferedImage.getWidth()];
				
				int j = 0;
				for(int i=0; i<rgbArray.length; i++) {
					int t=0;
					t |= ((int)frameRowBytes[j++])<<16;
					t |= ((int)frameRowBytes[j++])<<8;
					t |= ((int)frameRowBytes[j++])<<0;
					rgbArray[i] = t;
				}
				
				int offset = 0;
				int scansize = 0;
				
				bufferedImage.setRGB(0, startY, bufferedImage.getWidth(), 1, rgbArray, offset, scansize);
			
				
				if (--countDownRows == 0) {
					//convert image into array
					
				    ByteArrayOutputStream baos = new ByteArrayOutputStream();
				    try {
						ImageIO.write(bufferedImage, "jpg", baos);			
						imageData = baos.toByteArray();
						
					} catch (IOException e) {
						e.printStackTrace();
						now = -1;
						return true; ///skip rest of image						
					}
					
					
					//this is the end so publish					
					boolean posted = clientService.httpPost(session, "upload", w-> {			
						renderer.render(w, this);
					});
					if (posted) {
						now = -1;
					}
					return posted;
					
				} else {
					return true; //we added this row to the image.
				}
			
			} else {
				//this is a publish retry due to load
				boolean posted = clientService.httpPost(session, "upload", w-> {			
					renderer.render(w, this);
				});
				if (posted) {
					now = -1;
				}
				return posted;
			}			
		} else {
			return true;//drop data since the start was missing.
		}
	}

}

package com.ociweb.behaviors;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.iot.grove.motor_driver.MotorDriver_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayLoad;
import com.ociweb.pronghorn.pipe.BlobReader;

import static com.ociweb.iot.grove.motor_driver.MotorDriverTwig.MotorDriver;

public class ActuatorDriverBehavior implements PubSubMethodListener {
    private final MotorDriver_Transducer motorControl;
    private final ActuatorDriverPayLoad payload = new ActuatorDriverPayLoad();
    private int portAPower = 0;
    private int portBPower = 0;

    public ActuatorDriverBehavior(FogRuntime runtime) {
        final FogCommandChannel channel = runtime.newCommandChannel();
        motorControl = MotorDriver.newTransducer(channel);
    }

    public boolean setPower(CharSequence charSequence, BlobReader blobReader) {
        blobReader.readInto(payload);
        int ranged = (int)(payload.power * motorControl.getMaxVelocity());
        switch (payload.port) {
            case A:
                if (portAPower == ranged) return true;
                portAPower = ranged;
                break;
            case B:
                if (portBPower == ranged) return true;
                portBPower = ranged;
                break;
        }
        motorControl.setPower(portAPower, portBPower);
        return true;
    }
}

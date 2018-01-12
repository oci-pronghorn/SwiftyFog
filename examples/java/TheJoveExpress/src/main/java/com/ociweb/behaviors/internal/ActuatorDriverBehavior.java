package com.ociweb.behaviors.internal;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.iot.grove.motor_driver.MotorDriver_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.motor_driver.MotorDriverTwig.MotorDriver;

public class ActuatorDriverBehavior implements PubSubMethodListener, ShutdownListener {
    private final MotorDriver_Transducer motorControl;
    private final ActuatorDriverPayload payload = new ActuatorDriverPayload();
    private int portAPower = 0;
    private int portBPower = 0;

    public ActuatorDriverBehavior(FogRuntime runtime) {
        final FogCommandChannel channel = runtime.newCommandChannel();
        motorControl = MotorDriver.newTransducer(channel);
    }

    @Override
    public boolean acceptShutdown() {
        motorControl.setPower(0, 0);
        return true;
    }

    public boolean setPower(CharSequence charSequence, ChannelReader ChannelReader) {
        ChannelReader.readInto(payload);
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
        return motorControl.setPower(portAPower, portBPower);
    }
}

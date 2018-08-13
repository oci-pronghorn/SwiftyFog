package com.ociweb.behaviors;

import com.ociweb.FeatureEnabled;
import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.iot.grove.motor_driver.MotorDriver_Transducer;
import com.ociweb.iot.maker.FogCommandChannel;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.pronghorn.pipe.ChannelReader;

import static com.ociweb.iot.grove.motor_driver.MotorDriverTwig.MotorDriver;

/**
    A behavior to drive the MotorDriver_Transducer hardware
 */
public class SharedActuatorDriverBehavior implements PubSubMethodListener, ShutdownListener {
    private final MotorDriver_Transducer motorControl;
    private final ActuatorDriverPayload payload = new ActuatorDriverPayload();
    private int portAPower = 0;
    private int portBPower = 0;

    public static void configure(Hardware hardware, FeatureEnabled lightsEnabled, FeatureEnabled engineEnabled) {
        boolean enabled = lightsEnabled == FeatureEnabled.full || engineEnabled == FeatureEnabled.full;
        if (enabled) {
            hardware.connect(MotorDriver);
        }
    }

    public SharedActuatorDriverBehavior(FogRuntime runtime) {
        final FogCommandChannel channel = runtime.newCommandChannel();
        motorControl = MotorDriver.newTransducer(channel);
    }

    @Override
    public boolean acceptShutdown() {
        return motorControl.setPower(0, 0);
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

package com.ociweb.behaviors.internal;

import com.ociweb.gl.api.PubSubMethodListener;
import com.ociweb.gl.api.ShutdownListener;
import com.ociweb.gl.api.StartupListener;
import com.ociweb.iot.grove.simple_digital.SimpleDigitalTwig;
import com.ociweb.iot.maker.FogRuntime;
import com.ociweb.iot.maker.Hardware;
import com.ociweb.iot.maker.PinService;
import com.ociweb.iot.maker.Port;
import com.ociweb.model.ActuatorDriverPayload;
import com.ociweb.model.ActuatorDriverPort;
import com.ociweb.pronghorn.pipe.ChannelReader;

// TODO: fully implement
public class PWMActuatorDriverBehavior implements PubSubMethodListener, ShutdownListener, StartupListener {
    private final PinService pwmService;
    private final ActuatorDriverPort engineActuatorPort;
    private static Port enginePowerPort;
    private static Port engineDirectionPort;
    private static Port ledPort;
    private final ActuatorDriverPayload payload = new ActuatorDriverPayload();

    public static void connectHardware(Hardware hardware, Port enginePowerPort, Port engineDirectionPort, Port ledPort) {
        PWMActuatorDriverBehavior.enginePowerPort = enginePowerPort;
        PWMActuatorDriverBehavior.engineDirectionPort = engineDirectionPort;
        PWMActuatorDriverBehavior.ledPort = ledPort;

        if (ledPort != null) {
            hardware.connect(SimpleDigitalTwig.LED, ledPort);
        }
        if (enginePowerPort != null && engineDirectionPort != null) {
            hardware.connect(SimpleDigitalTwig.MDDS30Power, enginePowerPort);
            hardware.connect(SimpleDigitalTwig.MDDS30Direction, engineDirectionPort);
        }
    }

    public PWMActuatorDriverBehavior(FogRuntime runtime, ActuatorDriverPort engineActuatorPort) {
        this.pwmService = runtime.newCommandChannel().newPinService();
        this.engineActuatorPort = engineActuatorPort;
    }

    @Override
    public void startup() {
        //must be zero on startup or hardware will report an error, (double blink)
        pwmService.setValue(engineDirectionPort, 0);
        pwmService.setValue(enginePowerPort, 0);
        pwmService.setValue(ledPort, 0);
    }

    @Override
    public boolean acceptShutdown() {
        // Turn everything off
        return true;
    }

    public boolean setPower(CharSequence charSequence, ChannelReader ChannelReader) {
        ChannelReader.readInto(payload);
        if (payload.port == engineActuatorPort) {
            // TODO: actuate engine
            double power = payload.power; // values inclusive -1.0 to 1.0
            return true;
        }
        else {
            // TODO: actuate light
            double power = payload.power; // values only 0.0 and 1.0
            return true;
        }
    }
}

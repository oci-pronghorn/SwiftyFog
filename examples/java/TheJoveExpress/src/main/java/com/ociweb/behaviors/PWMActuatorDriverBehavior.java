package com.ociweb.behaviors;

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

/**
 * A behavior that operates both an LED and MDDS30 motor driver
 * TODO: Determine if we want two behaviors instead of one
 */
public class PWMActuatorDriverBehavior implements PubSubMethodListener, ShutdownListener, StartupListener {
    private final PinService pwmService;
    private final ActuatorDriverPort engineActuatorPort;
    private static Port enginePowerPort;
    private static Port engineDirectionPort;
    private static Port ledPort;
    private final ActuatorDriverPayload payload = new ActuatorDriverPayload();
    private final int powerMax;

    public static void configure(Hardware hardware, Port enginePowerPort, Port engineDirectionPort, Port ledPort) {
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
        this.powerMax = runtime.builder.getConnectedDevice(enginePowerPort).range()-1;
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
        pwmService.setValue(engineDirectionPort, 0);
        pwmService.setValue(enginePowerPort, 0);
        pwmService.setValue(ledPort, 0);
        return true;
    }

    public boolean setPower(CharSequence charSequence, ChannelReader ChannelReader) {
        ChannelReader.readInto(payload);
        if (payload.port == engineActuatorPort) {
            double actualPower = payload.power; // values inclusive -1.0 to 1.0
            int p = (int)(powerMax* Math.abs(actualPower));
            pwmService.setValue(engineDirectionPort,actualPower<0?0:255);
            pwmService.setValue(enginePowerPort, p);
            return true;
        }
        else {
            double updatePower = payload.power; // values only 0.0 and 1.0
            final int twigRange = 1024;
            //System.out.println("light" + (int)((twigRange-1)*updatePower));
            return this.pwmService.setValue(ledPort, (int)((twigRange-1)*updatePower));
        }
    }
}

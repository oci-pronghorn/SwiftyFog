package com.ociweb.model;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

/**
 * The payload sent to an actuator - has port and fractional payload
 */
public class ActuatorDriverPayload implements Externalizable {
    public ActuatorDriverPort port;
    public double power;

    public int messageSize() {
        return Integer.SIZE + Double.SIZE;
    }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeInt(port.ordinal());
        out.writeDouble(power);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        port = ActuatorDriverPort.values()[in.readInt()];
        power = in.readDouble();
    }
}

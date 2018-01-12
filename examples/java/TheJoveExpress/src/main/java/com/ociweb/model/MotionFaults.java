package com.ociweb.model;

import com.ociweb.iot.grove.six_axis_accelerometer.AccelerometerValues;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

public class MotionFaults implements Externalizable {
    private boolean derailed;
    private boolean tipped;
    private boolean lifted;
    private boolean falling;

    boolean hasFault() {
        return (derailed || tipped || lifted || falling);
    }

    public MotionFaults() {
    }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeBoolean(derailed);
        out.writeBoolean(tipped);
        out.writeBoolean(lifted);
        out.writeBoolean(falling);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        derailed = in.readBoolean();
        tipped = in.readBoolean();
        lifted = in.readBoolean();
        falling = in.readBoolean();
    }

    public boolean accept(AccelerometerValues accelerometerValues) {
        return false;
    }

    public boolean accept(int engineState) {
        return false;
    }
}

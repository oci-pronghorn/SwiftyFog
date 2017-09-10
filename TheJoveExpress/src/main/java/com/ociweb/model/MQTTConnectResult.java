package com.ociweb.model;

import com.ociweb.gl.api.MQTTConnectionStatus;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

public class MQTTConnectResult implements Externalizable {
    public MQTTConnectionStatus status;
    public boolean sessionPresent;

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {

    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        status = MQTTConnectionStatus.fromSpecification(in.readInt());
        sessionPresent = in.readInt() != 0;
    }
}

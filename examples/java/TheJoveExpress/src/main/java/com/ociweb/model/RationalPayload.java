package com.ociweb.model;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

// TODO: make swift understand big endian packed SInt32
public class RationalPayload implements Externalizable {
    public int num;
    public int den;

    public RationalPayload() {
        this.num = 0;
        this.den = 1;
    }

    public RationalPayload(int num, int den) {
        this.num = num;
        this.den = den;
    }

    public double ratio() { return (double)num / (double)den; }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeInt(num);
        out.writeInt(den);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        num = in.readInt();
        den = in.readInt();
    }
}

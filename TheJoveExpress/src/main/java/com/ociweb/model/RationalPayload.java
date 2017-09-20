package com.ociweb.model;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

// TODO: make swift understand big endian packed SInt64
public class RationalPayload implements Externalizable {
    public long num;
    public long den;

    public RationalPayload() {
        this.num = 0;
        this.den = 1;
    }

    public RationalPayload(long num, long den) {
        this.num = num;
        this.den = den;
    }

    public int messageSize() {
        return Long.SIZE + Long.SIZE;
    }

    public double ratio() { return (double)num / (double)den; }

    public long getNumForDen(long den) {
        double r = ratio();
        return (long)(r * den);
    }

    @Override
    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeLong(num);
        out.writeLong(den);
    }

    @Override
    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        num = in.readLong();
        den = in.readLong();
    }
}

package com.ociweb.model;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;

/**
 * A precise way to senf a decimal number and value with range
 */
// TODO: make swift understand big endian packed SInt32
public class RationalPayload implements Externalizable {
    public int num;
    public int den;
    //public ElapsedTimeRecorder etr = new ElapsedTimeRecorder();
    //private static final Logger logger = LoggerFactory.getLogger(RationalPayload.class);
    
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
       /*
        //check for optional trailing sent time
        if (in.available()==8) {
        	long sentTime = in.readLong();
        	long duration = System.currentTimeMillis()-sentTime;
        	ElapsedTimeRecorder.record(etr, duration*1_000_000L);
        	
        	if ((etr.totalCount(etr)%0xFF) == 0) {
        		logger.info("broker latency: \n{}", etr.report(new StringBuilder()));

        	}
        }
        */
    }
}

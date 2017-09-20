package com.ociweb.model;

import java.io.Externalizable;

public interface CallableExternalizedMethod<T extends Externalizable> {
    boolean method(CharSequence var1, T var2);
}

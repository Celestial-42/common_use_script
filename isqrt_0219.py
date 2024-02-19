# -*- coding: utf-8 -*-
"""
Created on Sat Jun 15 18:34:23 2019

@author: wangzhongfei
"""

import math
import numpy as np
import matplotlib.pyplot as plt

expDic = {}
def around(x):
    return np.trunc(np.where(x < 0, x - 0.5, x + 0.5))

def get_in_data0():
    A = range(-128, 128)
    FL = range(-15, 16)
    X = []

    for fl in FL:
        for a in A:
            x = a * np.power(2, -fl, dtype=np.float32)
            X.append(x)

    X = list(set(X))
    X.sort()

    return X

def get_ieee754_integer(A, fl):
    if A == 0:
        return 0
    A_bw = len(bin(A)) - 2
    i_bw = A_bw - fl

    E_ = i_bw - 1
    E = E_ + 127
    M = A & (np.power(2, A_bw - 1, dtype=np.int64) - 1)
    x = (E << 23) | (M << (23 - (A_bw - 1)))
    return x

def hw_cal(A, fl, M, M_fl):
    bw = M_fl if M_fl > fl else fl

    A_ = A << (bw - fl)
    M_ = M << (bw - M_fl)

    A_half = np.int64(around(A_ * np.power(2, -1, dtype=np.float32)))
    M_half = np.int64(around(M_ * np.power(2, -1, dtype=np.float32)))

    # y = M_ + M_*0.5 - A_half * M_^3
    tmp1 = np.int64(M_ * M_)
    tmp1 = np.int64(around(tmp1 * np.power(2, -bw, dtype=np.float32)))
    tmp2 = np.int64(around(M_ * A_half * np.power(2, -bw, dtype=np.float32)))
    tmp3 = np.int64(around(tmp1 * tmp2 * np.power(2, -bw, dtype=np.float32)))

    y = M_ + M_half - tmp3
    return y, bw

def hw_inv_sqrt(A, fl, iter_times):
    i = get_ieee754_integer(A, fl)
    i = 0x5f3759df - (i >> 1)
    E = i >> 23
    E_ = E - 127
    M = i & (np.power(2, 23, dtype=np.int64) - 1) | 0x800000
    M_fl = 23 - E_

    y, y_fl = hw_cal(A, fl, M, M_fl)

    for i in range(1, iter_times):
        y, y_fl = hw_cal(A, fl, y, y_fl)

    return y, y_fl

def sw_inv_sqrt(A, fl):
    x = A * np.power(2, -fl, dtype=np.float32)
    val = np.sqrt(x, dtype=np.float32)
    y = 1.0 / val
    return y

# hw_inv_sqrt(1759, 0, 1)

def data_in_compare():
    A = range(1, 65535)
    # FL = range(15, 16)
    fl = 0
    X = []
    Y = []
    DIF = []

    
    for a in A:
        x = a * np.power(2, -fl, dtype=np.float32)
        X.append(x)
        y_sw = sw_inv_sqrt(a, fl)
        y_hw, y_fl = hw_inv_sqrt(a, fl, 1)
        new = y_hw * pow(2.0, -y_fl)
        dif = abs(y_sw - new)
        DIF.append(dif)
        Y.append(new)

    print(max(DIF))
    plt.figure()
    plt.subplot(1, 2, 1)
    plt.plot(X, Y)
    plt.subplot(1, 2, 2)
    plt.plot(X, DIF)
    plt.show()

data_in_compare()













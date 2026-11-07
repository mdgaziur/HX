//
//  constants.swift
//  hx
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Darwin
import Hypervisor

public let hxPlatformKIB: Int = 1024
public let hxPlatformMIB: Int = 1024 * hxPlatformKIB
public let hxPlatformGIB: Int = 1024 * hxPlatformMIB
public let hxPlatformTIB: Int = 1024 * hxPlatformGIB

// Memory management related
public let hxPlatformPageSize: Int = Int(getpagesize())

// Registers
public let hxPlatformRegX0: HXPlatformReg = HV_REG_X0
public let hxPlatformRegX1: HXPlatformReg = HV_REG_X1
public let hxPlatformRegX2: HXPlatformReg = HV_REG_X2
public let hxPlatformRegX3: HXPlatformReg = HV_REG_X3
public let hxPlatformRegX4: HXPlatformReg = HV_REG_X4
public let hxPlatformRegX5: HXPlatformReg = HV_REG_X5
public let hxPlatformRegX6: HXPlatformReg = HV_REG_X6
public let hxPlatformRegX7: HXPlatformReg = HV_REG_X7
public let hxPlatformRegX8: HXPlatformReg = HV_REG_X8
public let hxPlatformRegX9: HXPlatformReg = HV_REG_X9
public let hxPlatformRegX10: HXPlatformReg = HV_REG_X10
public let hxPlatformRegX11: HXPlatformReg = HV_REG_X11
public let hxPlatformRegX12: HXPlatformReg = HV_REG_X12
public let hxPlatformRegX13: HXPlatformReg = HV_REG_X13
public let hxPlatformRegX14: HXPlatformReg = HV_REG_X14
public let hxPlatformRegX15: HXPlatformReg = HV_REG_X15
public let hxPlatformRegX16: HXPlatformReg = HV_REG_X16
public let hxPlatformRegX17: HXPlatformReg = HV_REG_X17
public let hxPlatformRegX18: HXPlatformReg = HV_REG_X18
public let hxPlatformRegX19: HXPlatformReg = HV_REG_X19
public let hxPlatformRegX20: HXPlatformReg = HV_REG_X20
public let hxPlatformRegX21: HXPlatformReg = HV_REG_X21
public let hxPlatformRegX22: HXPlatformReg = HV_REG_X22
public let hxPlatformRegX23: HXPlatformReg = HV_REG_X23
public let hxPlatformRegX24: HXPlatformReg = HV_REG_X24
public let hxPlatformRegX25: HXPlatformReg = HV_REG_X25
public let hxPlatformRegX26: HXPlatformReg = HV_REG_X26
public let hxPlatformRegX27: HXPlatformReg = HV_REG_X27
public let hxPlatformRegX28: HXPlatformReg = HV_REG_X28
public let hxPlatformRegX29: HXPlatformReg = HV_REG_X29
public let hxPlatformRegFP: HXPlatformReg = HV_REG_FP      // alias of X29
public let hxPlatformRegX30: HXPlatformReg = HV_REG_X30
public let hxPlatformRegLR: HXPlatformReg = HV_REG_LR      // alias of X30
public let hxPlatformRegPC: HXPlatformReg = HV_REG_PC
public let hxPlatformRegFPCR: HXPlatformReg = HV_REG_FPCR
public let hxPlatformRegFPSR: HXPlatformReg = HV_REG_FPSR
public let hxPlatformRegCPSR: HXPlatformReg = HV_REG_CPSR

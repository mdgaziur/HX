//
//  HXPlatform.swift
//  HXPlatform
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Foundation
import Hypervisor

typealias HXPlatformVCPUExitInner = UnsafeMutablePointer<hv_vcpu_exit_t>

public typealias HXPlatformVMConfig = hv_vm_config_t
public typealias HXPlatformVCPUConfig = hv_vcpu_config_t
public typealias HXPlatformVCPU = hv_vcpu_t
public typealias HXPlatformESR = hv_exception_syndrome_t
public typealias HXPlatformReg = hv_reg_t
public typealias HXPlatformIPA = hv_ipa_t
public typealias HXPlatformMemoryFlags = hv_memory_flags_t

public func hvVMConfigCreate() -> HXPlatformVMConfig {
    hv_vm_config_create()
}

public func hvVMCreate(config: HXPlatformVMConfig?) throws {
    try hvCheck(hv_vm_create(config), "hvVMCreate")
}

public func hvVMMap(_ addr: UnsafeMutableRawPointer, ipa: hv_ipa_t, size: Int, flags: hv_memory_flags_t) throws {
    precondition(Int(bitPattern: addr) % hxPlatformPageSize == 0, "host address not page-aligned")
    precondition(ipa % UInt64(hxPlatformPageSize) == 0, "gpa not page-aligned")
    precondition(size > 0 && size % hxPlatformPageSize == 0, "size not a page multiple")
    
    try hvCheck(hv_vm_map(addr, ipa, size, flags),
                "hvVMMap(hva: \(addr), gpa: 0x\(String(ipa, radix: 16)), size: 0x\(String(size, radix: 16))")
}

public func hvVCPUConfigCreate() throws -> HXPlatformVCPUConfig {
    hv_vcpu_config_create()
}

public func hvVCPUCreate(config: HXPlatformVCPUConfig?) throws -> (vcpu: HXPlatformVCPU, exit: HXPlatformVCPUExit) {
    var vcpu: HXPlatformVCPU = 0
    var exit: HXPlatformVCPUExitInner? = nil
    
    try hvCheck(hv_vcpu_create(&vcpu, &exit, config), "hvVCPUCreate")
    
    guard let exit else {
        fatalError("hv_vcpu_create succeeded but did not populate exit pointer")
    }
    
    return (vcpu, HXPlatformVCPUExit(inner: exit))
}

public func hvVCPUSetReg(vcpu: HXPlatformVCPU, reg: HXPlatformReg, value: UInt64) throws {
    try hvCheck(hv_vcpu_set_reg(vcpu, reg, value),
                "hvVCPUSetReg(vcpu, \(reg), 0x\(String(value, radix: 16))")
}

public func hvVCPUGetReg(vcpu: HXPlatformVCPU, reg: HXPlatformReg) throws -> UInt64 {
    var value: UInt64 = 0
    try hvCheck(hv_vcpu_get_reg(vcpu, reg, &value),
                "hvVCPUGetReg(vcpu, \(reg)")
    
    return value
}

public func hvVCPURun(vcpu: HXPlatformVCPU) throws {
    try hvCheck(hv_vcpu_run(vcpu), "hvVCPURun")
}

public func hvVCPUDestroy(vcpu: HXPlatformVCPU) throws {
    try hvCheck(hv_vcpu_destroy(vcpu), "hvVCPUDestroy")
}

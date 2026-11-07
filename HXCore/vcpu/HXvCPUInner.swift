//
//  HXvCPUInner.swift
//  hx
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import HXPlatform

class HXvCPUInner {
    let pc: HXPlatformIPA
    var vcpu: HXPlatformVCPU? = nil
    var exit: HXPlatformVCPUExit? = nil
    
    init(pc: HXPlatformIPA) {
        self.pc = pc
    }
    
    deinit {
        guard let vcpu else { return }
        
        do {
            try hvVCPUDestroy(vcpu: vcpu)
        } catch {
            assertionFailure("HXvCPUInner deinit failed: \(error)")
        }
    }
    
    func create() throws {
        let (vcpu, exit) = try hvVCPUCreate(config: nil)
        self.vcpu = vcpu
        self.exit = exit
        
        try hvVCPUSetReg(vcpu: vcpu, reg: hxPlatformRegPC, value: pc)
        try hvVCPUSetReg(vcpu: vcpu, reg: hxPlatformRegCPSR, value: 0x3c5)
    }
    
    func getReg(reg: HXPlatformReg) throws -> UInt64 {
        try hvVCPUGetReg(vcpu: vcpu!, reg: reg)
    }
    
    func setReg(reg: HXPlatformReg, value: UInt64) throws {
        try hvVCPUSetReg(vcpu: vcpu!, reg: reg, value: value)
    }
    
    func run() throws -> HXPlatformVMExit {
        try hvVCPURun(vcpu: vcpu!)
        
        return exit!.get_exit_status()
    }
}

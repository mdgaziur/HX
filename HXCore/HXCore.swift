//
//  HXCore.swift
//  HXCore
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Foundation
import HXPlatform

let hxRamStart = HXPlatformIPA(0x4000_0000)

public class HXCore {
    let hostMemory: HXHostMemory
    let cpu0: HXvCPU
    
    public init(hostMemorySize: Int) throws {
        try hvVMCreate(config: nil)
        
        hostMemory = try HXHostMemory(request: hostMemorySize)
        try hvVMMap(
            hostMemory.base,
            ipa: hxRamStart,
            size: hostMemory.size,
            flags: HXPlatformMemoryFlags(HV_MEMORY_READ | HV_MEMORY_WRITE | HV_MEMORY_EXEC))
        
        cpu0 = HXvCPU(id: 0, pc: hxRamStart, stackSize: 1 * hxPlatformMIB)
    }
    
    public func copyToMemory(offset: Int, data: [UInt8]) throws {
        try hostMemory.copyToMemory(offset: offset, data: data)
    }
    
    public func start() {
        cpu0.start()
    }
    
    public func wait() -> Int {
        cpu0.wait()
    }
}

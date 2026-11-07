//
//  HXvCPU.swift
//  hx
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Foundation
import HXPlatform
import Synchronization

enum VMAction {
    case resume, advancePC, stop(code: Int)
}

final class HXvCPUResult: Sendable {
    private let code = Mutex<Int?>(nil)
    func set(_ c: Int) {
        code.withLock {
            $0 = c
        }
    }
    var value: Int? {
        code.withLock {
            $0
        }
    }
}

class HXvCPU {
    let id: Int;
    let pc: HXPlatformIPA
    private let done = DispatchSemaphore(value: 0)
    private let thread: Thread
    private let result = HXvCPUResult()
    
    init(id: Int, pc: HXPlatformIPA, stackSize: Int) {
        self.id = id
        self.pc = pc
        
        let done = self.done
        let result = self.result
        
        thread = Thread {
            defer { done.signal() }
            
            let vCPUInner = HXvCPUInner(pc: pc)
            
            do {
                try vCPUInner.create()
            } catch {
                print("vCPU error while creating: \(error)")
                result.set(1)
                return
            }
            
            do {
                while true {
                    let vmExitReason = try vCPUInner.run()
                    let vmAction: VMAction
                    
                    switch vmExitReason {
                    case .cancelled: vmAction = .stop(code: 0x0)
                    case .hypercall(let imm):
                        let x0 = try vCPUInner.getReg(reg: hxPlatformRegX0)
                        print("guest hvc #\(imm), x0 = \(x0)")
                        vmAction = .stop(code: Int(x0))
                    default:
                        print("unhandled exit: \(vmExitReason) at PC \(String(try vCPUInner.getReg(reg: hxPlatformRegPC), radix: 16))")
                        vmAction = .stop(code: 1)
                    }
                    
                    switch vmAction {
                    case .advancePC: try vCPUInner.setReg(reg: hxPlatformRegPC, value: try vCPUInner.getReg(reg: hxPlatformRegPC) + 4)
                    case .resume:
                        continue
                    case .stop(let c):
                        result.set(c)
                        return
                    }
                }
            } catch {
                print("vCPU error: \(error)")
            }
        }
        
        thread.name = "HXvCPU-\(id)"
        thread.stackSize = stackSize
        thread.qualityOfService = .userInitiated
    }
    
    func start() {
        thread.start()
    }
    
    func wait() -> Int {
        self.done.wait()
        
        return result.value ?? 1
    }
}

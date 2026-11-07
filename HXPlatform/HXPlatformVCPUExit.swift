//
//  HXPlatformVCPUExit.swift
//  hx
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Hypervisor

public enum HXPlatformVMExit {
    /// The value that identifies exits requested by exit handler on the host.
    case cancelled
    
    /// The value that identifies when the virtual timer enters the pending state.
    case vTimerActivated
    
    /// The value that identifies unexpected exits.
    case unknown(HVRawVCPUExit)
    
    /// Trapped wait for interupt execution
    case waitForInterrupt
    
    /// Trapped wait for event execution
    case waitForEvent
    
    /// Hypercall execution
    case hypercall(imm: UInt16)
    
    /// Secure monitor call execution
    case secureMonitorCall(imm: UInt16)
    
    /// Handling system register access
    case systemRegisterAccess(register: HXPlatformSystemRegisterAccess)
    
    /// Instruction abort
    case instructionAbort(ipa: HXPlatformIPA, esr: HXPlatformESR)
    
    /// Unhandled data abort exception
    case mmioUndecodable(ipa: HXPlatformIPA, esr: HXPlatformESR)
    
    /// MMIO access caused by data abort exception
    case mmioAccess(_ mmioAccess: HXPlatformMMIOAccess)
}

public struct HXPlatformSystemRegisterAccess {
    let op0: UInt8
    let op1: UInt8
    let op2: UInt8
    let crn: UInt8
    let crm: UInt8
    let rt: UInt8
    let read: Bool
}

public struct HXPlatformMMIOAccess {
    let addr: HXPlatformIPA
    let accessSize: HXPlatformSyndromeAccessSize
    let signExtend: Bool
    let register: UInt8
    let is64Bit: Bool
    let isARSemantics: Bool
    let wnr: HXPlatformWNR
    let dfsc: HXPlatformDFSC
    let lst: HXPlatformLoadStoreType
}

public enum HXPlatformSyndromeAccessSize {
    case byte, halfword, word, doubleword, unknown
    
    init(value: UInt8) {
        self = switch value {
        case 0b00: .byte
        case 0b01: .halfword
        case 0b10: .word
        case 0b11: .doubleword
        default: .unknown
        }
    }
}

public enum HXPlatformWNR {
    case write(to: HXPlatformIPA), read(from: HXPlatformIPA)
    
    init(value: Bool, ipa: HXPlatformIPA) {
        self = switch value {
        case true: .write(to: ipa)
        case false: .read(from: ipa)
        }
    }
}

/// Data Fault Status Code: ESR ISS bits [5:0] for data aborts.
/// (Instruction aborts use the same encoding for their IFSC field.)
public enum HXPlatformDFSC: Equatable, Sendable {
    case addressSize(level: Int)                 // levels -2...3
    case translation(level: Int)                 // levels -2...3
    case accessFlag(level: Int)                  // levels 0...3 (0 needs FEAT_LPA2)
    case permission(level: Int)                  // levels 0...3 (0 needs FEAT_LPA2)
    case externalAbort                           // not on a table walk
    case externalAbortOnWalk(level: Int)         // levels -2...3
    case tagCheck                                // FEAT_MTE2
    case parityOrECC                             // not on a walk (no FEAT_RAS)
    case parityOrECCOnWalk(level: Int)           // levels -1...3 (no FEAT_RAS)
    case alignment
    case granuleProtection                       // not on a walk (FEAT_RME)
    case granuleProtectionOnWalk(level: Int)     // levels -2...3 (FEAT_RME)
    case tlbConflict
    case unsupportedAtomicUpdate                 // FEAT_HAFDBS
    case implementationDefinedLockdown
    case implementationDefinedUnsupportedExclusiveOrAtomic
    case reserved(UInt8)

    public init(_ code: UInt8) {
        let v = code & 0x3F
        let level = Int(v & 0b11)                // for the 0bxxxxLL families

        switch v {
        case 0b000000...0b000011: self = .addressSize(level: level)
        case 0b101001:            self = .addressSize(level: -1)
        case 0b101100:            self = .addressSize(level: -2)

        case 0b000100...0b000111: self = .translation(level: level)
        case 0b101011:            self = .translation(level: -1)
        case 0b101010:            self = .translation(level: -2)

        case 0b001000...0b001011: self = .accessFlag(level: level)
        case 0b001100...0b001111: self = .permission(level: level)

        case 0b010000:            self = .externalAbort
        case 0b010001:            self = .tagCheck
        case 0b010010:            self = .externalAbortOnWalk(level: -2)
        case 0b010011:            self = .externalAbortOnWalk(level: -1)
        case 0b010100...0b010111: self = .externalAbortOnWalk(level: level)

        case 0b011000:            self = .parityOrECC
        case 0b011011:            self = .parityOrECCOnWalk(level: -1)
        case 0b011100...0b011111: self = .parityOrECCOnWalk(level: level)

        case 0b100001:            self = .alignment
        case 0b100010:            self = .granuleProtectionOnWalk(level: -2)
        case 0b100011:            self = .granuleProtectionOnWalk(level: -1)
        case 0b100100...0b100111: self = .granuleProtectionOnWalk(level: level)
        case 0b101000:            self = .granuleProtection

        case 0b110000:            self = .tlbConflict
        case 0b110001:            self = .unsupportedAtomicUpdate
        case 0b110100:            self = .implementationDefinedLockdown
        case 0b110101:            self = .implementationDefinedUnsupportedExclusiveOrAtomic

        default:                  self = .reserved(v)
        }
    }

    /// Convenience: decode straight from an ISS value.
    public init(iss: UInt32) {
        self.init(UInt8(truncatingIfNeeded: iss & 0x3F))
    }
    
    public func hasLoadStoreType() -> Bool {
        switch self {
        case .translation, .accessFlag, .permission: true
        default: false
        }
    }
}

public enum HXPlatformLoadStoreType {
    case unspecified, st64bv, ld64bOrSt64b, st64bv0, unknown
    
    init(iss: UInt32) {
        self = switch (iss >> 11) & 0b11 {
        case 0b00: .unspecified
        case 0b01: .st64bv
        case 0b10: .ld64bOrSt64b
        case 0b11: .st64bv0
        default: .unknown
        }
    }
}

public struct HVRawVCPUExit {
    /// The intermediate physical address of the exception in the client.
    var physicalAddress: HXPlatformIPA
    
    /// The vCPU exception syndrome causing the exception.
    var syndrome: HXPlatformESR
    
    /// The vCPU virtual address of the exception.
    var virtualAddress: HXPlatformIPA
    
    /// Information about an exit from the vcpu to the host.
    var exitReason: HXPlatformExitReason
}

public enum HXPlatformExitReason {
    /// The value that identifies exits requested by exit handler on the host.
    case cancelled
    
    /// The value that identifies traps caused by the guest operations.
    case exception
    
    /// The value that identifies when the virtual timer enters the pending state.
    case vTimerActivated
    
    /// The value that identifies unexpected exits.
    case unknown(hv_exit_reason_t)
    
    init(reason: hv_exit_reason_t) {
        self = switch reason {
        case HV_EXIT_REASON_CANCELED: .cancelled
        case HV_EXIT_REASON_EXCEPTION: .exception
        case HV_EXIT_REASON_VTIMER_ACTIVATED: .vTimerActivated
        case HV_EXIT_REASON_UNKNOWN: .unknown(reason)
        default: .unknown(reason)
        }
    }
}

let hxPlatformTrappedWF: UInt8 = 0x01
let hxPlatformHVC: UInt8 = 0x16
let hxPlatformSMC: UInt8 = 0x17
let hxPlatformSysReg: UInt8 = 0x18
let hxPlatformInstructionAbort: UInt8 = 0x20
let hxPlatformDataAbort: UInt8 = 0x24

private func decodeRawExit(exit: HVRawVCPUExit) -> HXPlatformVMExit {
    switch exit.exitReason {
    case .cancelled:
        return .cancelled
    case .vTimerActivated:
        return .vTimerActivated
    case .unknown(let unknown_reason):
        return .unknown(exit)
    case .exception:
        break
    }
    
    let esr = exit.syndrome
    let ec = UInt8((esr >> 26) & 0x3FF)
    let iss = UInt32(esr & 0x1FF_FFFF)
    
    switch ec {
    case hxPlatformTrappedWF:
        return iss & 1 == 0 ? .waitForInterrupt : .waitForEvent
    case hxPlatformHVC:
        return .hypercall(imm: UInt16(truncatingIfNeeded: iss))
    case hxPlatformSMC:
        return .secureMonitorCall(imm: UInt16(truncatingIfNeeded: iss))
    case hxPlatformSysReg:
        return .systemRegisterAccess(register: HXPlatformSystemRegisterAccess(
            op0: UInt8((iss >> 20) & 0b11), op1: UInt8((iss >> 14) & 0b111),
            op2: UInt8((iss >> 17) & 0b111), crn: UInt8((iss >> 10) & 0b1111),
            crm: UInt8((iss >> 1) & 0b1111), rt: UInt8((iss >> 5) & 0b11111),
            read: (iss & 1) == 1))
    case hxPlatformInstructionAbort:
        return .instructionAbort(ipa: exit.physicalAddress, esr: esr)
    case hxPlatformDataAbort:
        return decodeDataAbort(exit, iss)
    
    default: return .unknown(exit)
    }
}

private func decodeDataAbort(_ exit: HVRawVCPUExit, _ iss: UInt32) -> HXPlatformVMExit {
    // If ISV is not set, we bail
    guard iss & (1 << 24) != 0 else {
        return .mmioUndecodable(ipa: exit.physicalAddress, esr: exit.syndrome)
    }
    
    let syndromeAccessSize = HXPlatformSyndromeAccessSize(value: UInt8((iss >> 22) & 0b11))
    let syndromeSignExtend = ((iss >> 21) & 1) == 1
    
    let syndromeRegisterTransfer = UInt8(((iss >> 16) & 0b11111))
    let is64BitRegister = ((iss >> 15) & 1) == 1
    let isARSemantics = ((iss >> 14) & 1) == 1
    let wnr = HXPlatformWNR(value: ((iss >> 6) & 1) == 1, ipa: exit.physicalAddress)
    let dfsc = HXPlatformDFSC(iss: iss)
    
    let lst = if dfsc.hasLoadStoreType() {
        HXPlatformLoadStoreType(iss: iss)
    } else {
        HXPlatformLoadStoreType.unknown
    }
    
    return .mmioAccess(HXPlatformMMIOAccess(
        addr: exit.physicalAddress,
        accessSize: syndromeAccessSize,
        signExtend: syndromeSignExtend,
        register: syndromeRegisterTransfer,
        is64Bit: is64BitRegister,
        isARSemantics: isARSemantics,
        wnr: wnr,
        dfsc: dfsc,
        lst: lst
    ))
}

public class HXPlatformVCPUExit {
    var inner: HXPlatformVCPUExitInner
    
    init(inner: HXPlatformVCPUExitInner) {
        self.inner = inner
    }
    
    public func get_exit_status() -> HXPlatformVMExit {
        let rawExitReason = HVRawVCPUExit(
            physicalAddress: inner.pointee.exception.physical_address,
            syndrome: inner.pointee.exception.syndrome,
            virtualAddress: inner.pointee.exception.virtual_address,
            exitReason: HXPlatformExitReason(reason: inner.pointee.reason)
        )
        
        return decodeRawExit(exit: rawExitReason)
    }
}

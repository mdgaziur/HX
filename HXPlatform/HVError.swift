//
//  HVError
//  hx
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Hypervisor

public struct HVError: Error, CustomStringConvertible {
    public enum Kind {
        case error, busy, badArgument, illegalGuestState, noResources, noDevice, unsupported, denied,
            unknown(hv_return_t)
    }

    public let code: hv_return_t
    public let call: String
    public let location: String

    public var kind: Kind {
        switch code {
        case Self.c(HV_ERROR): .error
        case Self.c(HV_BUSY): .busy
        case Self.c(HV_BAD_ARGUMENT): .badArgument
        case Self.c(HV_ILLEGAL_GUEST_STATE): .illegalGuestState
        case Self.c(HV_NO_RESOURCES): .noResources
        case Self.c(HV_NO_DEVICE): .noDevice
        case Self.c(HV_UNSUPPORTED): .unsupported
        case Self.c(HV_DENIED): .denied
        default: .unknown(code)
        }
    }

    public var description: String {
        let hex = String(UInt32(bitPattern: code), radix: 16)
        var msg = "\(call) failed: \(kind) (0x\(hex)) at \(location)"
        return msg
    }

    private static func c<T: BinaryInteger>(_ v: T) -> hv_return_t {
        hv_return_t(truncatingIfNeeded: v)
    }
}

@inline(__always)
func hvCheck(_ r: hv_return_t , _ call: @autoclosure () -> String,
             fileID: String = #fileID, line: Int = #line) throws {
    guard r != 0 else { return }
    throw HVError(code: r, call: call(), location: "\(fileID):\(line)")
}

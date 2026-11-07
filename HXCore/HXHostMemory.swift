//
//  memory.swift
//  hx
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Darwin
import HXPlatform

public enum HostMemoryError: Error {
    case InvalidSize(Int)
    case AllocationFailed(errno: Int32, message: String)
    case OutOfBoundCopyOffset
}

public class HXHostMemory {
    let size: Int
    let base: UnsafeMutableRawPointer
    
    init(request: Int) throws {
        guard request > 0 else {
            throw HostMemoryError.InvalidSize(request)
        }

        let (padded, overflow) = request.addingReportingOverflow(hxPlatformPageSize)
        guard !overflow else { throw HostMemoryError.InvalidSize(request) }
        let size = padded & ~(hxPlatformPageSize - 1)
        
        let p = mmap(
            nil,
            size,
            PROT_READ | PROT_WRITE,
            MAP_ANON | MAP_PRIVATE,
            -1,
            0
        );
        
        guard let p, p != UnsafeMutableRawPointer(bitPattern: -1) else {
            let e = errno
            throw HostMemoryError.AllocationFailed(errno: e, message: String(cString: strerror(e)))
        }
        
        precondition(Int(bitPattern: p) & (hxPlatformPageSize - 1) == 0, "mmap returned unaligned memory")
        self.base = p
        self.size = size
    }
    
    func copyToMemory(offset: Int, data: [UInt8]) throws {
        if offset < 0 || offset + data.count >= size {
            throw HostMemoryError.OutOfBoundCopyOffset
        }
        
        base.advanced(by: offset).copyMemory(from: data, byteCount: data.count)
    }
    
    deinit {
        if munmap(base, size) !=  0 {
            assertionFailure("munmap failed: \(String(cString: strerror(errno)))")
        }
    }
}

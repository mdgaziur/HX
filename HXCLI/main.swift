//
//  main.swift
//  HXCLI
//
//  Created by MD Gaziur Rahman Noor on 7/11/26.
//

import Foundation
import HXCore
import HXPlatform

func main() throws {
    let hxCore = try HXCore(hostMemorySize: 64 * hxMIB)
    
    let code: [UInt8] = [
                                  // uint64_t fib(void) {
        0x40, 0x01, 0x80, 0xD2,   //   uint64_t n = 10;            // 0x00  mov  x0, #10
        0x01, 0x00, 0x80, 0xD2,   //   uint64_t a = 0;             // 0x04  mov  x1, #0
        0x22, 0x00, 0x80, 0xD2,   //   uint64_t b = 1;             // 0x08  mov  x2, #1
                                  // loop:
        0xC0, 0x00, 0x00, 0xB4,   //   if (n == 0) goto done;      // 0x0C  cbz  x0, done
        0x23, 0x00, 0x02, 0x8B,   //   uint64_t t = a + b;         // 0x10  add  x3, x1, x2
        0xE1, 0x03, 0x02, 0xAA,   //   a = b;                      // 0x14  mov  x1, x2
        0xE2, 0x03, 0x03, 0xAA,   //   b = t;                      // 0x18  mov  x2, x3
        0x00, 0x04, 0x00, 0xD1,   //   n = n - 1;                  // 0x1C  sub  x0, x0, #1
        0xFB, 0xFF, 0xFF, 0x17,   //   goto loop;                  // 0x20  b    loop
                                  // done:
        0xE0, 0x03, 0x01, 0xAA,   //   uint64_t result = a;        // 0x24  mov  x0, x1
        0x02, 0x00, 0x00, 0xD4,   //   hypercall(result);          // 0x28  hvc  #0   → VMM sees x0 = 55
                                  // }
    ]
    try hxCore.copyToMemory(offset: 0, data: code)
    
    print("Starting HX guest...")
    hxCore.start()
    
    print("Waiting for return code...")
    let returnCode = hxCore.wait()
    
    print("Guest exited with return code \(returnCode)")
}

do {
    try main()
} catch {
    FileHandle.standardError.write(Data("HX Error: \(error)\n".utf8))
}

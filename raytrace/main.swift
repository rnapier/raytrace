//
//  main.swift
//  raytrace
//
//  Created by Rob Napier on 12/23/16.
//
//

let nx = 200
let ny = 100
print("P3\n\(nx) \(ny)\n255")
for j in (0..<ny).reversed() {
    for i in 0..<nx {
        let r = Float(i) / Float(nx)
        let g = Float(j) / Float(ny)
        let b = 0.2
        let ir = Int(255.99 * r)
        let ig = Int(255.99 * g)
        let ib = Int(255.99 * b)
        print("\(ir) \(ig) \(ib)")
    }
}

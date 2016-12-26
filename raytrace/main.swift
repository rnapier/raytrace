//
//  main.swift
//  raytrace
//
//  Created by Rob Napier on 12/23/16.
//
//

import Darwin
import Foundation

public struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) {
        fputs(string, stderr)}
}
public var errStream = StderrOutputStream()

func errPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    for item in items {
        print(item, separator, terminator: "", to: &errStream)
    }
    print(terminator, terminator: "", to: &errStream)
}

infix operator ⋅ : MultiplicationPrecedence

func randomDouble() -> Double {
    return drand48()
}

struct Vector {
    static var zero: Vector { return Vector(0, 0, 0) }
    static func *(scalar: Double, rhs: Vector) -> Vector {
        return Vector(scalar * rhs.x, scalar * rhs.y, scalar * rhs.z)
    }

    static func /(lhs: Vector, scalar: Double) -> Vector {
        return Vector(lhs.x / scalar, lhs.y / scalar, lhs.z / scalar)
    }

    func lerp(to: Vector, at t: Double) -> Vector {
        return (1.0 - t) * self + t * to
    }

    let x, y, z: Double
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    var length: Double {
        return sqrt(lengthSquared)
    }

    var lengthSquared: Double {
        return x*x + y*y + z*z
    }

    var unit: Vector {
        return self / length
    }
    static func +(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    static func -(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    static func ⋅(lhs: Vector, rhs: Vector) -> Double {
        return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    static func randomInUnitSphere() -> Vector {
        repeat {
            let p = 2.0*Vector(randomDouble(), randomDouble(), randomDouble()) - Vector(1,1,1)
            if p.lengthSquared < 1 { return p }
        } while true
    }
}

extension Vector: CustomStringConvertible {
    var description: String {
        return "(\(x),\(y),\(z))"
    }
}

struct Ray {
    let origin: Vector
    let direction: Vector
    init(origin: Vector, direction: Vector) {
        self.origin = origin
        self.direction = direction
    }
    init(origin: Vector, through: Vector) {
        self.origin = origin
        self.direction = through - origin
    }
    func point(atParameter t: Double) -> Vector {
        return origin + t * direction
    }
}

extension Ray: CustomStringConvertible {
    var description: String {
        return "[\(origin) -> \(direction)]"
    }
}

extension Vector {
    var r: Double { return x }
    var g: Double { return y }
    var b: Double { return z }
}

var totalHits = 0
extension Ray {
    func color<World: Hittable>(in world: World) -> Vector {
        if let hit = world.hitLocation(for: self, in: (0.001)..<(.infinity)) {
            totalHits += 1
            let target = hit.p + hit.normal + .randomInUnitSphere()
            return 0.5 * Ray(origin: hit.p, direction: target - hit.p).color(in: world)
        } else {
            let unitDirection = direction.unit
            let t = 0.5 * (unitDirection.y + 1)
            return Vector(1, 1, 1).lerp(to: Vector(0.5, 0.7, 1), at: t)
        }
    }
}

struct HitLocation {
    var t: Double
    var p: Vector
    var normal: Vector
}

protocol Hittable {
    func hitLocation(for ray: Ray, in: Range<Double>) -> HitLocation?
}

struct Sphere: Hittable {
    let center: Vector
    let radius: Double

    func hitLocation(for ray: Ray, in range: Range<Double>) -> HitLocation? {

        func hitLocation(for t: Double) -> HitLocation? {
            // Do not include ends of range
            guard t > range.lowerBound && t < range.upperBound else { return nil }
            let point = ray.point(atParameter: t)
            return HitLocation(t: t,
                               p: point,
                               normal: (point - center) / radius)
        }

        let oc = ray.origin - center
        let a = ray.direction ⋅ ray.direction
        let b = oc ⋅ ray.direction
        let c = oc ⋅ oc - radius * radius
        let discriminant = b * b - a * c

        if discriminant > 0 {
            let s = sqrt(discriminant)
            return hitLocation(for: (-b - s)/a) ?? hitLocation(for: (-b + s)/a)
        }

        return nil
    }
}

struct HittableArray: Hittable {
    let elements: [Hittable]

    init(_ elements: [Hittable]) { self.elements = elements }

    func hitLocation(for ray: Ray, in range: Range<Double>) -> HitLocation? {
        return elements.reduce(nil) { (previousHit, hittable) in
            let maxT = previousHit?.t ?? range.upperBound
            let hit = hittable.hitLocation(for: ray, in: range.lowerBound..<maxT)
            return hit ?? previousHit
        }
    }
}

struct Camera {
    let lowerLeftCorner = Vector(-2, -1, -1)
    let horizontal = Vector(4, 0, 0)
    let vertical = Vector(0, 2, 0)
    let origin = Vector.zero

    func ray(atPlaneX x: Double, planeY y: Double) -> Ray {
        return Ray(origin: origin, through: lowerLeftCorner + x * horizontal + y * vertical)
    }
}

srand48(0)

let nx = 200
let ny = 100
let ns = 100

print("P3\n\(nx) \(ny)\n255")

let world = HittableArray([
    Sphere(center: Vector(0, 0, -1), radius: 0.5),
    Sphere(center: Vector(0, -100.5, -1), radius: 100),
])

let camera = Camera()

for j in (0..<ny).reversed() {
    for i in 0..<nx {
        let col = (0..<ns).reduce(Vector.zero) { (c, s) in
            let u = (Double(i) + randomDouble()) / Double(nx)
            let v = (Double(j) + randomDouble()) / Double(ny)

            let r = camera.ray(atPlaneX: u, planeY: v)

            return c + r.color(in: world)
        } / Double(ns)

        let ir = Int(255.99 * col.r)
        let ig = Int(255.99 * col.g)
        let ib = Int(255.99 * col.b)
        print("\(ir) \(ig) \(ib)")
    }
}

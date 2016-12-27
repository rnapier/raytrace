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

struct Vector {
    static var zero: Vector { return Vector(0, 0, 0) }
    static func *(scalar: Double, rhs: Vector) -> Vector {
        return Vector(scalar * rhs.x, scalar * rhs.y, scalar * rhs.z)
    }
    static func *(rhs: Vector, scalar: Double) -> Vector {
        return Vector(scalar * rhs.x, scalar * rhs.y, scalar * rhs.z)
    }
    static prefix func -(v: Vector) -> Vector {
        return Vector(-v.x, -v.y, -v.z)
    }

    static func /(lhs: Vector, scalar: Double) -> Vector {
        return Vector(lhs.x / scalar, lhs.y / scalar, lhs.z / scalar)
    }

    func lerp(to: Vector, at t: Double) -> Vector {
        return (1.0 - t) * self + t * to
    }

    var x, y, z: Double
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

    static func *(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
    }

    static func ⋅(lhs: Vector, rhs: Vector) -> Double {
        return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z
    }

    static func randomInUnitSphere() -> Vector {
        repeat {
            let p = 2.0*Vector(drand48(), drand48(), drand48()) - Vector(1,1,1)
            if p.lengthSquared < 1 { return p }
        } while true
    }

    func reflect(acrossNormal n: Vector) -> Vector {
        return self - 2*self⋅n*n
    }

    func refract(acrossNormal n: Vector, withRefractiveIndex ri: Double) -> Vector? {
        let uv = unit
        let dt = uv ⋅ n
        let discriminant = 1.0 - ri*ri*(1-dt*dt)
        if discriminant > 0 {
            return ri*(uv - n*dt) - n*sqrt(discriminant)
        } else {
            return nil
        }
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

extension Ray {
    func color<World: Hittable>(in world: World, depth: Int = 0) -> Vector {
        if let rec = world.hitRecord(for: self, in: (0.001)..<(Double(MAXFLOAT))) {
            if depth < 50,
                let scatterResult = rec.material.scatter(ray: self, hitRecord: rec) {
                return scatterResult.attenuation * scatterResult.scattered.color(in: world, depth: depth + 1)
            } else {
                return Vector.zero
            }
        } else {
            let unitDirection = direction.unit
            let t = 0.5 * (unitDirection.y + 1)
            return Vector(1, 1, 1).lerp(to: Vector(0.5, 0.7, 1), at: t)
        }
    }
}

struct HitRecord {
    var t: Double
    var p: Vector
    var normal: Vector
    var material: Material
}

protocol Hittable {
    func hitRecord(for ray: Ray, in: Range<Double>) -> HitRecord?
}

struct Sphere: Hittable {
    let center: Vector
    let radius: Double
    let material: Material

    func hitRecord(for ray: Ray, in range: Range<Double>) -> HitRecord? {

        func hitRecord(for t: Double) -> HitRecord? {
            // Do not include ends of range
            guard t > range.lowerBound && t < range.upperBound else { return nil }
            let point = ray.point(atParameter: t)
            return HitRecord(t: t,
                             p: point,
                             normal: (point - center) / radius,
                             material: material)
        }

        let oc = ray.origin - center
        let a = ray.direction ⋅ ray.direction
        let b = oc ⋅ ray.direction
        let c = oc ⋅ oc - radius * radius
        let discriminant = b * b - a * c

        if discriminant > 0 {
            let s = sqrt(discriminant)
            return hitRecord(for: (-b - s)/a) ?? hitRecord(for: (-b + s)/a)
        }

        return nil
    }
}

struct HittableArray: Hittable {
    let elements: [Hittable]

    init(_ elements: [Hittable]) { self.elements = elements }

    func hitRecord(for ray: Ray, in range: Range<Double>) -> HitRecord? {
        return elements.reduce(nil) { (previousHit, hittable) in
            let maxT = previousHit?.t ?? range.upperBound
            let hit = hittable.hitRecord(for: ray, in: range.lowerBound..<maxT)
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

struct ScatterResult {
    let scattered: Ray
    let attenuation: Vector
}

protocol Material {
    func scatter(ray: Ray, hitRecord: HitRecord) -> ScatterResult?
}

struct Lambertian: Material {
    let albedo: Vector
    func scatter(ray: Ray, hitRecord rec: HitRecord) -> ScatterResult? {
        let target = rec.p + rec.normal + Vector.randomInUnitSphere()
        return ScatterResult(scattered: Ray(origin: rec.p, direction: target - rec.p),
                             attenuation: albedo)
    }
}

struct Metal: Material {
    let albedo: Vector
    func scatter(ray: Ray, hitRecord rec: HitRecord) -> ScatterResult? {
        let reflected = ray.direction.unit.reflect(acrossNormal: rec.normal)
        let scattered = Ray(origin: rec.p, direction: reflected)
        guard scattered.direction ⋅ rec.normal > 0 else { return nil }

        return ScatterResult(scattered: scattered, attenuation: albedo)
    }
}

struct Dielectric: Material {
    let refractionIndex: Double
    func scatter(ray: Ray, hitRecord rec: HitRecord) -> ScatterResult? {
        let reflected = ray.direction.reflect(acrossNormal: rec.normal)

        let outwardNormal: Vector
        let ni_over_nt: Double
        if ray.direction ⋅ rec.normal > 0 {
            outwardNormal = -rec.normal
            ni_over_nt = refractionIndex
        } else {
            outwardNormal = rec.normal
            ni_over_nt = 1.0 / refractionIndex
        }

        let attenuation = Vector(1,1,1)
        if let refracted = ray.direction.refract(acrossNormal: outwardNormal, withRefractiveIndex: ni_over_nt) {
            return ScatterResult(scattered: Ray(origin: rec.p, direction: refracted), attenuation: attenuation)
        } else {
            return ScatterResult(scattered: Ray(origin: rec.p, direction: reflected), attenuation: attenuation)
        }
    }
}

srand48(0)

let nx = 200
let ny = 100
let ns = 100

print("P3\n\(nx) \(ny)\n255")

let world = HittableArray([
    Sphere(center: Vector(0, 0, -1), radius: 0.5, material: Lambertian(albedo: Vector(0.1, 0.2, 0.5))),
    Sphere(center: Vector(0, -100.5, -1), radius: 100, material: Lambertian(albedo: Vector(0.8, 0.8, 0.0))),
    Sphere(center: Vector(1,0,-1), radius: 0.5, material: Metal(albedo: Vector(0.8,0.6,0.2))),
    Sphere(center: Vector(-1,0,-1), radius: 0.5, material: Dielectric(refractionIndex: 1.5)),
    ])

let camera = Camera()

for j in (0..<ny).reversed() {
    for i in 0..<nx {
        var col = (0..<ns).reduce(Vector.zero) { (c, s) in
            let u = (Double(i) + drand48()) / Double(nx)
            let v = (Double(j) + drand48()) / Double(ny)
            let r = camera.ray(atPlaneX: u, planeY: v)
            return c + r.color(in: world)
            }
        col = col / Double(ns)
        col = Vector(sqrt(col.x), sqrt(col.y), sqrt(col.z))

        let ir = Int(255.99 * col.r)
        let ig = Int(255.99 * col.g)
        let ib = Int(255.99 * col.b)
        print("\(ir) \(ig) \(ib)")
    }
}

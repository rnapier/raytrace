//
//  main.swift
//  raytrace
//
//  Created by Rob Napier on 12/23/16.
//
//

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
infix operator × : MultiplicationPrecedence

func schlick(cosine: Double, ri: Double) -> Double {
    var r0 = (1-ri)/(1+ri)
    r0 = r0*r0
    return r0 + (1-r0)*pow((1-cosine), 5)
}

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

    static func +=(lhs: inout Vector, rhs: Vector) {
        lhs = Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
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

    static func ×(lhs: Vector, rhs: Vector) -> Vector {
        return Vector( (  lhs.y * rhs.z - lhs.z * rhs.y),
                       (-(lhs.x * rhs.z - lhs.z * rhs.x)),
                       (  lhs.x * rhs.y - lhs.y * rhs.x))
    }

    static func randomInUnitSphere() -> Vector {
        repeat {
            let p = 2.0*Vector(drand48(), drand48(), drand48()) - Vector(1,1,1)
            if p.lengthSquared < 1 { return p }
        } while true
    }

    static func randomInUnitDisk() -> Vector {
        repeat {
            let p = 2.0*Vector(drand48(), drand48(), 0) - Vector(1,1,0)
            if p⋅p < 1 { return p }
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
    let time: Double

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
    func color(in world: Hittable, depth: Int = 0) -> Vector {
        if let rec = world.hit(for: self, in: (0.001)..<(Double(MAXFLOAT))) {
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

struct Hit {
    var t: Double
    var p: Vector
    var normal: Vector
    var material: Material
}

struct Hittable {
    var hitFunction: (Ray, Range<Double>) -> Hit?
    func hit(for ray: Ray, in range: Range<Double>) -> Hit? { return hitFunction(ray, range) }
    var boundingBoxFunction: (Range<Double>) -> AABB?
    func boundingBox(overTimes times: Range<Double>) -> AABB? { return boundingBoxFunction(times) }
}

func Sphere<M: Material>(center: Vector, radius: Double, material: M) -> Hittable {

    return Hittable(
        hitFunction: { (ray, range) in

            func hitRecord(for t: Double) -> Hit? {
                // Do not include ends of range
                guard t > range.lowerBound && t < range.upperBound else { return nil }
                let point = ray.point(atParameter: t)
                return Hit(t: t,
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
    },

        boundingBoxFunction: { times in
            return AABB(minCorner: center - Vector(radius, radius, radius),
                        maxCorner: center + Vector(radius, radius, radius))
    })
}

func MovingSphere<M: Material>(startCenter: Vector, endCenter: Vector, startTime: Double, endTime: Double, radius: Double, material: M) -> Hittable {

    func center(at time: Double) -> Vector {
        return startCenter + ((time - startTime) / (endTime - startTime))*(endCenter - startCenter)
    }

    return Hittable(
        hitFunction: { (ray, range) in
            func hit(for t: Double) -> Hit? {
                // Do not include ends of range
                guard t > range.lowerBound && t < range.upperBound else { return nil }
                let point = ray.point(atParameter: t)
                return Hit(t: t,
                           p: point,
                           normal: (point - center(at: ray.time)) / radius,
                           material: material)
            }

            let oc = ray.origin - center(at: ray.time)
            let a = ray.direction ⋅ ray.direction
            let b = oc ⋅ ray.direction
            let c = oc ⋅ oc - radius * radius
            let discriminant = b * b - a * c

            if discriminant > 0 {
                let s = sqrt(discriminant)
                return hit(for: (-b - s)/a) ?? hit(for: (-b + s)/a)
            }

            return nil
    },

        boundingBoxFunction: { times in
            return AABB(minCorner: center(at: times.lowerBound) - Vector(radius, radius, radius),
                        maxCorner: center(at: times.lowerBound) + Vector(radius, radius, radius)) +
                AABB(minCorner: center(at: times.upperBound) - Vector(radius, radius, radius),
                     maxCorner: center(at: times.upperBound) + Vector(radius, radius, radius))
    })
}

//struct HittableArray: Hittable {
//
//    let elements: [Hittable]
//    init(_ elements: [Hittable]) { self.elements = elements }
//
//    func hit(for ray: Ray, in range: Range<Double>) -> Hit? {
//        var closestHit: Hit? = nil
//        var maxT = range.upperBound
//        for element in elements {
//            if let hit = element.hit(for: ray, in: range.lowerBound..<maxT) {
//                closestHit = hit
//                maxT = hit.t
//            }
//        }
//        return closestHit
//    }
//    func boundingBox(overTimes times: Range<Double>) -> AABB? {
//        return elements.reduce(nil) { (box, e) in
//            guard let box = box else { return e.boundingBox(overTimes: times) }
//            guard let eBox = e.boundingBox(overTimes: times) else { return box }
//            return box + eBox
//        }
//    }
//}

func BVH(_ elements: [Hittable], timeRange: Range<Double>) -> Hittable {
    let left: Hittable // FIXME: Is duplicating here really better than optional?
    let right: Hittable

    let box: AABB

    let count = elements.count

    if count == 1 {
        left = elements[0]
        right = elements[0]
    } else if count == 2 {
        left = elements[0]
        right = elements[1]
    } else {

        func volumeDifference(list: [Hittable]) -> Double {
            let pivot = count / 2
            let left = list.prefix(upTo: pivot).map({ $0.boundingBox(overTimes: timeRange)!.volume }).reduce(0, +)
            let right = list.suffix(from: pivot).map({ $0.boundingBox(overTimes: timeRange)!.volume }).reduce(0, +)
            return abs(right - left)
        }

        let xSorted = elements.sorted { (lhs, rhs) in
            lhs.boundingBox(overTimes: 0..<1)!.minCorner.x < rhs.boundingBox(overTimes: timeRange)!.minCorner.x
        }

        let ySorted = elements.sorted { (lhs, rhs) in
            lhs.boundingBox(overTimes: 0..<1)!.minCorner.y < rhs.boundingBox(overTimes: timeRange)!.minCorner.y
        }

        let zSorted = elements.sorted { (lhs, rhs) in
            lhs.boundingBox(overTimes: 0..<1)!.minCorner.z < rhs.boundingBox(overTimes: timeRange)!.minCorner.z
        }

        let sortedElements = [xSorted, ySorted, zSorted].map({ ($0, volumeDifference(list: $0)) }).min(by: { $0.1 < $1.1 }).map { $0.0 }!


        let pivot = count / 2
        left = BVH(Array(sortedElements.prefix(upTo: pivot)), timeRange: timeRange)
        right = BVH(Array(sortedElements.suffix(from: pivot)), timeRange: timeRange)
    }

    let leftBox = left.boundingBox(overTimes: timeRange)!
    let rightBox = right.boundingBox(overTimes: timeRange)!

    //        errPrint(abs(leftBox.volume - rightBox.volume))
    box = leftBox + rightBox

    return Hittable(
        hitFunction: { (ray, range) in
            guard box.isHit(by: ray, inRange: range) else { return nil }

            let leftHit = left.hit(for: ray, in: range)
            let rightHit = right.hit(for: ray, in: range)
            if let leftHit = leftHit, let rightHit = rightHit {
                if leftHit.t < rightHit.t { return leftHit } else { return rightHit }
            }

            if let leftHit = leftHit { return leftHit }
            if let rightHit = rightHit { return rightHit }
            return nil
    },
        boundingBoxFunction: { _ in return box }
    )
}

struct Camera {
    init(lookFrom: Vector, lookAt: Vector, vup: Vector, vfov: Double, aspect: Double, aperture: Double, focusDist: Double, overTimes: Range<Double> ) {
        timeRange = overTimes
        lensRadius = aperture / 2
        let theta = vfov*M_PI/180
        let halfHeight = tan(theta/2)
        let halfWidth = aspect * halfHeight
        origin = lookFrom
        w = (lookFrom - lookAt).unit
        u = (vup × w).unit
        v = w × u
        lowerLeftCorner = origin - halfWidth*focusDist*u - halfHeight*focusDist*v - focusDist*w
        horizontal = 2*halfWidth*focusDist*u
        vertical = 2*halfHeight*focusDist*v
    }
    let lowerLeftCorner: Vector
    let horizontal: Vector
    let vertical: Vector
    let origin: Vector
    let u, v, w: Vector
    let timeRange: Range<Double>
    let lensRadius: Double

    func ray(atPlaneX x: Double, planeY y: Double) -> Ray {
        let rd = lensRadius*Vector.randomInUnitDisk()
        let offset = u * rd.x + v * rd.y
        let time = timeRange.lowerBound + drand48()*(timeRange.upperBound - timeRange.lowerBound)
        return Ray(origin: origin + offset,
                   direction: lowerLeftCorner + x * horizontal + y * vertical - origin - offset,
                   time: time)
    }
}

struct ScatterResult {
    let scattered: Ray
    let attenuation: Vector
}

protocol Material {
    func scatter(ray: Ray, hitRecord: Hit) -> ScatterResult?
}

struct Lambertian: Material {
    let albedo: Vector
    func scatter(ray: Ray, hitRecord rec: Hit) -> ScatterResult? {
        let target = rec.p + rec.normal + Vector.randomInUnitSphere()
        return ScatterResult(scattered: Ray(origin: rec.p, direction: target - rec.p, time: ray.time),
                             attenuation: albedo)
    }
}

struct Metal: Material {
    let albedo: Vector
    let fuzz: Double
    init(albedo: Vector, fuzz: Double) {
        self.albedo = albedo
        self.fuzz = min(fuzz, 1)
    }
    func scatter(ray: Ray, hitRecord rec: Hit) -> ScatterResult? {
        let reflected = ray.direction.unit.reflect(acrossNormal: rec.normal)
        let scattered = Ray(origin: rec.p, direction: reflected + fuzz*Vector.randomInUnitSphere(), time: ray.time)
        guard scattered.direction ⋅ rec.normal > 0 else { return nil }
        return ScatterResult(scattered: scattered, attenuation: albedo)
    }
}

struct Dielectric: Material {
    let refractionIndex: Double
    func scatter(ray: Ray, hitRecord rec: Hit) -> ScatterResult? {
        let outwardNormal: Vector
        let reflected = ray.direction.reflect(acrossNormal: rec.normal)
        let ni_over_nt: Double
        let attenuation = Vector(1,1,1)
        let cosine: Double
        if ray.direction ⋅ rec.normal > 0 {
            outwardNormal = -rec.normal
            ni_over_nt = refractionIndex
            cosine = refractionIndex * ray.direction ⋅ rec.normal / ray.direction.length
        } else {
            outwardNormal = rec.normal
            ni_over_nt = 1.0 / refractionIndex
            cosine = -ray.direction ⋅ rec.normal / ray.direction.length
        }

        let reflectProb: Double
        let refracted = ray.direction.refract(acrossNormal: outwardNormal, withRefractiveIndex: ni_over_nt)
        if refracted != nil {
            reflectProb = schlick(cosine: cosine, ri: refractionIndex)
        } else {
            reflectProb = 1.0
        }

        if drand48() < reflectProb {
            return ScatterResult(scattered: Ray(origin: rec.p, direction: reflected, time: ray.time), attenuation: attenuation)
        } else {
            return ScatterResult(scattered: Ray(origin: rec.p, direction: refracted!, time: ray.time), attenuation: attenuation)
        }
        //        if let refracted = ray.direction.refract(acrossNormal: outwardNormal, withRefractiveIndex: ni_over_nt),
        //            drand48() >= schlick(cosine: cosine, ri: refractionIndex) {
        //            return ScatterResult(scattered: Ray(origin: rec.p, direction: refracted), attenuation: attenuation)
        //        } else {
        //            return ScatterResult(scattered: Ray(origin: rec.p, direction: reflected), attenuation: attenuation)
        //        }
    }
}

struct AABB {
    let minCorner: Vector
    let maxCorner: Vector

    func isHit(by ray: Ray, inRange times: Range<Double>) -> Bool {
        func testDimension(minCorner: Double, maxCorner: Double, origin: Double, direction: Double) -> Bool {

            let t0 = min((minCorner - origin) / direction,
                         (maxCorner - origin) / direction)
            let t1 = max((minCorner - origin) / direction,
                         (maxCorner - origin) / direction)
            let tmin = max(t0, times.lowerBound)
            let tmax = min(t1, times.upperBound)
            return tmax > tmin
        }

        return testDimension(minCorner: minCorner.x, maxCorner: maxCorner.x, origin: ray.origin.x, direction: ray.direction.x) &&
            testDimension(minCorner: minCorner.y, maxCorner: maxCorner.y, origin: ray.origin.y, direction: ray.direction.y) &&
            testDimension(minCorner: minCorner.z, maxCorner: maxCorner.z, origin: ray.origin.z, direction: ray.direction.z)
    }

    static func +(lhs: AABB, rhs: AABB) -> AABB {
        let small = Vector(min(lhs.minCorner.x, rhs.minCorner.x),
                           min(lhs.minCorner.y, rhs.minCorner.y),
                           min(lhs.minCorner.z, rhs.minCorner.z))
        let big = Vector(max(lhs.maxCorner.x, rhs.maxCorner.x),
                         max(lhs.maxCorner.y, rhs.maxCorner.y),
                         max(lhs.maxCorner.z, rhs.maxCorner.z))
        return AABB(minCorner: small, maxCorner: big)
    }

    var volume: Double {
        return abs((maxCorner.x - minCorner.y) * (maxCorner.y - minCorner.y) * (maxCorner.z - minCorner.z))
    }
}

func randomScene() -> Hittable {
    var list: [Hittable] = [Sphere(center: Vector(0,-1000,0), radius: 1000, material: Lambertian(albedo: Vector(0.5,0.5,0.5)))]

    for a in -11..<11 {
        for b in -11..<11 {
            let chooseMat = drand48()
            let center = Vector(Double(a)+0.9*drand48(),0.2,Double(b)+0.9*drand48());
            if (center-Vector(4,0.2,0)).length > 0.9 {
                if (chooseMat < 0.8) { // diffuse
                    list.append(MovingSphere(startCenter: center, endCenter: center+Vector(0,0.5*drand48(), 0), startTime: 0, endTime: 1, radius: 0.2, material: Lambertian(albedo: Vector(drand48()*drand48(), drand48()*drand48(), drand48()*drand48()))))
                } else if chooseMat < 0.95 { // metal
                    list.append(Sphere(center: center, radius: 0.2, material: Metal(albedo: Vector(0.5*(1 + drand48()), 0.5*(1 + drand48()), 0.5*(1 + drand48())), fuzz: 0.5*drand48())))
                } else { // glass
                    list.append(Sphere(center: center, radius: 0.2, material: Dielectric(refractionIndex: 1.5)))
                }
            }
        }
    }

    list.append(Sphere(center: Vector(0,1,0), radius: 1.0, material: Dielectric(refractionIndex: 1.5)))
    list.append(Sphere(center: Vector(-4,1,0), radius: 1.0, material: Lambertian(albedo: Vector(0.4,0.2,0.1))))
    list.append(Sphere(center: Vector(4,1,0), radius: 1.0, material: Metal(albedo: Vector(0.7, 0.6, 0.5), fuzz: 0.0)))
    return BVH(list, timeRange: 0..<1)
}

srand48(0)

let nx = 200
let ny = 100
let ns = 100

print("P3\n\(nx) \(ny)\n255")

let world = randomScene()

let lookFrom = Vector(13,2,3)
let lookAt = Vector(0,0,0)
let distToFocus = 10.0
let aperture = 0.0
let camera = Camera(lookFrom: lookFrom, lookAt: lookAt, vup: Vector(0,1,0), vfov: 20, aspect: Double(nx)/Double(ny), aperture: aperture, focusDist: distToFocus, overTimes: 0..<1)

for j in (0..<ny).reversed() {
    for i in 0..<nx {
        var col = Vector.zero
        for _ in 0..<ns {
            let u = (Double(i) + drand48()) / Double(nx)
            let v = (Double(j) + drand48()) / Double(ny)
            let r = camera.ray(atPlaneX: u, planeY: v)
            col += r.color(in: world)
        }
        col = Vector(sqrt(col.x / Double(ns)), sqrt(col.y / Double(ns)), sqrt(col.z / Double(ns)))
        
        let ir = Int(255.99 * col.r)
        let ig = Int(255.99 * col.g)
        let ib = Int(255.99 * col.b)
        print("\(ir) \(ig) \(ib)")
    }
}

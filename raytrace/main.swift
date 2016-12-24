//
//  main.swift
//  raytrace
//
//  Created by Rob Napier on 12/23/16.
//
//

import Darwin

infix operator ⋅ : MultiplicationPrecedence

protocol VectorConvertible {
    init(vector: Vector)
    var vector: Vector { get }
}

extension VectorConvertible {
    static var zero: Self { return Self(vector: Vector(0, 0, 0)) }
    static func *(scalar: Float, rhs: Self) -> Self {
        return Self(vector: Vector(scalar * rhs.vector.a, scalar * rhs.vector.b, scalar * rhs.vector.c))
    }

    static func /(lhs: Self, scalar: Float) -> Self {
        return Self(vector: Vector(lhs.vector.a / scalar, lhs.vector.b / scalar, lhs.vector.c / scalar))
    }

    func lerp(to: Self, at t: Float) -> Self {
        return Self(vector: (1.0 - t) * self.vector + t * to.vector)
    }
}

struct Vector: VectorConvertible {
    let a, b, c: Float
    init(_ a: Float, _ b: Float, _ c: Float) {
        self.a = a
        self.b = b
        self.c = c
    }
    init(vector: Vector) {
        self = vector
    }
    var vector: Vector { return self }

    var length: Float {
        return sqrt(a*a + b*b + c*c)
    }
    var unit: Vector {
        return self / length
    }
    static func +(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.a + rhs.a, lhs.b + rhs.b, lhs.c + rhs.c)
    }
    static func -(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.a - rhs.a, lhs.b - rhs.b, lhs.c - rhs.c)
    }
    static func ⋅(lhs: Vector, rhs: Vector) -> Float {
        return lhs.a * rhs.a + lhs.b * rhs.b + lhs.c * rhs.c
    }
}

struct Point: VectorConvertible {
    let vector: Vector
    init(vector: Vector) {
        self.vector = vector
    }
    init(x: Float, y: Float, z: Float) {
        self.vector = Vector(x, y, z)
    }
    var x: Float { return vector.a }
    var y: Float { return vector.b }
    var z: Float { return vector.c }
    static func -(lhs: Point, rhs: Point) -> Vector {
        return lhs.vector - rhs.vector
    }
    static func +(lhs: Point, rhs: Vector) -> Point {
        return Point(vector: lhs.vector + rhs.vector)
    }
}

struct Ray {
    let origin: Point
    let direction: Vector
    init(origin: Point, through: Point) {
        self.origin = origin
        self.direction = through - origin
    }
    func point(atParameter t: Float) -> Point {
        return origin + t * direction
    }

    func intersectsSphere(at center: Point, radius: Float) -> Bool {
        let oc = origin - center
        let a = direction ⋅ direction
        let b = 2.0 * oc ⋅ direction
        let c = oc ⋅ oc - radius * radius
        let discriminant = b * b - 4 * a * c
        return discriminant > 0
    }

}

struct Color: VectorConvertible {
    let vector: Vector
    init(vector: Vector) {
        self.vector = vector
    }
    init(r: Float, g: Float, b: Float) {
        vector = Vector(r, g, b)
    }
    var r: Float { return vector.a }
    var g: Float { return vector.b }
    var b: Float { return vector.c }
}

extension Color {
    init(ray: Ray) {
        if ray.intersectsSphere(at: Point(x: 0, y: 0, z: -1), radius: 0.5) {
            self = Color(r: 1, g: 0, b: 0)
        } else {
            let unitDirection = ray.direction.unit
            let t = 0.5 * unitDirection.b + 1
            self = Color(r: 1, g: 1, b: 1).lerp(to: Color(r: 0.5, g: 0.7, b: 1), at: t)
        }
    }
}


let nx = 200
let ny = 100
print("P3\n\(nx) \(ny)\n255")

let lowerLeftCorner = Point(x: -2, y: -1, z: -1)
let horizontal = Vector(4, 0, 0)
let vertical = Vector(0, 2, 0)
let origin = Point.zero

for j in (0..<ny).reversed() {
    for i in 0..<nx {

        let u = Float(i) / Float(nx)
        let v = Float(j) / Float(ny)

        let r = Ray(origin: origin, through: lowerLeftCorner + u * horizontal + v * vertical)
        let col = Color(ray: r)

        let ir = Int(255.99 * col.r)
        let ig = Int(255.99 * col.g)
        let ib = Int(255.99 * col.b)
        print("\(ir) \(ig) \(ib)")
    }
}

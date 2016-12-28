import Darwin

struct vec3 {
    init() { e = [0,0,0] }
    init(_ e0: Double, _ e1: Double, _ e2: Double) { e = [e0, e1, e2] }
    var x: Double { return e[0] }
    var y: Double { return e[1] }
    var z: Double { return e[2] }
    var r: Double { return e[0] }
    var g: Double { return e[1] }
    var b: Double { return e[2] }

    static prefix func -(v: vec3) -> vec3 { return vec3(-v.e[0], -v.e[1], -v.e[2]) }

    subscript(i: Int) -> Double { return e[i] }

    static func +=(lhs: inout vec3, v: vec3) {
        lhs.e[0] += v.e[0];
        lhs.e[1] += v.e[1];
        lhs.e[2] += v.e[2];
    }

    static func /=(lhs: inout vec3, t: Double) {
        lhs.e[0] /= t;
        lhs.e[1] /= t;
        lhs.e[2] /= t;
    }

    var length: Double {
        return sqrt(e[0]*e[0] + e[1]*e[1] + e[2]*e[2])
    }

    var squared_length: Double {
        return e[0]*e[0] + e[1]*e[1] + e[2]*e[2];
    }

    var e: Array<Double>

    static func +(v1: vec3, v2: vec3) -> vec3 {
        return vec3(v1.e[0] + v2.e[0], v1.e[1] + v2.e[1], v1.e[2] + v2.e[2])
    }

    static func -(_ v1: vec3, _ v2: vec3) -> vec3 {
        return vec3(v1.e[0] - v2.e[0], v1.e[1] - v2.e[1], v1.e[2] - v2.e[2])
    }

    static func *(_ v1: vec3, _ v2: vec3) -> vec3 {
        return vec3(v1.e[0] * v2.e[0], v1.e[1] * v2.e[1], v1.e[2] * v2.e[2])
    }

    static func *(_ t: Double, v: vec3) -> vec3 {
        return vec3(t*v.e[0], t*v.e[1], t*v.e[2])
    }

    static func *(v: vec3, t: Double) -> vec3 {
        return vec3(t*v.e[0], t*v.e[1], t*v.e[2]);
    }

    static func /(v: vec3, t: Double) -> vec3 {
        return vec3(v.e[0]/t, v.e[1]/t, v.e[2]/t);
    }
}

func dot(_ v1: vec3, _ v2: vec3) -> Double {
    return v1.e[0] * v2.e[0] + v1.e[1] * v2.e[1] + v1.e[2] * v2.e[2]
}

func cross(_ v1: vec3, _ v2: vec3) -> vec3{
    return vec3(  (v1.e[1]*v2.e[2] - v1.e[2]*v2.e[1]),
                  (-(v1.e[0]*v2.e[2] - v1.e[2]*v2.e[0])),
                  (v1.e[0]*v2.e[1] - v1.e[1]*v2.e[0]))
}

func unit_vector(_ v: vec3) -> vec3 {
    return v / v.length
}

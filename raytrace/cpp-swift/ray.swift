struct ray {
    init() { A = vec3(); B = vec3() }
    init(_ a: vec3, _ b: vec3) { A = a; B = b; }
    var origin: vec3 { return A }
    var direction: vec3 { return B }
    func point_at_parameter(_ t: Double) -> vec3 { return A + t*B }

    let A: vec3
    let B: vec3
}

struct hit_record {
    var t: Double;
    var p: vec3;
    var normal: vec3;
    var mat_ptr: material;
    init() { t = 0; p = vec3(0,0,0); normal = vec3(0,0,0); mat_ptr = lambertian(vec3(0,0,0)) }
};

class hitable {
    func hit(_ r: ray, _ t_min: Double, _ t_max: Double, _ rec: inout hit_record) -> Bool { return false }
};

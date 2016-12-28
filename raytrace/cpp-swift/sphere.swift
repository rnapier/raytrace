import Darwin

class sphere: hitable {
    init(_ cen: vec3, _ r: Double, _ m: material) { center = cen; radius = r; mat_ptr = m }
    override func hit(_ r: ray, _ t_min: Double, _ t_max: Double, _ rec: inout hit_record) -> Bool {
        let oc = r.origin - center;

        let a = dot(r.direction, r.direction);
        let b = dot(oc, r.direction);
        let c = dot(oc, oc) - radius*radius;
        let discriminant = b*b - a*c;
        if (discriminant > 0) {
            var temp = (-b - sqrt(b*b-a*c))/a;
            if (temp < t_max && temp > t_min) {
                rec.t = temp;
                rec.p = r.point_at_parameter(rec.t);
                rec.normal = (rec.p - center) / radius;
                rec.mat_ptr = mat_ptr;
                return true;
            }
            temp = (-b + sqrt(b*b-a*c))/a;
            if (temp < t_max && temp > t_min) {
                rec.t = temp;
                rec.p = r.point_at_parameter(rec.t);
                rec.normal = (rec.p - center) / radius;
                rec.mat_ptr = mat_ptr;
                return true;
            }
        }
        return false;
    }
    let center: vec3;
    let radius: Double;
    let mat_ptr: material;
};

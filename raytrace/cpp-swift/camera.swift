import Darwin

func random_in_unit_disk() -> vec3 {
    var p: vec3
    repeat {
        p = 2.0*vec3(drand48(), drand48(), 0) - vec3(1,1,0);
    } while (dot(p,p) >= 1.0);
    return p;
}

class camera {
    init(_ lookfrom: vec3, _ lookat: vec3, _ vup: vec3, _ vfov: Double, _ aspect: Double, _ aperature: Double, _ focus_dist: Double) { // vfov is the top to bottom in degrees
        lens_radius = aperature / 2;
        let theta = vfov*M_PI/180;
        let half_height = tan(theta/2);
        let half_width = aspect * half_height;
        origin = lookfrom;
        w = unit_vector(lookfrom - lookat);
        u = unit_vector(cross(vup, w));
        v = cross(w, u);
        lower_left_corner = origin - half_width*focus_dist*u - half_height*focus_dist*v - focus_dist*w;
        horizontal = 2*half_width*focus_dist*u;
        vertical = 2*half_height*focus_dist*v;
    }
    func get_ray(_ s: Double, _ t: Double) -> ray {
        let rd = lens_radius*random_in_unit_disk();
        let offset = u * rd.x + v * rd.y;
        return ray(origin + offset, lower_left_corner + s*horizontal + t*vertical - origin - offset);
    }

    let origin: vec3;
    let lower_left_corner: vec3
    let horizontal: vec3
    let vertical: vec3;
    let u, v, w: vec3;
    let lens_radius: Double;
};

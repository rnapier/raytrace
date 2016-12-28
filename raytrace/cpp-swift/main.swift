import Darwin

func color(_ r: ray, _ world: hitable, _ depth: Int) -> vec3 {
    var rec = hit_record()
    if (world.hit(r, 0.001, Double(MAXFLOAT), &rec)) {
        var scattered = ray()
        var attenuation = vec3()
        if (depth < 50 && rec.mat_ptr.scatter(r, rec, &attenuation, &scattered)) {
            return attenuation*color(scattered, world, depth+1);
        }
        else {
            return vec3(0,0,0);
        }
    }
    else {
        let unit_direction = unit_vector(r.direction);
        let t = 0.5*(unit_direction.y + 1.0);
        return (1.0-t)*vec3(1.0, 1.0, 1.0) + t*vec3(0.5, 0.7, 1.0);
    }
}

func random_scene() -> hitable {
    var list: [hitable] = []
    list.append(sphere(vec3(0,-1000,0), 1000, lambertian(vec3(0.5, 0.5, 0.5))))
//    for a in -11..<11 {
//        for b in -11..<11 {
//            let choose_mat = drand48();
//            let center = vec3(Double(a)+0.9*drand48(),0.2,Double(b)+0.9*drand48());
//            if ((center-vec3(4,0.2,0)).length > 0.9) {
//                if (choose_mat < 0.8) { // diffuse
//                    list.append(sphere(center, 0.2, lambertian(vec3(drand48()*drand48(), drand48()*drand48(), drand48()*drand48()))))
//                }
//                else if (choose_mat < 0.95) { // metal
//                    list.append(sphere(center, 0.2,
//                                       metal(vec3(0.5*(1 + drand48()), 0.5*(1 + drand48()), 0.5*(1 + drand48())), 0.5*drand48())))
//                }
//                else { // glass
//                    list.append(sphere(center, 0.2, dielectric(1.5)))
//                }
//            }
//        }
//    }

    list.append(sphere(vec3(0, 1, 0), 1.0, dielectric(1.5)))
    list.append(sphere(vec3(-4, 1, 0), 1.0, lambertian(vec3(0.4, 0.2, 0.1))))
    list.append(sphere(vec3(4, 1, 0), 1.0, metal(vec3(0.7,0.6,0.5), 0.0)))

    return hitable_list(list);
}

srand48(0);
let nx = 200;
let ny = 100;
// int nx = 1600;
// int ny = 800;
let ns = 100;
print("P3\n\(nx) \(ny)\n255")
let world = random_scene();

let lookfrom = vec3(16,2,4);
let lookat = vec3(0,0.5,0);
let focalPoint = vec3(4,1,0);
let dist_to_focus = (lookfrom-focalPoint).length;
let aperature = 1.0/16.0;
let cam = camera(lookfrom, lookat, vec3(0,1,0), 15, Double(nx)/Double(ny), aperature, dist_to_focus);

for j in (0..<ny).reversed() {
    for i in 0..<nx {
        var col = vec3(0,0,0);
        for _ in 0..<ns {
            let u = (Double(i) + drand48()) / Double(nx);
            let v = (Double(j) + drand48()) / Double(ny);
            let r = cam.get_ray(u, v);
            col += color(r, world, 0);
        }
        col /= Double(ns);
        col = vec3(sqrt(col[0]), sqrt(col[1]), sqrt(col[2]));
        let ir = Int(255.99*col[0]);
        let ig = Int(255.99*col[1]);
        let ib = Int(255.99*col[2]);

        print("\(ir) \(ig) \(ib)")
    }
}

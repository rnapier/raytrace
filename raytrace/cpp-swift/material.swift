import Darwin

func reflect(_ v: vec3, _ n: vec3) -> vec3 {
    return v - 2*dot(v,n)*n
}

func refract(_ v: vec3, _ n: vec3, _ ni_over_nt: Double, _ refracted: inout vec3) -> Bool {
    let uv = unit_vector(v)
    let dt = dot(uv, n)
    let discriminant = 1.0 - ni_over_nt*ni_over_nt*(1-dt*dt)
    if (discriminant > 0) {
        refracted = ni_over_nt*(uv - n*dt) - n*sqrt(discriminant)
        return true
    }
    else {
        return false
    }
}

func schlick(_ cosine: Double, _ ref_idx: Double) -> Double {
    var r0 = (1-ref_idx) / (1+ref_idx)
    r0 = r0*r0
    return r0 + (1-r0)*pow((1 - cosine), 5)
}

func random_in_unit_sphere() -> vec3 {
    var p: vec3
    repeat {
        p = 2.0*vec3(drand48(),drand48(),drand48()) - vec3(1,1,1)
    } while (p.squared_length >= 1.0)
    return p
}

class material {
    func scatter(_ r_in: ray, _ rec: hit_record, _ attenuation: inout vec3, _ scattered: inout ray) -> Bool {
        return false
    }
}

class lambertian : material {
    init(_ a: vec3) { albedo = a }
    override func scatter(_ r_in: ray, _ rec: hit_record, _ attenuation: inout vec3, _ scattered: inout ray) -> Bool {
        let target = rec.p + rec.normal + random_in_unit_sphere()
        scattered = ray(rec.p, target-rec.p)
        attenuation = albedo
        return true
    }

    let albedo: vec3
}

class metal : material {
    init(_ a: vec3, _ f: Double) { albedo = a; if (f < 1) {fuzz = f } else { fuzz = 1 } }
    override func scatter(_ r_in: ray, _ rec: hit_record, _ attenuation: inout vec3, _ scattered: inout ray) -> Bool {
        let reflected = reflect(unit_vector(r_in.direction), rec.normal)
        scattered = ray(rec.p, reflected + fuzz*random_in_unit_sphere())
        attenuation = albedo
        return (dot(scattered.direction, rec.normal) > 0)
    }
    let albedo: vec3
    let fuzz: Double
}

class dielectric : material {
    init(_ ri: Double) { ref_idx = ri }
    override func scatter(_ r_in: ray, _ rec: hit_record, _ attenuation: inout vec3, _ scattered: inout ray) -> Bool {
        let outward_normal: vec3
        let reflected = reflect(r_in.direction, rec.normal)
        let ni_over_nt: Double
        attenuation = vec3(1.0, 1.0, 1.0)
        var refracted = vec3()
        let cosine: Double
        let reflect_prob: Double
        if (dot(r_in.direction, rec.normal) > 0) {
            outward_normal = -rec.normal;
            ni_over_nt = ref_idx;
            cosine = ref_idx * dot(r_in.direction, rec.normal) / r_in.direction.length;
        }
        else {
            outward_normal = rec.normal;
            ni_over_nt = 1.0 / ref_idx;
            cosine = -dot(r_in.direction, rec.normal) / r_in.direction.length;
        }
        if (refract(r_in.direction, outward_normal, ni_over_nt, &refracted)) {
            reflect_prob = schlick(cosine, ref_idx);
        }
        else {
            reflect_prob = 1.0;
        }
        if (drand48() < reflect_prob) {
            scattered = ray(rec.p, reflected);
        } else {
            scattered = ray(rec.p, refracted);
        }
        return true;
    }
    let ref_idx: Double
}

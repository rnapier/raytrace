class hitable_list: hitable {
    init(_ l: [hitable]) { list = l }
    override func hit(_ r: ray, _ t_min: Double, _ t_max: Double, _ rec: inout hit_record) -> Bool {
        var temp_rec = hit_record()
        var hit_anything = false;
        var closest_so_far = t_max;
        for element in list {
            if (element.hit(r, t_min, closest_so_far, &temp_rec)) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec = temp_rec;
            }
        }
        return hit_anything;
    }
    let list: [hitable];
};

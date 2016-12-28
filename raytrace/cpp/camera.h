#ifndef CAMERAH
#define CAMERAH

#include "ray.h"

class camera {
public:
    camera(vec3 lookfrom, vec3 lookat, vec3 vup, double vfov, double aspect) { // vfov is the top to bottom in degrees
        vec3 u, v, w;
        double theta = vfov*M_PI/180;
        double half_height = tan(theta/2);
        double half_width = aspect * half_height;
        origin = lookfrom;
        w = unit_vector(lookfrom - lookat);
        u = unit_vector(cross(vup, w));
        v = cross(w, u);
        lower_left_corner = origin - half_width*u - half_height*v - w;
        horizontal = 2*half_width*u;
        vertical = 2*half_height*v;
    }
    ray get_ray(double s, double t) { return ray(origin, lower_left_corner + s*horizontal + t*vertical - origin); }

    vec3 origin;
    vec3 lower_left_corner;
    vec3 horizontal;
    vec3 vertical;
};

#endif

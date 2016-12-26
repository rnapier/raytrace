#ifndef RAYH
#define RAYH
#include "vec3.h"
#include <iomanip>

class ray
{
public:
    ray() {}
    ray(const vec3& a, const vec3& b) { A = a; B = b; }
    vec3 origin() const { return A; }
    vec3 direction() const { return B; }
    vec3 point_at_parameter(double t) const { return A + t*B; }

    vec3 A;
    vec3 B;

    friend std::ostream& operator<<(std::ostream& os, const ray& r);
};

std::ostream& operator<<(std::ostream& os, const ray& r) {
    os << std::setprecision( 9 ) << "[" << r.A << " -> " << r.B << "]";
    return os;
}

#endif


#include <metal_stdlib>
using namespace metal;

struct Ray {
    float3 origin;
    float3 direction;
};

struct Hit {
    float l;
    float3 point;
    float3 normal;
    float3 color;
    int material;
    float ior;
    bool hit;
};

struct Triangle {
    float3 p0;
    float3 p1;
    float3 p2;
    float3 color;
    int material;
    float3 normal;
    float ior;
};

struct Sphere {
    float3 center;
    float radius;
    float3 color;
    int material; // 0: metal, 1: glass, 2: matte
    float ior;
    float3 padding;
};

struct Plane {
    float3 origin;
    float padding1;
    float3 normal;
    float padding2;
    float3 color;
    int material;
    float ior;
    float3 padding3;
};

struct Light {
    float3 origin;
    float intensity;
    float radius;
    float3 padding;
};

// --- Random Number Generator ---
float random(thread uint2& state) {
    state.x = 36969 * (state.x & 65535) + (state.x >> 16);
    state.y = 18000 * (state.y & 65535) + (state.y >> 16);
    uint word = ((state.x << 16) + state.y);
    return float(word) / 4294967296.0;
}

float3 randomInUnitSphere(thread uint2& state) {
    float3 p;
    do {
        p = float3(random(state) * 2.0 - 1.0,
                   random(state) * 2.0 - 1.0,
                   random(state) * 2.0 - 1.0);
    } while (length_squared(p) >= 1.0);
    return p;
}

// --- Intersection Functions ---

Hit hitTriangle(Ray ray, constant Triangle& triangle) {
    Hit hit;
    hit.hit = false;

    float epsilon = 1e-6;
    float3 p0 = triangle.p0;
    float3 p1 = triangle.p1;
    float3 p2 = triangle.p2;
    float3 normal = triangle.normal;

    float3 edge1 = p1 - p0;
    float3 edge2 = p2 - p0;
    float3 h = cross(ray.direction, edge2);
    float a = dot(edge1, h);
    if (fabs(a) < epsilon) return hit;
    
    // Backface culling: if determinant is negative (or dot(normal, ray) > 0), we are hitting the back
    // For closed objects, this prevents seeing the inside (fixing light leaks)
    if (triangle.material != 1) { // Don't cull glass
         if (dot(triangle.normal, ray.direction) > 0) return hit;
    }

    float f = 1.0 / a;
    float3 s = ray.origin - p0;
    float u = f * dot(s, h);
    // Relaxed bounds to prevent cracks
    if (u < -1e-5 || u > 1.0 + 1e-5) return hit;

    float3 q = cross(s, edge1);
    float v = f * dot(ray.direction, q);
    if (v < -1e-5 || u + v > 1.0 + 1e-5) return hit;

    float t = f * dot(edge2, q);
    if (t < epsilon) return hit; // no intersection behind ray origin

    hit.l = t;
    hit.point = ray.origin + t * ray.direction;
    hit.normal = normal;
    hit.color = triangle.color;
    hit.material = triangle.material;
    hit.ior = triangle.ior;
    hit.hit = true;
    return hit;
}

Hit hitSphere(Ray ray, constant Sphere& sphere) {
    Hit hit;
    hit.hit = false;
    
    float3 oc = sphere.center - ray.origin;
    float r2 = sphere.radius * sphere.radius;
    float a = dot(ray.direction, ray.direction);
    float b = -2.0 * dot(ray.direction, oc);
    float c = dot(oc, oc) - r2;
    float delta = b * b - 4 * a * c;
    
    if (delta < 0) return hit;
    
    float sqrtD = sqrt(delta);
    float t = (-b - sqrtD) / (2.0 * a);
    if (t < 0) {
        t = (-b + sqrtD) / (2.0 * a);
        if (t < 0) return hit;
    }
    
    hit.l = t;
    hit.point = ray.origin + t * ray.direction;
    hit.normal = normalize(hit.point - sphere.center);
    hit.color = sphere.color;
    hit.material = sphere.material;
    hit.ior = sphere.ior;
    hit.hit = true;
    return hit;
}

Hit hitPlane(Ray ray, constant Plane& plane) {
    Hit hit;
    hit.hit = false;
    
    float d = dot(plane.normal, ray.direction);
    if (d >= 0) return hit;
    
    float t = dot(plane.origin - ray.origin, plane.normal) / d;
    if (t < 0) return hit;
    
    hit.l = t;
    hit.point = ray.origin + t * ray.direction;
    hit.normal = plane.normal;
    hit.color = plane.color;
    hit.material = plane.material;
    hit.ior = plane.ior;
    hit.hit = true;
    return hit;
}

// --- Shadow Function ---
bool inShadow(Ray ray, float maxDistance, constant Sphere* spheres, int sphereCount, constant Plane* planes, int planeCount, constant Triangle* triangles, int triangleCount) {
    for (int i = 0; i < sphereCount; i++) {
        if (spheres[i].material == 1) continue; // Glass doesn't cast shadow
        Hit h = hitSphere(ray, spheres[i]);
        if (h.hit && h.l < maxDistance) return true;
    }
    for (int i = 0; i < planeCount; i++) {
        if (planes[i].material == 1) continue;
        Hit h = hitPlane(ray, planes[i]);
        if (h.hit && h.l < maxDistance) return true;
    }
    for (int i = 0; i < triangleCount; i++) {
        if (triangles[i].material == 1) continue; // Glass doesn't cast shadow
        Hit h = hitTriangle(ray, triangles[i]);
        if (h.hit && h.l < maxDistance) return true;
    }
    return false;
}

// --- Lighting Calculation ---
float3 calculateDiffuse(Hit hit, constant Sphere* spheres, int sphereCount, constant Plane* planes, int planeCount, constant Triangle* triangles, int triangleCount, constant Light* lights, int lightCount, thread uint2& rngState) {
    // Assuming only 1 light as per CPU code assumption, but loop works too
    if (lightCount == 0) return float3(0);
    
    constant Light& light = lights[0]; // Using first light mainly
    
    float3 lightDir = light.origin - hit.point;
    float distance = length(lightDir);
    float3 direction = normalize(lightDir);
    
    float diffuse = max(0.0, dot(hit.normal, direction));
    float falloff = light.intensity / (distance * distance + 20000);
    float lightContribution = diffuse * falloff;
    
    float shadowIntensity = 0.0;
    int samples = 64;
    
    if (light.radius > 0) {
        for (int i = 0; i < samples; i++) {
            float3 randomOffset = randomInUnitSphere(rngState) * light.radius;
            float3 samplePoint = light.origin + randomOffset;
            float3 sampleDir = samplePoint - hit.point;
            float sampleDist = length(sampleDir);
            
            Ray shadowRay;
            shadowRay.direction = normalize(sampleDir);
            shadowRay.origin = hit.point + hit.normal * 0.001;
            
            if (inShadow(shadowRay, sampleDist, spheres, sphereCount, planes, planeCount, triangles, triangleCount)) {
                shadowIntensity += 1.0;
            }
        }
        shadowIntensity /= float(samples);
    } else {
        Ray shadowRay;
        shadowRay.direction = normalize(lightDir);
        shadowRay.origin = hit.point + hit.normal * 0.001;
        
        if (inShadow(shadowRay, distance, spheres, sphereCount, planes, planeCount, triangles, triangleCount)) {
            shadowIntensity = 1.0;
        }
    }
    
    float ambient = 0.1;
    float totalIntensity = ambient + lightContribution * (1.0 - shadowIntensity);
    float finalIntensity = min(totalIntensity, 1.0);
    
    return hit.color * finalIntensity;
}

// --- Main Kernel ---
kernel void traceKernel(texture2d<float, access::write> output [[texture(0)]],
                        constant Sphere* spheres [[buffer(0)]],
                        constant uint& sphereCount [[buffer(1)]],
                        constant Plane* planes [[buffer(2)]],
                        constant uint& planeCount [[buffer(3)]],
                        constant Light* lights [[buffer(4)]],
                        constant uint& lightCount [[buffer(5)]],
                        constant Triangle* triangles [[buffer(6)]],
                        constant uint& triangleCount [[buffer(7)]],
                        uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) return;
    
    float size = float(output.get_width()); // Assuming square texture as per CPU code
    float u = 2.0 * float(gid.x) / size - 1.0;
    float v = 1.0 - 2.0 * float(gid.y) / size; // Flip Y to match CPU
    
    Ray ray;
    ray.origin = float3(0, 0, 0);
    ray.direction = normalize(float3(u, v, 1));
    
    float3 finalColor = float3(0);
    float3 throughput = float3(1.0);
    
    // RNG State initialization
    uint2 rngState = gid + uint2(size * 991, size * 13); 
    
    int maxDepth = 10;
    
    for (int depth = 0; depth < maxDepth; depth++) {
        Hit closest;
        closest.hit = false;
        closest.l = 1e9; // Infinity
        
        // Find closest intersection
        for (uint i = 0; i < sphereCount; i++) {
            Hit h = hitSphere(ray, spheres[i]);
            if (h.hit && h.l < closest.l) {
                closest = h;
            }
        }
        for (uint i = 0; i < planeCount; i++) {
            Hit h = hitPlane(ray, planes[i]);
            if (h.hit && h.l < closest.l) {
                closest = h;
            }
        }
        for (uint i = 0; i < triangleCount; i++) {
            Hit h = hitTriangle(ray, triangles[i]);
            if (h.hit && h.l < closest.l) {
                closest = h;
            }
        }
        
        if (!closest.hit) {
            // Background color or terminate
            // CPU code returns red (255,0,0) if no hit? 
            // Scene_One returns Red. Scene_Four returns (0,0,0) if max depth reached or no hit?
            // Scene_Four trace returns (0,0,0,255) (Black opaque) if no hit.
            // So we just break and leave what we have.
            break; 
        }
        
        // Handle Materials
        if (closest.material == 2) { // Matte
            float3 diffuse = calculateDiffuse(closest, spheres, sphereCount, planes, planeCount, triangles, triangleCount, lights, lightCount, rngState);
            finalColor += throughput * diffuse;
            break; // Terminate path
        } else if (closest.material == 0) { // Metal
            // Reflect
            // Blend: base (0.8 weight reflected?)
            // CPU: blendColors(base, color, weight: 0.8) -> (1-0.8)*base + 0.8*reflected
            // Base is hit.color (lighted? No, simply hit.color * 255 in CPU code)
            // Wait, Scene_Four:61: base = hit.color
            // So it adds 0.2 * base to accumulator, then continues with 0.8 weight.
            
            finalColor += throughput * (0.2 * closest.color);
            throughput *= 0.8;
            
            float3 rDir = ray.direction - 2.0 * dot(ray.direction, closest.normal) * closest.normal;
            ray.origin = closest.point + closest.normal * 0.001;
            ray.direction = normalize(rDir);
        } else if (closest.material == 1) { // Glass
            // Refract
            bool d = dot(ray.direction, closest.normal) < 0;
            float n1 = d ? 1.0 : closest.ior;
            float n2 = d ? closest.ior : 1.0;
            float3 normal = d ? closest.normal : -closest.normal;
            
            float3 I = normalize(ray.direction);
            float cos_theta = -dot(normal, I);
            float eta = n1 / n2;
            float k = 1.0 - eta * eta * (1.0 - cos_theta * cos_theta);
            
            if (k < 0) {
                // Total internal reflection
                float3 rDir = ray.direction - 2.0 * dot(ray.direction, normal) * normal;
                ray.origin = closest.point + normal * 0.001;
                ray.direction = normalize(rDir);
            } else {
                float3 dir = eta * I + (eta * cos_theta - sqrt(k)) * normal;
                ray.origin = closest.point + normalize(dir) * 0.001;
                ray.direction = normalize(dir);
            }
            // No color addition from glass itself, just throughput
        }
    }
    
    output.write(float4(finalColor, 1.0), gid);
}


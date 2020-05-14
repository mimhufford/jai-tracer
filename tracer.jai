#import "Basic";
#import "File";
#import "Math";

Ray :: struct {
    origin    : Vector3;
    direction : Vector3;
}

Sphere :: struct {
    position : Vector3;
    radius   : float = 1;
    diffuse  : Vector3;
    emmision : Vector3;
}

intersect :: (s: Sphere, r: Ray) -> (hit: bool, distance: float, point: Vector3, normal: Vector3) {
    dir := s.position - r.origin;
    b := dot(dir, r.direction);
    det := b * b - dot(dir, dir) + s.radius * s.radius;
    if det < 0 return false, 0, s.position, s.position;

    eps :: 0.00001;
    det = sqrt(det);
    neg := b - det;
    pos := b + det;

    if neg < eps && pos < eps return false, 0, s.position, s.position;

    distance := pos;
    if neg > eps distance = neg;

    hit_point := r.origin + r.direction * distance;
    normal    := hit_point - s.position;
    normalize(*normal, 0, normal);
    inside    := dot(normal, r.direction) > 0;
    if inside normal = -normal;
    return true, distance, hit_point, normal;

}

normalized_ray_from_to :: (a: Vector3, b: Vector3) -> Ray #must {
    r : Ray;
    r.origin = a;
    r.direction.x = b.x - a.x;
    r.direction.y = b.y - a.y;
    r.direction.z = b.z - a.z;
    normalize(*r.direction, 0, r.direction);
    return r;
}

#run {
    WIDTH  :: 160;
    HEIGHT :: 120;
    RATIO  :: cast(float)WIDTH / cast(float)HEIGHT;
    FOV    :: 50.0;
    y_extent := tan(FOV / 360 * 2 * 3.14159 / 2);
    x_extent := y_extent * RATIO;

    shapes : [2] Sphere;
    shapes[0].position.x = -10;
    shapes[0].position.z = 50;
    shapes[0].radius     = 15;
    shapes[0].diffuse.x  = 255;
    shapes[1].position.x = 12;
    shapes[1].position.z = 53;
    shapes[1].radius     = 17;
    shapes[1].diffuse.y  = 255;

    camera : Ray;
    camera.direction.z = 1;
    cam_x : Vector3; cam_x.x = 1;
    cam_y := cross(cam_x, camera.direction);
    normalize(*cam_y, 0, cam_y);
    
    data : String_Builder;
    append(*data, tprint("P3 % % 255\n", WIDTH, HEIGHT));

    for _y: 1..HEIGHT {
        y := cast(float)_y / HEIGHT * 2.0 - 1.0;
        for _x: 1..WIDTH {
            x := cast(float)_x / WIDTH * 2.0 - 1.0;

            dir := cam_x * (x * x_extent) + cam_y * (y * y_extent) + camera.direction;
            ray := normalized_ray_from_to(camera.origin, dir);

            brightness := 0;

            colour : Vector3;
            closest := FLOAT32_MAX;

            for shape : shapes {
                hit, distance, point, normal := intersect(shape, ray);
                if hit && distance < closest {
                    closest = distance;
                    falloff := dot(dir, normal);
                    falloff *= falloff;
                    if falloff < 0 falloff = 0;
                    if falloff > 1 falloff = 1;
                    colour  = shape.diffuse * falloff;
                }
            }

            append(*data, tprint("% % % ", cast(int)colour.x, cast(int)colour.y, cast(int)colour.z));
            reset_temporary_storage();
        }
    }

    write_entire_file("output.ppm", data);
}
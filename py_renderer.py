class Vec2D:
    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

    @staticmethod
    def zero():
        return Vec3D(0, 0, 0)

    def __add__(self, other):
        return Vec3D(self.x + other.x, self.y + other.y)

    def __iter__(self):
        yield self.x
        yield self.y

    def __repr__(self) -> str:
        return f"Vec2D({self.x}, {self.y})"


class Vec3D:
    @staticmethod
    def zero():
        return Vec3D(0, 0, 0)

    def __add__(self, other):
        return Vec3D(self.x + other.x, self.y + other.y, self.z + other.z)

    def __repr__(self) -> str:
        return f"Vec3D({self.x}, {self.y}, {self.z})"

    def __init__(self, x: float, y: float, z: float) -> None:
        self.x = x
        self.y = y
        self.z = z

    def __iter__(self):
        yield self.x
        yield self.y
        yield self.z


class Rect2D:
    def __init__(self, pos: Vec2D, size: Vec2D) -> None:
        self.position = pos
        self.size = size

    @staticmethod
    def from_center_size(pos_center: Vec2D, size: Vec2D):
        position = Vec2D(pos_center.x - size.x / 2, pos_center.y - size.y / 2)
        return Rect2D(position, size)

    def left(self):
        return self.position.x

    def right(self):
        return self.position.x + self.size.x

    def top(self):
        return self.position.y

    def bottom(self):
        return self.position.y + self.size.y

    def width(self):
        return self.size.x

    def height(self):
        return self.size.y


class View:
    def __init__(
        self, position: Vec2D, canvas_rect: Rect2D, image_rect: Rect2D, near_clip: float
    ) -> None:
        self.position = position
        self.canvas_rect = canvas_rect
        self.image_rect = image_rect
        self.near_clip = near_clip


class Triangle3D:
    def __init__(self, a: Vec3D, b: Vec3D, c: Vec3D) -> None:
        self.verticies = [a, b, c]

    def __iter__(self):
        for vertex in self.verticies:
            yield vertex


class Shape3D:
    def __init__(self, *args) -> None:
        self.triangles = list(args)

    def __iter__(self):
        for triangle in self.triangles:
            yield triangle


import math
import drawSvg as draw

# cam_po = point in camera space
def project(view: View, cam_pt: Vec3D) -> Vec2D:
    screen_x = view.near_clip * cam_pt.x / -cam_pt.z
    screen_y = view.near_clip * cam_pt.y / -cam_pt.z

    screen_pt = Vec2D(screen_x, screen_y)

    if (abs(screen_x) >= view.canvas_rect.width() / 2) or (
        abs(screen_y) >= view.canvas_rect.height() / 2
    ):
        print(f"screen pt{screen_pt} is out of screen bounds")
        return None

    print(f"screen pt: {screen_pt}")
    return screen_pt


def map_to_ndc(view: View, screen_pt: Vec3D) -> Vec2D:
    ndc_pt_x = (screen_pt.x + (view.canvas_rect.width() / 2)) / view.canvas_rect.width()
    ndc_pt_y = (
        screen_pt.y + (view.canvas_rect.height() / 2)
    ) / view.canvas_rect.height()
    ndc_pt = Vec2D(ndc_pt_x, ndc_pt_y)
    print(f"ndc pt: {ndc_pt}")
    return ndc_pt


def rasterize(view: View, ndc_pt: Vec2D, cam_pt: Vec3D) -> Vec3D:
    rast_x = math.floor(ndc_pt.x * view.image_rect.width())
    rast_y = math.floor((1 - ndc_pt.y) * view.image_rect.height())
    rast_z = -cam_pt.z

    rast_pt = Vec3D(rast_x, rast_y, rast_z)
    if rast_pt.z <= 0:
        print(f"rast pt {rast_pt} behind camera")
        return None

    print(f"rast pt: {rast_pt}")
    return rast_pt


def cam_pt_to_rast_pt(view: View, cam_pt: Vec2D):
    screen_pt = project(view, cam_pt)
    if screen_pt != None:
        ndc_pt = map_to_ndc(view, screen_pt)
        rast_pt = rasterize(view, ndc_pt, cam_pt)
        return rast_pt


def generate_cube(center_pos: Vec3D, size: float) -> Shape3D:
    d = size / 2  # delta
    left_top_front = center_pos + Vec3D(-d, d, d)
    left_top_back = center_pos + Vec3D(-d, d, -d)
    left_bottom_front = center_pos + Vec3D(-d, -d, d)
    left_bottom_back = center_pos + Vec3D(-d, -d, -d)

    right_top_front = center_pos + Vec3D(d, d, d)
    right_top_back = center_pos + Vec3D(d, d, -d)
    right_bottom_front = center_pos + Vec3D(d, -d, d)
    right_bottom_back = center_pos + Vec3D(d, -d, -d)

    left_lower = Triangle3D(left_top_back, left_bottom_back, left_bottom_front)
    left_upper = Triangle3D(left_top_back, left_top_front, left_bottom_front)

    right_lower = Triangle3D(right_top_back, right_bottom_back, right_bottom_front)
    right_upper = Triangle3D(right_top_back, right_top_front, right_bottom_front)

    front_lower = Triangle3D(left_bottom_front, left_top_front, right_bottom_front)
    front_upper = Triangle3D(right_top_front, left_top_front, right_bottom_front)

    back_lower = Triangle3D(left_bottom_back, left_top_back, right_bottom_back)
    back_upper = Triangle3D(right_top_back, left_top_back, right_bottom_back)

    top_lower = Triangle3D(left_top_front, left_top_back, right_top_front)
    top_upper = Triangle3D(right_top_back, left_top_back, right_top_front)

    bottom_lower = Triangle3D(left_bottom_front, left_bottom_back, right_bottom_front)
    bottom_upper = Triangle3D(right_bottom_back, left_bottom_back, right_bottom_front)

    return Shape3D(
        left_lower,
        left_upper,
        right_lower,
        right_upper,
        front_lower,
        front_upper,
        back_lower,
        back_upper,
        top_lower,
        top_upper,
        bottom_lower,
        bottom_upper,
    )

    pass


def render_point3d_to_svg(view: View, svg, point3d):
    if point3d != None:
        point2d = cam_pt_to_rast_pt(view, point3d)
        print(point2d)
        if point2d != None:
            svg.append(
                draw.Circle(
                    point2d.x, (view.image_rect.height() - point2d.y), 2, fill="white"
                )
            )


def render_shape3d_to_svg(view: View, svg, shape: Shape3D):
    for triangle in shape:
        points3d = list(triangle)
        points2d = [pt_coord for pt in map(lambda pt: (pt.x, pt.y), filter(lambda pt: pt != None, map(lambda pt: cam_pt_to_rast_pt(view, pt), points3d),)) for pt_coord in pt]
        
        svg.append(
            draw.Lines(
                *points2d,
                close=False,
                fill="#eeee00",
                stroke="black",
            )

        )

        # for point3d in triangle:
        #     render_point3d_to_svg(view, svg, point3d)


def main():
    view_pos = Vec3D.zero()
    view_canvas_rect = Rect2D.from_center_size(Vec2D.zero(), Vec2D(2, 2))
    view_image_rect = Rect2D(Vec2D.zero(), Vec2D(512, 512))

    view = View(view_pos, view_canvas_rect, view_image_rect, 1)
    point_3d = Vec3D(20, 23, -1)

    svg = draw.Drawing(
        view.image_rect.width(),
        view.image_rect.height(),
        origin=(0, 0),
        displayInline=False,
    )

    bg = draw.Rectangle(
        view_image_rect.position.x,
        view_image_rect.position.y,
        view_image_rect.width(),
        view_image_rect.height(),
        fill="#000000",
    )
    svg.append(bg)

    cube = generate_cube(Vec3D(0, 0, -300), 200)
    render_shape3d_to_svg(view, svg, cube)

    svg.rasterize()
    return svg
    

# run in a jupyter notebook
# main()

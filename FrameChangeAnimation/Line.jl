function _line_high(p1, p2)
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]
    
    xi = 1
    if dx < 0
        xi = -1
        dx = -dx
    end

    D = 2 * dx - dy
    x = p1[1]

    points = []
    for y in p1[2]:p2[2]
        push!(points, (x, y))
        if D > 0
            x += xi
            D += 2 * (dx - dy)
        else
            D += 2 * dx
        end
    end

    return points
end

function _line_low(p1, p2)
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]

    yi = 1
    if dy < 0
        yi = -1
        dy = -dy
    end

    D = 2 * dy - dx
    y = p1[2]

    points = []
    for x in p1[1]:p2[1]
        push!(points, (x, y))
        if D > 0
            y += yi
            D += 2 * (dy - dx)
        else
            D += 2 * dy
        end
    end

    return points
end

"""
    get_line(p1, p2)

Returns a list of integer points that represent the line between `p1` and `p2`.

Uses the Bresenham's line algorithm to get the points.
For more info, see: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
"""
function get_line(p1, p2)
    if abs(p2[2] - p1[2]) < abs(p2[1] - p1[1])
        if p1[1] > p2[1]
            return _line_low(p2, p1)
        else
            return _line_low(p1, p2)
        end
    else
        if p1[2] > p2[2]
            return _line_high(p2, p1)
        else
            return _line_high(p1, p2)
        end
    end
end

"""
    draw_wireframe(wireframe, project_transform, screen_size)

Returns a list of points that represent the wireframe of the `wireframe` projected 
on a screen of size `screen_size`.
"""
function draw_wireframe(wireframe::Wireframe, project_transform, screen_size::Tuple{Int, Int})
    
    # Composed screen transform applied after any projection or world space transformations
    screen_transform = Translation(
        [ screen_size[1] / 2,               # Center the XY-origin to the middle of the screen.
          screen_size[2] / 2 
    ]) ∘ LinearMap([                        # Scale the points to fit the screen: [0,1] |-> [0, screen_size]
        screen_size[1]          0     ;
             0          screen_size[2]; 
    ])

    # Apply the projection and screen transformations to the vertices
    transformed_vertices = map(screen_transform ∘ project_transform, wireframe.vertices)

    # Iterate every edge and get the line points by Bresenham's line algorithm implemented above
    points = []
    for edge in wireframe.edges
        # For every edge, look up the position of the vertices in the transformed vertices list
        # and convert them to Pixel type
        p1 = convert(Pixel, transformed_vertices[edge[1]])
        p2 = convert(Pixel, transformed_vertices[edge[2]])

        # For every point in the line, push it to the points list 
        # Note: We use the `Ref` function to have the points list act as
        # a single value in the broadcast operation.
        push!.(Ref(points), get_line(p1, p2))
    end

    return points
end
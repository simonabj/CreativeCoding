using GLMakie
using CoordinateTransformations
using LinearAlgebra
using Rotations

# Define the board size in pixels
BOARD_SIZE = (256, 256)
# Define the fill percentage of the board
FILL_PERCENTAGE = 0.5
# Upscale factor for rendering the board in Makie.jl
FIG_UPSCALE = 1.4

include("Geometry.jl")
include("Line.jl")

function draw(data)
    # Setup figure with resolution and styling 
    fig = Figure(resolution=BOARD_SIZE .* FIG_UPSCALE, backgroundcolor=:black)

    # Create a 2D axis with the same aspect ratio as the data (1:1 in this case)
    ax = Axis(fig[1, 1], aspect=DataAspect())

    # Disable decorations and spines from axis
    hidedecorations!(ax); hidespines!(ax)
    
    # Remove all user interactions from the axis
    deregister_interaction!.(ax, keys(interactions(ax)))

    # Create the image plot with the data
    img = image!(ax, data, interpolate=false, colorrange=(0, 1), colormap=:grays)

    # Create a Makie FigAxisPlot object to return all the data in a single object
    return Makie.FigureAxisPlot(fig, ax, img)
end

"""
    flip!(board, points)

Inverts the value of the pixels in `board` at the positions given by `points`.
The inversion assumes the board is binary, i.e. the values are either 0 or 1,
and is done by `new_value = 1 - old_value`.
"""
function flip!(board, points)
    for p in points
        if CartesianIndex(p) in CartesianIndices(BOARD_SIZE)
            board.val[p...] = 1.0 - board.val[p...]
        end
    end
end

"""
    blit!(board, points)

Resets the board to zero and sets the pixels in `board` at the positions given by `points` to 1.
This method is what would result in an animation where the figure is visible on every frame and
is the counterpart of `flip!`.
"""
function blit!(board, points)
    board.val = zeros(Float64, BOARD_SIZE)
    for p in points
        if CartesianIndex(p) in CartesianIndices(BOARD_SIZE)
            board.val[p...] = 1.0
        end
    end
    notify(board)
end

## Draw section

# We start by creating a board with random values and a fill percentage
# board = Observable(Float64.(rand(Float64, BOARD_SIZE)) .< FILL_PERCENTAGE);
board = Observable(Float64.(zeros(Float64, BOARD_SIZE)))

# We create a basic unit cube bounded by the points (0, 0, 0) and (1, 1, 1)
my_cube = UnitCube()

# We can easly translate the cube by applying a transformation to the vertices
# We use the `Translation` transformation to move the to have the origin at (0.5, 0.5, 0.5),
# and then we move it 4 units in the positive z-axis which is the direction of the camera
# provided by the `PerspectiveMap` transformation.
my_cube.vertices = Translation(-0.5, -0.5, 4-0.5).(my_cube.vertices)

# We get a list of all the points that represent the wireframe of the cube
# using the `draw_wireframe` function. It can take any kind of transformation
# we want to apply to the vertices, in this case we just use a basic `PerspectiveMap`
wireframe_points = draw_wireframe(my_cube, PerspectiveMap(), BOARD_SIZE)

# We then apply the points to the board using the a function of our choice
blit!(board, wireframe_points)

# Lasty, we draw the board.
fig, ax, img = draw(board)

# We now want to animate the cube, so we define a time-dependent transformation.
# The following is a composed transform that rotates the cube in 3D space as a function of time
# Composed transforms are read from the bottom-up, so the last transformation is applied first
TimeTransform(t) = Translation(0,0,3) ∘ # Lastly, move the cube 4 units in the positive z-axis (into the scene)
    LinearMap( # Create a rotation matrix that rotates the cube in 3D space
        RotY(t/10) *         # Rotate along the Y-axis by t/10 radians
        RotX(sqrt(2)*t/10) * # Rotate along the X-axis the same amount as Y, but by some irrational number
        RotZ(pi*t/10)        # Same as the previous, but along the Z-axis and a different irrational number
    ) ∘ Translation(-0.5, -0.5, -0.5) # First, center the cube at the origin


## Animate 

t = 0.0

# While the scene is visible, we update the cube's vertices and draw it to the board
while events(fig.scene).window_open.val
    # Get the basic unit cube
    cube = UnitCube()

    # Apply the time transformation to the vertices of the cube
    cube.vertices = TimeTransform(t).(cube.vertices)

    # Draw the wireframe of the cube using the `draw_wireframe` function
    blit!(board, draw_wireframe(cube, PerspectiveMap(), BOARD_SIZE))

    # Notify the board that it has been updated and should be redrawn
    notify(board) 

    # Advance animation
    t += 0.1
    sleep(0.01);
end

## Animate & save
# Same as the animation above, but we record the frames to a gif-file

# Reset board
board = Observable(Float64.(zeros(Float64, BOARD_SIZE)))
fig, ax, img = draw(board)

# Animation parameters
framerate = 20
T_p = 2 # Time to pause
T_l = 1 # Pause length in seconds
T = 5   # Total time in seconds
Nframes = framerate*T
delta_t = 0.6

# Time vector (with a second pause in the middle)
time_before_pause = 0.0:delta_t:delta_t*framerate*T_p
time_at_pause = ones(T_l*framerate) .* time_before_pause[end]
time_after_pause = time_before_pause[end]+delta_t:delta_t:delta_t*(framerate*T-1)
time = vcat(time_before_pause, time_at_pause, time_after_pause)

# Record the animation to a gif file. Every frame is an index in the time vector
# and is yielded to the function as `t`. 
record(fig, "cube_noeffect.gif", time; framerate=framerate) do t
    cube = UnitCube()
    cube.vertices = TimeTransform(t).(cube.vertices)
    blit!(board, draw_wireframe(cube, PerspectiveMap(), BOARD_SIZE))
    notify(board) 
end

# Reset board
board = Observable(Float64.(rand(Float64, BOARD_SIZE)) .< FILL_PERCENTAGE)
fig, ax, img = draw(board)

record(fig, "cube_effect.gif", time; framerate=framerate) do t
    cube = UnitCube()
    cube.vertices = TimeTransform(t).(cube.vertices)
    if !isapprox(t, time_before_pause[end]) # Only do flip if not at pause
        flip!(board, draw_wireframe(cube, PerspectiveMap(), BOARD_SIZE))
    end
    notify(board)
end
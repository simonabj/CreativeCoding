"""
    Wireframe

Defines a wireframe structure with a list of vertices and a list of edges.
Used to represent 3D objects and and is used in `Line.jl` to draw objects.
"""
mutable struct Wireframe
    vertices::Vector{Vector{Float64}}
    edges::Vector{Tuple{Int, Int}}
end

function UnitCube()
    vertices = [
        [0, 0, 0],
        [1, 0, 0],
        [1, 1, 0],
        [0, 1, 0],
        [0, 0, 1],
        [1, 0, 1],
        [1, 1, 1],
        [0, 1, 1],
    ]
    edges = [
        (1, 2), (2, 3), (3, 4), (4, 1),
        (5, 6), (6, 7), (7, 8), (8, 5),
        (1, 5), (2, 6), (3, 7), (4, 8)
    ]
    return Wireframe(vertices, edges)
end

"""
    Pixel

Represents a descrete point in a 2D plane.
"""
struct Pixel
    x::Int
    y::Int
end

"""
    getindex(p::Pixel, i::Int)

Returns the `i`-th coordinate of the `Pixel` `p`.
"""
Base.getindex(p::Pixel, i::Int) = i == 1 ? p.x : p.y

"""
    convert(::Type{Pixel}, p::Vector{Float64})

Allow for the conversion of a `Vector{Float64}` to a `Pixel`.
Only the first two elements of the vector are used and are floored to the nearest integer.
The rest of the elements in the vector are ignored.
"""
convert(::Type{Pixel}, p::Vector{Float64}) = Pixel(floor(Int, p[1]), floor(Int, p[2]))
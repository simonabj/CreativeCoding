using DSP
using GLMakie

# Load the data
BOARD_SIZE = (250, 250)



## Smooth life functions

S(N, M) = ifelse(((3 - M) <= N) & (N <= 3), 1, 0)
σ(x, a, α = 4) = 1 / (1 + exp(-4/α*(x-a)))

σₘ(a,b,α=0.01) = m -> a*(1-σ(m, 0.5, α)) + b*σ(m, 0.5, α)
σₙ(a,b,α=0.01) = n -> σ(n,a,α)*(1-σ(n,b,α))

## Smooth life transfer function with default parameters

b1 = 0.2
b2 = 0.3
d1 = 0.425
d2 = 0.425

αₘ = 0.15
αₙ = 0.02

S(n,m; b1=b1, b2=b2, d1=d1, d2=d2, αₙ=αₙ,αₘ=αₘ) = σₙ(σₘ(b1,b2,αₘ)(m), σₘ(d1,d2,αₘ)(m), αₙ)(n)

## Plot S
M = range(0,1,1000)
N = range(0,1,1000)

K = [S(n,m) for n in N, m in M]

heatmap(N, M, K,colormap=:jet, axis=(yreversed=true,aspect=DataAspect(), xticks=range(0,1,11), yticks=range(0,1,11)))



## Functions

function step(board)
    # do something with board
end

function save_gif(fig, image_node, nframes=200)
    record(fig, "output.gif", 1:nframes , framerate=20) do frame
        image_node[] = step(image_node.val)
    end
end

##

board = rand(Float64, BOARD_SIZE) .> 0.7

F = Figure(size = (800,800), backgroundcolor = :black)
ax = Axis(F[1,1])
hidedecorations!(ax)
hidespines!(ax)

board_node = Observable(board)
img = image!(ax, board_node, interpolate=false)
display(F)

##

save_gif(F, board_node)

##

while events(F).window_open.val
    sleep(1/20)
    board_node[] = step(board_node.val)
end
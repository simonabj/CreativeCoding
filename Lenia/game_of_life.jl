using DSP
using GLMakie

# Load the data
BOARD_SIZE = (250, 250)

# Discrete GoL transfer function
S(N, M) = ifelse(((3 - M) <= N) & (N <= 3), 1, 0)

function step(board)
    moore_neighborhood = [
        1 1 1;
        1 0 1;
        1 1 1
    ]

    padded_board = [
        board[end, end] board[end, :]' board[end, 1];
        board[:, 1]     board          board[:, end];
        board[1, end]   board[1, :]'   board[1, 1]
    ]
    
    counts = conv(padded_board, moore_neighborhood)[3:end-2, 3:end-2]

    return S.(counts, board)
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
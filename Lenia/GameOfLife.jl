using DSP
using GLMakie
using Distributions

## Functions

function step(board)
    M,N = size(board)
    moore_kernel = [1 1 1; 1 0 1; 1 1 1]

    wrapped_board = [
        board[M, N] board[M, :]' board[M, 1];
        board[:, N] board        board[:, 1];
        board[1, N] board[1, :]' board[1, 1]
    ]

    count_neighbors = conv(wrapped_board, moore_kernel)[3:M+2, 3:N+2]

    # Apply rules
    board = board .& (count_neighbors .== 2) .| (count_neighbors .== 3)

    return board
end
##

F = Figure(title="Game of Life", size=(800, 800), backgroundcolor = :black)

ax = Axis(F[1, 1], aspect = DataAspect())
hidedecorations!(ax)
hidespines!(ax)

const BOARD_SIZE = (100, 100)
board = Observable(rand(Normal(), 200, 200) .> 0.8);

img = image!(ax, board, colormap = :grays, interpolate = false)

display(F)

i = 0
while events(F).window_open.val
    print("\rFrame: $i")
    i += 1

    board[] = step(board.val)
    sleep(1.0 / 30)
end

##
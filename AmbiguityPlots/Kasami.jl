using DSP, LinearAlgebra, CairoMakie
using Statistics, Distributions

function generate_mls(n::Int, taps::Vector{Int})
    # Initial state: All bits are set to 1 (or another non-zero state)
    state = ones(Bool, n)
    sequence = Bool[]

    # Generate sequence
    for _ in 1:(2^n-1)
        push!(sequence, state[end])  # Record the output bit
        feedback = reduce(⊻, state[taps])
        state = [feedback; state[1:end-1]]  # Shift right and insert feedback at the front
    end

    return sequence
end

primitive_polynomial_taps = Dict(
    2 => [2, 1],
    4 => [4, 1],
    6 => [6, 1],
    8 => [8, 6, 5, 4],
    10 => [10, 3],
    12 => [12, 6, 4, 1]
)


function kasami_code(N=4)
    if N % 2 != 0
        error("N must be even")
    end
    if N ∉ keys(primitive_polynomial_taps)
        error("No primitive polynomial defined for N=$N")
    end

    taps = primitive_polynomial_taps[N]

    aₙ = generate_mls(N, taps)
    q = 2^(N ÷ 2) + 1
    bₙ = [aₙ[round(Int, ((i * q) % length(aₙ)) + 1)] for i in 1:length(aₙ)]

    return (t::Int = 0) -> begin
        aₙ .⊻ circshift(bₙ, t)
    end
end


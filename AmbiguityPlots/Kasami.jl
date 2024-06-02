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

# Example usage: 3-bit LFSR with taps at positions 3 and 2
N = 6
taps = [3, 2]
mls_sequence = generate_mls(N, taps)

function kasami_code(N=4, taps=[4, 1])
    if N % 2 != 0
        error("N must be even")
    end

    aₙ = generate_mls(N, taps)
    q = 2^(N / 2) - 1
    bₙ = [aₙ[round(Int, ((i * q) % length(aₙ)) + 1)] for i in 1:length(aₙ)]

    return (t::Int = 0) -> begin
        aₙ .⊻ circshift(bₙ, t)
    end
end

## Kasami code generator

N = 4
kasami = kasami_code(N)

kasami_img = [
    kasami(t) for t in 0:(2^N-1)
] |> x -> reduce(hcat, x)

heatmap(kasami_img, axis=(xlabel="Shifted sequences", ylabel="Kasami Code"))

## Phase-shift keying

N = 8
kasami_255bit = kasami_code(N, [8, 6, 5, 4])
kasami_0 = kasami_255bit(0)

R_b = 2048 # Bits per sekund
T_b = 1 / R_b  # Sekunder per bit
f_c = 22e3

t = 0:1/fs:T_b*length(kasami)

function bpsk(seq, t, fs, T_b, f_c)

    bpsk_seq = zeros(ComplexF64, length(t))
    for i in eachindex(seq)
        t_start = round(Int, (i - 1) * fs * T_b + 1)
        t_end = round(Int, i * fs * T_b)
        bpsk_seq[t_start:t_end] .= exp(π * im * seq[i]) .* cos.(2 * π * f_c * t[t_start:t_end])
    end
    return bpsk_seq
end

s_kasami = bpsk(kasami_0, t, fs, T_b, f_c)
fig, ax, plt = lines(t, real.(s_kasami))

## Discrete ambiguity

create_continuous_signal(s, time, fs) = t -> (time[1] <= t < time[end]) ? s[floor(Int, t / fs + 1)] : 0.0im

function discrete_ambiguity(s, t, fs)
    s_d = create_continuous_signal(s, t, fs)

    return (τ, f) -> begin
        return sum(
            [s_d(ti) * conj(s_d(ti - τ)) * exp(2π * f * ti * im)
             for ti in t])
    end
end

amb_kasami = discrete_ambiguity(s_kasami, t, fs)

ambiguity_plot(amb_kasami; N=500, freqs=range(-256, 256, 200), delays=range(-0.7, 0.7, 200))

## Cross correlation analysis

kasami_alt = kasami_255bit(1)

s_kasami_alt = bpsk(kasami_alt, t, fs, T_b, f_c);

s_kasami_crosscor = xcorr(s_kasami, s_kasami_alt);
data = abs.(s_kasami_crosscor) / (length(s_kasami_alt) / 2)
fig, ax, plt = lines(-length(s_kasami_crosscor) / 2:1:length(s_kasami_crosscor) / 2 - 1, data )
ylims!(ax, (0, 1))
fig

s_kasami_autocor = xcorr(s_kasami_alt, s_kasami_alt);
data = abs.(s_kasami_autocor) / (length(s_kasami_alt) / 2)
fig, ax, plt = lines(-length(s_kasami_autocor) / 2:1:length(s_kasami_autocor) / 2 - 1, data )
ylims!(ax, (0, 1))
fig

## 

generate_noise(N) = rand(Normal(0, 1), N) + rand(Normal(0, 1), N) * im

s_received = 0.2generate_noise(60000)
s_received[30000:30000+length(s_kasami)-1] .+= s_kasami

lines(real.(s_received))

# MAtch filter

s_filtered = conv(s_received, s_kasami)
lines(abs.(s_filtered))
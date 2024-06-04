"""
Create a BPSK signal from a binary sequence.

Parameters:
    seq: Array{Int64, 1} - Binary sequence
    t: Array{Float64, 1} - Time vector
    fs: Float64 - Sampling frequency
    T_b: Float64 - Bit period
    f_c: Float64 - Carrier frequency
"""
function bpsk(seq, t, fs, T_b, f_c)
    bpsk_seq = zeros(ComplexF64, length(t))
    for i in eachindex(seq)
        t_start = round(Int, (i - 1) * fs * T_b + 1)
        t_end = round(Int, i * fs * T_b)
        bpsk_seq[t_start:t_end] .= exp(π * im * seq[i]) .* cos.(2 * π * f_c * t[t_start:t_end])
    end
    return bpsk_seq
end
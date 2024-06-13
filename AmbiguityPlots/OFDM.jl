
function OFDM_pulse(seq_set, fs;
        L = 2048) 

    N_subcarriers = size(seq_set, 2) 
    M_symbols = size(seq_set, 1)

    println("Number of subcarriers: $N_subcarriers")

    Φ = BPSK_encoding(seq_set)

    T_b = L / M_symbols / fs
    Δf = 1 / T_b
    f1 = fs / 2

    println("Bit period: $T_b")
    println("Frequency spacing: $Δf")

    t = 0:1/fs:(M_symbols * T_b - 1/fs)
    sub_signals = zeros(ComplexF64, length(t), N_subcarriers)

    freqs = f1-Δf:-Δf:f1-N_subcarriers*Δf
    println("Min frequency: $(freqs[end])")
    println("Max frequency: $(freqs[1])")
    println("Bandwidth: $(freqs[1] - freqs[end])")

    for (i,fi) = enumerate(freqs)
        sub_signals[:,i] = BPSK(Φ[:,i], t, fs, T_b, fi)
    end

    S = sum(sub_signals, dims=2)

    return S[:]
end

function calc_stat_from_frequencies(f0, f1, fs;
    N_subcarriers = 64, M_symbols = 64)

    bw = f1 - f0
    println("Bandwidth: $bw")
    Δf = bw / N_subcarriers
    println("Desired frequency spacing: $Δf")
    println("---------------------")
    T_b = 1 / Δf
    println("Calculated symbol period: $T_b")
    println("Resulting pulse length: $(T_b * M_symbols)s")
    L = ceil(Int, T_b * M_symbols * fs) + 1
    println(" -> $L samples")
end
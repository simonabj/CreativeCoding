using DSP, FFTW
include("Ambiguity.jl")
include("Kasami.jl")
include("LFM.jl")
include("BPSK.jl")
include("OFDM.jl")
include("MPCM_LFM.jl")
include("NordMakie.jl")


L =  2048   # Number of samples per pulse
fs = 48000 # Sampling Rate in Hz

Bw = 1500  # Bandwidth in Hz
fc = 21e3 # Carrier frequency in Hz

f0 = fc - Bw / 2
f1 = fc + Bw / 2

t = collect(0:1/fs:L/fs-1/fs); # Time vector in s

println("Carrier frequency = $fc")
println("Bandwidth = $Bw")
println("Check frequency requirements: ")
println("f0 % 93.75 = $(f0 % 93.75)\nf1 % 93.75 = $(f1 % 93.75)")

# Simple LFM

s_lfm = LFM(f0, f1, L/fs).(t);

fig,ax,plt = lines(range(1,fs/2, div(L,2)), (abs.(fft(s_lfm).^2)[1:div(L,2)]),
    axis=(xlabel="Frequency [kHz]", ylabel="Magnitude", title="LFM Spectrum",
        backgroundcolor=:transparent,
        xticks=[0.0, f0, fc, f1, fs/2],
        xtickformat = x -> @. string(round(Int, x / 10) / 100.0)),
    figure=(backgroundcolor=:transparent,size=(600,400)))
xlims!(ax, f0-1000.0, fs/2)
save("lfm_spectrum.pdf", fig)
fig

lfm_delays, lfm_doppler, lfm_AF = ambiguity_function(s_lfm, fs);
fig,ax,hm = heatmap(
    lfm_delays, lfm_doppler / 1000, abs.(lfm_AF),
    axis=(xlabel="Delay [s]", ylabel="Doppler shift [kHz]", title="Ambiguity Function"),
    figure=(backgroundcolor=:transparent,)
)
save("LFM_ambiguity.png", fig)
fig

## Kasami code generator
N = 4
kasami = kasami_code(N)

kasami_img = kasami_set(N)

fig,ax,hm = heatmap(
    1:(2^N-1), 0:2^(N÷2),
    kasami_img,
    axis=(
        xlabel="Kasami Code", 
        ylabel="Sequence Shift", 
        title="Kasami Set $(2^N-1)-bit (N=$N)",
        yticks=0.5:1:2^(N÷2),
        ytickformat = x -> string.(floor.(Int, x)),
        xminorticks=IntervalsBetween(5),
        xminorticksvisible=true,
        backgroundcolor=:transparent,
    ), 
    figure=(backgroundcolor=:transparent,),
    colormap=cgrad(:grays, categorical=true)
)
Colorbar(fig[1,2], hm, label="Bit State", ticks=[0, 1])
save("kasami_set.png", fig)
fig

## Phase-shift keying

kasami_15bit = kasami_code(N)
M = 2^N - 1 # Number of bits in the sequence
T_b = L / M / fs # Bit period
R_b = 1 / T_b # Bit rate

s_kasami = BPSK(kasami_15bit(0), t, fs, T_b, fc);
fig, ax, plt = lines(t, real.(s_kasami), axis=(backgroundcolor=:transparent, title="BPSK Signal for Δ=0", xlabel="Time (s)", ylabel="Amplitude"), figure=(backgroundcolor=:transparent,))

fig,ax,plt = lines(range(1,fs/2, div(L,2)), (abs.(fft(s_kasami).^2)[1:div(L,2)]),
    axis=(xlabel="Frequency [kHz]", ylabel="Magnitude", title="LFM Spectrum",
        backgroundcolor=:transparent,
        xticks=[0.0, f0, fc, f1, fs/2],
        xtickformat = x -> @. string(round(Int, x / 10) / 100.0)),
    figure=(backgroundcolor=:transparent,size=(600,400)))
xlims!(ax, f0-1000.0, fs/2)
save("lfm_spectrum.pdf", fig)
fig

## Discrete ambiguity

kasami_delays, kasami_doppler, kasami_AF = ambiguity_function(s_kasami, fs);

heatmap(
    kasami_delays, kasami_doppler, kasami_AF,
    axis=(xlabel="Delay [s]", ylabel="Doppler shift [Hz]", title="Ambiguity Function"),
    figure=(backgroundcolor=:transparent,)
)

## OFDM

kas_set = kasami_set(6)

s = OFDM_pulse(kas_set, fs; L=2048);
lines(real.(s), figure=(backgroundcolor=:transparent,))

freqs = range(0, fs/2, div(4096, 2)+1)
fig, ax, plt = lines(freqs,abs.(fft(s)[1:end÷2+1]).^2, figure=(backgroundcolor=:transparent,))
xlims!(ax, 22e3, fs/2)
fig

ofdm_delays, ofdm_doppler, ofdm_AF = ambiguity_function(s, fs);
heatmap(
    ofdm_delays, ofdm_doppler, abs.(ofdm_AF),
    axis=(xlabel="Delay [s]", ylabel="Doppler shift [Hz]", title="Ambiguity Function"),
    figure=(backgroundcolor=:transparent,)
)

## Check signal requirements

kas_set = kasami_set(6)

calc_stat_from_frequencies(f0, f1, fs;
    N_subcarriers = 8, M_symbols = 63)

S2 = OFDM_pulse(kas_set, fs; L=16129)

ofdm_delays, ofdm_doppler, ofdm_AF = ambiguity_function(S2, fs);
heatmap(
    ofdm_delays, ofdm_doppler, abs.(ofdm_AF),
    axis=(xlabel="Delay [s]", ylabel="Doppler shift [Hz]", title="Ambiguity Function"),
    figure=(backgroundcolor=:transparent,)
)

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
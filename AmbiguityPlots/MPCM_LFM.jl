using Random, Printf
using Distributions, Statistics

include("Ambiguity.jl")
include("BPSK.jl")
include("Kasami.jl")

N_subs = 10;
L = 1024;

fs = 48000.0; # Sampling frequency
Bw = 1500.0;  # Bandwidth
fc = 21e3;    # Center frequency
m = 0.5;     # Frequency hopping interval 


T = L / fs
Tₚ = T / N_subs
Bₚ = Bw / N_subs

f0 = fc - Bw / 2
f1 = fc + Bw / 2

Δf = 1 / Tₚ

Lp = floor(Int, Tₚ * fs)

# Code sequences
# Random.seed!(23)
# Cn = shuffle(1:N_subs)   # Code selection
Cn = [2, 4, 8, 5, 10, 9, 7, 3, 6, 1]
Gn = BPSK_encoding(rand(N_subs) .> 0.0) # Slope coding
Ln = ones(10);
BPSK_encoding(kasami_code(6)(0)); # Phase coding

F = @. (fc - Bw / 2) + (Cn - 1)Δf;  # Frequency hopping
K = @. Gn * (Bₚ / Tₚ); # Frequency modulation slope

rect(t, Tp) = 0 <= t <= Tp ? 1.0 : 0.0

x_A(t, n) = rect(t, Tₚ) * exp(2π * 1im * (t * 0.5fc + 0.5K[n] * t^2))
x(t, n; Ln) = 0 <= t <= Tₚ ? Ln[n] * x_A(t, n) * exp(2π * 1im * 0.5F[n] * t) : 0.0
x(t; Ln=Ln) = 1 / sqrt(T) * sum(x(t - (n - 1) * Tₚ, n; Ln) for n in 1:N_subs)


t = 0.0:1/fs:T-1/fs
a = x_A.(t, 1)
s = x.(t)
lines(t, real.(s))

println("Resulting Bandwidth: ", maximum(F) + Bₚ - minimum(F))
# spectrum = spectrogram(s, 128; fs=fs)
# fig, ax, hm = heatmap(spectrum.time, spectrum.freq, spectrum.power',
#     axis=(xlabel="Time", ylabel="Frequency", title="Spectrogram"))
# fig

stft(s)

#
psd = periodogram(s; fs=fs)
fig, ax, plt = lines(psd.freq, psd.power, axis=(xtickformat = v -> (x -> @sprintf("%.0fkHz", x / 1000)).(v) ,))

ssp = spectrogram(s; fs=fs)
heatmap(ssp.power')
xlims!(ax, 19e3, fs/2); fig

##
# Auto corr
auto_corr = xcorr(s, s) / sqrt(sum(abs2, s) * sum(abs2, s))
lines(abs.(auto_corr) .^ 2, axis=(limits=(0, length(auto_corr), 0, 1),))

# Cross corr
s2 = x.(t; Ln=BPSK_encoding(kasami_code(6)(1)))
cross_corr = xcorr(s, s2) / sqrt(sum(abs2, s) * sum(abs2, s2))
lines(abs.(cross_corr) .^ 2, axis=(limits=(0, length(cross_corr), 0, 1),))

# Ambiguity

s_delay, s_doppler, s_amb = ambiguity_function(BPSK_encoding(kasami_code(6)(0)), 1.0)
fig, ax, hm = heatmap(s_delay, s_doppler, abs.(s_amb),
    axis=(xlabel="Delay [s]", ylabel="Doppler shift [Hz]", title="Ambiguity Function"),
    figure=(backgroundcolor=:transparent,))

fig, ax, cont = contour(s_delay, s_doppler, abs.(s_amb),
    axis=(xlabel="Delay [s]", ylabel="Doppler shift [Hz]", title="Ambiguity Function"),
    figure=(backgroundcolor=:transparent,))

# Add noise

t = 0.0:1/fs:5T-1/fs
s_noisy = 0.0 * (rand(Normal(0, 1), length(t)) + rand(Normal(0, 1), length(t)) * im)
s_noisy[L*2:L*3-1] .+= s
lines(t, real.(s_noisy))

# Match filter

s_matched = conv(s_noisy, s)
lines(real.(s_matched))
using CairoMakie
using ProgressMeter
using DSP

# χ(τ, f) = ∫_{-∞}^{∞} s(t)s'(t-τ) e^{j2πft} dt
function ambiguity(s; domain=(-20,20), resolution=1000)
    return (τ, f) -> begin
        return sum([s(t) * conj(s(t - τ)) * exp(2π*f * t * im) for t in range(domain...,resolution)])
    end
end

LFM(f0, f1, T) = t -> begin
    if t < 0 || t > T
        return 0
    end
    return exp(2π * im * (f0 * t + (f1 - f0) * t^2 / (2T)))
end

T = 20.0
t = 0:0.01:T
s = LFM(0.0,5.0,T) 

lines(t, real.(s.(t)))

amb = ambiguity(s; domain=(-20,20), resolution=1000)

function ambiguity_plot(amb; N = 500, freqs=range(-5,5,N), delays=range(-20,20,N))
    amb_s = zeros(length(delays), length(freqs));
    @showprogress for (i,τ) in enumerate(delays), (j,f) in enumerate(freqs)
            amb_s[i, j] = abs(amb(τ, f))
    end
    return heatmap(delays, freqs, amb_s, colormap = :viridis, axis=(title="Ambiguity plot", xlabel="Delay τ [samples]", ylabel="Doppler f [Hz]"))
end

ambiguity_plot(amb)
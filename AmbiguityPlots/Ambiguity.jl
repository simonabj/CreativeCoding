using CairoMakie
using ProgressMeter
using DSP

# χ(τ, f) = ∫_{-∞}^{∞} s(t)s'(t-τ) e^{j2πft} dt
function ambiguity(s; domain=(-20,20), resolution=1000)
    return (τ, f) -> begin
        return sum([s(t) * conj(s(t - τ)) * exp(2π*f * t * im) for t in range(domain...,resolution)])
    end
end

create_continuous_signal(s, time, fs) = t -> (time[1] <= t < time[end]) ? s[floor(Int, t / fs + 1)] : 0.0im

function discrete_ambiguity(s, t, fs)

    return (τ, f) -> begin
        return sum(
            [s_d(ti) * conj(s_d(ti - τ)) * exp(2π * f * ti * im)
             for ti in t])
    end
end




function ambiguity_plot(
    amb; 
    N = 500, freqs=range(-5,5,N), delays=range(-20,20,N), 
    axis=(title="Ambiguity plot",), 
    figure=(size=(500,400),)
)
    amb_s = zeros(length(delays), length(freqs));
    @showprogress for (i,τ) in enumerate(delays), (j,f) in enumerate(freqs)
            amb_s[i, j] = abs(amb(τ, f))^2
    end
    amb_s /= maximum(amb_s[:])
    return heatmap(delays, freqs, amb_s, colormap = :viridis, axis=axis, figure=figure)
end
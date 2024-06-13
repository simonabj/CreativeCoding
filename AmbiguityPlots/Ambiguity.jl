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

# Function to calculate the ambiguity function
function ambiguity_function2(signal::Vector{ComplexF64}, fs::Real;
        delay_cut = 0.5)
    N = length(signal)
    delays = -N+1:N-1
    doppler_shifts = (-N/2:N/2-1) * (fs / N)

    # Cut the delays to avoid aliasing
    delays = delays[abs.(delays) .<= delay_cut * N]

    # Initialize the ambiguity function matrix
    AF = zeros(ComplexF64, length(delays), N)
    
    # Compute the ambiguity function
    for (k, delay) in enumerate(delays)
        # Shift the signal by the delay
        shifted_signal = circshift(signal, delay)
        # Compute the cross-ambiguity function for this delay
        AF[k, :] .= ifftshift(ifft(fft(signal) .* conj(fft(shifted_signal))))
    end
    
    # Prepare axes for plotting
    delay_axis = delays / fs
    doppler_axis = doppler_shifts

    return delay_axis, doppler_axis, AF
end

function ambiguity_function(signal, fs; doppler_cut = 1.0)
    N = length(signal)
    τ = -(N÷2-1):(N÷2-1)
    Fd = -fs/2:fs/N:fs/2-fs/N;

    snorm = signal ./ norm(signal)
    # snorm = signal

    AF = zeros(length(τ), N)
    @showprogress for m in eachindex(τ)
        s_shift = localshift(snorm, τ[m])
        AF[m, :] = abs.(ifftshift(ifft(fft(snorm).*conj(fft(s_shift)))))
    end
    AF *= N

    return τ ./ fs, Fd,  AF
end

function localshift(x, τ)
    N = length(x)
    seq = zeros(ComplexF64, N) 
    if τ >= 0
        seq[1:N-τ] = x[1+τ:N];
    else
        seq[1-τ:N] = x[1:N+τ];
    end
    return seq
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
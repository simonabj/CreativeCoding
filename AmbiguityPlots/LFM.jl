function LFM(f0, f1, T)
    return t -> begin
        if t < 0 || t > T
            return 0
        end
        return exp(2π * im * (f0 * t + (f1 - f0) * t^2 / (2T)))
    end
end
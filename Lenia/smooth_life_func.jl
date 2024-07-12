function BesselJ(radius)
    f = zeros(ComplexF64,field_dims)
    weight = 0.0
    for I in CartesianIndices(f)
        ii = (I[1] + field_dims[1] ÷ 2) % field_dims[1] - field_dims[1] ÷ 2
        jj = (I[2] + field_dims[2] ÷ 2) % field_dims[2] - field_dims[2] ÷ 2
        r = √(ii^2 + jj^2) - radius
        v = 1.0 / (1.0 + exp(LOG_RES * r))
        weight += v
        field[I] = v
    end
    return fft(field), weight
end

function multiply_field!(buff, field, kernel)
    buff .= field .* kernel
end

function next_step()
    global current_field

    cur_field = view(fields, :, :, current_field)
    current_field = current_field % 2 + 1
    next_field = view(fields, :, :, current_field)

    fft!(cur_field)
    # M_buff .= 1/(2π*h^2) * ifft(M .* cur_field)
    # N_buff .= 1/(8π*h^2) * ifft((N .- M) .* cur_field)
    multiply_field!(M_buff, cur_field, M)
    ifft!(M_buff)
    multiply_field!(N_buff, cur_field, N)
    ifft!(N_buff)

    next_field .= S.(real(N_buff), real(M_buff))
end

clear_field(x) = fill!(view(fields, :, :, current_field), x)

function add_speckles(count, intensity)
    cur_field = view(fields, :, :, current_field)
    display(cur_field)

    for _ in 1:count
        u,v = floor.(rand(2) .* (field_dims .- h))
        println("Adding speckle at ($u, $v)")
        for x in 1:h, y in 1:h
            cur_field[Int(u+x), Int(v+y)] = intensity
        end
    end
end

function setup_scene()
    F = Figure()
    ax = Axis(F[1,1])
    hidedecorations!(ax)
    hidespines!(ax)

    f_node = Observable(zeros(field_dims))
    heatmap!(ax, f_node, colormap=:grays, colorrange=(0,1))

    return F, f_node
end

function draw_field!(f_node)
    f_node[] = real.(view(fields, :, :, current_field))
end
using GLMakie
using FFTW, LinearAlgebra

# Base functions

# linear clamping between a and b. 0 if x < a, 1 if x > b
function linear(x, a, b)
    r = @. (x-a+b/2) / b
    r[x .< a-b/2] .= 0
    r[x .> a+b/2] .= 1
    return r
end
        
σ(x, a, α) = @. 1 / (1 + exp(-4 / α * (x - a)))
σₘ(a, b, α) = m -> a * (1 .- σ(m, 0.5, α)) + b * σ(m, 0.5, α)
σₙ(a, b, α) = n -> σ(n, a, α) .* (1 .- σ(n, b, α))


NX, NY = 512, 512

h3 = 21.0
h = h3 / 3
b = 1

αₙ, αₘ = 0.028, 0.147
# b1, b2 = 0.278, 0.336
# d1, d2 = 0.365, 0.551
b1,b2 = 0.278, 0.365
d1,d2 = 0.267, 0.445

dt = 1/32

kd = zeros(NY, NX)
kr = zeros(NY, NX)
aa = zeros(NY, NX)

ix = ones(NY) * (1:NX)'
iy = (1:NY) * ones(NX)'
x = @. ix - 1 - NX / 2
y = @. iy - 1 - NY / 2
r = @. sqrt(x^2 + y^2)

# Close neighbors kernel
kd = 1 .- linear(r, h, b)
w_kd = sum(kd)
# Far neighbors kernel
kr = linear(r, h, b) .* (1 .- linear(r, h3, b))
w_kr = sum(kr)

Kd = fft(fftshift(kd))
Kr = fft(fftshift(kr))



S(n, m; αₙ=αₙ, αₘ=αₘ, b1=b1, b2=b2, d1=d1, d2=d2) = σₙ(σₘ(b1, d1, αₘ)(m), σₘ(b2, d2, αₘ)(m), αₙ)(n);

function plot_transfer_function()
    N = range(0,1,500)
    M = range(0,1,500)

    K = [S(n, m) for n in N, m in M]
    
    F = Figure()
    ax = Axis(F[1,1], aspect=DataAspect(), xlabel="N - Neighbors", ylabel="M - Self State",xticks=0:0.1:1,yticks=0:0.2:1)
    heatmap!(ax, N, M, K, colormap = :jet)

    slider_grid = SliderGrid(F[2,1],
        (label="b1", range=0.0:0.01:1.0, startvalue=b1),
        (label="b2", range=0.0:0.01:1.0, startvalue=b2),
        (label="d1", range=0.0:0.01:1.0, startvalue=d1),
        (label="d2", range=0.0:0.01:1.0, startvalue=d2),
    )

    lift([s.value for s in slider_grid.sliders]...) do vals...
        global b1, b2, d1, d2 = vals
        K = [S(n, m; b1=vals[1], b2=vals[2], d1=vals[3], d2=vals[4]) for n in N, m in M]
        heatmap!(ax, N, M, K, colormap = :jet)
    end

    return F, ax
end

function add_speckles!(field, ny, nx, ra, count, intensity)
    for _ in 1:count
        u,v = floor.(rand(2) .* ((nx,ny) .- ra))
        # println("Adding speckle at ($u, $v)")
        for x in 1:ra, y in 1:ra
            field[Int(v+y), Int(u+x)] = intensity
        end
    end
end

function init_field(ny, nx, ra; D = 50)
    field = zeros(ny, nx)
    add_speckles!(field, ny, nx, ra, D, 1.0)
    return field
end

function derivative(field)
    aaf = fft(field)
    nf = aaf.*Kr
    mf = aaf.*Kd
    N = real(ifft(nf)) / w_kr
    M = real(ifft(mf)) / w_kd
    return 2 * S(N, M, αₙ=αₙ, αₘ=αₘ, b1=b1, b2=b2, d1=d1, d2=d2) .- 1
end

function rk4(field, dt=0.1)
    # Runge-kutta 4th order integration
    k1 = derivative(field)
    k2 = derivative(clamp(field + dt/2 * k1))
    k3 = derivative(clamp(field + dt/2 * k2))
    k4 = derivative(clamp(field + dt * k3))
    return field + dt*(k1 + 2*k2 + 2*k3 + k4) / 6
end

function forward_euler(field, dt=0.1)
    return field + derivative(field) * dt
end

function clamp(x)
    x = copy(x)
    x[x .< 0] .= 0
    x[x .> 1] .= 1
    return x
end


## Test loop

# F = Figure()
# ax = Axis(F[1,1], aspect=DataAspect())
# hidedecorations!(ax)
# hidespines!(ax)

# field = init_field(NY, NX, h3)

# field_node = Observable(field)
# hm = heatmap!(ax, field_node, colorrange = (0,1))

# function step()
#     global field
#     field = clamp(forward_euler(field, dt))
#     field_node[] = field
# end

# display(F)


## Interactive app

function app()
    F = Figure(size=(1700, 1200))
    buffer_grid = F[1,1] = GridLayout()
    S_ax = Axis(buffer_grid[1,1], title="Transfer function", xticks=0:0.1:1, yticks=0:0.2:1, xlabel="N - Neighbors", ylabel="M - Self State", width=700, aspect=DataAspect())

    field_ax = Axis(F[1:2,2], title="Simulation", aspect=DataAspect())
    hidedecorations!(field_ax)
    hidespines!(field_ax)

    sliders = SliderGrid(F,
        (label="b1", range=0.0:0.01:1.0, startvalue=b1),
        (label="b2", range=0.0:0.01:1.0, startvalue=b2),
        (label="d1", range=0.0:0.01:1.0, startvalue=d1),
        (label="d2", range=0.0:0.01:1.0, startvalue=d2),
        (label="ra", range=1.0:1:100.0, startvalue=h3),
        (label="Td", range=1:10:1024, startvalue=1/dt),
        (label="Speckle Density", range=0:1:500, startvalue=50),
        ; width=700
    )
    refresh_btn = Button(F, label="Refresh")
    start_btn = Button(F, label="Start")
    stop_btn = Button(F, label="Stop")
    record_btn = Button(F, label="Record")

    controls_grid = F[2,1] = vgrid!(
        sliders,
        hgrid!(
            start_btn,
            stop_btn,
            refresh_btn,
            record_btn,
        );
        width=700
    )

    N = range(0,1,250)
    M = range(0,1,250)
    K = [S(n, m) for n in N, m in M]

    field = init_field(NY, NX, h3)
    
    transfer_node = Observable(K)
    field_node = Observable(field)

    is_running = Observable(false)

    function step()
        field_node[] = clamp(rk4(field_node.val, dt))
    end

    function record()
        is_running[] = false

        record("out/smoothlife.mp4", field_ax, 1:600; framerate=30) do _
            step()
        end
        println("Recording done")
    end

    function start()
        if is_running[]
            return
        end

        println("Starting simulation")
        is_running[] = true
        while is_running[]
            step()
            sleep(0.1)
        end
        println("Stopped")
    end

    function stop()
        is_running[] = false
    end

    heatmap!(S_ax, N, M, transfer_node, colormap = :jet)
    heatmap!(field_ax, field_node, colorrange = (0,1), colormap = :grays)

    lift([s.value for s in sliders.sliders]...) do vals...
        global b1, b2, d1, d2, h3, dt = vals
        global h = h3 / 3

        K = [S(n, m; b1=vals[1], b2=vals[2], d1=vals[3], d2=vals[4]) for n in N, m in M]
        transfer_node[] = K
    end

    on(refresh_btn.clicks) do _
        field = init_field(NY, NX, h3; D=sliders.sliders[end].value.val)
        field_node[] = field
    end

    on(start_btn.clicks) do _
        schedule(@task start())
    end

    on(stop_btn.clicks) do _
        stop()
    end

    on(record_btn.clicks) do _
        schedule(record())
    end

    return F
end; app()

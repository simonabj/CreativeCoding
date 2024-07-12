using GLMakie, LaTeXStrings
using DSP
using FFTW, LinearAlgebra, Bessels

## Parameters

b1, b2 = 0.278, 0.365
d1, d2 = 0.267, 0.445

αₘ = 0.147;
αₙ = 0.029;

## Sigmoid Functions

σ(x, a, α) = 1 / (1 + exp(-4 / α * (x - a)))
σₘ(a, b, α) = m -> a * (1 - σ(m, 0.5, α)) + b * σ(m, 0.5, α)
σₙ(a, b, α) = n -> σ(n, a, α) * (1 - σ(n, b, α))

S(n, m; αₙ=αₙ, αₘ=αₘ, b1=b1, b2=b2, d1=d1, d2=d2) = σₙ(σₘ(b1, d1, αₘ)(m), σₘ(b2, d2, αₘ)(m), αₙ)(n);

## Plot activation function

N = range(0,1,500)
M = range(0,1,500)
K = [S(n, m) for n in N, m in M]
heatmap(N, M, K, colormap = :jet, axis=(xticks=0:0.1:1,yticks=0:0.2:1))

## Test

h = 7.0
h3 = 3h
LOG_RES = 8

field_dims = (2^LOG_RES, 2^LOG_RES)
fields = zeros(ComplexF64, field_dims..., 2)
current_field = 1

M_buff = zeros(ComplexF64, field_dims)
N_buff = zeros(ComplexF64, field_dims)

Bₕ, wₕ = BesselJ(h);
B₃ₕ, w₃ₕ = BesselJ(h3);

Bₕ ./= wₕ
B₃ₕ ./= w₃ₕ

## Functions
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
    return fftshift(fft(field)), weight
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
    M_buff .= ifft(Bₕ .* fftshift(cur_field))
    N_buff .= ifft((B₃ₕ .- Bₕ) .* fftshift(cur_field))

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

## Debug


F = Figure()

ax11 = Axis(F[1,1], title = "Field")
ax21 = Axis(F[2,1], title = "Re(Bₕ)")
ax31 = Axis(F[3,1], title = "Re(B₃ₕ)")

ax32 = Axis(F[1,2], title="Next Field S(N,M)")
ax12 = Axis(F[2,2], title="Re(M)")
ax22 = Axis(F[3,2], title="Re(N)")

field_node = Observable(real(fields[ :, :, previous_field()]))
bh_node = Observable(real(Bₕ))
b3h_node = Observable(real(B₃ₕ))

S_node = Observable(real(fields[ :, :, current_field]))
M_node = Observable(real(M_buff))
N_node = Observable(real(N_buff))

heatmap!(ax11, field_node, colorrange=(0,1))
heatmap!(ax21, bh_node)
heatmap!(ax31, b3h_node)

hm1 = heatmap!(ax12, M_node, colorrange=(0,1))
hm2 = heatmap!(ax22, N_node, colorrange=(0,1))
hm3 = heatmap!(ax32, S_node, colorrange=(0,1))

Colorbar(F[1, 3], hm1)
Colorbar(F[2, 3], hm2)
Colorbar(F[3, 3], hm3)

F

## Debug

previous_field() = current_field % 2 + 1

function update_plot()
    field_node[] = real(view(fields, :, :, current_field))
    bh_node[] = real(Bₕ)
    b3h_node[] = real(B₃ₕ)

    M_node[] = real(M_buff)
    N_node[] = real(N_buff)
    S_node[] = real(view(fields, :, :, previous_field()))
    return
end

## Test

# F, f_node = setup_scene()

clear_field(0.0)
add_speckles(200, 1.0)
update_plot()

## Step

next_step()
update_plot()

## Loop
while events(F).window_open.val
    sleep(1.0)
    println("Current field index is $current_field")
    next_step()
    draw_field!(f_node)
end
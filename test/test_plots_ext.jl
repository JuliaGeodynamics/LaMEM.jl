# Tests the Plots plotting extension.
using Test
using Plots
using GeophysicalModelGenerator

@testset "Plots extension" begin

    # `plot_topo` used to read the topography as `Topography`, which is how
    # GeophysicalModelGenerator names it, whereas LaMEM writes `topography` -- so plotting
    # the free surface of an actual run threw. Both spellings have to work.
    x = range(-1, 1, 10)
    y = range(-1, 1, 12)
    X = repeat(collect(x), 1, length(y), 1)
    Y = repeat(collect(y)', length(x), 1, 1)
    Z = 0.1*sin.(X).*ones(size(Y))

    lamem_style = CartData(X, Y, Z, (topography=Z,))   # as LaMEM writes it
    gmg_style   = CartData(X, Y, Z, (Topography=Z,))   # as GMG names it

    @test plot_topo(lamem_style) isa Plots.Plot
    @test plot_topo(gmg_style)   isa Plots.Plot

    # a data set without any topography should say so, rather than throw a FieldError
    no_topo = CartData(X, Y, Z, (something_else=Z,))
    @test_throws ErrorException plot_topo(no_topo)
end

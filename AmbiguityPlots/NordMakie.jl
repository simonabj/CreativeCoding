using ColorSchemes
import ColorSchemes: nord, tab10, Dark2_8

fg = nord[5]
gg = nord[3]
bg = :transparent

set_theme!(Theme(
    fontsize = 20,
    palette = ( color = tab10,),
    Axis = (
        backgroundcolor = bg,
        xtickcolor = fg, ytickcolor = fg,
        xgridcolor = gg, ygridcolor = gg,
        xlabelcolor = fg, ylabelcolor = fg,
        xticklabelcolor = fg, yticklabelcolor = fg,
        topspinecolor = fg, bottomspinecolor = fg,
        leftspinecolor = fg, rightspinecolor = fg,
        titlecolor = fg, xminortickcolor=fg,
        yminortickcolor=fg
    ),
    Legend = (
        bgcolor = bg,
        labelcolor = fg, titlecolor = fg,
        framevisible = false, margin=(0,0,0,0),
    ),
    Colorbar = (
        ticklabelcolor = fg, labelcolor = fg, titlecolor = fg,
        tickcolor = fg, leftspinecolor=fg, rightspinecolor=fg,
        bottomspinecolor=fg, topspinecolor=fg,
    )
))
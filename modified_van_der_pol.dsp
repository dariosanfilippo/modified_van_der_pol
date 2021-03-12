import("stdfaust.lib");

declare name "Modified van der Pol complex generator";
declare author "Dario Sanfilippo";
declare copyright "Copyright (C) 2021 Dario Sanfilippo 
    <sanfilippo.dario@gmail.com>";
declare version "1.1";
declare license "GPL v3.0 license";

vanderpol(l, u, dt, x_0, y_0) = x_level(out * (x / l)) , 
                                y_level(out * (y / l)) 
    letrec {
        'x = fi.highpass(1, 10, tanh(l, (x_0 + x + (u * (x - x ^ 3 / 3 - y)) * dt)));
        'y = fi.highpass(1, 10, tanh(l, (y_0 + y + (x / max(u, ma.EPSILON)) * dt)));
    };

// tanh() saturator with adjustable saturating threshold
tanh(l, x) = l * ma.tanh(x / l);

// smoothing function for click-free parameter variations using 
// a one-pole low-pass with a 20-Hz cut-off frequency.
smooth(x) = fi.pole(pole, x * (1.0 - pole))
    with {
        pole = exp(-2.0 * ma.PI * 20.0 / ma.SR);
    };

// GUI parameters
x_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[5]x[style:dB]", -60, 0)));
y_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[6]y[style:dB]", -60, 0)));
z_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[7]z[style:dB]", -60, 0)));
global_group(x) = vgroup("[1]Global", x);
levels_group(x) = hgroup("[5]Levels (dB)", x);
u = global_group(hslider("[1]u[scale:exp]", 1, ma.EPSILON, 20, .000001) : smooth);  
dt = global_group(
    hslider("[9]dt (integration step)[scale:exp]", .001 , 0.000001, 1, .000001) : 
        smooth);
input(x) = global_group(nentry("[3]Input value", 1, 0, 10, .000001) <: 
    _ * impulse + _ * checkbox("[1]Constant inputs") + 
        x * checkbox("[0]External inputs"));
impulse = checkbox("[2]Impulse inputs") <: _ - _' : abs;
limit = global_group(
    hslider("[9]Saturation limit[scale:exp]", 1, 1, 64, .000001) : smooth);
out = global_group(hslider("[9]Output scaling[scale:exp]", 0, 0, 1, .000001) : 
    smooth);

process(x1, x2) = vanderpol(limit, u, dt, input(x1), input(x2));

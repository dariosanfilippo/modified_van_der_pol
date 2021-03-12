// =============================================================================
//      Modified van der Pol complex generator
// ============================================================================= 
//
//  Complex sound generator based on modified van der Pol equations.
//  The model is structurally-stable through hyperbolic tangent function
//  saturators and allows for parameters in unstable ranges to explore 
//  different dynamics. Furthermore, this model includes DC-blockers in the 
//  feedback paths to counterbalance a tendency towards fixed-point attractors 
//  – thus enhancing complex behaviours – and obtain signals suitable for audio.
//  Besides the original parameters in the model, this system includes a
//  saturating threshold determining the positive and negative bounds in the
//  equations, while the output peaks are within the [-1.0; 1.0] range.
//
//  The system can be triggered by an impulse or by a constant of arbitrary
//  values for deterministic and reproducable behaviours. Alternatively,
//  the oscillator can be fed with external inputs to be used as a nonlinear
//  distortion unit.
//
// =============================================================================

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
        'x = fi.highpass(1, 10, tanh(l, (x_0 + x + (u * (x - x ^ 3 / 3 - y)) 
            * dt)));
        'y = fi.highpass(1, 10, tanh(l, (y_0 + y + (x / max(u, ma.EPSILON)) 
            * dt)));
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
    levels_group(hbargraph("[0]x[style:dB]", -60, 0)));
y_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[1]y[style:dB]", -60, 0)));
z_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[2]z[style:dB]", -60, 0)));
global_group(x) = vgroup("[1]Global", x);
levels_group(x) = hgroup("[2]Levels (dB)", x);
u = global_group(hslider("[4]u[scale:exp]", 1, ma.EPSILON, 200, .000001) 
    : smooth);  
dt = global_group(
    hslider("[5]dt (integration step)[scale:exp]", .001 , 0.000001, 1, .000001) 
        : smooth);
input(x) = global_group(nentry("[3]Input value", 1, 0, 10, .000001) 
    <: _ * impulse + _ * checkbox("[1]Constant inputs") 
        + x * checkbox("[0]External inputs"));
impulse = button("[2]Impulse inputs") : ba.impulsify;
limit = global_group(
    hslider("[6]Saturation limit[scale:exp]", 1, 1, 64, .000001) : smooth);
out = global_group(hslider("[7]Output scaling[scale:exp]", 0, 0, 1, .000001) 
    : smooth);

process(x1, x2) = vanderpol(limit, u, dt, input(x1), input(x2));

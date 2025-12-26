function ret = get_fir_sys(final_val,pole)
    s = tf('s');
    ret = final_val*(-pole/(s-pole));
end
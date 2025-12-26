function ret = get_sec_sys(v_final, wn, zeta);
    s = tf('s');
    ret = v_final*(wn^2)/(s^2+2*wn*zeta*s+wn^2);
end
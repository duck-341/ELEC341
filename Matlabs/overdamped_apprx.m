%overdamped_apprx(final_val, tau_effective, modified_rise_time)-------------------
%
%根据阶跃响应计算二阶过阻尼近似 ------------------------------------------
%              τ_eff
%ζ  = ------------------------
%      3.86*τ_eff-1.82*tr_mdf
%----------------------------------------------------------------------
%               2.1                
%wn = ------------------------
%      3.86*τ_eff-1.82*tr_mdf            
%----------------------------------------------------------------------
%τ_eff:  达 63% 时间
%tr_mdf: 从 10% 到 90% 时间
%----------------------------------------------------------------------

function ret = overdamped_apprx(final_val,tau_effective, modified_rise_time)
    zeta = tau_effective/(3.86*tau_effective-1.83*modified_rise_time);
    wn = 2.1/(3.86*tau_effective-1.83*modified_rise_time);
    rise_tau_ratio = modified_rise_time/tau_effective;
    if (rise_tau_ratio>2.1)
        type = 'first';
    elseif(rise_tau_ratio>2.86/1.82)
        type = 'second';
    else
        type = 'warning';
    end

    fprintf("Results-----------------------------\n");
    fprintf("Damping factor ζ: %.3f\n", zeta);
    fprintf("Wn: %.3f\n", wn);
    fprintf("tau_effective: %.3f\n", tau_effective);
    fprintf("modified_rise_time: %.3f\n", modified_rise_time);
    fprintf("rise/tau: %.3f\n", modified_rise_time/tau_effective);
    fprintf("Type: %s\n", type)
    if (strcmp(type,'warning'))
        fprintf("Warning: zeta less than 1!\n");
    end
    fprintf("------------------------------------\n");
    ret.type = type;
    ret.dcgain = final_val;
    if     (strcmp(type,'first'))
        ret.pole = -1/tau_effective;
        ret.g = get_fir_sys(final_val, p);
    elseif (strcmp(type,'second'))
        ret.zeta = zeta;
        ret.wn = wn;
        ret.g = get_sec_sys(final_val, wn, zeta);
    elseif (strcmp(type,'warning'))
        ret.zeta = zeta;
        ret.wn = wn;
        ret.g = 'Warning!';
    end
end
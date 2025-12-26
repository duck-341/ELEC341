%underdamped_apprx(peak_val, steady_val, t_peak, t_rise, t_settle)-----
%
%根据阶跃响应计算二阶欠阻尼近似------------------------------------------
%               ln(os%)^2
%ζ = sqrt(---------------------)
%             π^2 + ln(os%)^2
%----------------------------------------------------------------------
%          π                 π-atan(β/ζ)
%wnp = ----------,  wnr = ---------------,  β = sqrt(1-ζ^2)
%         β*tp                  β*tr
%----------------------------------------------------------------------
%          4
%wns = ----------
%         ζ*ts
%----------------------------------------------------------------------

function ret = underdamped_apprx(peak_val, steady_val, t_peak, t_rise, t_settle)
    os = (peak_val-steady_val)/steady_val;
    osp = os*100;
    zeta = get_zeta(os);
    
    s = tf('s');
    if t_peak~=0
        wnp = get_wnp(t_peak, zeta);
        gwnp = get_sec_sys(steady_val, wnp, zeta);
    else
        wnp = NaN;
        gwnp = NaN;
    end

    if t_rise~=0
        wnr = get_wnr(t_rise, zeta);
        gwnr = get_sec_sys(steady_val, wnr, zeta);
    else
        wnr = NaN;
        gwnr = NaN;
    end

    if t_settle~=0
        wns = get_wns(t_settle, zeta);
        gwns = get_sec_sys(steady_val, wns, zeta);
    else
        wns = NaN;
        gwns = NaN;
    end
    fprintf("-------------------------------------------------\n");
    fprintf("Overshoot(%%):   %f\n",osp);
    fprintf("Damping Factor: %f\n",zeta);
    fprintf("Freq(t_peak):   %f\n",wnp);
    fprintf("Freq(t_rise):   %f\n",wnr);
    fprintf("Freq(t_settle): %f\n",wns);
    fprintf("-------------------------------------------------\n\n");
    ret.overshoot_percent = osp;
    ret.zeta = zeta;
    ret.dcgain = steady_val;
    ret.wnp = wnp;
    ret.wnr = wnr;
    ret.wns = wns;
    ret.gp = gwnp;
    ret.gr = gwnr;
    ret.gs = gwns;
end
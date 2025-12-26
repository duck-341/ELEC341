function info = get_opt_sec_zero(Gol_partial, wxo, zeta_step, wn_step)
% 高速搜索二阶共轭零点，使 PM 最大
% 使用：并行 parfor + 粗细搜索 + 三维绘图

    s = tf('s');

    % -------------------------
    % 1) 粗搜索（速度快，用大步长）
    % -------------------------
    zeta_min = 0.1;
    zeta_max = 1.1;

    wn_min = 0.3 * wxo;
    wn_max = 1.5 * wxo;

    % 粗步长（可调）
    zeta_coarse_step = zeta_step * 5;
    wn_coarse_step   = wn_step   * 5;

    zetas_c = zeta_min : zeta_coarse_step : zeta_max;
    wns_c   = wn_min   : wn_coarse_step   : wn_max;

    Nz_c = length(zetas_c);
    Nw_c = length(wns_c);

    PM_c = -inf(Nz_c, Nw_c);

    baseGain = margin(Gol_partial);

    % ---- 并行粗扫 ----
    parfor i = 1:Nz_c
        zeta = zetas_c(i);
        local_PM = -inf(1, Nw_c);
        for j = 1:Nw_c
            wn = wns_c(j);

            C = (s^2 + 2*zeta*wn*s + wn^2) / wn^2;
            L = baseGain * C * Gol_partial;

            [~, PM] = margin(L);
            if ~isnan(PM)
                local_PM(j) = PM;
            end
        end
        PM_c(i, :) = local_PM;
    end

    % 找粗扫的最佳点
    [~, idx] = max(PM_c(:));
    [i0, j0] = ind2sub(size(PM_c), idx);

    zeta_center = zetas_c(i0);
    wn_center   = wns_c(j0);

    % -------------------------
    % 2) 精搜索（只在 peak 附近 refine）
    % -------------------------
    zetas_f = (zeta_center - zeta_coarse_step) : zeta_step : (zeta_center + zeta_coarse_step);
    wns_f   = (wn_center   - wn_coarse_step)   : wn_step   : (wn_center   + wn_coarse_step);

    % 边界限制
    zetas_f = zetas_f(zetas_f>=zeta_min & zetas_f<=zeta_max);
    wns_f   = wns_f(wns_f>=wn_min & wns_f<=wn_max);

    Nz_f = length(zetas_f);
    Nw_f = length(wns_f);

    PM_f = -inf(Nz_f, Nw_f);

    % ---- 并行精扫 ----
    parfor i = 1:Nz_f
        zeta = zetas_f(i);
        local_PM = -inf(1, Nw_f);
        for j = 1:Nw_f
            wn = wns_f(j);

            C = (s^2 + 2*zeta*wn*s + wn^2) / wn^2;
            L = baseGain * C * Gol_partial;

            [~, PM] = margin(L);
            if ~isnan(PM)
                local_PM(j) = PM;
            end
        end
        PM_f(i, :) = local_PM;
    end

    % 找最终最佳
    [max_pm, idx2] = max(PM_f(:));
    [i_opt, j_opt] = ind2sub(size(PM_f), idx2);

    zeta_opt = zetas_f(i_opt);
    wn_opt   = wns_f(j_opt);

    % -------------------------
    % 3) 输出零点
    % -------------------------
    zeros_opt = pole( 1/(s^2 + 2*zeta_opt*wn_opt*s + wn_opt^2) );

    info.zeta_opt = zeta_opt;
    info.wn_opt   = wn_opt;
    info.max_pm   = max_pm;
    info.zeros    = transpose(zeros_opt);   % 两个共轭零点

    % -------------------------
    % 4) 三维绘图 (精搜索)
    % -------------------------
    figure(341); surf(wns_f, zetas_f, PM_f, 'EdgeColor','none');
    xlabel('\omega_n (rad/s)','FontSize',12);
    ylabel('\zeta','FontSize',12);
    zlabel('PM (deg)','FontSize',12);
    title('Phase Margin Surface (fine search)');
    colorbar; grid on; view(135,30);
end

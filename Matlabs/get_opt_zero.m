function info = get_opt_zero(wxo, Gol_partial)
    s = tf('s');

    % 现在 z 本身就是负的
    zstart = -wxo * 2.0;    % 更负
    zend   = -wxo * 0.5;    % 接近零但仍然负
    coarse_step = (zend - zstart)/30;   % 自动步长

    zeros_coarse = zstart:coarse_step:zend;
    pm_coarse    = zeros(size(zeros_coarse));

    baseGain = margin(Gol_partial);   % 提前计算，节省时间

    % 粗扫
    for k = 1:length(zeros_coarse)
        z = zeros_coarse(k);

        % z 本身是零点位置（负数）
        % 零点形式：zero at s = z
        Gz = baseGain * Gol_partial * (s - z)/(-z);

        [~, PM] = margin(Gz);
        pm_coarse(k) = PM;
    end

    % 找最大
    [~, idx] = max(pm_coarse);
    z_peak = zeros_coarse(idx);

    % 精扫
    fine_step = (coarse_step)/10;
    fine_range = z_peak - coarse_step : fine_step : z_peak + coarse_step;

    pm_fine = zeros(size(fine_range));

    for k = 1:length(fine_range)
        z = fine_range(k);

        Gz = baseGain * Gol_partial * (s - z)/(-z);

        [~, PM] = margin(Gz);
        pm_fine(k) = PM;
    end

    % 最终最优
    [max_pm, idx2] = max(pm_fine);

    info.optimal_zero = fine_range(idx2);   % 会是负的
    info.maximum_pm   = max_pm;
end

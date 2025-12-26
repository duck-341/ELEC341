function ret = step_help(figNum, cal)
% step_help(figNum, cal)
% 分析指定阶跃响应，必须是连续时间
% xlabel须指明时间单位 s/ms
%
% 示例:
%   info = step_help(1, 1)
    
    if nargin < 1
        figNum = gcf; % 默认当前图
    else
        figNum = figure(figNum);
    end
    if nargin < 2
        cal = 0;  % 默认值
    end

   
    %=== 找线条 ===
    ax = findobj(figNum, 'Type', 'axes');
    h = findobj(ax, 'Type', 'line');
    if isempty(h)
        error('图中没有线条');
    end

    %=== 取唯一线的数据 ===
    x = get(h, 'XData');
    y = get(h, 'YData');
    xlabel_str = get(get(ax, 'XLabel'), 'String');

    %=== 找最大值 ===
    [ymax, idx] = max(y);
    xmax = x(idx);
    
    %=== 找终值 ===
    N = 5;
    w = exp(linspace(0, 1, N));
    yfinal = sum(y(end-N+1:end).*w) / sum(w);
    xfinal = x(end);

    %=== 单位 ===
    if contains(xlabel_str, 'ms', 'IgnoreCase', true)
        unit = 'ms';
    elseif contains(xlabel_str, 's', 'IgnoreCase', true)
        unit = 's';
    else
        unit = 'unknown';
    end

    %=== over/under ===
    if (ymax-yfinal) < 0.00001*yfinal
        type = 'Overdamped';
    else
        type = 'Underdamped';
    end

    %=== unit ===
    

    % underamped
    if(strcmp(type,'Underdamped'))

        % rise time
        idx2 = find(y >= yfinal, 1, 'first'); 
        if idx2 == 1
            xrise = x(1);  % 如果第一个点就 >= vfinal
        else
            idx1 = idx2 - 1;
            % 线性插值求精确 t_rise
            xrise = x(idx1) + (yfinal - y(idx1)) / (y(idx2)-y(idx1)) * (x(idx2)-x(idx1));
        end

        lower = 0.98 * yfinal;
        upper = 1.02 * yfinal;

        % 找最后一次超出 2% band 的位置
        idx_out = find(y < lower | y > upper, 1, 'last');

        if isempty(idx_out)
            % 从未超出 → 一开始就稳定
            xsettle = x(1);
        else
            % 稳定时间是最后一次超出 band 之后的点
            if idx_out == length(y)
                xsettle = x(end); % 到最后都没稳定
            else
                xsettle = x(idx_out + 1);
            end
        end

        % 单位转换
        if(strcmp(unit,'ms'))
            tsettle = xsettle / 1000;
        else
            tsettle = xsettle;
        end

        if(strcmp(unit,'ms'))
            trise = xrise/1000;
            tpeak = xmax/1000;
        elseif(strcmp(unit,'s'))
            trise = xrise;
            tpeak = xmax;
        end

        hold(ax, 'on');
        xline(xmax, '--r', 'LineWidth', 1.2);
        plot(ax, xmax, ymax, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
        text(ax, xmax, ymax, sprintf('  Max = %.4g\n  Tp = %.4gs', ymax,tpeak), ...
            'VerticalAlignment', 'bottom', 'Color','r');
        
        xline(xrise, '--b', 'LineWidth', 1.2);
        plot(ax, xrise, yfinal, 'bo', 'MarkerSize', 8, 'LineWidth', 2);
        text(ax, xrise, yfinal, sprintf('  Rise = %.4g\n  Tr = %.4gs', yfinal,trise), ...
            'VerticalAlignment', 'bottom', 'Color', 'b');
    
        yline(yfinal, '--g', 'LineWidth', 1.2);
        text(ax, xfinal+0.2*x(end), yfinal, sprintf('  Final = %.4g', yfinal), ...
            'Color', 'g', ...
            'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');
        yline(0.98*yfinal, '--g', 'LineWidth', 0.5);
        yline(1.02*yfinal, '--g', 'LineWidth', 0.5);

        xline(xsettle, '--m', 'LineWidth', 1.2);
        plot(ax, xsettle, y(idx_out+1), 'mo', 'MarkerSize', 8, 'LineWidth', 2);
        text(ax, xsettle, y(idx_out+1), sprintf('  Ts = %.4gs', tsettle), ...
            'VerticalAlignment', 'top', 'Color','m');

    elseif(strcmp(type, "Overdamped"))
        % 计算 10% 和 90% 的上升时间
        y10 = 0.1 * yfinal;
        y90 = 0.9 * yfinal;

        % 找到 y >= 0.1*yfinal 的第一个点
        idx10 = find(y >= y10, 1, 'first');
        % 找到 y >= 0.9*yfinal 的第一个点
        idx90 = find(y >= y90, 1, 'first');

        % 线性插值提高精度
        if ~isempty(idx10) && idx10 > 1
            x10 = x(idx10-1) + (y10 - y(idx10-1)) / (y(idx10)-y(idx10-1)) * (x(idx10)-x(idx10-1));
        else
            x10 = x(1);
        end
        if ~isempty(idx90) && idx90 > 1
            x90 = x(idx90-1) + (y90 - y(idx90-1)) / (y(idx90)-y(idx90-1)) * (x(idx90)-x(idx90-1));
        else
            x90 = x(end);
        end

        trise = x90 - x10;

        %=== 计算时间常数 τ (63.2%) ===
        y63 = 0.632 * yfinal;

        % 找到 y >= 0.632*yfinal 的第一个点
        idx63 = find(y >= y63, 1, 'first');
        if ~isempty(idx63) && idx63 > 1
            x63 = x(idx63-1) + (y63 - y(idx63-1)) / (y(idx63) - y(idx63-1)) * (x(idx63) - x(idx63-1));
        else
            x63 = NaN;
        end

        tau = x63;

        if(strcmp(unit,'ms'))
            trise = trise/1000;
            tau = tau/1000;
        elseif(strcmp(unit,'s'))
            trise = trise;
            tau = tau;
        end

        % 绘制 63% 辅助线
        hold(ax, 'on');
        if ~isnan(x63)
            plot(ax, x63, y63, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
            text(ax, x63, y63, sprintf('  tau = %.4gs', tau), ...
                'VerticalAlignment', 'bottom', 'Color', 'r');
        end
        plot(ax, [x10 x90], [y10 y90], 'bo', 'MarkerSize', 8, 'LineWidth', 2);
        text(ax, x90, y90, sprintf('  Tr = %.4gs', trise), ...
            'VerticalAlignment', 'bottom', 'Color', 'b');
        yline(yfinal, '--g', 'LineWidth', 1);
        text(ax, x(end), yfinal, sprintf('  Final = %.4g', yfinal), ...
            'Color', 'g', 'VerticalAlignment', 'top', 'HorizontalAlignment', 'right');
    end

    %=== 输出 ===
    ret.type = type;
    if (strcmp(type,"Underdamped"))
        %fprintf('Underdamped Step_Res_Info:\n');
        %fprintf('\tPeak  = %.4f, tp = %.4fs\n', ymax, tpeak);
        %fprintf('\tFinal = %.4f, tr = %.4fs\n', yfinal, trise);
        ret.rise_time = trise;
        ret.final_value = yfinal;
        ret.peak_time = tpeak;
        ret.peak_value = ymax;
        ret.settle_time = tsettle;
        if(cal) 
            apprx = underdamped_apprx(ymax, yfinal, tpeak, trise, tsettle);
            ret.overshoot_percent = apprx.overshoot_percent;
            ret.zeta = apprx.zeta;
            ret.wr = apprx.wnr;
            ret.wp = apprx.wnp;
            ret.ws = apprx.wns;
            ret.gr = apprx.gr;
            ret.gp = apprx.gp;
        end

    elseif (strcmp(type,"Overdamped"))
        %fprintf('Overdamped Step_Res_Info:\n');
        %fprintf('\tFinal = %.4f\n\ttr1 = %.4fs\n\ttaue = %.4fs\n', yfinal, trise, tau);
        ret.tr1 = trise;
        ret.tau = tau;
        ret.final_value = yfinal;
        if(cal) 
            apprx = overdamped_apprx(yfinal, tau, trise);
            ret.apprx_type = apprx.type;
            if(strcmp(apprx.type,'first'))
                ret.pole = aprrx.pole;
                ret.g = apprx.g;
            elseif (strcmp(apprx.type,'second'))
                ret.wn = apprx.wn;
                ret.zeta = apprx.zeta;
                ret.g = apprx.g;
            end
        end
    end
end
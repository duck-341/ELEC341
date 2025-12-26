function pid_heuristic_gui(DP, G, H, K_master0, Kp_n0, Ki_n0, Kd_n0)
% pid_heuristic_gui 交互式 PID 启发式调参工具

    if nargin < 7
        error('需要 7 个输入：DP, G, H, K_master0, Kp_n0, Ki_n0, Kd_n0');
    end

    s = tf('s');
    poles = pole(DP);
    idx = find(poles);
    num_poles = size(poles);
    num_poles = num_poles(1);
    pi_flag = 0;
    pd_flag = 0;
    if num_poles == 1
        if isempty(idx)
            p = 0;
            msg = 'This DP is for PI, Kd should be 0.';
            pi_flag = 1;
        else
            p = poles(idx);
            msg = 'This DP is for PD, Ki should be 0.';
            pd_flag = 1;
        end 
    elseif num_poles == 2
        p = poles(idx);
        msg = 'This DP is for PID.';
    else
        msg = 'Too many poles for controler';
    end


    

    % 当前参数
    params.K_master = K_master0;
    params.Kp_n     = Kp_n0;
    params.Ki_n     = Ki_n0;
    params.Kd_n     = Kd_n0;

    last_export = struct();   % NEW: 存放最新可导出数据

    % ===== UI 窗口 =====
    f = uifigure('Position',[300 200 1000 600], ...
                 'Name','PID Heuristic Tuning', ...
                 'AutoResizeChildren','on');

    % ===== 绘图轴 =====
    ax = uiaxes(f,'Position',[50 230 600 330]);
    grid(ax,'on');
    xlabel(ax,'Time (s)');
    ylabel(ax,'Output');
    ylim(ax, [0 2])

    

    % ===== 文本标签（多行） =====
    txt1 = uilabel(f, 'Position',[50 70 900 150], ...
        'Text','', 'FontName','Consolas', 'FontSize',12);
    txt2 = uilabel(f, 'Position',[200 70 900 150], ...
        'Text','', 'FontName','Consolas', 'FontSize',12);
    txt3 = uilabel(f, 'Position',[350 70 900 150], ...
        'Text','', 'FontName','Consolas', 'FontSize',12);
    txt4 = uilabel(f, 'Position',[700 430 900 150], ...
        'Text','', 'FontName','Consolas', 'FontSize',15);

    % ===== 时间轴 =====
    t_ok = evalin('base','exist(''t'',''var'')');
    if t_ok
        t_inner = evalin('base','t');
    else
        t_inner = 0:0.001:5;
    end

    % ===== baseline =====
    C0 = K_master0*Kp_n0 + K_master0*Ki_n0/s + K_master0*Kd_n0*(-p*s/(s-p));
    T0 = feedback(C0 * G, H);
    baseline.y = step(T0, t_inner);

    hold(ax,'on');
    h_base = plot(ax, t_inner, baseline.y, '--','Color',[.5 .5 .5],'LineWidth',1.2);
    h_cur  = plot(ax, t_inner, baseline.y, 'LineWidth',1.4);   % 占位，后面更新
    hold(ax,'off');


    %% ===== UI 滑块设置 =====
    if K_master0 <= 0, K_master0 = 1; end
    if Kp_n0 <= 0, Kp_n0 = 1; end
    if Ki_n0 <= 0, Ki_n0 = 0.1; end
    if Kd_n0 <= 0, Kd_n0 = 0.01; end

    uilabel(f,'Position',[700 470 150 20],'Text','Master K');
    sld_Km = uislider(f,'Position',[700 460 180 3],'Limits',[0 5*K_master0],...
        'Value',K_master0,'ValueChangingFcn',@(sld,evt) onSliderChanging('Km', evt.Value));

    uilabel(f,'Position',[700 410 150 20],'Text','Kp_{norm}');
    sld_Kp = uislider(f,'Position',[700 400 180 3],'Limits',[0 3.5*Kp_n0],...
        'Value',Kp_n0,'ValueChangingFcn',@(sld,evt) onSliderChanging('Kp', evt.Value));
    
    if pd_flag == 1
        Ki_n0 = 0;
        ki_n_range = [0 0.000001];
    else
        ki_n_range = [0 3.5*Ki_n0];
    end
    uilabel(f,'Position',[700 350 150 20],'Text','Ki_{norm}');
    sld_Ki = uislider(f,'Position',[700 340 180 3],'Limits',ki_n_range,...
        'Value',Ki_n0,'ValueChangingFcn',@(sld,evt) onSliderChanging('Ki', evt.Value));
    
    if pi_flag == 1
        Kd_n0 = 0;
        kd_n_range = [0 0.000001];
    else
        kd_n_range = [0 3.5*Kd_n0];
    end
    uilabel(f,'Position',[700 290 150 20],'Text','Kd_{norm}');
    sld_Kd = uislider(f,'Position',[700 280 180 3],'Limits',kd_n_range,...
        'Value',Kd_n0,'ValueChangingFcn',@(sld,evt) onSliderChanging('Kd', evt.Value));

    % ===== Export 按钮 =====
    uibutton(f,'push','Position',[760 160 120 30],'Text','Export',...
    'ButtonPushedFcn',@(btn,event) onExport());

    ed_Km = uieditfield(f,'numeric','Position',[900 455 60 25],'Value',K_master0,'Editable','off');
    ed_Kp = uieditfield(f,'numeric','Position',[900 395 60 25],'Value',Kp_n0,'Editable','off');
    ed_Ki = uieditfield(f,'numeric','Position',[900 335 60 25],'Value',Ki_n0,'Editable','off');
    ed_Kd = uieditfield(f,'numeric','Position',[900 275 60 25],'Value',Kd_n0,'Editable','off');


    % ===== Reset 按钮 =====
    uibutton(f,'push','Position',[760 200 120 30],'Text','Reset',...
        'ButtonPushedFcn',@(btn,event) onReset());

    updatePlot();  % 初次绘图


    %% ========= 滑块回调 =========
    function onSliderChanging(which,val)
        switch which
            case 'Km'
                params.K_master = val; ed_Km.Value = val;
            case 'Kp'
                params.Kp_n = val; ed_Kp.Value = val;
            case 'Ki'
                params.Ki_n = val; ed_Ki.Value = val;
            case 'Kd'
                params.Kd_n = val; ed_Kd.Value = val;
        end
        updatePlot();
    end


    %% ========= Reset =========
    function onReset()
        params.K_master = K_master0;
        params.Kp_n     = Kp_n0;
        params.Ki_n     = Ki_n0;
        params.Kd_n     = Kd_n0;

        sld_Km.Value = K_master0;
        sld_Kp.Value = Kp_n0;
        sld_Ki.Value = Ki_n0;
        sld_Kd.Value = Kd_n0;

        ed_Km.Value = K_master0;
        ed_Kp.Value = Kp_n0;
        ed_Ki.Value = Ki_n0;
        ed_Kd.Value = Kd_n0;

        updatePlot();
    end

    %% ========= Export =========
    function onExport()
        if isempty(fieldnames(last_export))
            disp('Nothing to export yet.');
            return;
        end
        assignin('base','pid_export', last_export);
        disp('Exported to workspace variable: pid_export');
    end


    %% ========= 核心：绘图 + 指标计算 =========
    function updatePlot()

    
        persistent last_t;
        persistent firstRun;
        
        if isempty(firstRun)
            firstRun = true;
        else
            firstRun = false;
        end
        if ~firstRun
            if toc(last_t) < 0.05   % 50ms
                return;
            end
        end
        last_t = tic;
        Km = params.K_master;
        Kp = Km * params.Kp_n;
        Ki = Km * params.Ki_n;
        Kd = Km * params.Kd_n;

        C = Kp + Ki/s + Kd*(-p*s/(s-p));
        T = feedback(C*G, H);

        try
            y = step(T, t_inner);
        catch
            cla(ax);
            text(ax,0.5,0.5,'System unstable');
            return;
        end

        % ===== 绘图 =====
        h_cur.YData = y;

        %% ======= 指标计算 =======
        y_final = y(end);

        % ---- 上升时间：第一次达到最终值 ----
        idx_rise = find(y >= y_final, 1, 'first');
        rise_t = t_inner(idx_rise);

        % ---- 稳定时间：最后一次离开 ±2% band ----
        th = 0.02;
        lower = (1 - th) * y_final;
        upper = (1 + th) * y_final;
        
        % 找最后一次超出带的 index
        idx_out = find(y < lower | y > upper, 1, 'last');
        
        if isempty(idx_out)
            % 从一开始就在带内 → 立即稳定
            settle_t = t_inner(1);
        else
            if idx_out == length(y)
                % 到最后都没稳定
                settle_t = t_inner(end);
            else
                % 稳定时间 = 最后一次越界后的那个时间点
                settle_t = t_inner(idx_out + 1);
            end
        end

        % ---- 达峰时间 ----
        [y_peak, idx_peak] = max(y);
        peak_t = t_inner(idx_peak);

        % ---- 过冲 ----
        OS1 = (y_peak - 1) * 100;
        OSf = (y_peak - y_final) / y_final * 100;


        %% ======= Actual 文本 =======
        actual_msg = sprintf([ ...
            'Actual:\n' ...
            '  Rise   = %.4f s\n' ...
            '  Peak   = %.4f s\n' ...
            '  Settle = %.4f s\n' ...
            '  OSu    = %.3f %%\n' ...
            '  OSy    = %.3f %%\n\n'], ...
            rise_t, peak_t, settle_t, OS1, OSf);


        %% ======= 查找 standard struct（健壮版） =======
        standard_ok = evalin('base','exist(''standard'',''var'')');
        if standard_ok
            std_struct = evalin('base','standard');
        
            if isstruct(std_struct)
        
                % ===== 统一读取字段（存在 → 值，不存在 → NaN） =====
        
                S.Tr  = get_or_nan(std_struct, {'Tr','tr'});
                S.Tp  = get_or_nan(std_struct, {'Tp','tp','Peak','peak'});
                S.Ts  = get_or_nan(std_struct, {'Ts','ts'});
                S.OSu = get_or_nan(std_struct, {'OSu','Osu','osu'});
                S.OSy = get_or_nan(std_struct, {'OSy','Osy','osy'});
                S.Ess = get_or_nan(std_struct, {'Ess','ess'});
        
                % ===== 生成标准文本 =====
                std_lines = ["Standard:"];
        
                addline('Rise',   S.Tr);
                addline('Peak',   S.Tp);
                addline('Settle', S.Ts);
                addline('OSu',    S.OSu);
                addline('OSy',    S.OSy);
                addline('Ess',    S.Ess);
        
                std_msg = strjoin(std_lines, newline);
        
                % ===== 判定（仅对非 NaN 项进行） =====
                check_lines = ["Check:"];
        
                addcheck('Rise',   rise_t,   S.Tr);
                addcheck('Peak',   peak_t,   S.Tp);
                addcheck('Settle', settle_t, S.Ts);
                addcheck('OSu',    OS1,      S.OSu);
                addcheck('OSy',    OSf,      S.OSy);
                addcheck('Ess',    0,        S.Ess);
        
                check_msg = strjoin(check_lines, newline);
        
            else
                std_msg = 'Standard: (not a struct)';
                check_msg = '';
            end
        
        else
            std_msg = 'No standard found';
            check_msg = '';
        end

        last_export = struct();
        last_export.C  = C;       % PID 传递函数（含你那个 Kd 滤波形式）
        last_export.Kp = Kp;      % 非 normalized
        last_export.Ki = Ki;
        last_export.Kd = Kd;
        
        last_export.Tr  = rise_t;
        last_export.Tp  = peak_t;
        last_export.Ts  = settle_t;
        last_export.OSu = OS1;
        last_export.OSy = OSf;
        
        last_export.y_final = y_final;
        last_export.y_peak  = y_peak;
        
        
        % helper functions
        %====== 本地函数：安全追加行 ======
        function addcheck(label, actual, limit)
            if isnan(limit)
                status = 'N/A';
            else
                if actual <= limit
                    status = 'PASS';
                else
                    status = 'FAIL';
                end
            end
        
            check_lines(end+1) = sprintf("  %-6s %s", label, status);
        end

        function addline(name, val)
            if isnan(val)
                line = sprintf("  %-6s = NaN", name);
            else
                line = sprintf("  %-6s = %.4f", name, val);
            end
            std_lines(end+1) = line;
        end

        function val = get_or_nan(S, names)
            % names 是一个 cell，例如 {'Tp','tp','Peak'}
            val = NaN;
            for i = 1:length(names)
                if isfield(S, names{i})
                    val = S.(names{i});
                    return;
                end
            end
        end
        
        function out = iff(cond, a, b)
            if cond
                out = a;
            else
                out = b;
            end
        end


        %% ======= 最终显示 =======
        txt1.Text = sprintf('%s', actual_msg);
        txt2.Text = sprintf('%s', std_msg);
        txt3.Text = sprintf('%s', check_msg);
        txt4.Text = sprintf('%s', msg);

    end

end

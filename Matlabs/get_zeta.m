%zeta_os--------------------------------------------------
%
%用过冲占比(os percentage)计算阻尼系数(zeta, ζ)
%
%输入:  osper (小数形式)
%输出:  ζ     (介于0-1, 欠阻尼)
%---------------------------------------------------------

function zeta = get_zeta(osper)
    temp0 = (log(osper))^2;
    zeta = sqrt(temp0/(pi^2+temp0));
end
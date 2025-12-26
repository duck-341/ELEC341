function info = get_pid_k(dp_pid,zeros)
% info = get_pid_k(dp_pid,zeros)
% 利用pid partial dynamic和零点计算三路增益
    
    poles = pole(dp_pid);
    idx = find(poles);

    info.kp_n = 'Error';
    info.kd_n = 'Error';
    info.ki_n = 'Error';

    if (size(idx) ~= 1)
        info.message = "Error(1): partial dynamics(dp_pid) has more than 1 non zero poles.";
    elseif (size(zeros) ~= 2)
        info.message = "Error(2): 'zero' dynamics(dz_pid) doesn't have 2 zeros.";
    else
        info.message = "Okay: dp_pid, dz_pid is fine";
        p = poles(idx);
        z1 = zeros(1);
        z2 = zeros(2);
        info.pole = p;
        info.kp_n = 1/p - (z1+z2)/(z1*z2);
        info.kd_n = info.kp_n/p + 1/(z1*z2);
        info.ki_n = 1;
    end

end
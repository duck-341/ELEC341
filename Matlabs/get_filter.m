function info = get_filter(GHs, dc_as_percent, cf_as_hz, N)
% given a plant + sensor decide the sensor delay and delay block Hc
% wd is rounded by N (N位小数，默认0)

if nargin < 4
    N = 0;  % 默认值
end
res = 0.5 * 10^(-N);
Noh = dc_as_percent/100 + 0.5;

poles = pole(GHs);
idx = find(poles);
poles = poles(idx);
poles_freq = -real(poles);
dominate_pole_freq = min(poles_freq);

temp = round(dominate_pole_freq + res,N);
non_dominate_freq = 10 * temp;

N_tol = cf_as_hz/non_dominate_freq;
Nf = N_tol - Noh;

beta = Nf/(Nf+1);
tau = -1/log(beta)/cf_as_hz;

for k = 1:1:500
    if beta^(k) < exp(-4)
        break
    end
num = k+1;

info.mdp_freq = dominate_pole_freq;
info.Nf = Nf;
info.N = N_tol;
info.beta = beta;
info.tau = tau;
info.FIR_num = num;
end
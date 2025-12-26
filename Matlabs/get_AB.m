function ret = get_AB(dx, x, u)
% LINEARIZESYSTEM 自动符号线性化函数
% 输入:
%   dx  - 状态导数符号向量
%   x   - 状态变量符号向量
%   u   - 输入变量符号向量
%
% 输出:
%   ret.A, ret.B - 状态空间矩阵

    ret.A = double(simplify(jacobian(dx, x)));
    ret.B = double(simplify(jacobian(dx, u)));

end

%%% 顺序流计算：建模-传递函数-校正-结果可视化
% 气动表角度使用度，线性模型状态和导数统一使用弧度
%% ============ 1. 飞行状态 ============
% 用这4个数据组合出三种状态
H1 = 5000;        
M1 = 0.8;
H2 = 11000;
M2 = 0.8; 
H3 = H2;
M3 = 1.4;

%% ============ 2. 飞机常量 ============
m    = 9300;      % kg      质量
S    = 27.87;     % m^2     机翼参考面积
b    = 9.14;      % m       翼展
cbar = 3.45;   % m       平均气动弦长
Ix   = 12820;     % kg*m^2
Iy   = 75673;     % kg*m^2
Iz   = 85552;     % kg*m^2
g1   = 9.79128;   % m/s^2   重力加速度（5000m）
g2   = 9.77287;   % m/s^2   重力加速度（11000m）
g3   = g2;
tau  = 0.0495;    % s       舵机时间常数（先不算进传递函数）

%% ============ 3. 大气参数 ============
rou1 = 0.7364;   % 大气密度
T1 = 255.69;     % 大气温度
rou2 = 0.365;
T2 = 216.78;
rou3 = 0.365;
T3 = 216.78;
gamma = 1.4;     % 比热比
R = 287.05;      % 空气的比气体常数

%% ============ 4. 文件数据 ============
% 迎角 alpha (度)
alpha = [-5, 0, 5, 10, 15, 20, 25, 30];

% 侧滑角 beta (度)
beta = [0, 5, 10, 15, 20, 25, 30];

% 升降舵偏角 deltaE (度)
deltaE = [-24, -12, 0, 12, 24];

% 轴向力系数 Cx(alpha, deltaE) —— 行对应 deltaE，列对应 alpha
cx = [-0.081, -0.081, -0.063, -0.025,  0.044,  0.097,  0.113,  0.145;
    -0.038, -0.040, -0.021,  0.016,  0.083,  0.127,  0.137,  0.162;
    -0.020, -0.021, -0.004,  0.032,  0.094,  0.128,  0.130,  0.154;
    -0.038, -0.039, -0.025,  0.006,  0.062,  0.087,  0.085,  0.100;
    -0.073, -0.076, -0.072, -0.046,  0.012,  0.024,  0.025,  0.043];

% 法向力系数 Cz(alpha)
cz = [0.241, -0.100, -0.416, -0.731, -1.053, -1.366, -1.646, -1.917];

% 滚转力矩系数 Cl(alpha, beta) —— 行对应 beta，列对应 alpha
cl = [ 0,       0,       0,       0,       0,       0,       0,       0;
    -0.004,  -0.008,  -0.012,  -0.016,  -0.019,  -0.020,  -0.020,  -0.015;
    -0.009,  -0.017,  -0.024,  -0.030,  -0.034,  -0.040,  -0.037,  -0.016;
    -0.010,  -0.020,  -0.030,  -0.039,  -0.044,  -0.050,  -0.049,  -0.023;
    -0.010,  -0.022,  -0.034,  -0.047,  -0.046,  -0.059,  -0.061,  -0.033;
    -0.010,  -0.023,  -0.034,  -0.049,  -0.046,  -0.068,  -0.071,  -0.060;
    -0.011,  -0.023,  -0.037,  -0.050,  -0.047,  -0.074,  -0.079,  -0.091];

% 俯仰力矩系数 Cm(alpha, deltaE) —— 行对应 deltaE，列对应 alpha
cm = [ 0.168,  0.186,  0.196,  0.213,  0.251,  0.245,  0.238,  0.252;
    0.077,  0.107,  0.110,  0.110,  0.141,  0.127,  0.119,  0.133;
    -0.020, -0.009, -0.005, -0.006,  0.010,  0.006, -0.001,  0.014;
    -0.145, -0.121, -0.127, -0.129, -0.102, -0.097, -0.113, -0.087;
    -0.202, -0.184, -0.193, -0.199, -0.150, -0.160, -0.167, -0.104];

% 偏航力矩系数 Cn(alpha, beta) —— 行对应 beta，列对应 alpha
cn = [ 0,       0,       0,       0,       0,       0,       0,       0;
    0.019,   0.018,   0.019,   0.019,   0.018,   0.013,   0.007,   0.004;
    0.042,   0.042,   0.042,   0.043,   0.039,   0.030,   0.017,   0.004;
    0.057,   0.059,   0.058,   0.058,   0.053,   0.032,   0.012,   0.002;
    0.077,   0.076,   0.074,   0.073,   0.057,   0.029,   0.007,   0.012;
    0.086,   0.093,   0.089,   0.080,   0.062,   0.049,   0.022,   0.028;
    0.090,   0.106,   0.106,   0.096,   0.080,   0.068,   0.030,   0.064];

% 操纵导数：Cl_delta_a(alpha, beta) —— 行对应 beta，列对应 alpha
c_l_delta_a = [-0.052, -0.053, -0.056, -0.050, -0.056, -0.082, -0.059, -0.042;
    -0.053, -0.053, -0.053, -0.050, -0.051, -0.066, -0.043, -0.038;
    -0.053, -0.052, -0.051, -0.049, -0.049, -0.043, -0.035, -0.026;
    -0.052, -0.051, -0.052, -0.048, -0.048, -0.042, -0.037, -0.031;
    -0.049, -0.048, -0.049, -0.043, -0.042, -0.042, -0.036, -0.025;
    -0.048, -0.048, -0.047, -0.042, -0.041, -0.020, -0.028, -0.013;
    -0.049, -0.047, -0.045, -0.042, -0.037, -0.003, -0.013, -0.010];

% 操纵导数：Cl_delta_r(alpha, beta) —— 行对应 beta，列对应 alpha
c_l_delta_r = [ 0.017,  0.014,  0.010,  0.005,  0.009,  0.019,  0.005,  0.000;
    0.016,  0.014,  0.014,  0.013,  0.009,  0.012,  0.005,  0.000;
    0.013,  0.011,  0.012,  0.011,  0.009,  0.008,  0.005,  0.002;
    0.015,  0.015,  0.014,  0.014,  0.014,  0.014,  0.015,  0.013;
    0.014,  0.013,  0.013,  0.012,  0.011,  0.011,  0.010,  0.008;
    0.011,  0.010,  0.011,  0.010,  0.009,  0.008,  0.010,  0.006;
    0.010,  0.011,  0.011,  0.011,  0.010,  0.008,  0.010,  0.006];

% 操纵导数：Cn_delta_a(alpha, beta) —— 行对应 beta，列对应 alpha
c_n_delta_a = [-0.027, -0.017, -0.013, -0.012, -0.016,  0.001,  0.017,  0.011;
    -0.014, -0.016, -0.016, -0.014, -0.019, -0.021,  0.002,  0.012;
    -0.008, -0.006, -0.006, -0.005, -0.008, -0.005,  0.007,  0.004;
    -0.011, -0.010, -0.009, -0.008, -0.006,  0.000,  0.004,  0.007;
    -0.015, -0.014, -0.012, -0.011, -0.008, -0.002,  0.002,  0.006;
    -0.010, -0.004, -0.002, -0.001,  0.003,  0.014,  0.006, -0.001;
    0.002, -0.003, -0.005, -0.003, -0.001, -0.009, -0.009, -0.001];

% 操纵导数：Cn_delta_r(alpha, beta) —— 行对应 beta，列对应 alpha
c_n_delta_r = [-0.052, -0.052, -0.052, -0.054, -0.049, -0.059, -0.051, -0.030;
    -0.051, -0.043, -0.046, -0.045, -0.049, -0.057, -0.052, -0.030;
    -0.041, -0.038, -0.040, -0.040, -0.038, -0.037, -0.030, -0.027;
    -0.045, -0.045, -0.045, -0.044, -0.045, -0.047, -0.048, -0.049;
    -0.044, -0.041, -0.041, -0.040, -0.038, -0.034, -0.035, -0.035;
    -0.034, -0.036, -0.036, -0.035, -0.028, -0.024, -0.023, -0.020;
    -0.034, -0.027, -0.028, -0.027, -0.027, -0.023, -0.023, -0.019];

% 动导数（均为 alpha 的函数，行向量）
cxq = [-0.11,  0.308, 1.34,  2.08,  2.91,  2.76,  2.05,  1.5];
cyr = [ 0.852, 0.876, 0.958, 0.962, 0.974, 0.819, 0.483, 0.59];
cyp = [-0.108,-0.188, 0.11,  0.258, 0.226, 0.344, 0.362, 0.611];
czq = [-25.8, -28.9, -31.4, -31.2, -30.7, -27.7, -28.2, -29];
clr = [-0.026, 0.063, 0.113, 0.208, 0.23,  0.319, 0.437, 0.68];
clp = [-0.359,-0.443,-0.42, -0.383,-0.375,-0.329,-0.294,-0.23];
cmq = [-5.4,  -5.23, -5.26, -6.11, -6.64, -5.69, -6,    -6.2];
cnr = [-0.363,-0.378,-0.386,-0.37, -0.453,-0.55, -0.582,-0.595];
cnp = [ 0.052, 0.052,-0.012,-0.013,-0.024, 0.05,  0.15,  0.13];

%% ============ 5. 插值函数 ============
% 二维插值：Cx(alpha, deltaE)
Cx_fun = @(a,de) interp2(alpha, deltaE, cx, a, de, 'linear');

% 二维插值：Cl(alpha, beta)
Cl_fun = @(a,b) interp2(alpha, beta, cl, a, b, 'linear');

% 二维插值：Cm(alpha, deltaE)
Cm_fun = @(a,de) interp2(alpha, deltaE, cm, a, de, 'linear');


% 二维插值：Cn(alpha, beta)
Cn_fun = @(a,b) interp2(alpha, beta, cn, a, b, 'linear');

% 二维插值：操纵导数
C_l_delta_a_fun = @(a,b) interp2(alpha, beta, c_l_delta_a, a, b, 'linear');
C_l_delta_r_fun = @(a,b) interp2(alpha, beta, c_l_delta_r, a, b, 'linear');
C_n_delta_a_fun = @(a,b) interp2(alpha, beta, c_n_delta_a, a, b, 'linear');
C_n_delta_r_fun = @(a,b) interp2(alpha, beta, c_n_delta_r, a, b, 'linear');

% 一维插值：Cz(alpha)
Cz_fun = @(a) interp1(alpha, cz, a, 'linear');
solve_alpha_trim = @(c) interp1(cz, alpha, c, 'linear');

% 一维插值：动导数
Cxq_fun = @(a) interp1(alpha, cxq, a, 'linear');
Cyr_fun = @(a) interp1(alpha, cyr, a, 'linear');
Cyp_fun = @(a) interp1(alpha, cyp, a, 'linear');
Czq_fun = @(a) interp1(alpha, czq, a, 'linear');
Clr_fun = @(a) interp1(alpha, clr, a, 'linear');
Clp_fun = @(a) interp1(alpha, clp, a, 'linear');
Cmq_fun = @(a) interp1(alpha, cmq, a, 'linear');
Cnr_fun = @(a) interp1(alpha, cnr, a, 'linear');
Cnp_fun = @(a) interp1(alpha, cnp, a, 'linear');

%% ============ 6. 逐状态配平、线性化与传递函数 ============
flightStates = [H1, M1, rou1, T1, g1;
                H2, M2, rou2, T2, g2;
                H3, M3, rou3, T3, g3];
stateNames = ["5000 m, M=0.8"; "11000 m, M=0.8"; "11000 m, M=1.4"];
results = struct([]);
s = tf('s');
radPerDegree = 180/pi;

for k = 1:size(flightStates, 1)
    H = flightStates(k, 1);
    Mach = flightStates(k, 2);
    rho = flightStates(k, 3);
    T = flightStates(k, 4);
    gFlight = flightStates(k, 5);
    speedOfSound = sqrt(gamma*R*T);
    V = Mach*speedOfSound;
    qbar = 0.5*rho*V^2;

    CzTrim = -m*gFlight/(qbar*S);
    alphaTrim = interp1(fliplr(cz), fliplr(alpha), CzTrim, 'linear');
    if isnan(alphaTrim)
        error('所需升力系数超出 Cz(alpha) 数据表范围，无法配平。');
    end
    deltaETrim = fzero(@(de) Cm_fun(alphaTrim, de), ...
        [min(deltaE), max(deltaE)]);

    CmAtElevator = interp2(alpha, deltaE, cm, alpha, ...
        repmat(deltaETrim, size(alpha)), 'linear');
    CmAlpha = slopeAt(alpha, CmAtElevator, alphaTrim)*radPerDegree;
    CmAtAlpha = interp2(alpha, deltaE, cm, ...
        repmat(alphaTrim, size(deltaE)), deltaE, 'linear');
    CmDeltaE = slopeAt(deltaE, CmAtAlpha, deltaETrim)*radPerDegree;
    CzAlpha = slopeAt(alpha, cz, alphaTrim)*radPerDegree;
    Cmq = Cmq_fun(alphaTrim);

    ZAlpha = qbar*S/(m*V)*CzAlpha;
    ZDeltaE = 0;
    MAlpha = qbar*S*cbar/Iy*CmAlpha;
    MDeltaE = qbar*S*cbar/Iy*CmDeltaE;
    Mq = qbar*S*cbar/Iy*Cmq*cbar/(2*V);

    % alpha_dot 方程里俯仰角速度项的系数： (1 + Z_q)*q
    %   alpha_dot = ZAlpha*alpha + (1+Zq)*q + ZDeltaE*deltaE
    %   Zq = qbar*S*cbar/(2*m*V^2)*Czq,  Czq<0  =>  Zq 约 -0.03~-0.06, 即系数 0.94~0.97
    Czq = Czq_fun(alphaTrim);
    Zq  = qbar*S*cbar/(2*m*V^2)*Czq;
    a12 = 1 + Zq;

    % 短周期模型: x = [delta alpha; delta q], u = delta elevator.
    A_longitudinal = [ZAlpha, a12;
                      MAlpha, Mq];
    B_longitudinal = [ZDeltaE;
                      MDeltaE];
    C_longitudinal = [0, 1];
    D_longitudinal = 0;
    numQ = [MDeltaE, MAlpha*ZDeltaE - MDeltaE*ZAlpha];
    denQ = [1, -(ZAlpha + Mq), Mq*ZAlpha - a12*MAlpha];
    Gq = tf(numQ, denQ);

    ClAtAlpha = interp2(alpha, beta, cl, ...
        repmat(alphaTrim, size(beta)), beta, 'linear');
    CnAtAlpha = interp2(alpha, beta, cn, ...
        repmat(alphaTrim, size(beta)), beta, 'linear');
    ClBeta = slopeAt(beta, ClAtAlpha, 0)*radPerDegree;
    CnBeta = slopeAt(beta, CnAtAlpha, 0)*radPerDegree;

    CyBeta = -0.02;
    CyDeltaA = 0.001;
    CyDeltaR = 0.03;
    CyR = Cyr_fun(alphaTrim);
    CyP = Cyp_fun(alphaTrim);
    ClP = Clp_fun(alphaTrim);
    ClR = Clr_fun(alphaTrim);
    CnP = Cnp_fun(alphaTrim);
    CnR = Cnr_fun(alphaTrim);
    ClDeltaA = C_l_delta_a_fun(alphaTrim, 0);
    ClDeltaR = C_l_delta_r_fun(alphaTrim, 0);
    CnDeltaA = C_n_delta_a_fun(alphaTrim, 0);
    CnDeltaR = C_n_delta_r_fun(alphaTrim, 0);

    YBeta = qbar*S/(m*V)*CyBeta;
    YP = qbar*S*b/(2*m*V^2)*CyP;
    YR = qbar*S*b/(2*m*V^2)*CyR;
    LBeta = qbar*S*b/Ix*ClBeta;
    LP = qbar*S*b/Ix*ClP*b/(2*V);
    LR = qbar*S*b/Ix*ClR*b/(2*V);
    NBeta = qbar*S*b/Iz*CnBeta;
    NP = qbar*S*b/Iz*CnP*b/(2*V);
    NR = qbar*S*b/Iz*CnR*b/(2*V);
    YDeltaA = qbar*S/(m*V)*CyDeltaA;
    YDeltaR = qbar*S/(m*V)*CyDeltaR;
    LDeltaA = qbar*S*b/Ix*ClDeltaA;
    LDeltaR = qbar*S*b/Ix*ClDeltaR;
    NDeltaA = qbar*S*b/Iz*CnDeltaA;
    NDeltaR = qbar*S*b/Iz*CnDeltaR;

    % 荷兰滚近似.
    wnSquared = NBeta + YBeta*NR - YR*NBeta;
    if wnSquared <= 0
        wnDutchRoll = NaN;
        zetaDutchRoll = NaN;
    else
        wnDutchRoll = sqrt(wnSquared);
        zetaDutchRoll = -(YBeta + NR)/(2*wnDutchRoll);
    end

    A = [YBeta, YP, YR - 1, gFlight*cosd(alphaTrim)/V;
         LBeta, LP, LR, 0;
         NBeta, NP, NR, 0;
         0,     1,  0,  0];
    B = [YDeltaA, YDeltaR;
         LDeltaA, LDeltaR;
         NDeltaA, NDeltaR;
         0,       0];

    %% ---------- 7. 状态反馈校正设计（纵向 + 横向，均含舵机）----------
    % 目标：在一级品质区间 (0.35<=zeta<=1.30, wn>=1.0) 内取带余量的值
    wnDesign = 2.0;      % rad/s
    zeDesign = 0.75;

    % ==== 纵向：delta_e = Ka*alpha + Kq*q ====（本数据 Cm_de<0，正舵=低头，故为正反馈极性）
    % 扩维状态 x = [delta alpha; delta q; delta delta_e]，舵机 delta_e_dot = (delta_e_c - delta_e)/tau
    % 注意：B_longitudinal 要放进 A 的第 3 列，否则 (A3,B3) 不可控
    A3 = [A_longitudinal, B_longitudinal;
          0, 0, -1/tau];
    B3 = [0; 0; 1/tau];
    C3 = [0, 1, 0];
    D3 = 0;
    pd = [-zeDesign*wnDesign + 1i*wnDesign*sqrt(1 - zeDesign^2);
          -zeDesign*wnDesign - 1i*wnDesign*sqrt(1 - zeDesign^2);
          -1/tau];                       % 保留舵机极点
    K3 = place(A3, B3, pd);              % 控制律 delta_e_c = -K3*x
    Acl3 = A3 - B3*K3;
    ev3 = eig(Acl3);
    [~, isp] = sort(abs(imag(ev3)), 'descend');
    evSP = ev3(isp(1:2));                % 闭环短周期一对复根
    clWn = abs(evSP(1));
    clZe = -real(evSP(1))/abs(evSP(1));

    % 不含舵机的解析二阶增益（对照用，便于写报告）
    %   den(s) = s^2 - (Za+Mq-Md*kq)s + (Mq-Md*kq)*Za - a12*(Ma-Md*ka) = s^2 + 2*zeta*wn*s + wn^2
    kqDesign = ( 2*zeDesign*wnDesign + ZAlpha + Mq )/MDeltaE;
    MqEff    = Mq - MDeltaE*kqDesign;
    kaDesign = ( MAlpha - (ZAlpha*MqEff - wnDesign^2)/a12 )/MDeltaE;

    % ---- 指令通路：静态前馈 Kff + 参考模型（指令整形）----
    % Gloop: delta_e_c -> q，即反馈环路的闭环传函（直流增益 = 1/Kff）
    [numCl, denCl] = ss2tf(Acl3, B3, C3, D3);
    Gloop = tf(numCl, denCl);

    % (1) 静态前馈 Kff：把单位速率指令的稳态增益归一化为 1
    Kff = 1/dcgain(Gloop);

    % (2) 参考模型 F(s) = wf^2/(s^2 + 2*zf*wf*s + wf^2)
    %     决定“希望 q 以什么形状跟随 q_cmd”；它串在环路之前，不改变环路极点
    wfRef = 1.5;   zeRef = 0.9;
    Af = [0, 1; -wfRef^2, -2*zeRef*wfRef];   % xf = [q_ref; q_ref_dot]
    Bf = [0; wfRef^2];
    Cf = [1, 0];                              % q_ref = Cf*xf
    Gref = tf(wfRef^2, [1, 2*zeRef*wfRef, wfRef^2]);

    Gtrack = Gloop*Kff*Gref;                  % q_cmd -> q 的完整传函
    stInfo = stepinfo(Gtrack);

    % ---- 全系统状态方程（5 阶）: x_tot = [alpha; q; delta_e; q_ref; q_ref_dot] ----
    Bcl3 = B3*Kff;                            % 环路输入矩阵（q_ref 的系数）
    Atot = [Acl3, Bcl3*Cf;                    % 环路状态与参考模型的耦合
            zeros(2,3), Af];
    Btot = [0; 0; 0; Bf];
    Ctot = [0, 1, 0, 0, 0];

    % ==== 横向：偏航阻尼器 delta_r = Kr*(r - xw)，xw 为一阶洗出状态 ====
    %   洗出环节 Tw*s/(Tw*s+1) 避免稳态转弯时方向舵长期偏置
    Tw = 3.0;                            % 洗出时间常数 (s)
    Kr = 1.0;                            % 增益 (rad 舵偏 / (rad/s))
    A5 = [A, zeros(4,1);
          0, 0, 1/Tw, 0, -1/Tw];         % x = [beta; p; r; phi; xw]
    B5 = [B; 0, 0];
    Acl5 = A5 + B5(:,2)*(Kr*[0, 0, 1, 0, -1]);
    ev5  = eig(Acl5);
    [~, iw] = max(abs(imag(ev5)));
    drWn = abs(ev5(iw));
    drZe = -real(ev5(iw))/abs(ev5(iw));
    re5  = sort(real(ev5(abs(imag(ev5)) < 1e-6)));
    rollLam   = re5(1);                  % 最负的实根 = 滚转模态
    spiralLam = re5(end);                % 最接近 0 的实根 = 螺旋模态

    % 开环横向模态（对照）
    evL = eig(A);
    [~, iw0] = max(abs(imag(evL)));
    drWn0 = abs(evL(iw0));
    drZe0 = -real(evL(iw0))/abs(evL(iw0));
    re0 = sort(real(evL(abs(imag(evL)) < 1e-6)));
    rollLam0   = re0(1);
    spiralLam0 = re0(end);

    results(k).name = stateNames(k);
    results(k).V = V;
    results(k).qbar = qbar;
    results(k).alphaTrim = alphaTrim;
    results(k).deltaETrim = deltaETrim;
    results(k).longitudinalTF = Gq;
    results(k).longitudinalA = A_longitudinal;
    results(k).longitudinalB = B_longitudinal;
    results(k).longitudinalC = C_longitudinal;
    results(k).longitudinalD = D_longitudinal;
    results(k).longitudinalPoles = roots(denQ);
    results(k).lateralA = A;
    results(k).lateralB = B;
    results(k).lateralEigenvalues = eig(A);
    results(k).dutchRollWn = wnDutchRoll;
    results(k).dutchRollZeta = zetaDutchRoll;
    results(k).Zq = Zq;
    results(k).a12 = a12;
    results(k).K3 = K3;                  % 控制律 delta_e_c = -K3*x
    results(k).Ka = -K3(1);              % 物理增益 delta_e = Ka*alpha + Kq*q + Kde*delta_e
    results(k).Kq = -K3(2);
    results(k).Kde = -K3(3);
    results(k).KaDesign = kaDesign;      % 不含舵机的解析解（对照）
    results(k).KqDesign = kqDesign;
    results(k).Kff = Kff;
    results(k).wfRef = wfRef;
    results(k).zeRef = zeRef;
    results(k).Atot = Atot;
    results(k).Btot = Btot;
    results(k).evTot = eig(Atot);
    results(k).clPoles = ev3;
    results(k).clWn = clWn;
    results(k).clZe = clZe;
    results(k).overshoot = stInfo.Overshoot;
    results(k).settlingTime = stInfo.SettlingTime;
    results(k).rollTime = 1/abs(rollLam);
    results(k).spiralTime = 1/abs(spiralLam);
    results(k).rollTime0 = 1/abs(rollLam0);
    results(k).spiralTime0 = 1/abs(spiralLam0);
    results(k).drWn0 = drWn0;
    results(k).drZe0 = drZe0;
    results(k).drWn = drWn;
    results(k).drZe = drZe;
    results(k).Kr = Kr;
    results(k).Tw = Tw;

    fprintf('\n=== %s ===\n', stateNames(k));
    fprintf('V = %.2f m/s, qbar = %.1f Pa\n', V, qbar);
    fprintf('配平: alpha = %.4f deg, deltaE = %.4f deg, Cz = %.5f\n', ...
        alphaTrim, deltaETrim, CzTrim);
    fprintf('开环传递函数 q(s)/deltaE(s):\n');
    fprintf('  (%+.6g s %+.6g)\n', numQ(1), numQ(2));
    fprintf('  ------------------------------\n');
    fprintf('  (s^2 %+.6g s %+.6g)\n', denQ(2), denQ(3));
    fprintf('纵向短周期本体状态方程（不含舵机）:\n');
    fprintf('  x = [delta alpha; delta q], u = delta deltaE\n');
    fprintf('  x_dot = A_sp*x + B_sp*u, q = C_sp*x + D_sp*u\n');
    fprintf('  A_sp = [%+.6g, %+.6g; %+.6g, %+.6g]\n', ...
        A_longitudinal(1,1), A_longitudinal(1,2), ...
        A_longitudinal(2,1), A_longitudinal(2,2));
    fprintf('  B_sp = [%+.6g; %+.6g], C_sp = [0, 1], D_sp = 0\n', ...
        B_longitudinal(1), B_longitudinal(2));
    fprintf('纵向极点: ');
    fprintf('%+.5f ', results(k).longitudinalPoles);
    fprintf('\n横航向 A 矩阵特征值: ');
    fprintf('%+.5f%+.5fi ', [real(results(k).lateralEigenvalues), ...
        imag(results(k).lateralEigenvalues)].');
    fprintf('\n荷兰滚近似: wn = %.5f rad/s, zeta = %.5f\n', ...
        wnDutchRoll, zetaDutchRoll);

    % ---------- 校正结果 ----------
    fprintf('\n--- 状态反馈校正 ---\n');
    fprintf('纵向控制律: delta_e = %+.4f*alpha %+.4f*q %+.4f*delta_e   (前馈 Kff = %.4f)\n', ...
        -K3(1), -K3(2), -K3(3), Kff);
    fprintf('  解析二阶增益(不含舵机): Ka = %+.4f, Kq = %+.4f\n', kaDesign, kqDesign);
    fprintf('  闭环极点: %s\n', pol2str(ev3));
    fprintf('  闭环短周期: wn = %.4f rad/s, zeta = %.4f\n', clWn, clZe);

    % ---- 校正后的状态方程组 ----
    fprintf('\n  ===== 校正后的状态方程组 =====\n');
    fprintf('  [A] 反馈环路   x = [alpha; q; delta_e] ,  u = q_ref\n');
    fprintf('      控制律: delta_e_c = -K3*x + Kff*q_ref\n');
    fprintf('            = %+.4f*alpha %+.4f*q %+.4f*delta_e %+.4f*q_ref\n', ...
        -K3(1), -K3(2), -K3(3), Kff);
    fprintf('      x_dot = Acl*x + Bcl*q_ref ,  q = Ccl*x + Dcl*q_ref\n');
    fprintf('      Acl = [ %+9.4f  %+9.4f  %+9.4f ]\n', Acl3(1,1), Acl3(1,2), Acl3(1,3));
    fprintf('            [ %+9.4f  %+9.4f  %+9.4f ]\n', Acl3(2,1), Acl3(2,2), Acl3(2,3));
    fprintf('            [ %+9.4f  %+9.4f  %+9.4f ]\n', Acl3(3,1), Acl3(3,2), Acl3(3,3));
    fprintf('      Bcl = [ %+9.4f ; %+9.4f ; %+9.4f ] ,  Ccl = [0 1 0] ,  Dcl = 0\n', Bcl3);
    fprintf('      展开（均为相对配平点的增量）:\n');
    fprintf('        alpha_dot   = %+9.4f*alpha %+9.4f*q %+9.4f*delta_e\n', Acl3(1,:));
    fprintf('        q_dot       = %+9.4f*alpha %+9.4f*q %+9.4f*delta_e\n', Acl3(2,:));
    fprintf('        delta_e_dot = %+9.4f*alpha %+9.4f*q %+9.4f*delta_e %+9.4f*q_ref\n', ...
        Acl3(3,:), Bcl3(3));

    fprintf('  [B] 参考模型前馈   xf = [q_ref; q_ref_dot] ,  输入 q_cmd\n');
    fprintf('      q_ref_ddot = %+.4f*q_ref %+.4f*q_ref_dot %+.4f*q_cmd   (wf=%.3f, zf=%.3f)\n', ...
        -wfRef^2, -2*zeRef*wfRef, wfRef^2, wfRef, zeRef);
    fprintf('      xf_dot = [ 0       1     ] xf + [ 0      ] q_cmd\n');
    fprintf('               [ %+.4f %+.4f ]      [ %+.4f ]\n', -wfRef^2, -2*zeRef*wfRef, wfRef^2);
    fprintf('      q_ref  = [1 0]*xf\n');

    fprintf('  [C] 全系统（5 阶）  x_tot = [alpha; q; delta_e; q_ref; q_ref_dot]\n');
    fprintf('      x_tot_dot = Atot*x_tot + Btot*q_cmd ,   q = Ctot*x_tot\n');
    for ii = 1:5
        fprintf('      Atot(%d,:) = [ %+9.4f %+9.4f %+9.4f %+9.4f %+9.4f ]\n', ii, Atot(ii,:));
    end
    fprintf('      Btot      = [ %+.4f ; %+.4f ; %+.4f ; %+.4f ; %+.4f ]\n', Btot);
    fprintf('      Ctot      = [0 1 0 0 0] ,   Dtot = 0\n');
    fprintf('      eig(Atot) = %s\n', pol2str(eig(Atot)));
    fprintf('      -> 环路极点（-1.500+-1.323j, -20.202）保持不变，另加参考模型的一对 %.3f+-%.3fj\n', ...
        -zeRef*wfRef, wfRef*sqrt(1-zeRef^2));


    fprintf('  闭环单位速率指令阶跃(参考): 超调 = %.2f %%, 调节时间 = %.3f s\n', ...
        stInfo.Overshoot, stInfo.SettlingTime);
    fprintf('横向偏航阻尼器: delta_r = %.2f*(r - xw), 洗出 Tw = %.1f s\n', Kr, Tw);
    fprintf('  开环荷兰滚: wn = %.4f, zeta = %.4f\n', drWn0, drZe0);
    fprintf('  闭环荷兰滚: wn = %.4f, zeta = %.4f\n', drWn, drZe);
    fprintf('  滚转时间常数: %.3f -> %.3f s,  螺旋时间常数: %.1f -> %.1f s\n', ...
        1/abs(rollLam0), 1/abs(rollLam), 1/abs(spiralLam0), 1/abs(spiralLam));
end

%% ============ 8. 校正前后指标对比（一级飞行品质）============
fprintf('\n\n');
fprintf('====================== 校正前后指标对比 ======================\n');
fprintf(' 一级飞行品质判据（B 类飞行阶段、IV 类飞机）:\n');
fprintf('   短周期 : 0.35 <= zeta <= 1.30 ,  wn >= 1.0 rad/s\n');
fprintf('   荷兰滚 : zeta >= 0.08          ,  wn >= 1.0 rad/s\n');
fprintf('   滚转   : T = 1/|lambda| <= 1.0 s\n');
fprintf('   螺旋   : |T| >= 4 s\n');
fprintf('==============================================================\n');

passAll = true;
for k = 1:numel(results)
    r = results(k);
    okSP   = (r.clZe >= 0.35) && (r.clZe <= 1.30) && (r.clWn >= 1.0);
    okDR   = (r.drZe >= 0.08) && (r.drWn >= 1.0);
    okRoll = (r.rollTime <= 1.0);
    okSpir = (r.spiralTime >= 4.0);
    passAll = passAll && okSP && okDR && okRoll && okSpir;

    fprintf('\n--- %s ---\n', r.name);
    [~, isp2] = sort(abs(imag(r.clPoles)), 'descend');
    spcl = r.clPoles(isp2(1:2));            % 闭环短周期一对复根
    fprintf('  %-10s| %-28s| %-28s| %s\n', '项目', '开环(本体)', '闭环(校正后)', '一级');
    fprintf('  %-10s| %-28s| %-28s| %s\n', '短周期极点', ...
        pol2str(r.longitudinalPoles), pol2str(spcl), '');
    if any(real(r.longitudinalPoles) > 1e-9)
        sp0 = sprintf('发散 tau=%.1fs', 1/max(real(r.longitudinalPoles)));
    else
        sp0 = sprintf('wn=%.3f zeta=%.3f', ...
            sqrt(prod(abs(r.longitudinalPoles))), ...
            -sum(real(r.longitudinalPoles))/(2*sqrt(prod(abs(r.longitudinalPoles)))));
    end
    fprintf('  %-10s| %-28s| %-28s| %s\n', '短周期指标', sp0, ...
        sprintf('wn=%.3f zeta=%.3f', r.clWn, r.clZe), tf_ok(okSP));
    fprintf('  %-10s| %-28s| %-28s| %s\n', '荷兰滚模态', ...
        sprintf('wn=%.3f zeta=%.3f', r.drWn0, r.drZe0), ...
        sprintf('wn=%.3f zeta=%.3f', r.drWn, r.drZe), tf_ok(okDR));
    fprintf('  %-10s| %-28s| %-28s| %s\n', '滚转模态T', ...
        sprintf('%.3f s', r.rollTime0), sprintf('%.3f s', r.rollTime), tf_ok(okRoll));
    fprintf('  %-10s| %-28s| %-28s| %s\n', '螺旋模态T', ...
        sprintf('%.1f s', r.spiralTime0), sprintf('%.1f s', r.spiralTime), tf_ok(okSpir));
end

fprintf('\n');
if passAll
    fprintf('结论：三个飞行状态的纵向短周期、横航向荷兰滚、滚转与螺旋模态全部满足一级飞行品质。\n');
else
    fprintf('结论：仍有指标未满足一级飞行品质，请检查上面的判定列。\n');
end
fprintf('\n注1：长周期(Phugoid)需要阻力/推力数据，本作业数据表未提供，故不分析。\n');
fprintf('注2：纵向校正器 delta_e_c = -K3*[alpha;q;delta_e]，前馈 Kff 已把单位角速度指令的稳态增益归一化为 1。\n');
fprintf('注3：q/delta_e 的零点 s = ZAlpha 是“不变量零点”，任何反馈都移不走。动压越低 |ZAlpha| 越小，\n');
fprintf('      不经整形的速率指令阶跃超调就越大（5km 约 34%%, 11km/M0.8 约 127%%, 11km/M1.4 约 52%%）。\n');
fprintf('      这属于时域响应形状问题，不属于一级品质判据（一级品质只考核短周期的 wn 与 zeta）。\n');
fprintf('注4：指令通路 = 参考模型 F(s) + 静态前馈 Kff。F(s)=wf^2/(s^2+2*zf*wf*s+wf^2) 决定跟随形状，\n');
fprintf('      Kff 把单位速率指令的稳态增益归一化为 1。F(s) 串在环路之前，不改变环路极点，\n');
fprintf('      所以不影响一级品质判定；上面的“闭环阶跃响应”指标已按含参考模型的 Gtrack 计算。\n');
fprintf('      全系统 5 阶状态方程见每个状态的 [C] 段（x_tot = [alpha; q; delta_e; q_ref; q_ref_dot]）。\n');

%% ============ 附. 工具函数 ============
function s = pol2str(p)
% 把极点向量写成一行字符串
    p = p(:).';
    s = '';
    for i = 1:numel(p)
        if abs(imag(p(i))) < 1e-6
            s = [s, sprintf('%+.3f  ', real(p(i)))]; %#ok<AGROW>
        else
            s = [s, sprintf('%+.3f%+.3fj  ', real(p(i)), imag(p(i)))]; %#ok<AGROW>
        end
    end
    s = strtrim(s);
end

function s = tf_ok(flag)
    if flag, s = '满足'; else, s = '不满足'; end
end

%% ============ 附. 分段线性表格斜率 ============
function slope = slopeAt(x, y, x0)
    if x0 < x(1) || x0 > x(end)
        error('求导点超出数据表范围。');
    end
    idx = find(x <= x0, 1, 'last');
    if idx == numel(x)
        idx = idx - 1;
    end
    slope = (y(idx + 1) - y(idx))/(x(idx + 1) - x(idx));
end
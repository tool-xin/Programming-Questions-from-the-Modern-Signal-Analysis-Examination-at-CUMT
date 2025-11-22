clear; clc; close all;

%% 1. 参数设置
N = 2000;           % 总采样点数，设定足够长以观察收敛
L = 25;             % FIR滤波器阶数
alpha = 0.5;        % 相对步长
beta = 0.95;        % 平滑参数
switch_time = N/2;  % 开关断开的时间点

%% 2. 生成输入信号
% [-1, 1] 上均匀分布的白噪声
x = 2 * rand(N, 1) - 1; 

%% 3. 生成期望信号 d(n) (模拟未知系统的输出)
% 系统1 (闭环): H1(z) = 1.28 / (1 + 0.64z^-2)
b1 = [0, 0, 1.28]; 
a1 = [1, 0, 0.64];

% 系统2 (开环): H2(z) = 1.28 / (1 - 0.64z^-2)
b2 = [0, 0, 1.28]; 
a2 = [1, 0, -0.64];

% 分段产生输出
d = zeros(N, 1);
% 前半段状态
state = filtic(b1, a1, 0, 0); % 初始状态
[d(1:switch_time), zf] = filter(b1, a1, x(1:switch_time), state);
% 后半段状态 (继承之前的延迟状态，但这题目系统结构变了，简化起见可重置或延续)
% 为了严谨模拟物理开关，这里把前一段的最后输出作为初始状态不太适用，
% 因为分母变了。我们简单地让滤波器从零状态开始响应新的冲击，或者假设连续。
d(switch_time+1:end) = filter(b2, a2, x(switch_time+1:end));

%% 4. LMS 自适应滤波过程
w = zeros(L, 1);       % 权值向量初始化
y = zeros(N, 1);       % 滤波器输出
e = zeros(N, 1);       % 误差信号
mu_record = zeros(N,1);% 记录步长变化

xn_buffer = zeros(L, 1); % 输入缓存

for n = 1:N
    % 更新输入缓存 (模拟移位寄存器)
    xn_buffer = [x(n); xn_buffer(1:L-1)];
    
    % 1. 滤波 (计算输出)
    y(n) = w' * xn_buffer;
    
    % 2. 计算误差
    e(n) = d(n) - y(n);
    
    % 3. 计算变步长 mu(n) = alpha / (beta + ||x||^2)
    x_norm_sq = xn_buffer' * xn_buffer;
    mu = alpha / (beta + x_norm_sq);
    mu_record(n) = mu;
    
    % 4. 更新权值 (NLMS算法)
    w = w + 2 * mu * e(n) * xn_buffer;
end

%% 5. 绘图与分析
figure('Color', 'w');

subplot(3,1,1);
plot(d); hold on; plot(y, '--');
legend('期望输出 d(n)', 'LMS输出 y(n)');
title('系统输出追踪情况');
grid on;

subplot(3,1,2);
plot(e.^2);
title('(1) 平方误差 e^2(n) 随时间变化');
xlabel('迭代次数 n'); ylabel('Squared Error');
xline(switch_time, 'r--', '系统突变点');
grid on;

subplot(3,1,3);
plot(mu_record);
title('步长 \mu(n) 随时间变化');
xlabel('迭代次数 n');
grid on;
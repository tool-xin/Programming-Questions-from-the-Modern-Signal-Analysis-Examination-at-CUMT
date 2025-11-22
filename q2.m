clear; clc; close all;

%% 1. 读取音频文件
% 注意：文件路径必须用单引号括起来
file_path = 'C:\Users\10115\Desktop\study\现代信号\我和我的祖国-华语群星#iPnbX.mp3';

% 检查文件是否存在
if ~isfile(file_path)
    error('找不到文件，请检查路径是否正确！');
else
    disp(['正在读取文件：' file_path]);
end

[x_raw, fs_raw] = audioread(file_path);

% 如果是双声道（立体声），转换为单声道，方便处理
if size(x_raw, 2) > 1
    x_raw = mean(x_raw, 2);
end

%% 2. 预处理：模拟题目要求的 "32kHz 源信号"
% 你的MP3通常是44.1kHz或48kHz，为了严格贴合试卷题目 "选取32kHz的音频文件"，
% 我们先把读取到的信号重采样到 32kHz，作为我们的【实验输入源】。
fs_source = 32000; 
x_source = resample(x_raw, fs_source, fs_raw);
t_source = (0:length(x_source)-1) / fs_source;

disp('源信号已准备就绪，采样率：32 kHz');

%% 3. 核心任务：适配到固定的 16kHz 播放系统
fs_target = 16000; % 目标采样率

% 使用 resample 进行下采样 (32k -> 16k)
% 内部会自动加抗混叠低通滤波器
x_target = resample(x_source, fs_target, fs_source);
t_target = (0:length(x_target)-1) / fs_target;

disp('信号处理完毕，目标采样率：16 kHz');

%% 4. 绘图对比：时域波形与频域谱
figure('Color', 'w', 'Name', '我和我的祖国 - 信号处理对比');

% (1) 时域波形对比
subplot(2,1,1);
% 为了看清细节，我们只画中间的一小段（例如第5秒附近，持续0.05秒）
start_time = 5; 
duration = 0.02; 
idx_s = round(start_time * fs_source) : round((start_time + duration) * fs_source);
idx_t = round(start_time * fs_target) : round((start_time + duration) * fs_target);

plot(t_source(idx_s), x_source(idx_s), 'b', 'LineWidth', 1); hold on;
plot(t_target(idx_t), x_target(idx_t), 'r--o', 'MarkerSize', 4);
title('时域波形对比 (局部放大)');
legend(['源信号 (' num2str(fs_source/1000) 'kHz)'], ...
       ['处理后 (' num2str(fs_target/1000) 'kHz)']);
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% (2) 频域谱对比 (功率谱密度)
subplot(2,1,2);
% 使用 Welch 法估计功率谱
[pxx_s, f_s] = pwelch(x_source, [], [], [], fs_source);
[pxx_t, f_t] = pwelch(x_target, [], [], [], fs_target);

plot(f_s, 10*log10(pxx_s), 'b', 'LineWidth', 1.2); hold on;
plot(f_t, 10*log10(pxx_t), 'r', 'LineWidth', 1.2);
title('频域对比：功率谱密度');
legend(['源信号频谱 (最高 ' num2str(fs_source/2000) 'kHz)'], ...
       ['处理后频谱 (最高 ' num2str(fs_target/2000) 'kHz)']);
xlabel('频率 (Hz)'); ylabel('功率/频率 (dB/Hz)');
grid on;
xlim([0, fs_source/2]); % 显示范围设为源信号的奈奎斯特频率

%% 5. 系统性能评估 (对应题目问题)
bw_source = obw(x_source, fs_source);
bw_target = obw(x_target, fs_target);

fprintf('\n--- 系统性能分析 ---\n');
fprintf('1. 频谱差异：处理后信号的高频部分 (>8kHz) 被切除。\n');
fprintf('2. 听感差异：如果原曲高音丰富，处理后会略微变"闷"，但人声主要频段(300Hz-3.4kHz)保留完整。\n');
fprintf('3. 自动识别：\n');
if bw_target < (fs_target/2 * 0.95)
    fprintf('   -> 检测到信号带宽约为 %.2f Hz (接近 %.2f Hz 的理论上限)。\n', bw_target, fs_target/2);
    fprintf('   -> 结论：可以自动识别。频谱在 8kHz 处有明显截断，说明经过了重采样处理。\n');
else
    fprintf('   -> 结论：信号充满整个带宽，可能存在混叠或原始质量较高。\n');
end

%% 6. 播放音频 (按任意键)
fprintf('\n按任意键播放 32kHz 源信号...\n');
pause;
sound(x_source, fs_source);

fprintf('按任意键播放 16kHz 处理后信号...\n');
pause;
sound(x_target, fs_target);

fprintf('播放结束。\n');
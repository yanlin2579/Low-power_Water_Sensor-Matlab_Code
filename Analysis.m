%% 数据读入
% 处理前参数设置
RawFs = 1e6;       % 原始采样频率
RawT = 1/RawFs;    % 原始采样周期
Fs = 0.1e6;        % 重新对原始数据以Fs再次采样
T = 1/Fs;

% 数据读入
tmp_dir = dir('*');
tmp_gsfilename = [];
for i = 3:length(tmp_dir)
    tmp_gsfilename = [tmp_gsfilename,string(tmp_dir(i).name)];
end
gsFilename = regexp(tmp_gsfilename, "rxData", 'match','once');
gsFilename = rmmissing(gsFilename); 
gsFilename = gsFilename.';
s_Data = cell(3,length(gsFilename));  % 信号：第1行名称，第2行时间，第3行数据

% 读入
for i = 1:1
    s_Data{3,i} = abs(funcReadIQDataInParProcessing(gsFilename(i),[0, 1], RawFs, Fs, 800, 20));
    s_Data{1,i} = gsFilename(i);
    s_Data{2,i} = (0:length(s_Data{3,i})-1)*T;
end

% 画图
figure;
for i = 1:length(s_Data(1,:))
    plot(s_Data{2,i}, s_Data{3, i});
    title("信号");
    xlabel("时间（s）");
    ylabel("幅度");
end
%% 整形与解调
% 整形
F_sig = 3170.8;
T_sig = 1/F_sig;
s_CorrectData = cell(3,length(gsFilename));
for i = 1:length(s_Data(1,:))
    data = s_Data{3,i};
    correctData = zeros(1, length(data)-floor(T_sig/T));
    for j = 1:length(data)-floor(T_sig/T)
        sig_mean = mean(data(j:j+floor(T_sig/T)));
        curData = 0;
        if data(j) >= sig_mean
            curData = 1;
        end
        correctData(1, j) = curData;
    end
    correctData = correctData(0.01*Fs:end-0.01*Fs);
    s_CorrectData{3, i} = correctData;
    s_CorrectData{2, i} = (0:length(correctData)-1)*T;
    s_CorrectData{1,i} = gsFilename(i);
end
% 解调电压
% 解调
slp_data = zeros([2,4]);
slp_data(:, 1) = funcDeCode("pH", s_CorrectData{3, 1});
slp_data(:, 2) = funcDeCode("tds", s_CorrectData{3, 1});
slp_data(:, 3) = funcDeCode("cod", s_CorrectData{3, 1});
slp_data(:, 4) = funcDeCode("tmp", s_CorrectData{3, 1});

% 电压数据
slp_vin = zeros([1,4]);
Vth = 0.008;  % 比较器门限
Vref1 = 2.5;
Vref2 = 2.45+Vth/2;
for i=1:4
    Tref = slp_data(1, i);
    Tupdown = slp_data(2, i);
    slp_vin(i) = 1 / ( (1/Vref2)*((1-Vref2/Vref1)^(1-Tupdown/Tref)) + 1/Vref1 )+Vth/2;
end

% 画图
figure;
bar(slp_vin)
categories = ["pH", "TDS","COD","温度"];
set(gca, 'XTickLabel', categories)
for i = 1:length(slp_vin)
    text(i, slp_vin(i), num2str(slp_vin(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom')
end
title('电压数据')
ylabel('电压（V）')
xlabel('水质参数')
%% 结果计算
% pH
V_out = slp_vin(1);
V_ref = 1.25;
T_ref = 23;
a = 17e-3;
n = 1;
F = 96485;
R = 8.314;
pH_ref = 7;
pH = (a-V_out+V_ref) / (2.303*R*(T_ref+273.1)/(n*F)) + pH_ref;

% TDS
V_out = slp_vin(2);
V_ref = 0.25;
R_s =1e3;
A = 1+360e3/45e3;
R = R_s*(A*V_ref/V_out-1);
K = 1.345;
S = 1e6*K/R;
TDS = 0.5*S;

% COD
V_out = slp_vin(3)*2;  % 分压恢复
R_f = 1e3;
I_blank = 66.2e-6;
V_reference = 1;
V_working = 2.4;
I_sense = (V_out-V_working)/R_f;
COD = 1.0404*10^8*(I_sense-I_blank)-1.9713;

% 温度
V_out = slp_vin(4);
R_s = 200e3;
V_drive = 2.5;
R = R_s*(V_drive/V_out-1);
B = 3950;
T_ref = 25;
R_ref = 100e3;
T = B*(T_ref+273.15)/( (T_ref+273.15)*log(R/R_ref)+B)-273.15;

% 画图
water_data = [pH, TDS, COD, T];
categories = ["pH", "TDS","COD","温度"];
figure;
subplot(2,2,1);
bar(water_data(1))
ylim([0, 9]);
yticks(0:9);
set(gca, 'XTickLabel', categories(1))
subplot(2,2,2);
bar(water_data(2))
ylabel("ppm");
ylim([0, 1000]);
yticks(0:200:1000);
set(gca, 'XTickLabel', categories(2))
subplot(2,2,3);
bar(water_data(3))
yticks(0:100:600);
ylabel("mg/L");
ylim([0, 600]);
set(gca, 'XTickLabel', categories(3))
subplot(2,2,4);
bar(water_data(4))
ylim([0, 31]);
yticks(0:3:31);
ylabel("℃");
set(gca, 'XTickLabel', categories(4))
sgtitle('水质检测结果');

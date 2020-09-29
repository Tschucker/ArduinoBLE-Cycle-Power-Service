%% Cycle Power Calculation
clear;

%% Imoport Magnitometer Data
tcalibfile = 'test_data/t_calib.csv';
t1file = 'test_data/t1.csv';
t2file = 'test_data/t2.csv';
t3file = 'test_data/t3.csv';
t4file = 'test_data/t4.csv';
t5file = 'test_data/t5.csv';
t6file = 'test_data/t6.csv';
t7file = 'test_data/t7.csv';
t8file = 'test_data/t8.csv';

tcalib = csvread(tcalibfile);
t1 = csvread(t1file);
t2 = csvread(t2file);
t3 = csvread(t3file);
t4 = csvread(t4file);
t5 = csvread(t5file);
t6 = csvread(t6file);
t7 = csvread(t7file);
t8 = csvread(t8file);

%% Plot Mag Data
figure;
plot(tcalib(:,1))
hold on
plot(tcalib(:,2))
plot(tcalib(:,3))
hold off
legend("X","Y","Z")
title("Calibration Data")

figure;
plot(t1(:,1))
hold on
plot(t1(:,2))
plot(t1(:,3))
hold off
legend("X","Y","Z")
title("Tension 1 Data")

figure;
plot(t2(:,1))
hold on
plot(t2(:,2))
plot(t2(:,3))
hold off
legend("X","Y","Z")
title("Tension 2 Data")

figure;
plot(t3(:,1))
hold on
plot(t3(:,2))
plot(t3(:,3))
hold off
legend("X","Y","Z")
title("Tension 3 Data")

figure;
plot(t4(:,1))
hold on
plot(t4(:,2))
plot(t4(:,3))
hold off
legend("X","Y","Z")
title("Tension 4 Data")

figure;
plot(t5(:,1))
hold on
plot(t5(:,2))
plot(t5(:,3))
hold off
legend("X","Y","Z")
title("Tension 5 Data")

figure;
plot(t6(:,1))
hold on
plot(t6(:,2))
plot(t6(:,3))
hold off
legend("X","Y","Z")
title("Tension 6 Data")

figure;
plot(t7(:,1))
hold on
plot(t7(:,2))
plot(t7(:,3))
hold off
legend("X","Y","Z")
title("Tension 7 Data")

figure;
plot(t8(:,1))
hold on
plot(t8(:,2))
plot(t8(:,3))
hold off
legend("X","Y","Z")
title("Tension 8 Data")

%% Smooth Z Data calb
window = 20;
avecoeffs = ones(1, window)/window;

tcalb_filter_z = filter(avecoeffs, 1, tcalib(:,3));

figure;
plot(tcalb_filter_z)
hold on
%plot(tcalb(:,3))
hold off
title("Filtered Tension Calb Data")

%% Find Cycle Cadence and Power
data = abs(cat(1,t1(:,3),t2(:,3),t3(:,3),t4(:,3),t5(:,3),t6(:,3),t7(:,3),t8(:,3)));
%data = abs(awgn(ones(1,1000),1,'measured'));
length_data = length(data);

curr_min = 100;
curr_max = 0;
i_prev = 0;
point = false;
static = true;
crank_count = zeros(1,length_data-1);
time_stamp = zeros(1,length_data-1);

total_crank_count = 1;

i_diffs = zeros(1,length_data-1);
power = zeros(1,length_data-1);

loggmax = zeros(1,length_data-1);
loggmin = zeros(1,length_data-1);

%calibration adjustment values
mag_samps_per_sec = 16;
mag_power_calib = 100;
cap_power = 400;
decay_factor = 0.5;
noise_factor = 3;

for i = 3:length_data
    tm2 = data(i-2);
    tm1 = data(i-1);
    tm0 = data(i);
    
    if tm2 > curr_max
        curr_max = tm2;
    else
        curr_max = curr_max - decay_factor;
    end
    loggmax(i) = curr_max;
    if tm2 < curr_min
        curr_min = tm2;
    else
        curr_min = curr_min + decay_factor;
    end
    loggmin(i) = curr_min;
    
    if ((tm1-tm2) < 0) && ((tm1-tm0) < 0)
        point = true;
    else
        point = false;
    end
    
    if((mean(loggmax(i-2:i))-mean(loggmin(i-2:i))) < noise_factor)
        static = true;
    else
        static = false;
    end
    
    if (tm1 < (curr_max - curr_min)) && point && (~static)
        i_curr = i-1;
        i_diff = i_curr - i_prev;

        total_crank_count = total_crank_count + 1;
        i_diffs(i_curr) = i_diff;
        
        crank_count(total_crank_count) = mod(crank_count(total_crank_count - 1) + 1,65535);
        time_stamp(total_crank_count) = time_stamp(total_crank_count - 1) + (i_diffs(i_curr)*(1024/mag_samps_per_sec));
        power(i_curr) = (((mag_power_calib - curr_max)^2)*(60/(i_diffs(i_curr)*(1024/mag_samps_per_sec))));
        if power(i_curr) > cap_power
            power(i_curr) = cap_power;
        end
        i_prev = i_curr;
    end 
end

figure;
plot(i_diffs);
title("Time Diffs between Cranks")
hold on
plot(data)
hold off

figure;
plot(loggmax);
title("logged max min")
hold on
plot(loggmin)
plot(data)
hold off

figure;
plot(power)
title("Power")

figure;
plot(crank_count)
title("Cumulative Crank Count")

figure;
plot(time_stamp)
title("Time Stamp")

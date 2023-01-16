close all 
clear variables;
%% bortavao under dagen

cost=(200:1200)';
time=cost./10./0.18./80.*60;
coeff=cost;
coeff(:,1)=(0.010387/1.48204).*cost.*60;  % car (Modell)
coeff(:,2)=0.85./time.*cost.*60; % car (ink segment3/4 Sampers)
coeff(:,3)=1.139./time.*cost.*60; % car (ink segment5/6 Sampers)

figure(1)
plot(cost./10,coeff(:,1)./10,'--')
hold on
plot(cost./10,coeff(:,2:3)./10,'-')
hold off
title('VOT (EUR/h): private daytrip, car')
legend({'Model','Sampers: incSegment medium','Sampers: incSegment high'},'Location','northeast')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([200./10 1200./10 0 1000./10])




coeff(:,1)=(0.001981/1.48204).*cost.*60; % 'bus/train/air (Modell)
coeff(:,2)=(0.7886./time+0.0025)./2.6203.*cost.*60; % 'bus/train/air - (ink segment3/4 Sampers)
coeff(:,3)=(0.7886./time+0.0025)./1.9554.*cost.*60;  % bus/train/air - (ink segment5/6 Sampers)
figure(2)
plot(cost./10,coeff(:,1)./10,'--')
hold on
plot(cost./10,coeff(:,2:3)./10,'-')
hold off
title('VOT (EUR/h): private daytrip, bus/train/air')
legend({'Model','Sampers: incSegment medium','Sampers: incSegment high'},'Location','northeast')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([18 120 0 30])


%% bortavaro 1-5 nätter
% car inVehTime
cost=(180:100:10000)';
coeff=cost;
coeff(:,1)=0.005521./(0.369456./(cost./10)+0.006589).*10.*60;% Modell ink<=700tkr
coeff(:,2)=(0.005521/0.006589*10).*60; % Modell ink>700tkr
coeff(:,3)=0.005521./(0.006589+0.005872).*10.*60; % Modell Modell ink<=700tkr age<18
coeff(:,4)=0.005521./(0.369456./(cost./10)+0.006589+0.005872).*10.*60; % Modell ink>700tkr age<18
coeff(:,5)=0.00618./(0.429./cost+0.0026).*60; % car Modell ink<=500tkr
coeff(:,6)=3.86.*60; % car (Modell ink<=500tkr
figure(3)
plot(cost./10,coeff(:,1:2)./10,'--')
hold on
plot(cost./10,coeff(:,3:4)./10,'*')
hold on
plot(cost./10,coeff(:,5:6)./10,'-')
hold off

title('VOT (EUR/h): Private 1-5 nights, car')
legend({'Model: income <=70TEUR, age>=18','Model: income >70TEUR, age>=18','Model: income <=70TEUR, age<18','Model: income >70TEUR, age<18','Sampers: incSegment medium','Sampers: incSegment high'},'Location','east')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([18 500 0 120])

% bus/train/air/ferry inVehTime
cost=(180:200:10000)';
coeff=cost;
coeff(:,1)=0.001507./(0.369456./(cost./10)+0.006589).*10.*60;% Modell ink<=700tkr
coeff(:,2)=(0.001507/0.006589*10).*60; % Modell ink>700tkr
coeff(:,3)=0.001507./(0.006589+0.005872).*10.*60; % Modell Modell ink<=700tkr age<18
coeff(:,4)=0.001507./(0.369456./(cost./10)+0.006589+0.005872).*10.*60; % Modell ink>700tkr age<18
time=max([(cost-1447)./0.04952.*60./850,zeros(length(cost),1)],[],2);
coeff(:,5)=(0.002452./time+0.0013)./(0.429./cost+0.0026).*60; % car Modell ink<=500tkr
coeff(:,6)=(0.002452./time+0.0013)./0.0016.*60; % car (Modell ink<=500tkr
figure(4)
plot(cost./10,coeff(:,1:2)./10,'--')
hold on
plot(cost./10,coeff(:,3:4)./10,'*')
hold on
plot(cost./10,coeff(:,5:6)./10,'-')
hold off


title('VOT (EUR/h): Private 1-5 nights, bus/train/air/ferry')
legend({'Model: income <=70TEUR, age>=18','Model: income >70TEUR, age>=18','Model: income <=70TEUR, age<18','Model: income >70TEUR, age<18','Sampers: incSegment medium','Sampers: incSegment high'},'Location','east')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([150 1000 0 25])

% % train/air/ferry access/egress
% cost=(180:200:10000)';
% coeff=cost;
% coeff(:,1)=15.3329.*60; % Modell ink<=500tkr, train
% coeff(:,2)=0.012113./(1.046451./(cost./10)+0.002113).*10.*60; % Modell ink>500tkr, train
% coeff(:,3)=7.1937; % Modell ink<=500tkr, air
% coeff(:,4)=0.004588./(1.046451./(cost./10)+0.002113).*10.*60; % Modell ink>500tkr, air
% coeff(:,5)=5.8076; % Modell ink<=500tkr, ferry
% coeff(:,6)=0.005683./(1.046451./(cost./10)+0.002113).*10.*60; % Modell ink>500tkr, ferry
% 
% coeff(:,7)=0.0226./(0.429./cost+0.0026).*60; % car Modell ink<=500tkr
% coeff(:,8)=14.125.*60; % car (Modell ink<=500tkr
% coeff(:,9)=0.0263./(0.429./cost+0.0026).*60; % car Modell ink<=500tkr
% coeff(:,10)=16.4375.*60; % car (Modell ink<=500tkr
% figure(5)
% plot(cost,coeff(:,1:2),'--')
% hold on
% plot(cost,coeff(:,3:4),'-*')
% hold on
% plot(cost,coeff(:,5:6),'*')
% hold on
% plot(cost,coeff(:,7:8),'-')
% hold on
% plot(cost,coeff(:,9:10),'s')
% hold off
% 
% 
% title('VOT (sek/min) acc/egr time: 1-5 nights, train/air/ferry')
% legend({'Model: income <=500tkr, train','Model: income >500tkr, train',...
%         'Model: income <=500tkr, air','Model: income >500tkr, air',...
%         'Model: income <=500tkr, ferry','Model: income >500tkr, ferry',...
%         'Sampers: ink segment3/4, train','Sampers: ink segment 5/6, train',...
%         'Sampers: ink segment3/4, air','Sampers: ink segment 5/6, air'},'Location','east')
% xlabel('cost (sek)') 
% ylabel('VOT (sek/min)') 
% axis([180 10000 0 50])

%% bortavaro 6+ nätter
% car
cost=(180:200:10000)';
coeff=cost;
coeff(:,1)=(0.002999/0.001829*10).*60; % Modell ink<=700tkr
coeff(:,2)=(0.002999/0.00149*10).*60; % Modell ink>700tkr
coeff(:,3)=2.21.*60; % car (ink segment3/4 Sampers)
coeff(:,4)=2.31.*60; % car (ink segment5/6 Sampers)

figure(5)
plot(cost./10,coeff(:,1:2)./10,'--')
hold on
plot(cost./10,coeff(:,3:4)./10,'-')
hold off
title('VOT (EUR/h): Private 6+ nights, car')
legend({'Model: income<=70TEUR','Model: income>70TEUR','Sampers: incSegment medium','Sampers: incSegment high'},'Location','northeast')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([18 1000 0 180])

% bus/train/air/ferry
coeff=cost;
coeff(:,1)=(0.00048/0.001829*10).*60; % Modell ink<=700tkr
coeff(:,2)=(0.00048/0.00149*10).*60; % Modell ink>700tkr
coeff(:,3)=0.91.*60; % car (ink segment3/4 Sampers)
coeff(:,4)=0.95.*60; % car (ink segment5/6 Sampers)

figure(6)
plot(cost./10,coeff(:,1:2)./10,'--')
hold on
plot(cost./10,coeff(:,3:4)./10,'-')
hold off
title('VOT (EUR/h): Private 6+ nights, bus/train/air/ferry')
legend({'Model: income<=70TEUR','Model: income>70TEUR','Sampers: incSegment medium','Sampers: incSegment high'},'Location','northeast')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([18 100 0 30])

%% business model

% car
cost=(1000:200:10000)';
timeCar=cost/1.8/90*60;
coeff=cost;

coeff(:,1)=0.008034./(0.630233./(cost./10)+0.003838).*10.*60;% Modell ink<=700tkr
coeff(:,2)=(0.008034/0.003838*10).*60; % Modell ink>700tkr
coeff(:,3)=(2.22811./timeCar+0.00278)./(0.47312./cost+0.00023).*60; % car (ink segment3/4 Sampers)
coeff(:,4)=(2.22811./timeCar+0.00278)./(0.00007).*60; % car (ink segment5/6 Sampers)

figure(7)
plot(cost./10,coeff(:,1:2)./10,'--')
hold on
plot(cost./10,coeff(:,3)./10,'-')
hold off
title('VOT (EUR/h): Business, car')
legend({'Model: individualIncome<=30TEUR','Model: individualIncome>30TEUR','Sampers: incSegment medium'},'Location','northeast')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([100 1000 0 200])


% bus/train/air/ferry
cost=(1000:200:10000)';
time=max([(cost-1447)./0.04952.*60./850,zeros(length(cost),1)],[],2);
coeff=cost;

coeff(:,1)=0.003916./(0.630233./(cost./10)+0.003838).*10.*60;% Modell ink<=700tkr
coeff(:,2)=(0.003916/0.003838*10).*60; % Modell ink>700tkr
coeff(:,3)=(2.22811./timeCar+0.00278)./(0.47312./cost+0.00023).*60; % car (ink segment3/4 Sampers)
coeff(:,4)=(2.22811./timeCar+0.00278)./(0.00007).*60; % car (ink segment5/6 Sampers)

figure(8)
plot(cost./10,coeff(:,1:2)./10,'--')
hold on
plot(cost./10,coeff(:,3)./10,'-')
hold off
title('VOT (EUR/h): Business, bus/train/air')
legend({'Model: individualIncome<=30TEUR','Model: individualIncome>30TEUR','Sampers: incSegment medium'},'Location','northeast')
xlabel('cost (EUR)') 
ylabel('VOT (EUR/h)') 
axis([100 1000 0 200])

%% business compared to private
% car
cost=(200:200:10000)';
timeCar=cost/1.8/90*60;
coeff=cost;

coeff(:,1)=(0.010387/1.48204).*cost.*60;  % car (Modell)
coeff(:,2)=0.005521./(0.369456./(cost./10)+0.006589).*10.*60;% Modell ink<=700tkr
coeff(:,3)=(0.005521/0.006589*10).*60; % Modell ink>700tkr
coeff(:,4)=(0.002999/0.001829*10).*60; % Modell ink<=700tkr
coeff(:,5)=(0.002999/0.00149*10).*60; % Modell ink>700tkr
coeff(:,6)=0.008034./(0.630233./(cost./10)+0.003838).*10.*60;% Modell ink<=700tkr
coeff(:,7)=(0.008034/0.003838*10).*60; % Modell ink>700tkr
coeff(7:end,1)=nan;

figure(9)
plot(cost,coeff(:,1),'--rs')
hold on
plot(cost,coeff(:,2:3),'--')
hold on
plot(cost,coeff(:,4:5),'-')
hold on
plot(cost,coeff(:,6:7),'*')
hold off
title('coeffficient per sek for VOT (sek/h): Private vs Business, car')
legend({'Private 1 day',...
    'Private 1-5 days: inc<=700tkr','Private 1-5 days: inc>700tkr',...
    'Private 6+ days: inc<=700tkr','Private 6+ days: inc>700tkr',...
    'Business: individualIncome<=300tkr','Business: individualIncome>300tkr'},'Location','northeast')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([200 10000 0 2500])


% bus/train/air/ferry
cost=(200:200:10000)';
time=max([(cost-1447)./0.04952.*60./850,zeros(length(cost),1)],[],2);
coeff=cost;

coeff(:,1)=(0.001981/1.48204).*cost.*60; % 'bus/train/air (Modell)
coeff(:,2)=0.001507./(0.369456./(cost./10)+0.006589).*10.*60;% Modell ink<=700tkr
coeff(:,3)=(0.001507/0.006589*10).*60; % Modell ink>700tkr
coeff(:,4)=(0.00048/0.001829*10).*60; % Modell ink<=700tkr
coeff(:,5)=(0.00048/0.00149*10).*60; % Modell ink>700tkr
coeff(:,6)=0.003916./(0.630233./(cost./10)+0.003838).*10.*60;% Modell ink<=700tkr
coeff(:,7)=(0.003916/0.003838*10).*60; % Modell ink>700tkr
coeff(7:end,1)=nan;

figure(10)
plot(cost,coeff(:,1),'--s')
hold on
plot(cost,coeff(:,2:3),'--')
hold on
plot(cost,coeff(:,4:5),'-')
hold on
plot(cost,coeff(:,6:7),'*')
hold off
title('coeffficient per sek for VOT (sek/h): Private vs Business, bus/train/air/ferry')
legend({'Private 1 day',...
    'Private 1-5 days: inc<=700tkr','Private 1-5 days: inc>700tkr',...
    'Private 6+ days: inc<=700tkr','Private 6+ days: inc>700tkr',...
    'Business: individualIncome<=300tkr','Business: individualIncome>300tkr'},'Location','northeast')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([200 10000 0 1200])
yticks((0:200:1500))
close all 
clear variables;
%% bortavao under dagen

cost=(200:1200)';
time=cost./10./0.18./80.*60;
coeff=cost;
coeff(:,1)=0.02481.*cost.*60;  % car (Modell)
coeff(:,2)=0.85./time.*cost.*60; % car (ink segment3/4 Sampers)
coeff(:,3)=1.139./time.*cost.*60; % car (ink segment5/6 Sampers)

figure(1)
plot(cost,coeff(:,1),'--')
hold on
plot(cost,coeff(:,2:3),'-')
hold off
title('coeffficient per sek for VOT (sek/h): 0 night, car')
legend({'Model','Sampers: ink segment3/4','Sampers: ink segment 5/6'},'Location','northeast')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([200 1200 0 2000])




coeff(:,1)=0.00627.*cost.*60; % 'bus/train (Modell)
coeff(:,2)=(0.7886./time+0.0025)./2.6203.*cost.*60; % 'bus/train/air - (ink segment3/4 Sampers)
coeff(:,3)=(0.7886./time+0.0025)./1.9554.*cost.*60;  % bus/train/air - (ink segment5/6 Sampers)
figure(2)
plot(cost,coeff(:,1),'--')
hold on
plot(cost,coeff(:,2:3),'-')
hold off
title('coeffficient per sek for VOT (sek/h): 0 night, bus/train/air')
legend({'Model','Sampers: ink segment3/4','Sampers: ink segment 5/6'},'Location','northeast')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([180 1200 0 700])


%% bortavaro 1-5 nätter
% car inVehTime
cost=(180:3000)';
coeff=cost;
coeff(:,1)=6.45093.*60; % Modell ink<=500tkr
coeff(:,2)=0.005078./(1.046451./(cost./10)+0.002113).*10.*60; % Modell ink>500tkr
coeff(:,3)=0.00618./(0.429./cost+0.0026).*60; % car Modell ink<=500tkr
coeff(:,4)=3.86.*60; % car (Modell ink<=500tkr
figure(3)
plot(cost,coeff(:,1:2),'--')
hold on
plot(cost,coeff(:,3:4),'-')
hold off

title('coeffficient per sek for VOT (sek/h): 1-5 nights, car')
legend({'Model: income <=500tkr','Model: income >500tkr','Sampers: ink segment3/4','Sampers: ink segment 5/6'},'Location','east')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([180 3000 0 800])

% bus/train/air/ferry inVehTime
cost=(180:10000)';
coeff=cost;
coeff(:,1)=2.0638.*60; % Modell ink<=500tkr
coeff(:,2)=0.001605./(1.046451./(cost./10)+0.002113).*10.*60; % Modell ink>500tkr
time=max([(cost-1447)./0.04952.*60./850,zeros(length(cost),1)],[],2);
coeff(:,3)=(0.002452./time+0.0013)./(0.429./cost+0.0026).*60; % car Modell ink<=500tkr
coeff(:,4)=(0.002452./time+0.0013)./0.0016.*60; % car (Modell ink<=500tkr
figure(4)
plot(cost,coeff(:,1:2),'--')
hold on
plot(cost,coeff(:,3:4),'-')
hold off


title('coeffficient per sek for VOT (sek/h): 1-5 nights, bus/train/air/ferry')
legend({'Model: income <=500tkr','Model: income >500tkr','Sampers: ink segment3/4','Sampers: ink segment 5/6'},'Location','east')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([1500 10000 0 500])

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
cost=(180:10000)';
coeff=cost;
coeff(:,1)=18.06.*60; % Modell ink<=500tkr
coeff(:,2)=28.29.*60; % Modell ink>500tkr
coeff(:,3)=2.21.*60; % car (ink segment3/4 Sampers)
coeff(:,4)=2.31.*60; % car (ink segment5/6 Sampers)

figure(6)
plot(cost,coeff(:,1:2),'--')
hold on
plot(cost,coeff(:,3:4),'-')
hold off
title('coeffficient per sek for VOT (sek/h): 6+ night, car')
legend({'Model: ink<=500tkr','Model: ink>500tkr','Sampers: ink segment3/4','Sampers: ink segment 5/6'},'Location','northeast')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([180 10000 0 2400])

% bus/train/air/ferry
coeff=cost;
coeff(:,1)=4.3.*60; % Modell ink<=500tkr
coeff(:,2)=6.74.*60; % Modell ink>500tkr
coeff(:,3)=0.91.*60; % car (ink segment3/4 Sampers)
coeff(:,4)=0.95.*60; % car (ink segment5/6 Sampers)

figure(7)
plot(cost,coeff(:,1:2),'--')
hold on
plot(time,coeff(:,3:4),'-')
hold off
title('coeffficient per sek for VOT (sek/h): 6+ night, bus/train/air/ferry')
legend({'Model: ink<=500tkr','Model: ink>500tkr','Sampers: ink segment3/4','Sampers: ink segment 5/6'},'Location','northeast')
xlabel('cost (sek)') 
ylabel('VOT (sek/h)') 
axis([180 10000 0 500])

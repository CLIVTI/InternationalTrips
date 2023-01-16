% close all 
% clear variables;
% restoredefaultpath
% RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering_Elasticity.csv';
% 
% opts = detectImportOptions(RVUFilePath);
% RVU=readtable(RVUFilePath,opts);
% 
% %% överdagen
% baselineBortavaro1=table2array(RVU(:,{'bortavaror1_baseline_Probability_car','bortavaror1_baseline_Probability_bus','bortavaror1_baseline_Probability_train','bortavaror1_baseline_Probability_air'}));
% mean(baselineBortavaro1)
% trainCostBortavaro1=table2array(RVU(:,{'bortavaror1_trainCostIncreaseScenario_Probability_car','bortavaror1_trainCostIncreaseScenario_Probability_bus','bortavaror1_trainCostIncreaseScenario_Probability_train','bortavaror1_trainCostIncreaseScenario_Probability_air'}));
% % nanmean((trainCostBortavaro1-baselineBortavaro1)./baselineBortavaro1)
% mean(trainCostBortavaro1)
% trainInVehTimeBortavaro1=table2array(RVU(:,{'bortavaror1_trainInVehTimeDecreaseScenario_Probability_car','bortavaror1_trainInVehTimeDecreaseScenario_Probability_bus','bortavaror1_trainInVehTimeDecreaseScenario_Probability_train','bortavaror1_trainInVehTimeDecreaseScenario_Probability_air'}));
% mean(trainInVehTimeBortavaro1)
% trainCombinedBortavaro1=table2array(RVU(:,{'bortavaror1_trainCombinedScenario_Probability_car','bortavaror1_trainCombinedScenario_Probability_bus','bortavaror1_trainCombinedScenario_Probability_train','bortavaror1_trainCombinedScenario_Probability_air'}));
% mean(trainCombinedBortavaro1)
% 
% %% 1-5 nätter
% baselineBortavaro23=table2array(RVU(:,{'bortavaror23_baseline_Probability_car','bortavaror23_baseline_Probability_bus','bortavaror23_baseline_Probability_train','bortavaror23_baseline_Probability_air','bortavaror23_baseline_Probability_ferry'}));
% mean(baselineBortavaro23)
% trainCostBortavaro23=table2array(RVU(:,{'bortavaror23_trainCostIncreaseScenario_Probability_car','bortavaror23_trainCostIncreaseScenario_Probability_bus','bortavaror23_trainCostIncreaseScenario_Probability_train','bortavaror23_trainCostIncreaseScenario_Probability_air','bortavaror23_trainCostIncreaseScenario_Probability_ferry'}));
% mean(trainCostBortavaro23)
% trainInVehTimeBortavaro23=table2array(RVU(:,{'bortavaror23_trainInVehTimeDecreaseScenario_Probability_car','bortavaror23_trainInVehTimeDecreaseScenario_Probability_bus','bortavaror23_trainInVehTimeDecreaseScenario_Probability_train','bortavaror23_trainInVehTimeDecreaseScenario_Probability_air','bortavaror23_trainInVehTimeDecreaseScenario_Probability_ferry'}));
% mean(trainInVehTimeBortavaro23)
% trainWaitingTimeBortavaro23=table2array(RVU(:,{'bortavaror23_trainWaitingTimeDecreaseScenario_Probability_car','bortavaror23_trainWaitingTimeDecreaseScenario_Probability_bus','bortavaror23_trainWaitingTimeDecreaseScenario_Probability_train','bortavaror23_trainWaitingTimeDecreaseScenario_Probability_air','bortavaror23_trainWaitingTimeDecreaseScenario_Probability_ferry'}));
% mean(trainWaitingTimeBortavaro23)
% trainCombinedBortavaro23=table2array(RVU(:,{'bortavaror23_trainCombinedScenario_Probability_car','bortavaror23_trainCombinedScenario_Probability_bus','bortavaror23_trainCombinedScenario_Probability_train','bortavaror23_trainCombinedScenario_Probability_air','bortavaror23_trainCombinedScenario_Probability_ferry'}));
% mean(trainCombinedBortavaro23)
% 
% %% 6+ nätter
% baselineBortavaro4=table2array(RVU(:,{'bortavaror4_baseline_Probability_car','bortavaror4_baseline_Probability_bus','bortavaror4_baseline_Probability_train','bortavaror4_baseline_Probability_air','bortavaror4_baseline_Probability_ferry'}));
% mean(baselineBortavaro4)
% trainCostBortavaro4=table2array(RVU(:,{'bortavaror4_trainCostIncreaseScenario_Probability_car','bortavaror4_trainCostIncreaseScenario_Probability_bus','bortavaror4_trainCostIncreaseScenario_Probability_train','bortavaror4_trainCostIncreaseScenario_Probability_air','bortavaror4_trainCostIncreaseScenario_Probability_ferry'}));
% mean(trainCostBortavaro4)
% trainInVehTimeBortavaro4=table2array(RVU(:,{'bortavaror4_trainInVehTimeDecreaseScenario_Probability_car','bortavaror4_trainInVehTimeDecreaseScenario_Probability_bus','bortavaror4_trainInVehTimeDecreaseScenario_Probability_train','bortavaror4_trainInVehTimeDecreaseScenario_Probability_air','bortavaror4_trainInVehTimeDecreaseScenario_Probability_ferry'}));
% mean(trainInVehTimeBortavaro4)
% trainWaitingTimeBortavaro4=table2array(RVU(:,{'bortavaror4_trainWaitingTimeDecreaseScenario_Probability_car','bortavaror4_trainWaitingTimeDecreaseScenario_Probability_bus','bortavaror4_trainWaitingTimeDecreaseScenario_Probability_train','bortavaror4_trainWaitingTimeDecreaseScenario_Probability_air','bortavaror4_trainWaitingTimeDecreaseScenario_Probability_ferry'}));
% mean(trainWaitingTimeBortavaro4)
% trainCombinedBortavaro4=table2array(RVU(:,{'bortavaror4_trainCombinedScenario_Probability_car','bortavaror4_trainCombinedScenario_Probability_bus','bortavaror4_trainCombinedScenario_Probability_train','bortavaror4_trainCombinedScenario_Probability_air','bortavaror4_trainCombinedScenario_Probability_ferry'}));
% mean(trainCombinedBortavaro4)
% 
% 
% %% from trip generation
% baselineTripGeneration=table2array(RVU(:,{'Baseline_Probability_NoTrip','Baseline_Probability_UnderDagen','Baseline_Probability_Natter15','Baseline_Probability_Natter6'}));
% baselineBortavaro1(:,5)=0;
% BaselineProbability=baselineTripGeneration(:,2).*baselineBortavaro1+baselineTripGeneration(:,3).*baselineBortavaro23+baselineTripGeneration(:,4).*baselineBortavaro4;
% BaselineProbability=[baselineTripGeneration(:,1),BaselineProbability];
% mean(BaselineProbability)
% 
% costScenarioTripGeneration=table2array(RVU(:,{'CostScenario_Probability_NoTrip','CostScenario_Probability_UnderDagen','CostScenario_Probability_Natter15','CostScenario_Probability_Natter6'}));
% trainCostBortavaro1(:,5)=0;
% costScenarioProbability=costScenarioTripGeneration(:,2).*trainCostBortavaro1+costScenarioTripGeneration(:,3).*trainCostBortavaro23+costScenarioTripGeneration(:,4).*trainCostBortavaro4;
% costScenarioProbability=[costScenarioTripGeneration(:,1),costScenarioProbability];
% mean(costScenarioProbability)
% 
% 
% InvTimeScenarioTripGeneration=table2array(RVU(:,{'InVehTimeScenario_Probability_NoTrip','InVehTimeScenario_Probability_UnderDagen','InVehTimeScenario_Probability_Natter15','InVehTimeScenario_Probability_Natter6'}));
% trainInVehTimeBortavaro1(:,5)=0;
% InvTimeScenarioProbability=InvTimeScenarioTripGeneration(:,2).*trainInVehTimeBortavaro1+InvTimeScenarioTripGeneration(:,3).*trainInVehTimeBortavaro23+InvTimeScenarioTripGeneration(:,4).*trainInVehTimeBortavaro4;
% InvTimeScenarioProbability=[InvTimeScenarioTripGeneration(:,1),InvTimeScenarioProbability];
% mean(InvTimeScenarioProbability)
% 
% 
% WaitingTimeScenarioTripGeneration=table2array(RVU(:,{'WaitingTimeScenario_Probability_NoTrip','WaitingTimeScenario_Probability_UnderDagen','WaitingTimeScenario_Probability_Natter15','WaitingTimeScenario_Probability_Natter6'}));
% WaitingTimeScenarioProbability=WaitingTimeScenarioTripGeneration(:,2).*baselineBortavaro1+WaitingTimeScenarioTripGeneration(:,3).*trainWaitingTimeBortavaro23+WaitingTimeScenarioTripGeneration(:,4).*trainWaitingTimeBortavaro4;
% WaitingTimeScenarioProbability=[WaitingTimeScenarioTripGeneration(:,1),WaitingTimeScenarioProbability];
% mean(WaitingTimeScenarioProbability)
% 
% 
% CombinedScenarioTripGeneration=table2array(RVU(:,{'CombinedScenario_Probability_NoTrip','CombinedScenario_Probability_UnderDagen','CombinedScenario_Probability_Natter15','CombinedScenario_Probability_Natter6'}));
% trainCombinedBortavaro1(:,5)=0;
% CombinedScenarioProbability=CombinedScenarioTripGeneration(:,2).*trainCombinedBortavaro1+CombinedScenarioTripGeneration(:,3).*trainCombinedBortavaro23+CombinedScenarioTripGeneration(:,4).*trainCombinedBortavaro4;
% CombinedScenarioProbability=[CombinedScenarioTripGeneration(:,1),CombinedScenarioProbability];
% mean(CombinedScenarioProbability)
% % for i=1:length(RVU.bortavaror1_baseline_Probability_bus)
% %     ratioCar=(RVU.bortavaror1_trainCostIncreaseScenario_Probability_car(i)-RVU.bortavaror1_baseline_Probability_car(i))/RVU.bortavaror1_baseline_Probability_car(i);
% %     ratioBus=(RVU.bortavaror1_trainCostIncreaseScenario_Probability_bus(i)-RVU.bortavaror1_baseline_Probability_bus(i))/RVU.bortavaror1_baseline_Probability_bus(i);
% %      if (~isnan(ratioCar)&& ~isnan(ratioBus))
% %          ratioCar=floor(ratioCar*100000);
% %          ratioBus=floor(ratioBus*100000);
% %         if (ratioCar~=ratioBus)   
% %             break; 
% %         end
% %     end
% %     
% % end


%% business
close all
clear variables;
restoredefaultpath
RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering_business_Elasticity.csv';

opts = detectImportOptions(RVUFilePath);
RVU=readtable(RVUFilePath,opts);


baseline=table2array(RVU(:,{'baseline_Probability_car','baseline_Probability_bus','baseline_Probability_train','baseline_Probability_air'}));
mean(baseline)
trainCost=table2array(RVU(:,{'trainCostIncreaseScenario_Probability_car','trainCostIncreaseScenario_Probability_bus','trainCostIncreaseScenario_Probability_train','trainCostIncreaseScenario_Probability_air'}));
mean(trainCost)
trainInVehTime=table2array(RVU(:,{'trainInVehTimeDecreaseScenario_Probability_car','trainInVehTimeDecreaseScenario_Probability_bus','trainInVehTimeDecreaseScenario_Probability_train','trainInVehTimeDecreaseScenario_Probability_air'}));
mean(trainInVehTime)
trainWaitingTime=table2array(RVU(:,{'trainWaitingTimeDecreaseScenario_Probability_car','trainWaitingTimeDecreaseScenario_Probability_bus','trainWaitingTimeDecreaseScenario_Probability_train','trainWaitingTimeDecreaseScenario_Probability_air'}));
mean(trainWaitingTime)
trainCombined=table2array(RVU(:,{'trainCombinedScenario_Probability_car','trainCombinedScenario_Probability_bus','trainCombinedScenario_Probability_train','trainCombinedScenario_Probability_air'}));
mean(trainCombined)

baselineTripGeneration=table2array(RVU(:,{'Baseline_Probability_NoTrip','Baseline_Probability_Trip'}));
BaselineProbability=baselineTripGeneration(:,2).*baseline;
BaselineProbability=[baselineTripGeneration(:,1),BaselineProbability];
mean(BaselineProbability)


CostProbability=baselineTripGeneration(:,2).*trainCost;
CostProbability=[baselineTripGeneration(:,1),CostProbability];
mean(CostProbability)


InVTimeProbability=baselineTripGeneration(:,2).*trainInVehTime;
InVTimeProbability=[baselineTripGeneration(:,1),InVTimeProbability];
mean(InVTimeProbability)

WaitingTimeProbability=baselineTripGeneration(:,2).*trainWaitingTime;
WaitingTimeProbability=[baselineTripGeneration(:,1),WaitingTimeProbability];
mean(WaitingTimeProbability)

CombinedProbability=baselineTripGeneration(:,2).*trainCombined;
CombinedProbability=[baselineTripGeneration(:,1),CombinedProbability];
mean(CombinedProbability)
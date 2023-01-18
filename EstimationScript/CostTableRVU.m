close all 
clear variables;
restoredefaultpath
% Important naming convention!!!!!!!!!!!!!
% 1:
% in access PT and mode choice specification, use "alternative_variable name" as beta_names_fix, 
% example
% beta_names_fix.(mode_choice_names{2})={'bike_ASC','bike_age65_84','bike_child7_18','bike_Hog'};  
% X_names_fix.(mode_choice_names{2})={'ASC','age65_84','child7_18','Hog'};

% 2:
% in population synthetic and tillämpning, variables in X_names_fix must be the same.
% example:
% variable name "age65_84" will be used in synthetic population as well as in simulation, so do not use "Age65_84" or
% "age_65_84" in synthetic population, simulation if "age65_84" is used in estimation

% 3: 
% also use ASC for alternative specific constant

% 4:
% using LU_ before the land use name. example: "LU_sumSAMFUNK"
PathStorage='C:/Users/ChengxiL/VTI/Internationella resor - General/Estimation';
addpath(genpath(PathStorage))


%% input file path
% land use:
landUseFilePath='ZonesImputed.csv';
% RVU data:
RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering.csv';

% level-of-service variables
% car
CarTimeFilePath='LOS/Car/CarTime.xlsx';
CarDistancePath='LOS/Car/CarDistanceKM.xlsx';
% bus
BusTimeFilePath='LOS/Bus/TravelTime.xlsx';
BusDistancePath='LOS/Bus/TravelDistanceKM.xlsx';
% Train

TrainInVehicleTimePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/InVehicleTime.xlsx';
TrainFirstWaitTimePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/FirstWaitTime.xlsx';
TrainAccessTimePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/AccessTime.xlsx';
TrainEgressTimePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/EgressTime.xlsx';
TrainDistancePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/InVehDistance.xlsx';
TrainNtransferPath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/NTransfer.xlsx';
TrainTransferWaitTimeInSwedenPath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/TransferWaitTimeWithinSweden.xlsx';
TrainTransferWaitTimeOutSwedenPath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/TransferWaitTimeOutsideSweden.xlsx';
TrainAccessEgressDistancePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/AccessEgressDistance.xlsx';

% Flight
AirInVehicleTimePath='LOS/Air/EMMEWeights/InVehicleTime.xlsx';
AirAccessEgressTimePath='LOS/Air/EMMEWeights/AccessEgressTime.xlsx';
AirCostPath='LOS/Air/EMMEWeights/TicketPrice.xlsx';
AirTransferPath='LOS/Air/EMMEWeights/NumberofFlights.xlsx';

% Ferry
FerryInVehicleTimeFilePath='LOS/Ferry/EMMEWeights/InVehicleTime.xlsx';
FerryHeadwayPath='LOS/Ferry/EMMEWeights/Headway.xlsx';
FerryAccessEgressTimePath='LOS/Ferry/EMMEWeights/AccessEgressTime.xlsx';
FerryCostPath='LOS/Ferry/EMMEWeights/TravelCost.xlsx';
FerryDistancePath='LOS/Ferry/EMMEWeights/TravelDistanceKM_Ferry.xlsx';
DistancePath='LOS/Ferry/EMMEWeights/TravelDistanceKM.xlsx';
FerryNumberLineUsedPath='LOS/Ferry/EMMEWeights/NumberOfFerryLinesUsed.xlsx';
%% model specifications
mode_choice_names={'car','bus','train','air','ferry'};
ModeChoice_varname='Mode';
Origin_varname='D_A_TransCadID';
Destination_varname='D_B_TransCadID';
TripID_varname='TripID';
ZoneID_varname='TransCadID';

%% read the estimation data
opts = detectImportOptions(RVUFilePath);
RVU=readtable(RVUFilePath,opts);
RVU.D_B_TransCadID=RVU.D_B_TransCadID_EU;
RVU.D_B_TransCadID(RVU.D_B_TransCadID==-1)=RVU.D_B_TransCadID_World(RVU.D_B_TransCadID==-1);  % destination variable is D_B_TransCadID

% recode some RVU variables
%party size
RVU.sallskap(isnan(RVU.sallskap))=1.9159;  % this value is the mean of RVU.sallskap
RVU.sallskap(RVU.sallskap>5)=5;  % if its >5 then probabilty the party cant be fitted in a car, just assuming 5 as maximum.
RVU.PartySizeFactor=1./(1+RVU.sallskap);

% number car
RVU.BILANT(isnan(RVU.BILANT))=0;

% income
RVU.lowMediumIncome=RVU.HHINK<700000;
RVU.highIncome=RVU.HHINK>=700000;
RVU.incomeMissing=isnan(RVU.HHINK);
% age
RVU.age17=RVU.AGE<18;
RVU.age1830=RVU.AGE>=18 & RVU.AGE<=30;
RVU.age3164=RVU.AGE>=31 & RVU.AGE<=64;
RVU.age64=RVU.AGE>=65;

% gender
RVU.female=RVU.SEX==2;
% villa or apartment
RVU.VILLA=RVU.VILLA==1;

% arbetsdummy
RVU.WorkDummy=(RVU.D_ARE>=1 & RVU.D_ARE<=5)| (RVU.D_ARE>=80 & RVU.D_ARE<=98);
RVU.NoWorkDummy=1-RVU.WorkDummy;

% we need to recode some stuff to make sure there is 
%  air 55 (canary), move the key to 75. fixed
%  air 54 iceland, fixed
%  air 177 malta to 136,  fixed 
%  141 Corse to 151 fixed
%  ferry 198 Ã…land to 209
% 53 azores, not in the map
% 57 madera to 75 fixed
% car 28 bolivia, probably wrong data 
% car to 310 austrilia, probably wrong data
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==55)=75;
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==57)=75;
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==177)=136;
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==141)=151;
RVU.D_B_TransCadID(RVU.D_B_TransCadID==198)=209;

% car cost
carDistance = xlsread(CarDistancePath) ;
carCost=carDistance;
carCost(2:end,2:end)=carDistance(2:end,2:end).*0.18;
RVUValidCar=RVU(RVU.D_A_TransCadID~=-1 & RVU.D_B_TransCadID~=-1 & RVU.Mode==1,:);
RVUValidCar=joinCost(RVUValidCar,carCost,'carCost');
nanmean(RVUValidCar.carCost)
% bus cost
busDistance = xlsread(BusDistancePath) ;
busCost=busDistance;
busCost(2:end,2:end)=busDistance(2:end,2:end).*0.08;
RVUValidBus=RVU(RVU.D_A_TransCadID~=-1 & RVU.D_B_TransCadID~=-1 & RVU.Mode==2,:);
RVUValidBus=joinCost(RVUValidBus,busCost,'busCost');
nanmean(RVUValidBus.busCost)
%train cost
trainDistance = xlsread(TrainDistancePath) ;
trainAccessEgressDistance = xlsread(TrainAccessEgressDistancePath) ;
trainCost=trainDistance;
trainCost(2:end,2:end)=(trainDistance(2:end,2:end).*0.06492+(1).*13.04077+trainDistance(2:end,2:end).*0.17553+(1).*21.09441)./2+trainAccessEgressDistance(2:end,2:end)*0.18; % average
RVUValidTrain=RVU(RVU.D_A_TransCadID~=-1 & RVU.D_B_TransCadID~=-1 & RVU.Mode==3,:);
RVUValidTrain=joinCost(RVUValidTrain,trainCost,'trainCost');
nanmean(RVUValidTrain.trainCost)
% air cost
airCost = xlsread(AirCostPath);
RVUValidAir=RVU(RVU.D_A_TransCadID~=-1 & RVU.D_B_TransCadID~=-1 & RVU.Mode==4,:);
RVUValidAir=joinCost(RVUValidAir,airCost,'airCost');
nanmean(RVUValidAir.airCost)
% ferry cost
ferryCost = xlsread(FerryCostPath);  %% calculated as for car link, cost=0.18 euro/km, for ferry link, use the ferry line cost: car_HS_H
RVUValidFerry=RVU(RVU.D_A_TransCadID~=-1 & RVU.D_B_TransCadID~=-1 & RVU.Mode==5,:);
RVUValidFerry=joinCost(RVUValidFerry,ferryCost,'ferryCost');
nanmean(RVUValidFerry.ferryCost)
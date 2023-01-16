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
% in population synthetic and simulation, variables in X_names_fix must be the same.
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
RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/DataForTripGenerationEstimation.csv';

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
TrainTransferWaitTimePath='LOS/Train/EMMEWeightsAndBusNetworkAsAccessEgress/TransferWaitTime.xlsx';
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
mode_choice_names={'car','bus','train','air'};
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
% sällskap
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
RVU.ageover17=RVU.AGE>=18;
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


RVU_bortavaror=RVU(RVU.bortavaro==1,:);
RVU_bortavaror=RVU_bortavaror(RVU_bortavaror.Mode<5,:);
count=0;
for i=1:size(RVU_bortavaror,1)
    check=find(RVU_bortavaror.UENR==RVU_bortavaror.UENR(i));
    if length(check)>2
        count=count+1;
    end
end
%% read land use data
opts = detectImportOptions(landUseFilePath);
ZoneData=readtable(landUseFilePath,opts);
ZoneData.Properties.VariableNames{'TransCadUniqueID'} = 'TransCadID';
% % recode the variables into density
% land_use_read.population_density=land_use_read.sumTOTKON./land_use_read.Nrutor_job;
ZoneData=sortrows(ZoneData,'TransCadID');  % important here, you must sort rows to make sure the sams_zone code is sorted
landUseZoneID=ZoneData.TransCadID;
ZoneData.Hotel_beds(ZoneData.Hotel_beds==0)=1000;
ZoneData.Hotel_beds_per_area=ZoneData.Hotel_beds./1000;
ZoneData.Population_per_area=ZoneData.Population./1000;
ZoneData.Employment_per_area=ZoneData.Employment./100000;
ZoneData.GDP_CAP_per_area=ZoneData.GDP_CAP/1000000;
%% specify land use data
% car
zonal_data_car=[];
% zonal_data_car.betaNames={'LU_Population','LU_Employment','LU_Hotel_beds'};
% zonal_data_car.XNames={'Population','Employment','Hotel_beds'};
zonal_data_car.betaNames={'LU_Hotel_beds'};
zonal_data_car.XNames={'Hotel_beds_per_area'};

% bus
zonal_data_bus=[];
zonal_data_bus.betaNames=zonal_data_car.betaNames;
zonal_data_bus.XNames=zonal_data_car.XNames;

% train
zonal_data_train=[];
zonal_data_train.betaNames=zonal_data_car.betaNames;
zonal_data_train.XNames=zonal_data_car.XNames;


% air
zonal_data_air=[];
zonal_data_air.betaNames=zonal_data_car.betaNames;
zonal_data_air.XNames=zonal_data_car.XNames;

% ferry
zonal_data_ferry=[];
zonal_data_ferry.betaNames=zonal_data_car.betaNames;
zonal_data_ferry.XNames=zonal_data_car.XNames;



zonal_varNames=[];
zonal_varNames.(mode_choice_names{1})=zonal_data_car;
zonal_varNames.(mode_choice_names{2})=zonal_data_bus;
zonal_varNames.(mode_choice_names{3})=zonal_data_train;
zonal_varNames.(mode_choice_names{4})=zonal_data_air;
% zonal_varNames.(mode_choice_names{5})=zonal_data_ferry;


%% read the level-of-service variables
DestinationZoneIDs=ZoneData.TransCadID;
SemesterZone=ZoneData.SemesterZone;
GDP_CAP=ZoneData.GDP_CAP/100000;
NoDKZones=ZoneData.NODKDummy;
% car time and cost
carTime = xlsread(CarTimeFilePath);
carTimeLog=carTime;
carTimeLog(2:end,2:end)=log(carTimeLog(2:end,2:end));

carDistance = xlsread(CarDistancePath) ;
carCost=carDistance;
carCost(2:end,2:end)=carDistance(2:end,2:end).*0.18;
carCostLog=carCost;
carCostLog(2:end,2:end)=log(carCost(2:end,2:end)+0.01);


% create destinatoion zone dymmy
carDestinationZoneIDs=carTime(1,2:end);
SemesterZonesDummy=zeros(1,length(carDestinationZoneIDs));
GDPPerCapita=zeros(1,length(carDestinationZoneIDs));
NoDKWork=zeros(1,length(carDestinationZoneIDs));
for i=1:length(carDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==carDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==carDestinationZoneIDs(i));
    NoDKWork(i)=NoDKZones(DestinationZoneIDs==carDestinationZoneIDs(i));
end
SemesterZonesMatrixCar=carTime;
SemesterZonesMatrixCar(2:end,2:end)=SemesterZonesDummy(ones(size(carTime,1)-1,1),:);
GDPPerCapitaMatrixCar=carTime;
GDPPerCapitaMatrixCar(2:end,2:end)=GDPPerCapita(ones(size(carTime,1)-1,1),:);
NoDKZonesMatrixCar=carTime;
NoDKZonesMatrixCar(2:end,2:end)=NoDKWork(ones(size(carTime,1)-1,1),:);

for i=1:(size(carDistance,1)-1)
    noUsedIndex=carDistance(i+1,:)<100 | carTime(i+1,:)>480;
    noUsedIndex(1)=0;
    SemesterZonesMatrixCar(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixCar(i+1,noUsedIndex)=nan;
    NoDKWork(i+1,noUsedIndex)=nan;
    carTime(i+1,noUsedIndex)=nan;
    carTimeLog(i+1,noUsedIndex)=nan;
    carCost(i+1,noUsedIndex)=nan;
    carCostLog(i+1,noUsedIndex)=nan;
end

% bus time and cost
busTime = xlsread(BusTimeFilePath) ;
busTimeLog=busTime;
busTimeLog(2:end,2:end)=log(busTime(2:end,2:end));

busDistance = xlsread(BusDistancePath) ;
busCost=busDistance;
busCost(2:end,2:end)=busDistance(2:end,2:end).*0.08;
busCostLog=busCost;
busCostLog(2:end,2:end)=log(busCost(2:end,2:end)+0.01);


% create destinatoion zone dymmy
busDestinationZoneIDs=busTime(1,2:end);
SemesterZonesDummy=zeros(1,length(busDestinationZoneIDs));
GDPPerCapita=zeros(1,length(busDestinationZoneIDs));
NoDKWork=zeros(1,length(busDestinationZoneIDs));
for i=1:length(busDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==busDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==busDestinationZoneIDs(i));
    NoDKWork(i)=NoDKZones(DestinationZoneIDs==busDestinationZoneIDs(i));
end
SemesterZonesMatrixBus=busTime;
SemesterZonesMatrixBus(2:end,2:end)=SemesterZonesDummy(ones(size(busTime,1)-1,1),:);
GDPPerCapitaMatrixBus=busTime;
GDPPerCapitaMatrixBus(2:end,2:end)=GDPPerCapita(ones(size(busTime,1)-1,1),:);
NoDKZonesMatrixBus=busTime;
NoDKZonesMatrixBus(2:end,2:end)=NoDKWork(ones(size(busTime,1)-1,1),:);

for i=1:(size(busDistance,1)-1)
    noUsedIndex=busDistance(i+1,:)<100 | busTime(i+1,:)>480;
    noUsedIndex(1)=0;
    SemesterZonesMatrixBus(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixBus(i+1,noUsedIndex)=nan;
    NoDKZonesMatrixBus(i+1,noUsedIndex)=nan;
    busTime(i+1,noUsedIndex)=nan;
    busTimeLog(i+1,noUsedIndex)=nan;
    busCost(i+1,noUsedIndex)=nan;
    busCostLog(i+1,noUsedIndex)=nan;
end

% train impedance and cost
% TrainInVehicleTimePath='LOS/Train/InVehicleTime.xlsx';
% TrainFirstWaitTimePath='LOS/Train/FirstWaitTime.xlsx';
% TrainAccessTimePath='LOS/Train/AccessTime.xlsx';
% TrainEgressTimePath='LOS/Train/EgressTime.xlsx';




TrainInVehicleTime= xlsread(TrainInVehicleTimePath) ;
TrainFirstWaitTime=xlsread(TrainFirstWaitTimePath) ;
TrainTransferWaitTime=xlsread(TrainTransferWaitTimePath);
TrainTransferWaitTimeInSweden=xlsread(TrainTransferWaitTimeInSwedenPath);
TrainTransferWaitTimeOutSweden=xlsread(TrainTransferWaitTimeOutSwedenPath);
TrainTransferWaitTimeOutSweden_reduce=TrainTransferWaitTimeOutSweden;
TrainTransferWaitTimeOutSweden_reduce(2:end,2:end)=TrainTransferWaitTimeOutSweden(2:end,2:end)*0.9;
TrainAccessTime=xlsread(TrainAccessTimePath) ;
TrainEgressTime=xlsread(TrainEgressTimePath) ;
TrainAccessEgressTime=TrainAccessTime;
TrainAccessEgressTime(2:end,2:end)=TrainAccessTime(2:end,2:end)+TrainEgressTime(2:end,2:end);
TrainTotalTime=TrainInVehicleTime;
TrainTotalTime(2:end,2:end)=TrainInVehicleTime(2:end,2:end)+TrainFirstWaitTime(2:end,2:end)+TrainAccessEgressTime(2:end,2:end);
TrainWeightedTotalTime=TrainInVehicleTime;
TrainWeightedTotalTime(2:end,2:end)=TrainInVehicleTime(2:end,2:end)+3*TrainAccessEgressTime(2:end,2:end);
TrainWeightedTotalTime_InVehReduce=TrainInVehicleTime;
TrainWeightedTotalTime_InVehReduce(2:end,2:end)=TrainInVehicleTime(2:end,2:end)*0.9+3*TrainAccessEgressTime(2:end,2:end);
trainDistance = xlsread(TrainDistancePath) ;
trainAccessEgressDistance = xlsread(TrainAccessEgressDistancePath) ;

trainCost=trainDistance;
trainNTransfer=xlsread(TrainNtransferPath) ;
% trainCost(2:end,2:end)=trainDistance(2:end,2:end).*0.17553+(1).*21.09441; % high
% trainCost(2:end,2:end)=trainDistance(2:end,2:end).*0.06492+(1).*13.04077; % low
trainCost(2:end,2:end)=(trainDistance(2:end,2:end).*0.06492+(1).*13.04077+trainDistance(2:end,2:end).*0.17553+(1).*21.09441)./2+trainAccessEgressDistance(2:end,2:end)*0.18; % average
% trainCost(2:end,2:end)=trainDistance(2:end,2:end).*0.087953; % low no intercept
% trainCost(2:end,2:end)=trainDistance(2:end,2:end).*(0.087953+0.212784)./2; % average low and high no intercept
trainCost_increase=trainCost;
trainCost_increase(2:end,2:end)=1.1*trainCost(2:end,2:end);
% create destinatoion zone dymmy
trainDestinationZoneIDs=TrainInVehicleTime(1,2:end);
SemesterZonesDummy=zeros(1,length(trainDestinationZoneIDs));
GDPPerCapita=zeros(1,length(trainDestinationZoneIDs));
NoDKWork=zeros(1,length(trainDestinationZoneIDs));
for i=1:length(trainDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==trainDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==trainDestinationZoneIDs(i));
    NoDKWork(i)=NoDKZones(DestinationZoneIDs==trainDestinationZoneIDs(i));
end
SemesterZonesMatrixTrain=TrainInVehicleTime;
SemesterZonesMatrixTrain(2:end,2:end)=SemesterZonesDummy(ones(size(TrainInVehicleTime,1)-1,1),:);
GDPPerCapitaMatrixTrain=TrainInVehicleTime;
GDPPerCapitaMatrixTrain(2:end,2:end)=GDPPerCapita(ones(size(TrainInVehicleTime,1)-1,1),:);
NoDKZonesMatrixTrain=TrainInVehicleTime;
NoDKZonesMatrixTrain(2:end,2:end)=NoDKWork(ones(size(TrainInVehicleTime,1)-1,1),:);

for i=1:(size(trainDistance,1)-1)
    noUsedIndex=trainCost(i+1,:)==0 | trainDistance(i+1,:)<100 | TrainTotalTime(i+1,:)>480;
    noUsedIndex(1)=0;
    SemesterZonesMatrixTrain(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixTrain(i+1,noUsedIndex)=nan;
    NoDKZonesMatrixTrain(i+1,noUsedIndex)=nan;
    TrainWeightedTotalTime(i+1,noUsedIndex)=nan;
    TrainWeightedTotalTime_InVehReduce(i+1,noUsedIndex)=nan;
    trainCost_increase(i+1,noUsedIndex)=nan;
    TrainInVehicleTime(i+1,noUsedIndex)=nan;
    TrainFirstWaitTime(i+1,noUsedIndex)=nan;
    TrainTransferWaitTime(i+1,noUsedIndex)=nan;
    TrainTransferWaitTimeInSweden(i+1,noUsedIndex)=nan;
    TrainTransferWaitTimeOutSweden(i+1,noUsedIndex)=nan;
    TrainTransferWaitTimeOutSweden_reduce(i+1,noUsedIndex)=nan;
    TrainAccessEgressTime(i+1,noUsedIndex)=nan;
    trainNTransfer(i+1,noUsedIndex)=nan;
end

TrainInVehicleTimeLog=TrainInVehicleTime;
TrainInVehicleTimeLog(2:end,2:end)=log(TrainInVehicleTime(2:end,2:end)+0.01);
trainCostLog=trainCost;
trainCostLog(2:end,2:end)=log(trainCost(2:end,2:end)+0.01);
trainCostLog_increase=trainCost_increase;
trainCostLog_increase(2:end,2:end)=log(trainCost_increase(2:end,2:end)+0.01);
% flight time and cost

% AirInVehicleTimePath='LOS/Air/InVehicleTime.xlsx';
% AirAccessEgressTimePath='LOS/Air/AccessEgressTime.xlsx';
% AirCostPath='LOS/Air/TicketPrice.xlsx';
% AirTransferPath='LOS/Air/NumberofFlights.xlsx';
AirInVehicleTime = xlsread(AirInVehicleTimePath) ;
AirAccessEgressTime= xlsread(AirAccessEgressTimePath) ;
AirTotalTime=AirInVehicleTime;
AirTotalTime(2:end,2:end)=AirInVehicleTime(2:end,2:end)+AirAccessEgressTime(2:end,2:end);
AirWeightedTotalTime=AirInVehicleTime;
AirWeightedTotalTime(2:end,2:end)=AirInVehicleTime(2:end,2:end)+2.*AirAccessEgressTime(2:end,2:end);
airCost = xlsread(AirCostPath);
airNTransfer = xlsread(AirTransferPath);
airTransferWaitingtime=airNTransfer;
airTransferWaitingtime(2:end,2:end)=(airNTransfer(2:end,2:end)-1).*60;
% create destinatoion zone dymmy
airDestinationZoneIDs=AirInVehicleTime(1,2:end);
SemesterZonesDummy=zeros(1,length(airDestinationZoneIDs));
GDPPerCapita=zeros(1,length(airDestinationZoneIDs));
NoDKWork=zeros(1,length(airDestinationZoneIDs));
for i=1:length(airDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==airDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==airDestinationZoneIDs(i));
    NoDKWork(i)=NoDKZones(DestinationZoneIDs==airDestinationZoneIDs(i));
end
SemesterZonesMatrixAir=AirInVehicleTime;
SemesterZonesMatrixAir(2:end,2:end)=SemesterZonesDummy(ones(size(AirInVehicleTime,1)-1,1),:);
GDPPerCapitaMatrixAir=AirInVehicleTime;
GDPPerCapitaMatrixAir(2:end,2:end)=GDPPerCapita(ones(size(AirInVehicleTime,1)-1,1),:);
NoDKZonesMatrixAir=AirInVehicleTime;
NoDKZonesMatrixAir(2:end,2:end)=NoDKWork(ones(size(AirInVehicleTime,1)-1,1),:);

for i=1:(size(airCost,1)-1)
    noUsedIndex=airNTransfer(i+1,:)==0 | AirInVehicleTime(i+1,:)<100/850*60 | AirTotalTime(i+1,:)>480;
    noUsedIndex(1)=0;
    SemesterZonesMatrixAir(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixAir(i+1,noUsedIndex)=nan;
    NoDKZonesMatrixAir(i+1,noUsedIndex)=nan;
    AirInVehicleTime(i+1,noUsedIndex)=nan;
    AirWeightedTotalTime(i+1,noUsedIndex)=nan;
    airCost(i+1,noUsedIndex)=nan;
    AirAccessEgressTime(i+1,noUsedIndex)=nan;
    airNTransfer(i+1,noUsedIndex)=nan;
    airTransferWaitingtime(i+1,noUsedIndex)=nan;
end
airNTransfer(2:end,2:end)=airNTransfer(2:end,2:end)-1;
AirInVehicleTimeLog=AirInVehicleTime;
AirInVehicleTimeLog(2:end,2:end)=log(AirInVehicleTime(2:end,2:end)+0.01);
airCostLog=airCost;
airCostLog(2:end,2:end)=log(airCost(2:end,2:end)+0.01);

% ferry
% FerryInVehicleTimeFilePath='LOS/Ferry/InVehicleTime.xlsx';
% FerryHeadwayPath='LOS/Ferry/Headway.xlsx';
% FerryAccessEgressTimePath='LOS/Ferry/AccessEgressTime.xlsx';
% FerryCostPath='LOS/Ferry/TravelCost.xlsx';
% FerryDistancePath='LOS/Ferry/TravelDistanceKM_Ferry.xlsx';
% DistancePath='LOS/Ferry/TravelDistanceKM.xlsx';
% FerryNumberLineUsedPath='LOS/Ferry/NumberOfFerryLinesUsed.xlsx';



FerryInVehicleTime = xlsread(FerryInVehicleTimeFilePath) ;
FerryFirstWaitTime=xlsread(FerryHeadwayPath) ;
FerryFirstWaitTime(2:end,2:end)=FerryFirstWaitTime(2:end,2:end)./2;
FerryAccessEgressTime=xlsread(FerryAccessEgressTimePath) ;
FerryTotalTime=FerryInVehicleTime;
FerryTotalTime(2:end,2:end)=FerryInVehicleTime(2:end,2:end)+FerryAccessEgressTime(2:end,2:end);
ferryCost = xlsread(FerryCostPath);  %% calculated as for car link, cost=0.18 euro/km, for ferry link, use the ferry line cost: car_HS_H
FerryDistance = xlsread(FerryDistancePath);
FerryDistanceFullTrip= xlsread(DistancePath);
ferryNTransfer=xlsread(FerryNumberLineUsedPath);


% create destinatoion zone dymmy
ferryDestinationZoneIDs=FerryInVehicleTime(1,2:end);
SemesterZonesDummy=zeros(1,length(ferryDestinationZoneIDs));
GDPPerCapita=zeros(1,length(ferryDestinationZoneIDs));
for i=1:length(ferryDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==ferryDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==ferryDestinationZoneIDs(i));
end
SemesterZonesMatrixFerry=FerryInVehicleTime;
SemesterZonesMatrixFerry(2:end,2:end)=SemesterZonesDummy(ones(size(FerryInVehicleTime,1)-1,1),:);
GDPPerCapitaMatrixFerry=FerryInVehicleTime;
GDPPerCapitaMatrixFerry(2:end,2:end)=GDPPerCapita(ones(size(FerryInVehicleTime,1)-1,1),:);
% we assume that if there is no ferry line used, the destination is not available, code as nan.
for i=1:(size(ferryNTransfer,1)-1)
    % noFerryUsedIndex=ferryNTransfer(i+1,:)==0 | FerryDistanceFullTrip(i+1,:)<100 | FerryTotalTime(i+1,:)>480 | FerryDistance(i+1,:)./FerryDistanceFullTrip(i+1,:)<0.5;
    noFerryUsedIndex=ferryNTransfer(i+1,:)==0 | FerryDistanceFullTrip(i+1,:)<100 | FerryTotalTime(i+1,:)>480;
    noFerryUsedIndex(1)=0;
    SemesterZonesMatrixFerry(i+1,noFerryUsedIndex)=nan;
    GDPPerCapitaMatrixFerry(i+1,noFerryUsedIndex)=nan;
    FerryInVehicleTime(i+1,noFerryUsedIndex)=nan;
    ferryCost(i+1,noFerryUsedIndex)=nan;
    FerryFirstWaitTime(i+1,noFerryUsedIndex)=nan;
    FerryAccessEgressTime(i+1,noFerryUsedIndex)=nan;
    ferryNTransfer(i+1,noFerryUsedIndex)=nan;
end
ferryNTransfer(2:end,2:end)=ferryNTransfer(2:end,2:end)-1;
FerryInVehicleTimeLog=FerryInVehicleTime;
FerryInVehicleTimeLog(2:end,2:end)=log(FerryInVehicleTime(2:end,2:end));
ferryCostLog=ferryCost;
ferryCostLog(2:end,2:end)=log(ferryCost(2:end,2:end)+0.01);
%% specify LOS variables
% summarize to one structure as model input

% car
% make sure always using "travelCost" as variable name to denote cost as this is used to notify this is the cost
% variable for car since we need to divide the car cost by party size
level_of_service_var_car=[];
% level_of_service_var_car.SemesterZone_WorkDummy=SemesterZonesMatrixCar;
level_of_service_var_car.SemesterZone_NoWorkDummy=SemesterZonesMatrixCar;
% level_of_service_var_car.NODKZones_WorkDummy=NoDKZonesMatrixCar;
% level_of_service_var_car.GDPPerCapita=GDPPerCapitaMatrixCar;
level_of_service_var_car.carTravelTime=carTime;
% level_of_service_var_car.carTravelTime_WorkDummy=carTime;
% level_of_service_var_car.carTravelTime_NoWorkDummy=carTime;
% level_of_service_var_car.carLogTravelTime=carTimeLog;
% level_of_service_var_car.travelCost=carCost;
% level_of_service_var_car.travelCostLog_ageover17=carCostLog;
% level_of_service_var_car.travelCostLog_age17=carCostLog;
level_of_service_var_car.travelCostLog=carCostLog;
% level_of_service_var_car.travelCost_highIncome=carCost;
% level_of_service_var_car.travelCost_incomeMissing=carCost;
% level_of_service_var_car.travelCostLog_lowMediumIncome=carCostLog;
% level_of_service_var_car.travelCostLog_highIncome=carCostLog;
% level_of_service_var_car.travelCost_WorkDummy=carCost;
% level_of_service_var_car.travelCost_NoWorkDummy=carCost;

% bus
level_of_service_var_bus=[];
% level_of_service_var_bus.SemesterZone_WorkDummy=SemesterZonesMatrixBus;
level_of_service_var_bus.SemesterZone_NoWorkDummy=SemesterZonesMatrixBus;
% level_of_service_var_bus.NODKZones_WorkDummy=NoDKZonesMatrixBus;
% level_of_service_var_bus.GDPPerCapita=GDPPerCapitaMatrixBus;
level_of_service_var_bus.inVehicleTimeBusTrainAir=busTime;
% level_of_service_var_bus.logInVehicleTimeBusTrainAirFerry=busTimeLog;
% level_of_service_var_bus.travelCost=busCost;
% level_of_service_var_bus.travelCostLog_ageover17=busCostLog;
% level_of_service_var_bus.travelCostLog_age17=busCostLog;
level_of_service_var_bus.travelCostLog=busCostLog;
% level_of_service_var_bus.travelCost_highIncome=busCost;
% level_of_service_var_bus.travelCost_incomeMissing=busCost;
% level_of_service_var_bus.travelCostLog_lowMediumIncome=busCostLog;
% level_of_service_var_bus.travelCostLog_highIncome=busCostLog;
% level_of_service_var_bus.travelCost_WorkDummy=busCost;
% level_of_service_var_bus.travelCost_NoWorkDummy=busCost;

% train
level_of_service_var_train=[];
% level_of_service_var_train.SemesterZone_WorkDummy=SemesterZonesMatrixTrain;
level_of_service_var_train.SemesterZone_NoWorkDummy=SemesterZonesMatrixTrain;
% level_of_service_var_train.NODKZones_WorkDummy=NoDKZonesMatrixTrain;
% level_of_service_var_train.GDPPerCapita=GDPPerCapitaMatrixTrain;
% level_of_service_var_train.accessEgressTimeTrainAir=TrainAccessEgressTime;
% level_of_service_var_train.firstWaitTimeTrain=TrainFirstWaitTime;
% level_of_service_var_train.numberTransferTrain=trainNTransfer;
% level_of_service_var_train.transferWaitTimeTrain=TrainTransferWaitTime;
% level_of_service_var_train.transferWaitTimeInSwedenTrain=TrainTransferWaitTimeInSweden;
% level_of_service_var_train.transferWaitTimeOutSwedenTrain=TrainTransferWaitTimeOutSweden;

% level_of_service_var_train.inVehicleTimeBusTrain=TrainInVehicleTime;
level_of_service_var_train.inVehicleTimeBusTrainAir=TrainWeightedTotalTime;

% level_of_service_var_train.logInVehicleTimeBusTrainAirFerry=TrainInVehicleTimeLog;

% level_of_service_var_train.travelCost=trainCost;
% level_of_service_var_train.travelCostLog_ageover17=trainCostLog;
% level_of_service_var_train.travelCostLog_age17=trainCostLog;
level_of_service_var_train.travelCostLog=trainCostLog;
% level_of_service_var_train.travelCost_highIncome=trainCost;
% level_of_service_var_train.travelCost_incomeMissing=trainCost;
% level_of_service_var_train.travelCostLog_lowMediumIncome=trainCostLog;
% level_of_service_var_train.travelCostLog_highIncome=trainCostLog;
% level_of_service_var_train.travelCost_WorkDummy=trainCost;
% level_of_service_var_train.travelCost_NoWorkDummy=trainCost;

% flight
level_of_service_var_air=[];
% % split airTime for EU and international,

% airTimeEU=AirInVehicleTime;
% airTimeInternational=AirInVehicleTime;
% for i=1:(size(AirInVehicleTime,2)-1)
%     destinationCode=AirInVehicleTime(1,i+1);
%     if ZoneData.WorldDummy(ismember(landUseZoneID,destinationCode))==1 %% its international
%         airTimeEU(2:end,i+1)=0;
%     else %% its EU
%         airTimeInternational(2:end,i+1)=0;
%     end
% end
%
% airTime_threshold1=AirInVehicleTime;
% airTime_threshold2=AirInVehicleTime;
% for i=1:(size(airTime_threshold1,1)-1)
%     airTime_threshold1(i+1,airTime_threshold1(i+1,:)>=300)=0;
%     airTime_threshold2(i+1,airTime_threshold2(i+1,:)<300)=0;
% end
% airTime_threshold1(:,1)=AirInVehicleTime(:,1);
% airTime_threshold2(:,1)=AirInVehicleTime(:,1);

% level_of_service_var_air.SemesterZone_WorkDummy=SemesterZonesMatrixAir;
level_of_service_var_air.SemesterZone_NoWorkDummy=SemesterZonesMatrixAir;
% level_of_service_var_air.NODKZones_WorkDummy=NoDKZonesMatrixAir;
% level_of_service_var_air.GDPPerCapita=GDPPerCapitaMatrixAir;
% level_of_service_var_air.accessEgressTimeTrainAir=AirAccessEgressTime;
% level_of_service_var_air.numberTransferAir=airNTransfer;
% level_of_service_var_air.transferWaitTimeOutSwedenAir=airTransferWaitingtime;

% level_of_service_var_air.inVehicleTimeAir=AirInVehicleTime;
level_of_service_var_air.inVehicleTimeBusTrainAir=AirWeightedTotalTime;
% level_of_service_var_air.logInVehicleTimeBusTrainAirFerry=AirInVehicleTimeLog;
% level_of_service_var_air.travelCost=airCost;
% level_of_service_var_air.travelCostLog_ageover17=airCostLog;
% level_of_service_var_air.travelCostLog_age17=airCostLog;
level_of_service_var_air.travelCostLog=airCostLog;
% level_of_service_var_air.travelCost_lowMediumIncome=airCost;
% level_of_service_var_air.travelCost_highIncome=airCost;
% level_of_service_var_air.travelCost_incomeMissing=airCost;
% level_of_service_var_air.travelCostLog_lowMediumIncome=airCostLog;
% level_of_service_var_air.travelCostLog_highIncome=airCostLog;
% level_of_service_var_air.travelCost_WorkDummy=airCost;
% level_of_service_var_air.travelCost_NoWorkDummy=airCost;

%
% % ferry
% level_of_service_var_ferry=[];
% level_of_service_var_ferry.SemesterZone=SemesterZonesMatrixFerry;
% % level_of_service_var_ferry.GDPPerCapita=GDPPerCapitaMatrixFerry;
% level_of_service_var_ferry.accessEgressTimeTrainAirFerry=FerryAccessEgressTime;
% % level_of_service_var_ferry.firstWaitTimeTrainFerry=FerryFirstWaitTime;
% % level_of_service_var_ferry.numberTransferFerry=ferryNTransfer;
% level_of_service_var_ferry.inVehicleTimeBusTrainFerry=FerryInVehicleTime;
% % level_of_service_var_ferry.logInVehicleTimeBusTrainAirFerry=FerryInVehicleTimeLog;
% level_of_service_var_ferry.travelCostLog=ferryCostLog;
% % level_of_service_var_ferry.travelCost_lowMediumIncome=ferryCost;
% % level_of_service_var_ferry.travelCost_highIncome=ferryCost;
% % level_of_service_var_ferry.travelCost_incomeMissing=ferryCost;
% % level_of_service_var_ferry.travelCostLog_lowMediumIncome=ferryCostLog;
% % level_of_service_var_ferry.travelCostLog_highIncome=ferryCostLog;



level_of_service_var=[];
level_of_service_var.(mode_choice_names{1})=level_of_service_var_car;
level_of_service_var.(mode_choice_names{2})=level_of_service_var_bus;
level_of_service_var.(mode_choice_names{3})=level_of_service_var_train;
level_of_service_var.(mode_choice_names{4})=level_of_service_var_air;
% level_of_service_var.(mode_choice_names{5})=level_of_service_var_ferry;
%% specify mode choice part

% all variable names {'female','VILLA','age_64','age_18_30','age_17','BILANT'}
beta_names_fix.(mode_choice_names{1})={'NcarInHH','bil_female'};   % walk
X_names_fix.(mode_choice_names{1})={'BILANT','female'};  % walk

beta_names_fix.(mode_choice_names{2})={'bus_ASC'};
X_names_fix.(mode_choice_names{2})={'ASC'};

beta_names_fix.(mode_choice_names{3})={'train_ASC','train_age_64'};
X_names_fix.(mode_choice_names{3})={'ASC','age64'};

beta_names_fix.(mode_choice_names{4})={'air_ASC'};
X_names_fix.(mode_choice_names{4})={'ASC'};

% beta_names_fix.(mode_choice_names{5})={'ferry_ASC','ferry_age_17','ferry_age_64'};
% X_names_fix.(mode_choice_names{5})={'ASC','age_17','age_64'};


model_specification_modeChoice=[];
model_specification_modeChoice.beta_names=beta_names_fix;
model_specification_modeChoice.X_names=X_names_fix;
model_specification_modeChoice.Y_names=ModeChoice_varname;
model_specification_modeChoice.choice_name=mode_choice_names;

%
final_result_bortavaror_4=NL_model_joint_estimation_log_zonal_flexible(RVU_bortavaror,...
    RVU,...
    model_specification_modeChoice,...
    ZoneData,...
    ZoneID_varname,...
    zonal_varNames,...
    level_of_service_var,...
    TripID_varname,...
    Origin_varname,...
    Destination_varname);


RVU.logsumBortavaro_1=final_result_bortavaror_4.logsum;





%
predictionBaseline=Apply_NL_model(final_result_bortavaror_4,...
    RVU_bortavaror,...
    RVU,...
    model_specification_modeChoice,...
    ZoneData,...
    ZoneID_varname,...
    zonal_varNames,...
    level_of_service_var,...
    TripID_varname,...
    Origin_varname,...
    Destination_varname);
RVU.bortavaror1_baseline_Probability_car=predictionBaseline.probability_fullData(:,1);
RVU.bortavaror1_baseline_Probability_bus=predictionBaseline.probability_fullData(:,2);
RVU.bortavaror1_baseline_Probability_train=predictionBaseline.probability_fullData(:,3);
RVU.bortavaror1_baseline_Probability_air=predictionBaseline.probability_fullData(:,4);

% scenario of train cost +10%
level_of_service_var_scenario=level_of_service_var;
level_of_service_var_scenario.train.travelCostLog=trainCostLog_increase;
prediction_scenario=Apply_NL_model(final_result_bortavaror_4,...
    RVU_bortavaror,...
    RVU,...
    model_specification_modeChoice,...
    ZoneData,...
    ZoneID_varname,...
    zonal_varNames,...
    level_of_service_var_scenario,...
    TripID_varname,...
    Origin_varname,...
    Destination_varname);
RVU.bortavaror1_trainCostIncreaseScenario_Probability_car=prediction_scenario.probability_fullData(:,1);
RVU.bortavaror1_trainCostIncreaseScenario_Probability_bus=prediction_scenario.probability_fullData(:,2);
RVU.bortavaror1_trainCostIncreaseScenario_Probability_train=prediction_scenario.probability_fullData(:,3);
RVU.bortavaror1_trainCostIncreaseScenario_Probability_air=prediction_scenario.probability_fullData(:,4);
RVU.bortavaror1_trainCostIncreaseScenario_logsum=prediction_scenario.logsum_fullData;
% scenario of train invehicle time -10%
level_of_service_var_scenario=level_of_service_var;
level_of_service_var_scenario.train.inVehicleTimeBusTrainAir=TrainWeightedTotalTime_InVehReduce;
prediction_scenario=Apply_NL_model(final_result_bortavaror_4,...
    RVU_bortavaror,...
    RVU,...
    model_specification_modeChoice,...
    ZoneData,...
    ZoneID_varname,...
    zonal_varNames,...
    level_of_service_var_scenario,...
    TripID_varname,...
    Origin_varname,...
    Destination_varname);
RVU.bortavaror1_trainInVehTimeDecreaseScenario_Probability_car=prediction_scenario.probability_fullData(:,1);
RVU.bortavaror1_trainInVehTimeDecreaseScenario_Probability_bus=prediction_scenario.probability_fullData(:,2);
RVU.bortavaror1_trainInVehTimeDecreaseScenario_Probability_train=prediction_scenario.probability_fullData(:,3);
RVU.bortavaror1_trainInVehTimeDecreaseScenario_Probability_air=prediction_scenario.probability_fullData(:,4);
RVU.bortavaror1_trainInVehTimeDecreaseScenario_logsum=prediction_scenario.logsum_fullData;

% scenario of train waitingTime -10%
RVU.bortavaror1_trainWaitingTimeDecreaseScenario_Probability_car=predictionBaseline.probability_fullData(:,1);
RVU.bortavaror1_trainWaitingTimeDecreaseScenario_Probability_bus=predictionBaseline.probability_fullData(:,2);
RVU.bortavaror1_trainWaitingTimeDecreaseScenario_Probability_train=predictionBaseline.probability_fullData(:,3);
RVU.bortavaror1_trainWaitingTimeDecreaseScenario_Probability_air=predictionBaseline.probability_fullData(:,4);
RVU.bortavaror1_trainWaitingTimeDecreaseScenario_logsum=prediction_scenario.logsum_fullData;

% scenario of combined scenario
level_of_service_var_scenario=level_of_service_var;
level_of_service_var_scenario.train.inVehicleTimeBusTrainAir=TrainWeightedTotalTime_InVehReduce;
level_of_service_var_scenario.train.travelCostLog=trainCostLog_increase;
prediction_scenario=Apply_NL_model(final_result_bortavaror_4,...
    RVU_bortavaror,...
    RVU,...
    model_specification_modeChoice,...
    ZoneData,...
    ZoneID_varname,...
    zonal_varNames,...
    level_of_service_var_scenario,...
    TripID_varname,...
    Origin_varname,...
    Destination_varname);

RVU.bortavaror1_trainCombinedScenario_Probability_car=prediction_scenario.probability_fullData(:,1);
RVU.bortavaror1_trainCombinedScenario_Probability_bus=prediction_scenario.probability_fullData(:,2);
RVU.bortavaror1_trainCombinedScenario_Probability_train=prediction_scenario.probability_fullData(:,3);
RVU.bortavaror1_trainCombinedScenario_Probability_air=prediction_scenario.probability_fullData(:,4);
RVU.bortavaror1_trainCombinedScenario_logsum=prediction_scenario.logsum_fullData;
% nanmean((RVU.bortavaror1_trainCombinedScenario_Probability_train-RVU.bortavaror1_baseline_Probability_train)./RVU.bortavaror1_baseline_Probability_train)
% nanmean((RVU.bortavaror1_trainInVehTimeDecreaseScenario_Probability_train-RVU.bortavaror1_baseline_Probability_train)./RVU.bortavaror1_baseline_Probability_train)
% nanmean((RVU.bortavaror1_trainCostIncreaseScenario_Probability_train-RVU.bortavaror1_baseline_Probability_train)./RVU.bortavaror1_baseline_Probability_train)

%% write results
writetable(RVU,'//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering.csv')
baseline=RVU(:,{'bortavaror1_baseline_Probability_car','bortavaror1_baseline_Probability_bus','bortavaror1_baseline_Probability_train','bortavaror1_baseline_Probability_air'});
nanmean(baseline{:,:},1)
costIncrease=RVU(:,{'bortavaror1_trainCostIncreaseScenario_Probability_car','bortavaror1_trainCostIncreaseScenario_Probability_bus','bortavaror1_trainCostIncreaseScenario_Probability_train','bortavaror1_trainCostIncreaseScenario_Probability_air'});
nanmean(costIncrease{:,:},1)

check=(table2array(costIncrease)-table2array(baseline))./table2array(baseline).*100;
%% descriptive for air invehicle time
% ZoneData.valdDestination=zeros(size(ZoneData,1),1);
% startZoneID=RVU_bortavaror.(Origin_varname);
% endZoneID=RVU_bortavaror.(Destination_varname);
% AirInVehicleTimeData=AirInVehicleTime(2:end,2:end);
% AirInVehicleTimeStartZone=AirInVehicleTime(2:end,1);
% AirInVehicleTimeEndZone=AirInVehicleTime(1,2:end);
% check=nan(size(RVU_bortavaror,1),1);
%  for i=1:size(RVU_bortavaror,1)
%      InVehicleTime=AirInVehicleTimeData(AirInVehicleTimeStartZone==startZoneID(i),AirInVehicleTimeEndZone==endZoneID(i));
%      AirInVehicleTimeRow=AirInVehicleTimeData(AirInVehicleTimeStartZone==startZoneID(i),:);
%      AirInVehicleTimeRow=sort(AirInVehicleTimeRow(~isnan(AirInVehicleTimeRow)));
%      if ~isnan(InVehicleTime)
%          index=find(AirInVehicleTimeRow==InVehicleTime);
%          check(i)=index(1)/length(AirInVehicleTimeRow);
%      end
%
%      if (RVU_bortavaror.D_ARE(i)>=1 && RVU_bortavaror.D_ARE(i)<=4)|| (RVU_bortavaror.D_ARE(i)>=80 && RVU_bortavaror.D_ARE(i)<=98)
%          ZoneData.valdDestination(ZoneData.TransCadID==endZoneID(i))=ZoneData.valdDestination(ZoneData.TransCadID==endZoneID(i))+1;
%      end
%
%  end
%  checkNoNan=check(~isnan(check));
%  hist(checkNoNan)
% size(RVU_bortavaror((RVU_bortavaror.D_ARE>=1 & RVU_bortavaror.D_ARE<=4)| (RVU_bortavaror.D_ARE>=80 & RVU_bortavaror.D_ARE<=98),:),1)./size(RVU_bortavaror,1);
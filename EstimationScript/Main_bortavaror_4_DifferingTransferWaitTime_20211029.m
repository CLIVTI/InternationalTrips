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

TrainInVehicleTimePath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/InVehicleTime.xlsx';
TrainFirstWaitTimePath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/FirstWaitTime.xlsx';
TrainAccessTimePath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/AccessTime.xlsx';
TrainEgressTimePath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/EgressTime.xlsx';
TrainDistancePath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/InVehDistance.xlsx';
TrainNtransferPath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/NTransfer.xlsx';
TrainTransferWaitTimeInSwedenPath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/TransferWaitTimeWithinSweden.xlsx';
TrainTransferWaitTimeOutSwedenPath='LOS/Train/EMMEWeights/WithHeterogenuousTransferPenaltyOutsideSweden/TransferWaitTimeOutsideSweden.xlsx';

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
RVU.sallskap(isnan(RVU.sallskap))=1;
RVU.sallskap(RVU.sallskap>5)=5;  % if its >5 then probabilty the party cant be fitted in a car, just assuming 5 as maximum.
RVU.PartySizeFactor=1./(1+RVU.sallskap);

% number car
RVU.BILANT(isnan(RVU.BILANT))=0;

% income
RVU.lowMediumIncome=RVU.HHINK<500000;
RVU.highIncome=RVU.HHINK>=500000;
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


RVU_bortavaror=RVU(RVU.bortavaro==4,:);
%% read land use data
opts = detectImportOptions(landUseFilePath);
ZoneData=readtable(landUseFilePath,opts);
ZoneData.Properties.VariableNames{'TransCadUniqueID'} = 'TransCadID';
% % recode the variables into density
% land_use_read.population_density=land_use_read.sumTOTKON./land_use_read.Nrutor_job;
ZoneData=sortrows(ZoneData,'TransCadID');  % important here, you must sort rows to make sure the sams_zone code is sorted
landUseZoneID=ZoneData.TransCadID;
ZoneData.Hotel_beds(ZoneData.Hotel_beds==0)=1;
ZoneData.Hotel_beds_per_area=ZoneData.Hotel_beds./1000;
ZoneData.Population_per_area=ZoneData.Population./10000;
ZoneData.Employment_per_area=ZoneData.Employment./100000000;
ZoneData.GDP_CAP_per_area=ZoneData.GDP_CAP./10000;
ZoneData.hotel_per_population=ZoneData.Hotel_beds./ZoneData.Population*100;
%% specify land use data
% car
zonal_data_car=[];
% zonal_data_car.betaNames={'LU_Hotel_beds','LU_Employment','LU_GDP_CAP','LU_Population'};
% zonal_data_car.XNames={'Hotel_beds','Employment','GDP_CAP','Population'};
zonal_data_car.betaNames={'LU_Population'};
zonal_data_car.XNames={'Population_per_area'};

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
zonal_varNames.(mode_choice_names{5})=zonal_data_ferry;


%% read the level-of-service variables
DestinationZoneIDs=ZoneData.TransCadID;
SemesterZone=ZoneData.SemesterZone;
GDP_CAP=ZoneData.GDP_CAP/100000;
HotelPopulation=ZoneData.hotel_per_population;
FlightZoneDummy=ZoneData.FlightZoneDummy;
FerryZone=ZoneData.FerryDummy;
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
hotel_per_population=zeros(1,length(carDestinationZoneIDs));
FlightDummy=zeros(1,length(carDestinationZoneIDs));
for i=1:length(carDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==carDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==carDestinationZoneIDs(i));
    hotel_per_population(i)=HotelPopulation(DestinationZoneIDs==carDestinationZoneIDs(i));
    FlightDummy(i)=FlightZoneDummy(DestinationZoneIDs==carDestinationZoneIDs(i));
end
SemesterZonesMatrixCar=carTime;
SemesterZonesMatrixCar(2:end,2:end)=SemesterZonesDummy(ones(size(carTime,1)-1,1),:);
GDPPerCapitaMatrixCar=carTime;
GDPPerCapitaMatrixCar(2:end,2:end)=GDPPerCapita(ones(size(carTime,1)-1,1),:);
HotelPopulationMatrixCar=carTime;
HotelPopulationMatrixCar(2:end,2:end)=hotel_per_population(ones(size(carTime,1)-1,1),:);
FlightZoneDummyMatrixCar=carTime;
FlightZoneDummyMatrixCar(2:end,2:end)=FlightDummy(ones(size(carTime,1)-1,1),:);

for i=1:(size(carDistance,1)-1)
    noUsedIndex=carDistance(i+1,:)<100;
    noUsedIndex(1)=0;
    SemesterZonesMatrixCar(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixCar(i+1,noUsedIndex)=nan;
    HotelPopulationMatrixCar(i+1,noUsedIndex)=nan;
    FlightZoneDummyMatrixCar(i+1,noUsedIndex)=nan;
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
hotel_per_population=zeros(1,length(busDestinationZoneIDs));
FlightDummy=zeros(1,length(busDestinationZoneIDs));
for i=1:length(busDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==busDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==busDestinationZoneIDs(i));
    hotel_per_population(i)=HotelPopulation(DestinationZoneIDs==busDestinationZoneIDs(i));
    FlightDummy(i)=FlightZoneDummy(DestinationZoneIDs==busDestinationZoneIDs(i));
end
SemesterZonesMatrixBus=busTime;
SemesterZonesMatrixBus(2:end,2:end)=SemesterZonesDummy(ones(size(busTime,1)-1,1),:);
GDPPerCapitaMatrixBus=busTime;
GDPPerCapitaMatrixBus(2:end,2:end)=GDPPerCapita(ones(size(busTime,1)-1,1),:);
HotelPopulationMatrixBus=busTime;
HotelPopulationMatrixBus(2:end,2:end)=hotel_per_population(ones(size(busTime,1)-1,1),:);
FlightZoneDummyMatrixBus=busTime;
FlightZoneDummyMatrixBus(2:end,2:end)=FlightDummy(ones(size(busTime,1)-1,1),:);


for i=1:(size(busDistance,1)-1)
    noUsedIndex=busDistance(i+1,:)<100;
    noUsedIndex(1)=0;
    SemesterZonesMatrixBus(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixBus(i+1,noUsedIndex)=nan;
    HotelPopulationMatrixBus(i+1,noUsedIndex)=nan;
    FlightZoneDummyMatrixBus(i+1,noUsedIndex)=nan;
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
TrainTransferWaitTimeInSweden=xlsread(TrainTransferWaitTimeInSwedenPath);
TrainTransferWaitTimeOutSweden=xlsread(TrainTransferWaitTimeOutSwedenPath);
TrainAccessTime=xlsread(TrainAccessTimePath) ;
TrainEgressTime=xlsread(TrainEgressTimePath) ;
TrainAccessEgressTime=TrainAccessTime;
TrainAccessEgressTime(2:end,2:end)=TrainAccessTime(2:end,2:end)+TrainEgressTime(2:end,2:end);
TrainMergedTime=TrainInVehicleTime;
TrainMergedTime(2:end,2:end)=TrainInVehicleTime(2:end,2:end)+2.*TrainAccessEgressTime(2:end,2:end);
trainDistance = xlsread(TrainDistancePath) ;
trainCost=trainDistance;
trainNTransfer=xlsread(TrainNtransferPath) ;
trainCost(2:end,2:end)=trainDistance(2:end,2:end).*0.17553+(trainNTransfer(2:end,2:end)+1).*21.09441;


% create destinatoion zone dymmy
trainDestinationZoneIDs=TrainInVehicleTime(1,2:end);
SemesterZonesDummy=zeros(1,length(trainDestinationZoneIDs));
GDPPerCapita=zeros(1,length(trainDestinationZoneIDs));
hotel_per_population=zeros(1,length(trainDestinationZoneIDs));
FlightDummy=zeros(1,length(trainDestinationZoneIDs));
for i=1:length(trainDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==trainDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==trainDestinationZoneIDs(i));
    hotel_per_population(i)=HotelPopulation(DestinationZoneIDs==trainDestinationZoneIDs(i));
    FlightDummy(i)=FlightZoneDummy(DestinationZoneIDs==trainDestinationZoneIDs(i));
end
SemesterZonesMatrixTrain=TrainInVehicleTime;
SemesterZonesMatrixTrain(2:end,2:end)=SemesterZonesDummy(ones(size(TrainInVehicleTime,1)-1,1),:);
GDPPerCapitaMatrixTrain=TrainInVehicleTime;
GDPPerCapitaMatrixTrain(2:end,2:end)=GDPPerCapita(ones(size(TrainInVehicleTime,1)-1,1),:);
HotelPopulationMatrixTrain=TrainInVehicleTime;
HotelPopulationMatrixTrain(2:end,2:end)=hotel_per_population(ones(size(TrainInVehicleTime,1)-1,1),:);
FlightZoneDummyMatrixTrain=TrainInVehicleTime;
FlightZoneDummyMatrixTrain(2:end,2:end)=FlightDummy(ones(size(TrainInVehicleTime,1)-1,1),:);


for i=1:(size(trainDistance,1)-1)
    noUsedIndex=trainCost(i+1,:)==0 | trainDistance(i+1,:)<100;
    noUsedIndex(1)=0;
    SemesterZonesMatrixTrain(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixTrain(i+1,noUsedIndex)=nan;
    HotelPopulationMatrixTrain(i+1,noUsedIndex)=nan;
    FlightZoneDummyMatrixTrain(i+1,noUsedIndex)=nan;
    TrainInVehicleTime(i+1,noUsedIndex)=nan;
    TrainFirstWaitTime(i+1,noUsedIndex)=nan;
    TrainTransferWaitTimeInSweden(i+1,noUsedIndex)=nan;
    TrainTransferWaitTimeOutSweden(i+1,noUsedIndex)=nan;
    TrainAccessEgressTime(i+1,noUsedIndex)=nan;
    trainNTransfer(i+1,noUsedIndex)=nan;
end

TrainInVehicleTimeLog=TrainInVehicleTime;
TrainInVehicleTimeLog(2:end,2:end)=log(TrainInVehicleTime(2:end,2:end)+0.01);
trainCostLog=trainCost;
trainCostLog(2:end,2:end)=log(trainCost(2:end,2:end)+0.01);

% flight time and cost

% AirInVehicleTimePath='LOS/Air/InVehicleTime.xlsx';
% AirAccessEgressTimePath='LOS/Air/AccessEgressTime.xlsx';
% AirCostPath='LOS/Air/TicketPrice.xlsx';
% AirTransferPath='LOS/Air/NumberofFlights.xlsx';
AirInVehicleTime = xlsread(AirInVehicleTimePath) ;
AirAccessEgressTime= xlsread(AirAccessEgressTimePath) ;
AirMergedTime=AirInVehicleTime;
AirMergedTime(2:end,2:end)=AirInVehicleTime(2:end,2:end)+2.*AirAccessEgressTime(2:end,2:end);
airCost = xlsread(AirCostPath);
airNTransfer = xlsread(AirTransferPath);


% create destinatoion zone dymmy
airDestinationZoneIDs=AirInVehicleTime(1,2:end);
SemesterZonesDummy=zeros(1,length(airDestinationZoneIDs));
GDPPerCapita=zeros(1,length(airDestinationZoneIDs));
hotel_per_population=zeros(1,length(airDestinationZoneIDs));
FlightDummy=zeros(1,length(airDestinationZoneIDs));
for i=1:length(airDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==airDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==airDestinationZoneIDs(i));
    hotel_per_population(i)=HotelPopulation(DestinationZoneIDs==airDestinationZoneIDs(i));
    FlightDummy(i)=FlightZoneDummy(DestinationZoneIDs==airDestinationZoneIDs(i));
end
SemesterZonesMatrixAir=AirInVehicleTime;
SemesterZonesMatrixAir(2:end,2:end)=SemesterZonesDummy(ones(size(AirInVehicleTime,1)-1,1),:);
GDPPerCapitaMatrixAir=AirInVehicleTime;
GDPPerCapitaMatrixAir(2:end,2:end)=GDPPerCapita(ones(size(AirInVehicleTime,1)-1,1),:);
HotelPopulationMatrixAir=AirInVehicleTime;
HotelPopulationMatrixAir(2:end,2:end)=hotel_per_population(ones(size(AirInVehicleTime,1)-1,1),:);
FlightZoneDummyMatrixAir=AirInVehicleTime;
FlightZoneDummyMatrixAir(2:end,2:end)=FlightDummy(ones(size(AirInVehicleTime,1)-1,1),:);

for i=1:(size(airCost,1)-1)
    % noUsedIndex=airNTransfer(i+1,:)==0 | ((AirInVehicleTime(i+1,:)/60*850+AirAccessEgressTime(i+1,:)/60*70)<100);
    noUsedIndex=airNTransfer(i+1,:)==0 | ((AirInVehicleTime(i+1,:)/60*850)<100);
    noUsedIndex(1)=0;
    SemesterZonesMatrixAir(i+1,noUsedIndex)=nan;
    GDPPerCapitaMatrixAir(i+1,noUsedIndex)=nan;
    HotelPopulationMatrixAir(i+1,noUsedIndex)=nan;
    FlightZoneDummyMatrixAir(i+1,noUsedIndex)=nan;
    AirInVehicleTime(i+1,noUsedIndex)=nan;
    AirMergedTime(i+1,noUsedIndex)=nan;
    airCost(i+1,noUsedIndex)=nan;
    AirAccessEgressTime(i+1,noUsedIndex)=nan;
    airNTransfer(i+1,noUsedIndex)=nan;
end
airNTransfer(2:end,2:end)=airNTransfer(2:end,2:end)-1;
AirInVehicleTimeLog=AirInVehicleTime;
AirInVehicleTimeLog(2:end,2:end)=log(AirInVehicleTime(2:end,2:end)./60+0.01);
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
FerryMergedTime=FerryInVehicleTime;
FerryMergedTime(2:end,2:end)=FerryInVehicleTime(2:end,2:end)+2.*FerryAccessEgressTime(2:end,2:end);
ferryCost = xlsread(FerryCostPath);  %% calculated as for car link, cost=0.18 euro/km, for ferry link, use the ferry line cost: car_HS_H
FerryDistance = xlsread(FerryDistancePath);
FerryDistanceFullTrip= xlsread(DistancePath);
ferryNTransfer=xlsread(FerryNumberLineUsedPath);


% create destinatoion zone dymmy
ferryDestinationZoneIDs=FerryInVehicleTime(1,2:end);
SemesterZonesDummy=zeros(1,length(ferryDestinationZoneIDs));
GDPPerCapita=zeros(1,length(ferryDestinationZoneIDs));
hotel_per_population=zeros(1,length(ferryDestinationZoneIDs));
FlightDummy=zeros(1,length(ferryDestinationZoneIDs));
FerryDestination=zeros(1,length(ferryDestinationZoneIDs));
for i=1:length(ferryDestinationZoneIDs)
    SemesterZonesDummy(i)=SemesterZone(DestinationZoneIDs==ferryDestinationZoneIDs(i));
    GDPPerCapita(i)=GDP_CAP(DestinationZoneIDs==ferryDestinationZoneIDs(i));
    hotel_per_population(i)=HotelPopulation(DestinationZoneIDs==ferryDestinationZoneIDs(i));
    FlightDummy(i)=FlightZoneDummy(DestinationZoneIDs==ferryDestinationZoneIDs(i));
    FerryDestination(i)=FerryZone(DestinationZoneIDs==ferryDestinationZoneIDs(i));
end
SemesterZonesMatrixFerry=FerryInVehicleTime;
SemesterZonesMatrixFerry(2:end,2:end)=SemesterZonesDummy(ones(size(FerryInVehicleTime,1)-1,1),:);
GDPPerCapitaMatrixFerry=FerryInVehicleTime;
GDPPerCapitaMatrixFerry(2:end,2:end)=GDPPerCapita(ones(size(FerryInVehicleTime,1)-1,1),:);
HotelPopulationMatrixFerry=FerryInVehicleTime;
HotelPopulationMatrixFerry(2:end,2:end)=hotel_per_population(ones(size(FerryInVehicleTime,1)-1,1),:);
FlightZoneDummyMatrixFerry=FerryInVehicleTime;
FlightZoneDummyMatrixFerry(2:end,2:end)=FlightDummy(ones(size(FerryInVehicleTime,1)-1,1),:);
FerryDestinationFerry=FerryInVehicleTime;
FerryDestinationFerry(2:end,2:end)=FerryDestination(ones(size(FerryInVehicleTime,1)-1,1),:);
% we assume that if there is no ferry line used, the destination is not available, code as nan.
for i=1:(size(ferryNTransfer,1)-1)
    % noFerryUsedIndex=ferryNTransfer(i+1,:)==0 | FerryDistanceFullTrip(i+1,:)<100 | FerryDistance(i+1,:)./FerryDistanceFullTrip(i+1,:)<0.5;
    noFerryUsedIndex=ferryNTransfer(i+1,:)==0 | FerryDistanceFullTrip(i+1,:)<100 | FerryDistance(i+1,:)./FerryDistanceFullTrip(i+1,:)<0.5;
    noFerryUsedIndex(1)=0;
    SemesterZonesMatrixFerry(i+1,noFerryUsedIndex)=nan;
    GDPPerCapitaMatrixFerry(i+1,noFerryUsedIndex)=nan;
    HotelPopulationMatrixFerry(i+1,noFerryUsedIndex)=nan;
    FlightZoneDummyMatrixFerry(i+1,noFerryUsedIndex)=nan;
    FerryDestinationFerry(i+1,noFerryUsedIndex)=nan;
    FerryInVehicleTime(i+1,noFerryUsedIndex)=nan;
    ferryCost(i+1,noFerryUsedIndex)=nan;
    FerryFirstWaitTime(i+1,noFerryUsedIndex)=nan;
    FerryAccessEgressTime(i+1,noFerryUsedIndex)=nan;
    FerryMergedTime(i+1,noFerryUsedIndex)=nan;
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
level_of_service_var_car=[];
level_of_service_var_car.SemesterZone=SemesterZonesMatrixCar;
level_of_service_var_car.GDPPerCapita=GDPPerCapitaMatrixCar;
level_of_service_var_car.HotelPerPopulation=HotelPopulationMatrixCar;
level_of_service_var_car.carTravelTime=carTime;
% level_of_service_var_car.carLogTravelTime=carTimeLog;
level_of_service_var_car.travelCost_lowMediumIncome=carCost;
level_of_service_var_car.travelCost_highIncome=carCost;
level_of_service_var_car.travelCost_incomeMissing=carCost;
% level_of_service_var_car.travelCost_age17=carCost;
% level_of_service_var_car.travelCostLog_lowMediumIncome=carCostLog;
% level_of_service_var_car.travelCostLog_highIncome=carCostLog;

% bus
level_of_service_var_bus=[];
level_of_service_var_bus.SemesterZone=SemesterZonesMatrixBus;
level_of_service_var_bus.GDPPerCapita=GDPPerCapitaMatrixBus;
level_of_service_var_bus.HotelPerPopulation=HotelPopulationMatrixBus;
level_of_service_var_bus.inVehicleTimeBusTrainAirFerry=busTime;
% level_of_service_var_bus.logInVehicleTimeBusTrainFerry=busTimeLog;
level_of_service_var_bus.travelCost_lowMediumIncome=busCost;
level_of_service_var_bus.travelCost_highIncome=busCost;
level_of_service_var_bus.travelCost_incomeMissing=busCost;
% level_of_service_var_bus.travelCost_age17=busCost;
% level_of_service_var_bus.travelCostLog_lowMediumIncome=busCostLog;
% level_of_service_var_bus.travelCostLog_highIncome=busCostLog;

% train
level_of_service_var_train=[];
level_of_service_var_train.SemesterZone=SemesterZonesMatrixTrain;
level_of_service_var_train.GDPPerCapita=GDPPerCapitaMatrixTrain;
level_of_service_var_train.HotelPerPopulation=HotelPopulationMatrixTrain;
% level_of_service_var_train.accessEgressTimeTrain=TrainAccessEgressTime;
%level_of_service_var_train.firstWaitTimeTrain=TrainFirstWaitTime;
% level_of_service_var_train.numberTransferTrain=trainNTransfer;
% level_of_service_var_train.transferWaitTimeInSwedenTrain=TrainTransferWaitTimeInSweden;
level_of_service_var_train.transferWaitTimeOutSwedenTrain=TrainTransferWaitTimeOutSweden;
% level_of_service_var_train.inVehicleTimeBusTrainAirFerry=TrainInVehicleTime;
level_of_service_var_train.inVehicleTimeBusTrainAirFerry=TrainMergedTime;
% level_of_service_var_train.logInVehicleTimeBusTrainFerry=TrainInVehicleTimeLog;
level_of_service_var_train.travelCost_lowMediumIncome=trainCost;
level_of_service_var_train.travelCost_highIncome=trainCost;
level_of_service_var_train.travelCost_incomeMissing=trainCost;
% level_of_service_var_train.travelCost_age17=trainCost;
% level_of_service_var_train.travelCostLog_lowMediumIncome=trainCostLog;
% level_of_service_var_train.travelCostLog_highIncome=trainCostLog;

% flight
level_of_service_var_air=[];
% % split airTime for EU and international,

airTimeSemesterZone=AirInVehicleTime;
airTimeNoSemesterZone=AirInVehicleTime;
for i=1:(size(AirInVehicleTime,2)-1)
    destinationCode=AirInVehicleTime(1,i+1);
    if ZoneData.SemesterZone(ismember(landUseZoneID,destinationCode))==0 %% its not a flightzone dummy destination
        airTimeSemesterZone(2:end,i+1)=0;
    else %% its semester zone
        airTimeNoSemesterZone(2:end,i+1)=0;
    end
end

airTime_threshold1=AirInVehicleTime;
airTime_threshold2=AirInVehicleTime;
airTime_threshold3=AirInVehicleTime;
airTime_threshold4=AirInVehicleTime;
airTime_threshold5=AirInVehicleTime;
for i=1:(size(airTime_threshold1,1)-1)
    airTime_threshold1(i+1,(airTime_threshold1(i+1,:)<=120)==0)=0;
    airTime_threshold2(i+1,(airTime_threshold2(i+1,:)>120)==0)=0;
    airTime_threshold3(i+1,(airTime_threshold3(i+1,:)>240 & airTime_threshold3(i+1,:)<=480)==0)=0;
    airTime_threshold4(i+1,(airTime_threshold4(i+1,:)>480 & airTime_threshold4(i+1,:)<=720)==0)=0;
    airTime_threshold5(i+1,(airTime_threshold5(i+1,:)>720)==0)=0;
end
airTime_threshold1(:,1)=AirInVehicleTime(:,1);
airTime_threshold2(:,1)=AirInVehicleTime(:,1);
airTime_threshold3(:,1)=AirInVehicleTime(:,1);
airTime_threshold4(:,1)=AirInVehicleTime(:,1);
airTime_threshold5(:,1)=AirInVehicleTime(:,1);
level_of_service_var_air.SemesterZoneAir=SemesterZonesMatrixAir;
% level_of_service_var_air.GDPPerCapitaAir=GDPPerCapitaMatrixAir;
level_of_service_var_air.HotelPerPopulationAir=HotelPopulationMatrixAir;
% level_of_service_var_air.FlightDummy=FlightZoneDummyMatrixAir;
% level_of_service_var_air.accessEgressTimeAir=AirAccessEgressTime;
% level_of_service_var_air.numberTransferAir=airNTransfer;
% level_of_service_var_air.inVehicleTimeBusTrainAirFerry=AirInVehicleTime;
level_of_service_var_air.inVehicleTimeBusTrainAirFerry=AirMergedTime;

% level_of_service_var_air.inVehicleTimeAirSemesterZone=airTimeSemesterZone;
% level_of_service_var_air.inVehicleTimeAirNoSemesterZone=airTimeNoSemesterZone;
% level_of_service_var_air.inVehicleTimeAirSeg1=airTime_threshold1;
% level_of_service_var_air.inVehicleTimeAirSeg2=airTime_threshold2;
% level_of_service_var_air.inVehicleTimeAirSeg3=airTime_threshold3;
% level_of_service_var_air.inVehicleTimeAirSeg4=airTime_threshold4;
% level_of_service_var_air.inVehicleTimeAirSeg5=airTime_threshold5;
% level_of_service_var_air.logInVehicleTimeAir=AirInVehicleTimeLog;

% 
level_of_service_var_air.travelCost_lowMediumIncome=airCost;
level_of_service_var_air.travelCost_highIncome=airCost;
level_of_service_var_air.travelCost_incomeMissing=airCost;
% level_of_service_var_air.travelCost_age17=airCost;
% level_of_service_var_air.travelCostLog_lowMediumIncome=airCostLog;
% level_of_service_var_air.travelCostLog_highIncome=airCostLog;

% ferry
level_of_service_var_ferry=[];
level_of_service_var_ferry.SemesterZone=SemesterZonesMatrixFerry;
level_of_service_var_ferry.GDPPerCapita=GDPPerCapitaMatrixFerry;
level_of_service_var_ferry.HotelPerPopulation=HotelPopulationMatrixFerry;
% level_of_service_var_ferry.BalticSeaCoastDummy=FerryDestinationFerry;
% level_of_service_var_ferry.accessEgressTimeFerry=FerryAccessEgressTime;
% level_of_service_var_ferry.firstWaitTimeTrainFerry=FerryFirstWaitTime;
% level_of_service_var_ferry.numberTransferFerry=ferryNTransfer;
% level_of_service_var_ferry.inVehicleTimeBusTrainAirFerry=FerryInVehicleTime;
level_of_service_var_ferry.inVehicleTimeBusTrainAirFerry=FerryMergedTime;
% level_of_service_var_ferry.logInVehicleTimeBusTrainFerry=FerryInVehicleTimeLog;
level_of_service_var_ferry.travelCost_lowMediumIncome=ferryCost;
level_of_service_var_ferry.travelCost_highIncome=ferryCost;
level_of_service_var_ferry.travelCost_incomeMissing=ferryCost;
% level_of_service_var_ferry.travelCost_age17=ferryCost;
% level_of_service_var_ferry.travelCostLog_lowMediumIncome=ferryCostLog;
% level_of_service_var_ferry.travelCostLog_highIncome=ferryCostLog;



level_of_service_var=[];
level_of_service_var.(mode_choice_names{1})=level_of_service_var_car;
level_of_service_var.(mode_choice_names{2})=level_of_service_var_bus;
level_of_service_var.(mode_choice_names{3})=level_of_service_var_train;
level_of_service_var.(mode_choice_names{4})=level_of_service_var_air;
level_of_service_var.(mode_choice_names{5})=level_of_service_var_ferry;
%% specify mode choice part

% all variable names {'female','VILLA','age_64','age_18_30','age_17','BILANT'}
beta_names_fix.(mode_choice_names{1})={'NcarInHH','bil_female','bil_VILLA'};   % walk
X_names_fix.(mode_choice_names{1})={'BILANT','female','VILLA'};  % walk

beta_names_fix.(mode_choice_names{2})={'bus_ASC','bus_age_64'};  
X_names_fix.(mode_choice_names{2})={'ASC','age64'};  

beta_names_fix.(mode_choice_names{3})={'train_ASC'};   
X_names_fix.(mode_choice_names{3})={'ASC'};  

beta_names_fix.(mode_choice_names{4})={'air_ASC'};  
X_names_fix.(mode_choice_names{4})={'ASC'};  

beta_names_fix.(mode_choice_names{5})={'ferry_ASC'};  
X_names_fix.(mode_choice_names{5})={'ASC',};  


model_specification_modeChoice=[];
model_specification_modeChoice.beta_names=beta_names_fix;
model_specification_modeChoice.X_names=X_names_fix;
model_specification_modeChoice.Y_names=ModeChoice_varname;
model_specification_modeChoice.choice_name=mode_choice_names;




% also need to delete some obs for those choosing boat
 %% descriptive for air invehicle time
startZoneID=RVU_bortavaror.(Origin_varname);
endZoneID=RVU_bortavaror.(Destination_varname);
InVehicleTimeData=FerryInVehicleTime(2:end,2:end);
InVehicleTimeStartZone=FerryInVehicleTime(2:end,1);
InVehicleTimeEndZone=FerryInVehicleTime(1,2:end);
InVehicleTime=0;
 for i=1:size(RVU_bortavaror,1)
     if RVU_bortavaror.Mode(i)==5
         time=InVehicleTimeData(InVehicleTimeStartZone==startZoneID(i),InVehicleTimeEndZone==endZoneID(i));
         if time>1000
             RVU_bortavaror.bortavaro(i)=-1;
         end
     end
     
 end
RVU_bortavaror=RVU_bortavaror(RVU_bortavaror.bortavaro==4,:);
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

RVU.logsumBortavaro_3=final_result_bortavaror_4.logsum;
writetable(RVU,'//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering.csv')
                                                      
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
%      ZoneData.valdDestination(ZoneData.TransCadID==endZoneID(i))=ZoneData.valdDestination(ZoneData.TransCadID==endZoneID(i))+1;
%  end
%  checkNoNan=check(~isnan(check));
%  hist(checkNoNan)
%  size(RVU_bortavaror((RVU_bortavaror.D_ARE>=1 & RVU_bortavaror.D_ARE<=4)| (RVU_bortavaror.D_ARE>=80 & RVU_bortavaror.D_ARE<=98),:),1)./size(RVU_bortavaror,1)
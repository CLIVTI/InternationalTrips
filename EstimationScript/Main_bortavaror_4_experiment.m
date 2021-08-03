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
RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation.csv';

% level-of-service variables
% car
CarTimeFilePath='LOS/Car/CarTime.xlsx';
CarDistancePath='LOS/Car/CarDistanceKM.xlsx';
% bus
BusTimeFilePath='LOS/Bus/TravelTime.xlsx';
BusDistancePath='LOS/Bus/TravelDistanceKM.xlsx';
% Train
TrainImpedanceFilePath='LOS/Train/Impedans.xlsx';
TrainDistancePath='LOS/Train/InVehDistance.xlsx';
TrainNtransferPath='LOS/Train/NTransfer.xlsx';

% Flight
AirTimePath='LOS/Air/Time.xlsx';
AirCostPath='LOS/Air/TicketPrice.xlsx';
AirTransferPath='LOS/Air/NumberofFlights.xlsx';

% Ferry
FerryTimeFilePath='LOS/Ferry/Time.xlsx';
FerryCostPath='LOS/Ferry/TravelCost.xlsx';
FerryDistancePath='LOS/Ferry/TravelDistanceKM_Ferry.xlsx';
DistancePath='LOS/Ferry/TravelDistanceKM.xlsx';
FerryNumberLineUsedPath='LOS/Ferry/NumberOfFerryLinesUsed';
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
% number car
RVU.BILANT(isnan(RVU.BILANT))=0;

% income
RVU.lowMediumIncome=RVU.HHINK<500000;
RVU.highIncome=RVU.HHINK>=500000;
RVU.incomeMissing=isnan(RVU.HHINK);
% age
RVU.age_17=RVU.AGE<18;
RVU.age_18_30=RVU.AGE>=18 & RVU.AGE<=30;
RVU.age_31_64=RVU.AGE>=31 & RVU.AGE<=64;
RVU.age_64=RVU.AGE>=65;

% gender
RVU.female=RVU.SEX==2;
% villa or apartment
RVU.VILLA=RVU.VILLA==1;
% we need to recode some stuff to make sure there is 
%  air 55 (canary), move the key to 75. fixed
%  air 54 iceland, fixed
%  air 177 malta to 136,  fixed 
%  141 Corse to 151 fixed
%  ferry 198 Åland to 209
% 53 azores, not in the map
% 57 madera to 75 fixed
% car 28 bolivia, probably wrong data 
% car to 310 austrilia, probably wrong data
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==55)=75;
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==57)=75;
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==177)=136;
% RVU.D_B_TransCadID(RVU.D_B_TransCadID==141)=151;
RVU.D_B_TransCadID(RVU.D_B_TransCadID==198)=209;
RVU(:,1)=[];

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
ZoneData.Hotel_beds_per_area=ZoneData.Hotel_beds./ZoneData.Area;
ZoneData.Population_per_area=ZoneData.Population./ZoneData.Area;
ZoneData.Employment_per_area=ZoneData.Employment./ZoneData.Area;
ZoneData.GDP_CAP_per_area=ZoneData.GDP_CAP./ZoneData.Area;
%% specify land use data
% car
zonal_data_car=[];
% zonal_data_car.betaNames={'LU_Population','LU_Employment','LU_GDP_CAP','LU_Hotel_beds'};
% zonal_data_car.XNames={'Population','Employment','GDP_CAP','Hotel_beds'};
zonal_data_car.betaNames={'LU_Hotel_beds','LU_Employment','LU_GDP_CAP'};
zonal_data_car.XNames={'Hotel_beds','Employment','GDP_CAP'};

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
% car time and cost
carTime = xlsread(CarTimeFilePath) ;
carCost = xlsread(CarDistancePath) ;
carCost(2:end,2:end)=carCost(2:end,2:end).*0.18;

% bus time and cost
busTime = xlsread(BusTimeFilePath) ;
busCost = xlsread(BusDistancePath) ;
busCost(2:end,2:end)=busCost(2:end,2:end).*0.08;

% train impedance and cost
trainImpedance = xlsread(TrainImpedanceFilePath) ;
trainCost = xlsread(TrainDistancePath) ;
trainNTransfer=xlsread(TrainNtransferPath) ;
trainCost(2:end,2:end)=trainCost(2:end,2:end).*0.17553+(trainNTransfer(2:end,2:end)+1).*21.09441;
for i=1:(size(trainCost,1)-1)
    noTrainUsedIndex=trainCost(i+1,:)==0;
    trainImpedance(i+1,noTrainUsedIndex)=nan;
end
% flight time and cost
airTime = xlsread(AirTimePath) ;
airCost = xlsread(AirCostPath);
airTransfer = xlsread(AirTransferPath);
for i=1:(size(airCost,1)-1)
    noAirUsedIndex=airTransfer(i+1,:)==0;
    airTime(i+1,noAirUsedIndex)=nan;
    airCost(i+1,noAirUsedIndex)=nan;
end



% ferry
ferryTime = xlsread(FerryTimeFilePath) ;
ferryCost = xlsread(FerryCostPath);  %% calculated as for car link, cost=0.18 euro/km, for ferry link, use the ferry line cost: car_HS_H
FerryDistance = xlsread(FerryDistancePath);
FerryDistanceFullTrip= xlsread(DistancePath);
FerryNumberLineUsed=xlsread(FerryNumberLineUsedPath);
% we assume that if there is no ferry line used, the destination is not available, code as nan.
for i=1:(size(FerryNumberLineUsed,1)-1)
    noFerryUsedIndex=FerryNumberLineUsed(i+1,:)==0;
    ferryTime(i+1,noFerryUsedIndex)=nan;
    ferryCost(i+1,noFerryUsedIndex)=nan;
end


%% specify LOS variables
% summarize to one structure as model input

% car
level_of_service_var_car=[];
level_of_service_var_car.carTime=carTime;
level_of_service_var_car.travelCost_lowMediumIncome=carCost;
level_of_service_var_car.travelCost_highIncome=carCost;
level_of_service_var_car.travelCost_incomeMissing=carCost;
% bus
level_of_service_var_bus=[];
level_of_service_var_bus.busTime=busTime;
level_of_service_var_bus.travelCost_lowMediumIncome=busCost;
level_of_service_var_bus.travelCost_highIncome=busCost;
level_of_service_var_bus.travelCost_incomeMissing=busCost;

% train
level_of_service_var_train=[];
level_of_service_var_train.trainImpedance=trainImpedance;
level_of_service_var_train.travelCost_lowMediumIncome=trainCost;
level_of_service_var_train.travelCost_highIncome=trainCost;
level_of_service_var_train.travelCost_incomeMissing=trainCost;

% flight
level_of_service_var_air=[];
% split airTime for EU and international,

airTimeEU=airTime;
airTimeInternational=airTime;
for i=1:(size(airTime,2)-1)
    destinationCode=airTime(1,i+1);
    if ZoneData.WorldDummy(ismember(landUseZoneID,destinationCode))==1 %% its international
        airTimeEU(2:end,i+1)=0;
    else %% its EU
        airTimeInternational(2:end,i+1)=0;
    end
end

airTime_threshold1=airTime;
airTime_threshold2=airTime;
for i=1:(size(airTime_threshold1,1)-1)
    airTime_threshold1(i+1,airTime_threshold1(i+1,:)>=300)=0;
    airTime_threshold2(i+1,airTime_threshold2(i+1,:)<300)=0;
end
airTime_threshold1(:,1)=airTime(:,1);
airTime_threshold2(:,1)=airTime(:,1);

level_of_service_var_air.airTimeEU=airTimeEU;
level_of_service_var_air.airTimeInternational=airTimeInternational;
% level_of_service_var_air.airCost=airCost;
% level_of_service_var_air.airTimeBelowThreshold=airTime_threshold1;
% level_of_service_var_air.airTimeOverThreshold=airTime_threshold2;
level_of_service_var_air.travelCost_lowMediumIncome=airCost;
level_of_service_var_air.travelCost_highIncome=airCost;
level_of_service_var_air.travelCost_incomeMissing=airCost;

% ferry
level_of_service_var_ferry=[];
level_of_service_var_ferry.ferryTime=ferryTime;
level_of_service_var_ferry.travelCost_lowMediumIncome=ferryCost;
level_of_service_var_ferry.travelCost_highIncome=ferryCost;
level_of_service_var_ferry.travelCost_incomeMissing=ferryCost;


level_of_service_var=[];
level_of_service_var.(mode_choice_names{1})=level_of_service_var_car;
level_of_service_var.(mode_choice_names{2})=level_of_service_var_bus;
level_of_service_var.(mode_choice_names{3})=level_of_service_var_train;
level_of_service_var.(mode_choice_names{4})=level_of_service_var_air;
level_of_service_var.(mode_choice_names{5})=level_of_service_var_ferry;
%% specify mode choice part

% all variable names {'female','VILLA','age_64','age_18_30','age_17','BILANT'}
beta_names_fix.(mode_choice_names{1})={'NcarInHH'};   % walk
X_names_fix.(mode_choice_names{1})={'BILANT'};  % walk

beta_names_fix.(mode_choice_names{2})={'bus_ASC','bus_female','bus_VILLA','bus_age_17','bus_age_64'};  
X_names_fix.(mode_choice_names{2})={'ASC','female','VILLA','age_17','age_64'};  

beta_names_fix.(mode_choice_names{3})={'train_ASC','train_female','train_VILLA','train_age_17','train_age_64'};   
X_names_fix.(mode_choice_names{3})={'ASC','female','VILLA','age_17','age_64'};  

beta_names_fix.(mode_choice_names{4})={'air_ASC','air_female','air_VILLA','air_age_17','air_age_64'};  
X_names_fix.(mode_choice_names{4})={'ASC','female','VILLA','age_17','age_64'};  

beta_names_fix.(mode_choice_names{5})={'ferry_ASC','ferry_female','ferry_VILLA','ferry_age_17','ferry_age_64'};  
X_names_fix.(mode_choice_names{5})={'ASC','female','VILLA','age_17','age_64'};  


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


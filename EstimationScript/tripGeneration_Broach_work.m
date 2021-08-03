close all 
clear variables;

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

PathStorage='E:/CykelKedjorModell/DemandEstimation';
addpath(genpath(PathStorage))


% read the sam_emme file
opts = detectImportOptions('sam_emme_study_area.csv');
sam_emme=readtable('sam_emme_study_area.csv',opts);
sam_emme_match=table2array(sam_emme(:,{'sams_zone','emme_zone'}));


% % read cykel parkering
% cykel_parkering=readtable('sams_cykel_parkering_final.csv');
% cykel_parkering.Properties.VariableNames{2}='sams_zone';
% CP=cykel_parkering(:,{'sams_zone','weighted_P','N_parking'});
% 
% 
% % read population building job
% population_building_job=readtable('samszone_population_building_job.csv');
% population_building_job.Properties.VariableNames{2}='sams_zone';
% 
% results = join(population_building_job,CP,'Keys','sams_zone');
% writetable(results,'C:/Users/ChengxiL/Box Sync/VTI job/cyckelkjedie projekt/demand model/matrix storage/samzone_data/samszone_population_building_job_parking.csv','Delimiter',',')
% test=readtable('samszone_population_building_job.csv');

% read land use data
opts = detectImportOptions('samszone_population_all_info_0531_matlabinput.csv');
land_use_read=readtable('samszone_population_all_info_0531_matlabinput.csv',opts);
% recode the variables into density
land_use_read.population_density=land_use_read.sumTOTKON./land_use_read.Nrutor_job;
land_use_read.job_density=land_use_read.sumTotalt./land_use_read.Nrutor_job;
land_use_read.Service_density=land_use_read.sumService./land_use_read.Nrutor_job;
land_use_read.Poffice_density=land_use_read.sumPoffice./land_use_read.Nrutor_job;
land_use_read.Public_density=land_use_read.sumPublic./land_use_read.Nrutor_job;
land_use_read.Build_density=land_use_read.sumBuild./land_use_read.Nrutor_job;
land_use_read.N_bikeParking=round(land_use_read.unweight_P.*land_use_read.Nrutor_P);

land_use_read=sortrows(land_use_read,'sams_zone');  % important here, you must sort rows to make sure the sams_zone code is sorted

Key=land_use_read(:,'sams_zone');

%% try estimating a trip generation model
% 1. load in the person data 
opts = detectImportOptions('RVU2015_ind_tripGeneration_work.csv');
RVU_ind=readtable('RVU2015_ind_tripGeneration_work.csv',  opts);


%% start from here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
% opts = detectImportOptions('C:/Users/ChengxiL/Box Sync/VTI job/cyckelkjedie projekt/demand model/RVU data/Data2015_RVU_Stockholm/RVU2015_study_area_work_no_missing.csv');
% RVU_morningCommute=readtable('C:/Users/ChengxiL/Box Sync/VTI job/cyckelkjedie projekt/demand model/RVU data/Data2015_RVU_Stockholm/RVU2015_study_area_work_no_missing.csv',opts);
% RVU_morningCommute.PT_cost(RVU_morningCommute.PT_cost==50)=20.75; % recode those Övrig periodbiljett from 50 to normal 30 dagar biljetts pris
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% read in data
% % RVU_stockholm_MorningCommute = RVU1113_stockholm(RVU1113_stockholm.purpose==1 & (RVU1113_stockholm.D_A_KL>=600 & RVU1113_stockholm.D_A_KL<=900),:);
% RVU_stockholm_MorningCommute_no_missing_for_estimation=RVU_morningCommute(~isnan(RVU_morningCommute.D_A_S) & ~isnan(RVU_morningCommute.D_B_S),:);
% RVU_stockholm_MorningCommute_no_missing_for_estimation.access_mode(RVU_stockholm_MorningCommute_no_missing_for_estimation.access_mode==4)=3;
% 
% variableSet={'D_A_S','D_B_S','access_mode','mode_choice','female','age16_24','age25_44','age45_64','age65_84','child0_6','child7_18','N_car_per_drivLic','PT_cost','parking_cost','Lag','Mlag','Mhog','Hog','IncMissing'};
% Dataset_commute=RVU_stockholm_MorningCommute_no_missing_for_estimation(:,variableSet);
% 
% % writetable('population_unitest.csv')
% 
% 
% Dataset_Full=Dataset_commute((Dataset_commute.mode_choice>=1 & Dataset_commute.mode_choice<=4) | (Dataset_commute.mode_choice==5 & (Dataset_commute.access_mode>=1 & Dataset_commute.access_mode<=4)),:);
% Dataset_Full.indIndex=(1:size(Dataset_Full,1))';
% Dataset_Full.log_PTcost=log(Dataset_Full.PT_cost);

walk_inVehicleTime_read=csvread('PT_gång/in_vehicle_time_SAMS.csv');
walk_inVehicleTime_read(walk_inVehicleTime_read==0)=-999;
walk_inVehicleTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_inVehicleTime_read);

bike_inVehicleTime_read=csvread('PT_cykel/in_vehicle_time_cykelPT_SAMS.csv');
bike_inVehicleTime_read(bike_inVehicleTime_read==0)=-999;
bike_inVehicleTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_inVehicleTime_read);

car_inVehicleTime_read=csvread('PT_bil_20km_h/in_vehicle_time_bilPT_SAMS.csv');
car_inVehicleTime_read(car_inVehicleTime_read==0)=-999;
car_inVehicleTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_inVehicleTime_read);

invehicle_time_PT=[];
invehicle_time_PT.accessWalk=walk_inVehicleTime;
invehicle_time_PT.accessBike=bike_inVehicleTime;
invehicle_time_PT.accessCar=car_inVehicleTime;

% Dataset_Full=obs_chosen_destination_not_in_choiceset(Key,RVU_ind,invehicle_time_PT,'mode_choice',5);  % 
RVU_ind.indIndex=(1:size(RVU_ind,1))';


% % recode the index that extracts different mode choice 
% walk_index=Dataset_Full.mode_choice==1;
% bike_index=Dataset_Full.mode_choice==2;
% car_driver_index=Dataset_Full.mode_choice==3;
% car_passenger_index=Dataset_Full.mode_choice==4;
% PT_index=Dataset_Full.mode_choice==5 & (Dataset_Full.access_mode>=1 & Dataset_Full.access_mode<=4);
% until here the Dataset should be clean 

% south Stockholm dummy
south_dummy_column=land_use_read(:,{'sams_zone','SOUTH_DUMMY'});
south_dummy_X=southDummy_to_X(Key,RVU_ind,'Lopnr','sams_ID',south_dummy_column);

Central_dummy_column=land_use_read(:,{'sams_zone','CentralDummy'});
InCentral_dummy_X=OutsideInCentralDummy_to_X(Key,RVU_ind,'Lopnr','sams_ID',Central_dummy_column);
OutCentral_dummy_X=InsideOutCentralDummy_to_X(Key,RVU_ind,'Lopnr','sams_ID',Central_dummy_column);
%% public transport for different access modes, estimate together
accessMode_var_names={'accessWalk','accessBike','accessCar'};
mode_choice_names={'walk','bike','carDriver','carPassenger','PT'};

% access modes==1 (walk)
% zonal_data
% zonal_data_PT_varNames={'sams_zone','Service_density','Poffice_density','Public_density','Build_density'};
% zonal_data_PT_varNames={'sams_zone','sumTOTKON','sumTotalt','sumINDUSTR','sumSAMFUNK','sumVERKSAM'};
zonal_data_PT_walk_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_PT_walk=[];
for i=1:length(zonal_data_PT_walk_varNames)-1
    zonal_data_PT_walk.(strcat('LU_',zonal_data_PT_walk_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',land_use_read(:,zonal_data_PT_walk_varNames([1,i+1])));
end


% LOS variables for different access modes, 
walk_accessTime_read=csvread('PT_gång/access_walking_time_SAMS.csv');
walk_accessTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_accessTime_read);

walk_initialWaitingTime_read=csvread('PT_gång/initial_waiting_time_SAMS.csv');
walk_initialWaitingTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_initialWaitingTime_read);

walk_inVehicleTime_read=csvread('PT_gång/in_vehicle_time_SAMS.csv');
walk_inVehicleTime_read(walk_inVehicleTime_read==0)=-999;
walk_inVehicleTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_inVehicleTime_read);

walk_transferWaitingTime_read=csvread('PT_gång/transfer_waiting_time_SAMS.csv');
walk_transferWaitingTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_transferWaitingTime_read);

walk_transferWalkTime_read=csvread('PT_gång/transfer_walk_time_SAMS.csv');
walk_transferWalkTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_transferWalkTime_read);

walk_egressWalkTime_read=csvread('PT_gång/egress_walking_time_SAMS.csv');
walk_egressWalkTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_egressWalkTime_read);

log_cost=walk_egressWalkTime;
RVU_ind.PT_cost(RVU_ind.PT_cost==0)=1;
log_cost(:,2:end)=log(repmat(RVU_ind.PT_cost,[1,size(log_cost,2)-1]));
% walk_accessTime_read(walk_inVehicleTime_read==0)=0;
% walk_initialWaitingTime_read(walk_inVehicleTime_read==0)=0;
% walk_transferWaitingTime_read(walk_inVehicleTime_read==0)=0;
% walk_transferWalkTime_read(walk_inVehicleTime_read==0)=0;
% walk_egressWalkTime_read(walk_inVehicleTime_read==0)=0;


level_of_service_var_walk=[];
level_of_service_var_walk.walk_accessTime=walk_accessTime;
level_of_service_var_walk.initialWaitingTime=walk_initialWaitingTime;
level_of_service_var_walk.inVehicleTime=walk_inVehicleTime;
level_of_service_var_walk.transferWaitingTime=walk_transferWaitingTime;
level_of_service_var_walk.transferWalkTime=walk_transferWalkTime;
level_of_service_var_walk.egressWalkTime=walk_egressWalkTime;
level_of_service_var_walk.log_cost=log_cost;

% access modes==2 (bike)
zonal_data_PT_bike_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_PT_bike=[];
for i=1:length(zonal_data_PT_bike_varNames)-1
    zonal_data_PT_bike.(strcat('LU_',zonal_data_PT_bike_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',land_use_read(:,zonal_data_PT_bike_varNames([1,i+1])));
end


bike_GK_read=csvread('PT_cykel/access_cykel_time_cykelPT_SAMS.csv');
bike_GK=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_GK_read);
% bike_accessTime_read=csvread('PT_cykel/access_cykel_time_cykelPT_SAMS.csv');
% bike_accessTime=los_to_X(Key,Dataset_Full,'indIndex','D_A_S',bike_accessTime_read);

bike_N_parking_at_stop_read=csvread('PT_cykel/parking_at_stop_SAMS.csv');
bike_N_parking_at_stop=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_N_parking_at_stop_read);


bike_initialWaitingTime_read=csvread('PT_cykel/initial_wait_time_cykelPT_SAMS.csv');
bike_initialWaitingTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_initialWaitingTime_read);

bike_inVehicleTime_read=csvread('PT_cykel/in_vehicle_time_cykelPT_SAMS.csv');
bike_inVehicleTime_read(bike_inVehicleTime_read==0)=-999;
bike_inVehicleTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_inVehicleTime_read);

bike_transferWaitingTime_read=csvread('PT_cykel/transfer_wait_time_cykelPT_SAMS.csv');
bike_transferWaitingTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_transferWaitingTime_read);

bike_transferWalkTime_read=csvread('PT_cykel/transfer_walk_time_cykelPT_SAMS.csv');
bike_transferWalkTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_transferWalkTime_read);

bike_egressWalkTime_read=csvread('PT_cykel/egress_walk_time_cykelPT_SAMS.csv');
bike_egressWalkTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_egressWalkTime_read);


level_of_service_var_bike=[];
level_of_service_var_bike.bike_accessTime=bike_GK;
% level_of_service_var_bike.parkingAtStop=bike_N_parking_at_stop;
level_of_service_var_bike.initialWaitingTime=bike_initialWaitingTime;
level_of_service_var_bike.inVehicleTime=bike_inVehicleTime;
level_of_service_var_bike.transferWaitingTime=bike_transferWaitingTime;
level_of_service_var_bike.transferWalkTime=bike_transferWalkTime;
level_of_service_var_bike.egressWalkTime=bike_egressWalkTime;
level_of_service_var_bike.log_cost=log_cost;

% access modes==3 (car)
zonal_data_PT_car_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_PT_car=[];
for i=1:length(zonal_data_PT_car_varNames)-1
    zonal_data_PT_car.(strcat('LU_',zonal_data_PT_car_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',land_use_read(:,zonal_data_PT_car_varNames([1,i+1])));
end


car_accessTime_read=csvread('PT_bil_20km_h/access_driving_time_bilPT_SAMS.csv');
car_accessTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_accessTime_read);

car_initialWaitingTime_read=csvread('PT_bil_20km_h/initial_waiting_time_bilPT_SAMS.csv');
car_initialWaitingTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_initialWaitingTime_read);

car_inVehicleTime_read=csvread('PT_bil_20km_h/in_vehicle_time_bilPT_SAMS.csv');
car_inVehicleTime_read(car_inVehicleTime_read==0)=-999;
car_inVehicleTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_inVehicleTime_read);

car_transferWaitingTime_read=csvread('PT_bil_20km_h/transfer_waiting_time_bilPT_SAMS.csv');
car_transferWaitingTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_transferWaitingTime_read);

car_transferWalkTime_read=csvread('PT_bil_20km_h/transfer_walk_time_bilPT_SAMS.csv');
car_transferWalkTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_transferWalkTime_read);

car_egressWalkTime_read=csvread('PT_bil_20km_h/egress_walk_time_bilPT_SAMS.csv');
car_egressWalkTime=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',car_egressWalkTime_read);

level_of_service_var_car=[];
level_of_service_var_car.car_accessTime=car_accessTime;
level_of_service_var_car.initialWaitingTime=car_initialWaitingTime;
level_of_service_var_car.inVehicleTime=car_inVehicleTime;
level_of_service_var_car.transferWaitingTime=car_transferWaitingTime;
level_of_service_var_car.transferWalkTime=car_transferWalkTime;
level_of_service_var_car.egressWalkTime=car_egressWalkTime;

level_of_service_var_car.log_cost=log_cost;


% save them into PT_matrix
zonal_var_PT=[];
zonal_var_PT.(accessMode_var_names{1})=zonal_data_PT_walk;
zonal_var_PT.(accessMode_var_names{2})=zonal_data_PT_bike;
zonal_var_PT.(accessMode_var_names{3})=zonal_data_PT_car;


level_of_service_var_PT=[];
level_of_service_var_PT.(accessMode_var_names{1})=level_of_service_var_walk;
level_of_service_var_PT.(accessMode_var_names{2})=level_of_service_var_bike;
level_of_service_var_PT.(accessMode_var_names{3})=level_of_service_var_car;




%%

% PT_test=conditional_logit_model_destination_choice_pt(Key,PT_index,zonal_data_PT_X,level_of_service_var_PT,Dataset_Full,'indIndex','D_B_S','access_mode');


% Dataset_Full.logsum_accessWalk=PT_test.logsum_PTwalk_FullData;
% Dataset_Full.logsum_accessBike=PT_test.logsum_PTbike_FullData;
% Dataset_Full.logsum_accessCar=PT_test.logsum_PTcar_FullData;
% 
% Dataset_PT=Dataset_Full(PT_index,:);


%%
% % MNL model with logsum
% estimation_sample=Dataset_PT;


Y_names={'access_mode'};
choice_name=accessMode_var_names;
beta_names_fix.(choice_name{1})={'Awalk_ASC','Awalk_female','Awalk_age25_44','Awalk_child7_18'};   % walk
X_names_fix.(choice_name{1})={'ASC','female','age25_44','child7_18'};  % walk

beta_names_fix.(choice_name{2})={'Abike_ASC','Abike_female','Abike_child0_6','Abike_Lag'};   % bike
X_names_fix.(choice_name{2})={'ASC','female','child0_6','Lag'};  % bike

beta_names_fix.(choice_name{3})={'Acar_N_car_per_drivLic'};   % car
X_names_fix.(choice_name{3})={'N_car_per_drivLic'};  % car




model_specification_PTAccess=[];
model_specification_PTAccess.beta_names=beta_names_fix;
model_specification_PTAccess.X_names=X_names_fix;
model_specification_PTAccess.Y_names=Y_names;
model_specification_PTAccess.choice_name=choice_name;

% logsum_var={'logsum_accessWalk','logsum_accessBike','logsum_accessCar'};
% PT_overall=MNL_model_logsum(estimation_sample,beta_names_fix,X_names_fix,Y_names,choice_name,logsum_var,Dataset_Full);

%% walk commute
% zonal_data'
% zonal_data_walk_varNames={'sams_zone','Service_density','Poffice_density','Public_density','Build_density'};
zonal_data_walk_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_walk=land_use_read(:,zonal_data_walk_varNames);

zonal_data_Walk_X=[];
for i=1:size(zonal_data_walk,2)-1
    zonal_data_Walk_X.(strcat('LU_',zonal_data_walk_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',zonal_data_walk(:,[1,i+1]));
end


% LOS variables
level_of_service_var_walk=[];
walk_distance_read=csvread('gång/gång_distance_SAMS.csv');

% recode to walk travel time
walk_distance_read(:,2:end)=walk_distance_read(:,2:end)./1000/5*60;
walk_TT_read=walk_distance_read;
walk_TT=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',walk_TT_read);
level_of_service_var_walk.walk_TT=walk_TT;


% recode the within_zone dummy
% withinZone_dummy_read=walk_distance_read;
% withinZone_dummy_read(:,2:end)=eye(size(withinZone_dummy_read,1));
% withinZone_dummy=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',withinZone_dummy_read);
% level_of_service_var_walk.walk_withinZone_dummy=withinZone_dummy;
level_of_service_var_walk.walk_OutCentralDummy=OutCentral_dummy_X;

% level_of_service_var.walk=level_of_service_var_walk;
% to make sure Key has the save sequence as los matrix
% key=table2array(Key);
% check=walk_distance_read(:,1);
% if key==check
%     disp(1)
% else 
%     disp(0)
% end

% run the destination choice model

% walk=conditional_logit_model_destination_choice(Key,walk_index,zonal_data_Walk_X,level_of_service_var_walk,Dataset_Full,'indIndex','D_B_S');

%% bike commute
zonal_data_Bike_X=[];
% LOS variables
level_of_service_var_bike=[];

% zonal_data
% zonal_data_bike_varNames={'sams_zone','Service_density','Poffice_density','Public_density','Build_density','weight_P'};
zonal_data_bike_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_bike=land_use_read(:,zonal_data_bike_varNames);


for i=1:size(zonal_data_bike,2)-1
    if strcmp(zonal_data_bike_varNames{i+1},'weight_P')==1
        level_of_service_var_bike.(strcat('bike_',zonal_data_bike_varNames{i+1}))=zonal_to_X_parking(Key,RVU_ind,'Lopnr',zonal_data_bike(:,[1,i+1]));
    else
        zonal_data_Bike_X.(strcat('LU_',zonal_data_bike_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',zonal_data_bike(:,[1,i+1]));
    end
end



bike_restid_read=csvread('cykel/cykel_GK_Broach_SAMS.csv'); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% change here!!!
% bike_GK_read(:,2:end)=log(bike_GK_read(:,2:end));
% bike_GK_read(bike_GK_read==-inf)=0;
% bike_GK_read(isnan(bike_GK_read))=0;
bike_restid=los_to_X(Key,RVU_ind,'Lopnr','sams_ID',bike_restid_read);
level_of_service_var_bike.bike_GK_Broach=bike_restid;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% change here!!!

% interaction effect between 
female=RVU_ind.female;
bike_restid_female=bike_restid;
bike_restid_female(:,2:end)=bike_restid(:,2:end).*female(:,ones(1,size(bike_restid,2)-1));
level_of_service_var_bike.bike_GK_female=bike_restid_female; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% change here!!!


% age65_84=Dataset_Full.age65_84;
% bike_GK_age65_84=bike_GK;
% bike_GK_age65_84(:,2:end)=bike_GK(:,2:end).*age65_84(:,ones(1,size(bike_GK,2)-1));
% level_of_service_var_bike.bike_GK_age65_84=bike_GK_age65_84;

% recode the within_zone dummy
% withinZone_dummy_read=bike_GK_read;
% withinZone_dummy_read(:,2:end)=eye(size(withinZone_dummy_read,1));
% withinZone_dummy=los_to_X(Key,Dataset_Full,'indIndex','D_A_S',withinZone_dummy_read);
% level_of_service_var_bike.bike_withinZone_dummy=withinZone_dummy;
level_of_service_var_bike.bike_southDummy=south_dummy_X;
% level_of_service_var_bike.bike_InCentralDummy=InCentral_dummy_X;
level_of_service_var_bike.bike_OutCentralDummy=OutCentral_dummy_X;

% run the destination choice model

% bike=conditional_logit_model_destination_choice(Key,bike_index,zonal_data_Bike_X,level_of_service_var_bike,Dataset_Full,'indIndex','D_B_S');


%% car driver commute

% zonal_data
% zonal_data_carDriver_varNames={'sams_zone','Service_density','Poffice_density','Public_density','Build_density'};
zonal_data_carDriver_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_carDriver=land_use_read(:,zonal_data_carDriver_varNames);
zonal_data_carDriver_X=[];
for i=1:size(zonal_data_carDriver,2)-1
    zonal_data_carDriver_X.(strcat('LU_',zonal_data_carDriver_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',zonal_data_carDriver(:,[1,i+1]));
end


% LOS variables
level_of_service_var_carDriver=[];
car_TT_read_rushHour=csvread('bil/mf60_peak_car_traveltime_SAMS.csv');
car_TT_read_nonRushHour=csvread('bil/mf61_offpeak_car_traveltime_SAMS.csv');
% car_TT_read(:,2:end)=log(car_TT_read(:,2:end));
% car_TT_read(car_TT_read==-inf)=0;
car_TT=los_to_X_carTime_rushHour(Key,RVU_ind,'Lopnr','sams_ID','rushHour',car_TT_read_rushHour,car_TT_read_nonRushHour);
level_of_service_var_carDriver.car_TT=car_TT;

%%
car_distance_read_rushHour=csvread('bil/car_distance_peak_SAMS.csv');
car_distance_read_nonRushHour=csvread('bil/car_distance_offpeak_SAMS.csv');
car_congestionCharge_read=csvread('bil/car_congestionCharge_SAMS_new.csv');

car_cost_rushHour=car_distance_read_rushHour;
car_cost_rushHour(:,2:end)=car_distance_read_rushHour(:,2:end).*1.8+car_congestionCharge_read(:,2:end).*15;
log_car_cost_rushHour=car_cost_rushHour;
log_car_cost_rushHour(:,2:end)=log(log_car_cost_rushHour(:,2:end));
log_car_cost_rushHour(log_car_cost_rushHour==-inf)=0;

car_cost_nonRushHour=car_distance_read_nonRushHour;
car_cost_nonRushHour(:,2:end)=car_distance_read_nonRushHour(:,2:end).*1.8+car_congestionCharge_read(:,2:end).*10;
log_car_cost_nonRushHour=car_cost_nonRushHour;
log_car_cost_nonRushHour(:,2:end)=log(log_car_cost_nonRushHour(:,2:end));
log_car_cost_nonRushHour(log_car_cost_nonRushHour==-inf)=0;
log_car_cost_final=los_to_X_carTime_rushHour(Key,RVU_ind,'Lopnr','sams_ID','rushHour',log_car_cost_rushHour,log_car_cost_nonRushHour);
%%

level_of_service_var_carDriver.log_cost=log_car_cost_final;

% car_congestionCharge_read=csvread('bil/car_congestionCharge_SAMS_new.csv');
% car_congestionCharge=los_to_X(Key,Dataset_Full,'indIndex','D_A_S',car_congestionCharge_read);
% level_of_service_var_carDriver.car_congestionCharge=car_congestionCharge;



% recode the within_zone dummy
% withinZone_dummy_read=car_TT_read;
% withinZone_dummy_read(:,2:end)=eye(size(withinZone_dummy_read,1));
% withinZone_dummy=los_to_X(Key,Dataset_Full,'indIndex','D_A_S',withinZone_dummy_read);
% level_of_service_var_carDriver.withinZone_dummy=withinZone_dummy;

% run the destination choice model
% carDriver=conditional_logit_model_destination_choice(Key,car_driver_index,zonal_data_carDriver_X,level_of_service_var_carDriver,Dataset_Full,'indIndex','D_B_S');

%% car passenger commute

% zonal_data
% zonal_data_carPassenger_varNames={'sams_zone','Service_density','Poffice_density','Public_density','Build_density'};
zonal_data_carPassenger_varNames={'sams_zone','DagbTotal','sumSAMFUNK','sumVERKSAM'};
zonal_data_carPassenger=land_use_read(:,zonal_data_carPassenger_varNames);
zonal_data_carPassenger_X=[];
for i=1:size(zonal_data_carPassenger,2)-1
    zonal_data_carPassenger_X.(strcat('LU_',zonal_data_carPassenger_varNames{i+1}))=zonal_to_X(Key,RVU_ind,'Lopnr',zonal_data_carPassenger(:,[1,i+1]));
end



% LOS variables
level_of_service_var_carPassenger=[];
car_TT_read_rushHour=csvread('bil/mf60_peak_car_traveltime_SAMS.csv');
car_TT_read_nonRushHour=csvread('bil/mf61_offpeak_car_traveltime_SAMS.csv');
% car_TT_read(:,2:end)=log(car_TT_read(:,2:end));
% car_TT_read(car_TT_read==-inf)=0;
car_TT=los_to_X_carTime_rushHour(Key,RVU_ind,'Lopnr','sams_ID','rushHour',car_TT_read_rushHour,car_TT_read_nonRushHour);
level_of_service_var_carPassenger.carP_TT=car_TT;


log_car_passenger_cost_final=log_car_cost_final;
log_car_passenger_cost_final(:,2:end)=log_car_passenger_cost_final(:,2:end)-log(3);
level_of_service_var_carPassenger.log_cost=log_car_cost_final;

% recode the within_zone dummy
% withinZone_dummy_read=car_TT_read;
% withinZone_dummy_read(:,2:end)=eye(size(withinZone_dummy_read,1));
% withinZone_dummy=los_to_X(Key,Dataset_Full,'indIndex','D_A_S',withinZone_dummy_read);
% level_of_service_var_carPassenger.withinZone_dummy=withinZone_dummy;

% run the destination choice model
% carPassenger=conditional_logit_model_destination_choice(Key,car_passenger_index,zonal_data_carPassenger_X,level_of_service_var_carPassenger,Dataset_Full,'indIndex','D_B_S');

%%



% Dataset_Full.logsum_PT=PT_overall.logsum_fullData;
% Dataset_Full.logsum_walk=walk.logsum_full;
% Dataset_Full.logsum_bike=bike.logsum_full;
% Dataset_Full.logsum_carDriver=carDriver.logsum_full;
% Dataset_Full.logsum_carPassenger=carPassenger.logsum_full;


Y_names={'mode_choice'};

% full set of variables
% beta_names_fix.(mode_choice_names{1})={};   % walk
% X_names_fix.(mode_choice_names{1})={};  % walk
% 
% beta_names_fix.(mode_choice_names{2})={'bike_ASC','bike_female','bike_age16_24','bike_age25_39','bike_age65_84','bike_child0_6','bike_child7_18','bike_Lag','bike_Mlag','bike_Hog','bike_IncMissing'};  
% X_names_fix.(mode_choice_names{2})={'ASC','female','age16_24','age25_44','age65_84','child0_6','child7_18','Lag','Mlag','Hog','IncMissing'};  
% 
% beta_names_fix.(mode_choice_names{3})={'car_ASC','car_female','car_age16_24','car_age25_39','car_age65_84','car_child0_6','car_child7_18','car_N_car_per_drivLic','parking_cost','car_Lag','car_Mlag','car_Hog','car_IncMissing'};   
% X_names_fix.(mode_choice_names{3})={'ASC','female','age16_24','age25_44','age65_84','child0_6','child7_18','N_car_per_drivLic','parking_cost','Lag','Mlag','Hog','IncMissing'};  
% 
% beta_names_fix.(mode_choice_names{4})={'carP_ASC','carP_female','carP_age16_24','carP_age25_39','carP_age65_84','carP_child0_6','carP_child7_18','carP_N_car_per_drivLic','carP_Hog','carP_IncMissing'};  
% X_names_fix.(mode_choice_names{4})={'ASC','female','age16_24','age25_44','age65_84','child0_6','child7_18','N_car_per_drivLic','Hog','IncMissing'};  
% 
% beta_names_fix.(mode_choice_names{5})={'PT_ASC','PT_female','PT_age16_24','PT_age25_39','PT_age65_84','PT_child0_6','PT_child7_18','PT_cost','PT_Lag','PT_Mlag','PT_Hog','PT_IncMissing'};  
% X_names_fix.(mode_choice_names{5})={'ASC','female','age16_24','age25_44','age65_84','child0_6','child7_18','PT_cost','Lag','Mlag','Hog','IncMissing'};  

% variableSet={'D_A_S','D_B_S','access_mode','mode_choice','female','age16_24','age25_44','age45_64',...
%     'age65_84','child0_6','child7_18','N_car_per_drivLic','PT_cost','parking_cost','Lag','Mlag','Mhog','Hog','IncMissing'};
beta_names_fix.(mode_choice_names{1})={'walk_ASC','walk_child7_18'};   % walk
X_names_fix.(mode_choice_names{1})={'ASC','child7_18'};  % walk

beta_names_fix.(mode_choice_names{2})={'bike_ASC','bike_age65_84','bike_child7_18'};  
X_names_fix.(mode_choice_names{2})={'ASC','age65_84','child7_18'};  

beta_names_fix.(mode_choice_names{3})={'car_ASC','car_female','car_child7_18','car_N_car_per_drivLic'};   
X_names_fix.(mode_choice_names{3})={'ASC','female','child7_18','N_car_per_drivLic'};  

beta_names_fix.(mode_choice_names{4})={'carP_ASC','carP_age25_44','carP_N_car_per_drivLic'};  
X_names_fix.(mode_choice_names{4})={'ASC','age25_44','N_car_per_drivLic'};  

beta_names_fix.(mode_choice_names{5})={};  
X_names_fix.(mode_choice_names{5})={};  



model_specification_modeChoice=[];
model_specification_modeChoice.beta_names=beta_names_fix;
model_specification_modeChoice.X_names=X_names_fix;
model_specification_modeChoice.Y_names=Y_names;
model_specification_modeChoice.choice_name=mode_choice_names;




% logsum_var={'logsum_walk','logsum_bike','logsum_carDriver','logsum_carPassenger','logsum_PT'};


% modeChoice_final=MNL_model_logsum(Dataset_Full,beta_names_fix,X_names_fix,Y_names,choice_name,logsum_var,Dataset_Full);

%%
% Dataset_test=Dataset_Full(Dataset_Full.mode_choice<5,:);
% 
% Y_names={'mode_choice'};
% choice_name={'walk','bike','carDriver','carPassenger'};
% beta_names_fix.(choice_name{1})={};   % walk
% X_names_fix.(choice_name{1})={};  % walk
% 
% beta_names_fix.(choice_name{2})={'bike_ASC'};  
% X_names_fix.(choice_name{2})={'ASC'};  
% 
% beta_names_fix.(choice_name{3})={'carDriver_ASC'};   
% X_names_fix.(choice_name{3})={'ASC'};  
% 
% beta_names_fix.(choice_name{4})={'carPassenger_ASC'};   
% X_names_fix.(choice_name{4})={'ASC'};  
% 
% logsum_var={'logsum_walk','logsum_bike','logsum_carDriver','logsum_carPassenger'};
% PT_test=MNL_model_logsum(Dataset_test,beta_names_fix,X_names_fix,Y_names,choice_name,logsum_var,Dataset_test);
level_of_service_var=[];
level_of_service_var.(mode_choice_names{1})=level_of_service_var_walk;
level_of_service_var.(mode_choice_names{2})=level_of_service_var_bike;
level_of_service_var.(mode_choice_names{3})=level_of_service_var_carDriver;
level_of_service_var.(mode_choice_names{4})=level_of_service_var_carPassenger;
level_of_service_var.(mode_choice_names{5})=level_of_service_var_PT;

zonal_data=[];
zonal_data.(mode_choice_names{1})=zonal_data_Walk_X;
zonal_data.(mode_choice_names{2})=zonal_data_Bike_X;
zonal_data.(mode_choice_names{3})=zonal_data_carDriver_X;
zonal_data.(mode_choice_names{4})=zonal_data_carPassenger_X;
zonal_data.(mode_choice_names{5})=zonal_var_PT;



load('modelResult_final_Broach_slussen_updated_AllDummy_work.mat')    %% change here!!!!!!!!!!!!!
% logP_output=NL_model_joint_prediction_log_zonal_flexible(final_result,...
%                                                           Key,...
%                                                           Dataset_Full,...
%                                                           model_specification_modeChoice,...
%                                                           model_specification_PTAccess,...
%                                                           zonal_data,...
%                                                           level_of_service_var,...
%                                                           'indIndex',...
%                                                           'D_B_S');

                                                      


[logP_output,logsum]=NL_model_joint_prediction_log_zonal_flexible(final_result,...
                                                          Key,...
                                                          RVU_ind,...
                                                          model_specification_modeChoice,...
                                                          model_specification_PTAccess,...
                                                          zonal_data,...
                                                          level_of_service_var,...
                                                          'Lopnr',...
                                                          'sams_ID');

RVU_ind.logsum_modeChoice=logsum;                                                     
Y_names_TripGeneration={'work'};
choice_name_TripGeneration={'hem','arbeta'};
               
beta_names_TripGeneration.(choice_name_TripGeneration{1})={};   % EV
X_names_TripGeneration.(choice_name_TripGeneration{1})={};  % EV
				
beta_names_TripGeneration.(choice_name_TripGeneration{2})={'ASC_trip','Lag','Mhog','Hog','deltid'};   % ICEV
X_names_TripGeneration.(choice_name_TripGeneration{2})={'ASC','Lag','Mhog','Hog','deltid'}; % ICEV

% beta_names_TripGeneration.(choice_name_TripGeneration{2})={'ASC_trip','Lag','Mhog','Hog','deltid','fulltid','logsum_modeChoice'};   % ICEV
% X_names_TripGeneration.(choice_name_TripGeneration{2})={'ASC','Lag','Mhog','Hog','deltid','fulltid','logsum_modeChoice'};    % ICEV

tripGeneration_model=MNL_model(RVU_ind,beta_names_TripGeneration,X_names_TripGeneration,Y_names_TripGeneration,choice_name_TripGeneration);
      Probability=  tripGeneration_model.Probability  ;
      sum(Probability)
save('TripGenerationResult_final_work_Broach.mat','tripGeneration_model')      
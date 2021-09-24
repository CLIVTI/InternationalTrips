
%-------------------------------------------------------
function output=NL_model_joint_estimation_log_zonal_flexible(Dataset,...
    DatasetPrediction,...
    model_specification_modeChoice,...
    ZoneData,...
    ZoneID_varname,...
    zonal_varNames,...
    level_of_service_var,...
    obs_varName,...
    origin_varName,...
    destination_varName) % note that ASC has been included in both "specific_names_fix" and "variables"
% the simple benchmark MNL model
% input:
%        Dataset: (NP*Nvar table) -- it must have first 2 variables as (departure and arrival zones) the data stores the departure and arrival Keys (samszone id) of each trip
%        model_specification_modeChoice: (structure) -- it contains four elements for each mode:
%                                        1.model_specification_modeChoice.beta_names: (structure) contains the following elements:
%                                                  model_specification_modeChoice.beta_names.(choice_name{x}) -- each element (.(choice_name{x}))represents a string vector of the names of beta in each 1st level choice
%                                        2. model_specification_modeChoice.X_names_fix: (structure) contains the following elements:
%                                                  model_specification_modeChoice.X_names_fix.choice_name{x}) -- each element (.(choice_name{x}))represents a string vector of the names of X variables in each 1st level choice
%                                        3. model_specification_modeChoice.Y_names: (a string)
%                                                  model_specification_modeChoice.Y_names -- the variable name denoting the 1st level choice chosen by each obs  (in this case, its 'mode_choice')
%                                        4.model_specification_modeChoice.choice_name -- (a string vector)
%                                                  model_specification_modeChoice.choice_name -- the string vector contains the name of each choice e.g. walk, bike, carDriver,...
%
%        ZoneData: (NdestinationZone*??? table) -- it contains the zonal lvl variables
%        ZoneID_varnames: the variable name in ZoneData that denotes the zone ID.
%        zonal_varNames: (structure) -- it contains two elements for each mode:
%                                        1. zonal_data_car.betaNames:  string contains var names for the model, t.ex.{'LU_Population','LU_Employment','LU_GDP_CAP','LU_Hotel_beds'};
%                                        2. zonal_data_car.XNames:  string contains var names in ZoneData, t.ex.{'Population','Employment','GDP_CAP','Hotel_beds'};
%
%
%        level_of_service_var: (structure) -- it contains the level of service variables that are specified for each choice in the 1st level choice part
%                                   e.g. level_of_service_var.walk -- (structure), contains a structure  with each element a matrix of level of service variable (NZ,NZ+1) dimension
%        constraint: a string cell representing which variables are the same
%        obs_varName: (string) -- the variable name of individual/observation index
%        origin_varName: (string) -- the variable name of the origin zone in the dataset
%        destination_varName: (string) -- the variable name of the destination choice in the dataset
%        flag: (integer) -- 1 if you only want the sequential estimation results, faster; 0 if you want the joint
%        estimatin results.

% output:
%         output has the following structure names
%
%         output.('fixed_beta'): a structure with each element as a vector of fixed beta for each choice alternative
%         output.('fixed_beta_tvalue'): a structure with each element as a vector of tvalues of fixed beta for each choice alternative
%         output.('fixed_beta_name'): a structure with each element as a vector of names of fixed beta for each choice alternative
%         output.('fixed_variable_name'): a structure with each element as a vector of variable names of fixed beta for each choice alternative
%         output.('model_fit'): a structure with element as model fit:
%         following elements contained:
%                                 model_fit_info.('Loglikelihood_final')
%                                 model_fit_info.('Loglikelihood_zero')
%                                 model_fit_info.('adjusted_McFadden_rho')
%                                 model_fit_info.('Loglikelihood_intercept')
global dataset_obsID
global firstLevel_choiceName
global DestinationCHOICE_All zonal_matrix_All los_matrix_All
global zonal_data_varName_All level_of_service_var_varNames_All
global N_destination_beta N_ModeChoice_beta
global DATA_CHOICE Data_originZone Data_destinationZone Observation_index_ALL
global choiceSetIndex
global ZoneKey
global Y_name_level_modeChoice
global beta_indexing_structure
global N_choice_modeChoice
global predictionData
%% check the validity of input data

DATA = table2array(Dataset);
title = Dataset.Properties.VariableNames;
if size(DATA,2)~=length(title)
    disp('number of variables do not match number of variable titles in the estimation dataset')
    return
end
if ~ismember(title,'ASC')
    Dataset.ASC=ones(size(DATA,1),1);
end

% check Dataset: 1. whether there is any missing value in the Dataset
%                2. whether all start and end zones are included in the "Key"
% check 1
dataset_varName=Dataset.Properties.VariableNames;
zoneKeyInputCheck=ZoneData.(ZoneID_varname);
% check if all destinations are registered in the zone keys.
unique_id=unique(DATA(:,ismember(dataset_varName,destination_varName)));
for i=1:length(unique_id)
    if sum(zoneKeyInputCheck==unique_id(i))~=1
        fprintf('\nthe following zone id is not included in "Key": %10.0f ', unique_id(i));
        return
    end
end

% loop through the zone data and check if the zone variables exist in the zone data.
zoneData_varName=ZoneData.Properties.VariableNames;
zone_choiceName=fieldnames(zonal_varNames);
for i=1:length(zone_choiceName)
    xNames=zonal_varNames.(zone_choiceName{i}).XNames;
    for j=1:length(xNames)
        if (sum(ismember(zoneData_varName,xNames{j}))~=1)
            fprintf('\n the following zone variable name is not included in Zone data: %10.0s ', xNames{j});
            return
        end
    end
end

% loop each los variable and check if the destination zones exist in the zone data
losData_choiceName=fieldnames(level_of_service_var);
for i=1:length(losData_choiceName)
    level_of_service_var_ModeX=level_of_service_var.(losData_choiceName{i});
    level_of_service_var_ModeX_varNames=fieldnames(level_of_service_var_ModeX);
    for j=1:length(level_of_service_var_ModeX_varNames)
        losMatrix=level_of_service_var_ModeX.(level_of_service_var_ModeX_varNames{j});
        destinationZoneIDs=losMatrix(1,2:end);
        for k=1:length(destinationZoneIDs)
            if (sum(ismember(zoneKeyInputCheck,destinationZoneIDs(k)))~=1)
                fprintf('\n the following zone key %10.0f in the los matrix %10.0s of mode %10.0s is not found',destinationZoneIDs(k), level_of_service_var_ModeX_varNames{j},losData_choiceName{i});
                return
            end
        end
    end
end

% check if the chosen obs has the chosen origin-destination connection in los
firstLevel_choiceNameInputCheck=model_specification_modeChoice.choice_name;
Data_originZoneInputCheck=Dataset.(origin_varName);
Data_destinationZoneInputCheck=Dataset.(destination_varName);
NPInputCheck = size(DATA,1);
DATA_CHOICEInputCheck=Dataset.(model_specification_modeChoice.Y_names);
obsShouldBeUsed=ones(NPInputCheck,1);
for i=1:NPInputCheck
    travelMode=firstLevel_choiceNameInputCheck(DATA_CHOICEInputCheck(i));
    origin=Data_originZoneInputCheck(i);
    destination=Data_destinationZoneInputCheck(i);
    level_of_service_var_ModeX=level_of_service_var.(travelMode{1});
    level_of_service_var_ModeX_varNames=fieldnames(level_of_service_var_ModeX);
    for j=1:length(level_of_service_var_ModeX_varNames)
        losMatrix=level_of_service_var_ModeX.(level_of_service_var_ModeX_varNames{j});
        originIDs=losMatrix(2:end,1);
        destinationIDs=losMatrix(1,2:end);
        searchMatrix=losMatrix(2:end,2:end);
        rowIndex=ismember(originIDs,origin);
        colIndex=ismember(destinationIDs,destination);
        losValue=searchMatrix(rowIndex,colIndex);
        if isempty(losValue)
            fprintf('\n the following destrination in the input data cannnot be found in the "Key":  mode: %10s ,destinationID: %10.0f', travelMode{1}, destination);
            obsShouldBeUsed(i)=0;
        elseif isnan(losValue)
            fprintf('\n the destination id returns nan for obs: %10.0f', destination);
            obsShouldBeUsed(i)=0;
        end
    end
end

fprintf('\n  %10.0f observations are removed since there is no matching in los data', sum(obsShouldBeUsed==0));

% check if there is any observation that has alternative mode with 0 destinations. e.g. if one chooses car from zone 1
% to 2, while from zone 1 to K for air has all nan, not available. need to remove this observation

for i=1:length(losData_choiceName)
    level_of_service_var_ModeX=level_of_service_var.(losData_choiceName{i});
    level_of_service_var_ModeX_varNames=fieldnames(level_of_service_var_ModeX);
    for j=1:length(level_of_service_var_ModeX_varNames)
        losMatrix=level_of_service_var_ModeX.(level_of_service_var_ModeX_varNames{j});
        originIDs=losMatrix(2:end,1);
        destinationIDs=losMatrix(1,2:end);
        searchMatrix=losMatrix(2:end,2:end);
        for k=1:size(searchMatrix,1)
            if sum(isnan(searchMatrix(k,:)))==size(searchMatrix,2) % if the whole row is nan
                rowWithAllnan=originIDs(k);
                obsShouldBeUsed(Data_originZoneInputCheck==rowWithAllnan)=0;
            end
        end
    end
    
    
end
% remove the invalid data
Dataset=Dataset(logical(obsShouldBeUsed),:);

%% define global variables
firstLevel_choiceName=model_specification_modeChoice.choice_name;
Y_name_level_modeChoice=model_specification_modeChoice.Y_names;
DATA_CHOICE=Dataset.(Y_name_level_modeChoice);
Data_originZone=Dataset.(origin_varName);
Data_destinationZone=Dataset.(destination_varName);
ZoneKey=ZoneData.(ZoneID_varname);
dataset_obsID=Dataset.(obs_varName);

%% generate los and zone variables for each observation for estimation data
originZone=Dataset.(origin_varName);
originZonePrediction=DatasetPrediction.(origin_varName);
losData_choiceName=fieldnames(level_of_service_var);
level_of_service_var_prediction=[];
zonal_var_prediction=[];
for i=1:length(losData_choiceName)
    % los variables
    level_of_service_var_ModeX=level_of_service_var.(losData_choiceName{i});
    level_of_service_var_ModeX_varNames=fieldnames(level_of_service_var_ModeX);
    for j=1:length(level_of_service_var_ModeX_varNames)
        losMatrix=level_of_service_var_ModeX.(level_of_service_var_ModeX_varNames{j});
        originZoneID=losMatrix(2:end,1);
        destinationZoneIDs=losMatrix(1,2:end);
        losMatrixToRead=losMatrix(2:end,2:end);
        transformedMatrix=nan(length(originZone)+1,size(losMatrix,2)-1);
        transformedMatrix(1,:)=destinationZoneIDs;
        % for estimation data
        for k=1:length(originZone)
            if (sum(ismember(originZoneID,originZone(k)))==1)
                transformedMatrix(k+1,:)=losMatrixToRead(ismember(originZoneID,originZone(k)),:);
            else
                warning('there is still missing value in los data %10.0f',originZone(k))
                output=[];
                return
            end
        end
        
        if sum(ismember(level_of_service_var_ModeX_varNames{j},'_'))==0
            if strcmp(losData_choiceName{i},'car') && contains(level_of_service_var_ModeX_varNames{j},'travelCost')
                warning('\n car cost is further divided by the party size factor for variable : %10.0s',level_of_service_var_ModeX_varNames{j})
                dataVar=Dataset.('PartySizeFactor');
                transformedMatrix(2:end,:)=transformedMatrix(2:end,:).*dataVar(:,ones(1,size(transformedMatrix,2)));
                level_of_service_var.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            else
                level_of_service_var.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            end
            
            
        else
            dataVarName=strsplit(level_of_service_var_ModeX_varNames{j},'_');
            if sum(ismember(dataset_varName,dataVarName{2}))==0
                warning('\n the following variable defined in los data does not exist in choice dataset: %10.0s',dataVarName{2})
                output=[];
                return
            end
            if strcmp(losData_choiceName{i},'car') && contains(dataVarName{1},'travelCost')
                warning('\n car cost is further divided by the party size factor for variable : %10.0s',level_of_service_var_ModeX_varNames{j})
                dataVar=Dataset.(dataVarName{2}).*Dataset.('PartySizeFactor');
                transformedMatrix(2:end,:)=transformedMatrix(2:end,:).*dataVar(:,ones(1,size(transformedMatrix,2)));
                level_of_service_var.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            else
                dataVar=Dataset.(dataVarName{2});
                transformedMatrix(2:end,:)=transformedMatrix(2:end,:).*dataVar(:,ones(1,size(transformedMatrix,2)));
                level_of_service_var.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            end
            
        end
        
        % for logsum data -----------------------------------------------------------------------------------------
        transformedMatrix=nan(length(originZonePrediction)+1,size(losMatrix,2)-1);
        transformedMatrix(1,:)=destinationZoneIDs;
        for k=1:length(originZonePrediction)
            if (sum(ismember(originZoneID,originZonePrediction(k)))==1)
                transformedMatrix(k+1,:)=losMatrixToRead(ismember(originZoneID,originZonePrediction(k)),:);
            else
                %                 warning('there is still missing value in los data %10.0f',originZonePrediction(k))
                %                 output=[];
                %                 return
            end
        end
        
        if sum(ismember(level_of_service_var_ModeX_varNames{j},'_'))==0
            
            if strcmp(losData_choiceName{i},'car') && contains(level_of_service_var_ModeX_varNames{j},'travelCost')
                dataVar=DatasetPrediction.('PartySizeFactor');
                transformedMatrix(2:end,:)=transformedMatrix(2:end,:).*dataVar(:,ones(1,size(transformedMatrix,2)));
                level_of_service_var_prediction.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            else
                level_of_service_var_prediction.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            end
            
            
            
        else
            dataVarName=strsplit(level_of_service_var_ModeX_varNames{j},'_');
            if sum(ismember(dataset_varName,dataVarName{2}))==0
                warning('the following variable defined in los data does not exist in choice dataset: %10.0s',dataVarName{2})
                output=[];
                return
            end
            
            if strcmp(losData_choiceName{i},'car') && contains(dataVarName{1},'travelCost')
                dataVar=DatasetPrediction.(dataVarName{2}).*DatasetPrediction.('PartySizeFactor');
                transformedMatrix(2:end,:)=transformedMatrix(2:end,:).*dataVar(:,ones(1,size(transformedMatrix,2)));
                level_of_service_var_prediction.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            else
                dataVar=DatasetPrediction.(dataVarName{2});
                transformedMatrix(2:end,:)=transformedMatrix(2:end,:).*dataVar(:,ones(1,size(transformedMatrix,2)));
                level_of_service_var_prediction.(losData_choiceName{i}).(level_of_service_var_ModeX_varNames{j})=transformedMatrix;
            end
            
        end
        % -----------------------------------------------------------------------------------------------------------
        
    end
    
    % for zone var
    % for estimation data
    xNames=zonal_varNames.(losData_choiceName{i}).XNames;
    betaNames=zonal_varNames.(losData_choiceName{i}).betaNames;
    zonal_varNames.(losData_choiceName{i}).X=[];
    for j=1:length(xNames)
        transformedMatrix=nan(length(originZone)+1,length(destinationZoneIDs));
        transformedMatrix(1,:)=destinationZoneIDs;
        
        
        zoneVar=ZoneData.(xNames{j});
        zoneAttributeVector=nan(1,length(destinationZoneIDs));
        for k=1:length(destinationZoneIDs)
            zoneAttributeVector(k)=zoneVar(ismember(ZoneKey,destinationZoneIDs(k)));
        end
        transformedMatrix(2:end,:)=zoneAttributeVector(ones(length(originZone),1),:);
        zonal_varNames.(losData_choiceName{i}).X.(xNames{j})=transformedMatrix;
    end
    
    
    % for prediction data
    for j=1:length(xNames)
        transformedMatrix=nan(length(originZonePrediction)+1,length(destinationZoneIDs));
        transformedMatrix(1,:)=destinationZoneIDs;
        
        
        zoneVar=ZoneData.(xNames{j});
        zoneAttributeVector=nan(1,length(destinationZoneIDs));
        for k=1:length(destinationZoneIDs)
            zoneAttributeVector(k)=zoneVar(ismember(ZoneKey,destinationZoneIDs(k)));
        end
        transformedMatrix(2:end,:)=zoneAttributeVector(ones(length(originZonePrediction),1),:);
        zonal_var_prediction.(losData_choiceName{i}).(betaNames{j})=transformedMatrix;
    end
end

%% this part checks the same beta in destination choice
destinationChoice_betaNames_all={};
beta_belong=[];
zonal_or_los=[];  % zonal_or_los (1*N_destination_var vector), 1 means the corresponding variable is zonal_var; 3 means the corrsponding variable is los_var
N_destination_beta_all=0;
beta_0_varName={};
for i=1:length(firstLevel_choiceName)
    
    zonal_data_varnames_i=zonal_varNames.(firstLevel_choiceName{i}).betaNames';
    destinationChoice_betaNames_all=[destinationChoice_betaNames_all;zonal_data_varnames_i];
    zonal_or_los=[zonal_or_los;ones(length(zonal_data_varnames_i),1)];
    beta_belong=[beta_belong;i*ones(length(zonal_data_varnames_i),1)];
    
    level_of_service_varnames_i=fieldnames(level_of_service_var.(firstLevel_choiceName{i}));
    destinationChoice_betaNames_all=[destinationChoice_betaNames_all;level_of_service_varnames_i];
    zonal_or_los=[zonal_or_los;3*ones(length(level_of_service_varnames_i),1)];
    beta_belong=[beta_belong;i*ones(length(level_of_service_varnames_i),1)];
    
    N_destination_beta_all=N_destination_beta_all+length(zonal_data_varnames_i)+length(level_of_service_varnames_i);
    if ~isempty(zonal_data_varnames_i)
        beta_0_varName.(firstLevel_choiceName{i})=zonal_data_varnames_i{1};
    else
        beta_0_varName.(firstLevel_choiceName{i})='';
    end
    
    
end

% find the unique parameter
[unique_destinationChoice_betaNames,LA,LC]=unique(destinationChoice_betaNames_all,'stable');
unique_destinationChoice_beta_belong=[];
unique_destinationChoice_zonal_or_los=[];
for i=1:length(unique_destinationChoice_betaNames)
    unique_destinationChoice_zonal_or_los.(unique_destinationChoice_betaNames{i})=zonal_or_los(LC==i);
    unique_destinationChoice_beta_belong.(unique_destinationChoice_betaNames{i})=beta_belong(LC==i);
end

beta_indexing_structure.unique_destinationChoice_betaNames=unique_destinationChoice_betaNames;
beta_indexing_structure.unique_destinationChoice_zonal_or_los=unique_destinationChoice_zonal_or_los;
beta_indexing_structure.unique_destinationChoice_beta_belong=unique_destinationChoice_beta_belong;
beta_indexing_structure.LC=LC;
beta_indexing_structure.beta_belong=beta_belong;
beta_indexing_structure.zonal_or_los=zonal_or_los;
beta_indexing_structure.beta_0_varName=beta_0_varName;
%% estimate destination choice first


% N_choice_accessMode=length(secondLevel_choiceName);
N_choice_modeChoice=length(firstLevel_choiceName);
Observation_index_ALL=[];
DestinationCHOICE_All=[];  % DestinationCHOICE_All.(firstLevel_choiceName{i}) gives the destination choice matrix
zonal_matrix_All=[]; % zonal_matrix_All.(firstLevel_choiceName{i}) gives the zonal matrix structure
zonal_data_varName_All=[]; % zonal_data_varName_All.(firstLevel_choiceName{i}) gives the string vector of variable names
los_matrix_All=[]; % los_matrix_All.(firstLevel_choiceName{i}) gives the level of service structure
level_of_service_var_varNames_All=[]; % level_of_service_var_varNames_All.(firstLevel_choiceName{i}) gives variabke names of los_matrix
choiceSetIndex=[];
predictionData=[];
predictionData_prediction=[];
for i=1:length(firstLevel_choiceName)
    
    mode_index=Dataset.(Y_name_level_modeChoice)==i;
    zonal_data_i=zonal_varNames.(firstLevel_choiceName{i});
    level_of_service_var_i=level_of_service_var.(firstLevel_choiceName{i});
    [CHOICE_i,zonal_matrix_i,zonal_matrix_i_prediction,zonal_data_varName_i,los_matrix_i,los_matrix_i_prediction,level_of_service_var_varNames_i,choiceSetIndex_i]=...
        SpecifyVariables_destinationChoice(mode_index,zonal_data_i,level_of_service_var_i,Dataset,obs_varName,destination_varName);
    
    Observation_index_ALL.(firstLevel_choiceName{i})=mode_index;
    DestinationCHOICE_All.(firstLevel_choiceName{i})=CHOICE_i;
    zonal_matrix_All.(firstLevel_choiceName{i})=zonal_matrix_i;
    zonal_data_varName_All.(firstLevel_choiceName{i})=zonal_data_varName_i;
    los_matrix_All.(firstLevel_choiceName{i})=los_matrix_i;
    level_of_service_var_varNames_All.(firstLevel_choiceName{i})=level_of_service_var_varNames_i;
    choiceSetIndex.(firstLevel_choiceName{i})=choiceSetIndex_i;
    predictionData.los.(firstLevel_choiceName{i})=los_matrix_i_prediction;
    predictionData.zonal.(firstLevel_choiceName{i})=zonal_matrix_i_prediction;
    
    
    level_of_service_var_prediction_i=level_of_service_var_prediction.(firstLevel_choiceName{i});
    zonal_var_prediction_i=zonal_var_prediction.(firstLevel_choiceName{i});
    los_matrix_i_prediction=SpecifyVariables_prediction(level_of_service_var_prediction_i);
    zonal_matrix_i_prediction=SpecifyVariables_prediction(zonal_var_prediction_i);
    predictionData_prediction.los.(firstLevel_choiceName{i})=los_matrix_i_prediction;
    predictionData_prediction.zonal.(firstLevel_choiceName{i})=zonal_matrix_i_prediction;
end

%%estimate the joint destination model
destinationChoice_modelResult=conditional_logit_model_destination_choice_log_zonal_joint(Observation_index_ALL,DestinationCHOICE_All,choiceSetIndex,zonal_matrix_All,los_matrix_All,beta_indexing_structure,predictionData,predictionData_prediction);
%



%%
% for the nested logit model part

Dataset_temp=Dataset;
Dataset_temp_prediction=DatasetPrediction;
logsum_var_ModeChoice={};
beta_names_ModeChoice=model_specification_modeChoice.beta_names;
X_names_ModeChoice=model_specification_modeChoice.X_names;
Y_names_ModeChoice=model_specification_modeChoice.Y_names;
choice_name_ModeChoice=model_specification_modeChoice.choice_name;

logsum_all=destinationChoice_modelResult.logsum_full;
logsum_all_prediction=destinationChoice_modelResult.logsum_full_prediction;
validModeChoice=ones(size(Dataset_temp,1),1);
for j=1:length(firstLevel_choiceName)
    logsum_temp=logsum_all.(firstLevel_choiceName{j});
    Dataset_temp.(strcat('logsum_',firstLevel_choiceName{j}))=logsum_temp;
    logsum_var_ModeChoice=[logsum_var_ModeChoice,strcat('logsum_',firstLevel_choiceName{j})];
    validModeChoice(isnan(logsum_temp))=0;
    
    logsum_temp_prediction=logsum_all_prediction.(firstLevel_choiceName{j});
    Dataset_temp_prediction.(strcat('logsum_',firstLevel_choiceName{j}))=logsum_temp_prediction;
end
Dataset_ModeChoice=Dataset_temp(logical(validModeChoice),:);



%%
MC_overall=MNL_model_logsum(Dataset_ModeChoice,beta_names_ModeChoice,X_names_ModeChoice,Y_names_ModeChoice,choice_name_ModeChoice,logsum_var_ModeChoice,Dataset_temp_prediction,1);


%%%%%%%%%%%%%%%%%start here do the specific variables for the accessMode part
% specific variables
% [CHOICEIDX_modeChoice, F_X_modeChoice, LAB_FX_modeChoice, I_BETA_FX_modeChoice, FX_alt_modeChoice]=SpecifyVariables_MNL(Dataset_temp,model_specification_modeChoice,Dataset_temp);
%%%%%%%%% continue here!!!!!!!!!!!!!!!!!!!!!!!

% save the parameter
ModeChoice_beta=MC_overall.beta;
ModeChoice_beta_tvalue=MC_overall.beta_tvalue;
ModeChoice_beta_names=MC_overall.beta_names;
for i=1:length(firstLevel_choiceName)
    logsum_col=logsum_all.(firstLevel_choiceName{i});
    Dataset_ModeChoice.(strcat('logsum_',firstLevel_choiceName{i}))=logsum_col(logical(validModeChoice));
end

%%

% Initial parameter values
% 1st variables from destination choice
beta_start_fx=destinationChoice_modelResult.beta;
beta_start_tvalue=destinationChoice_modelResult.beta_tvalue;
beta_names=destinationChoice_modelResult.beta_name;
N_destination_beta=length(destinationChoice_modelResult.beta);

% 2nd: variables from PTaccessMode nest
N_ModeChoice_beta=length(ModeChoice_beta);
beta_start_fx=[beta_start_fx;ModeChoice_beta];
beta_start_tvalue=[beta_start_tvalue;ModeChoice_beta_tvalue];

for k=1:length(ModeChoice_beta_names)
    beta_names=[beta_names;strcat('ModeChoicePart_',ModeChoice_beta_names{k})];
end



beta_start_structure={};
tvalue_start_structure={};
betaName_start_structure={};
beta_start_structure.('destinationChoice')=destinationChoice_modelResult.organized_beta;
tvalue_start_structure.('destinationChoice')=destinationChoice_modelResult.organized_beta_tvalue;
betaName_start_structure.('destinationChoice')=destinationChoice_modelResult.organized_beta_name;

beta_start_structure.('modeChoice')=MC_overall.organized_beta;  % note that the last element in beta_structure.('mode_choice') is logsum variable
tvalue_start_structure.('modeChoice')=MC_overall.organized_beta_tvalue;
betaName_start_structure.('modeChoice')=MC_overall.organized_beta_names;
beta_start_structure.('modeChoicemu')=MC_overall.mu;
tvalue_start_structure.('modeChoicemu')=MC_overall.mu_t_value;

output_sequential={};
output_sequential.('beta')=beta_start_structure;
output_sequential.('tvalue')=tvalue_start_structure;
output_sequential.('beta_name')=betaName_start_structure;
output_sequential.('unorganized_beta')=beta_start_fx;

% Beta_belong is used to estimate which beta belongs to which part
% it is a 1*N_beta vector:
% 1 denotes beta for destination choice
% 2 denotes beta for acessBeta
% 3 denotes beta for mode choice
Beta_belong=ones(1,length(beta_start_fx));
Beta_belong(N_destination_beta+1:N_destination_beta+N_ModeChoice_beta)=2;


fprintf('\n\n----------------- DISPLAY RESULTS ---------------------')

fprintf('\nnumber of observations: %10.0f', size(Dataset_ModeChoice,1));
fprintf('\nnumber of variables: %10.0f', length(beta_start_fx));

LL_B_start = destinationChoice_modelResult.model_fit.Loglikelihood_final+MC_overall.model_fit.Loglikelihood_final;
fprintf('\nLog-likelihood final: %10.3f', LL_B_start)

% 3: (change the value if needed in calculating the null loglikelihood LL_0)
LL_0=destinationChoice_modelResult.model_fit.Loglikelihood_zero+MC_overall.model_fit.Loglikelihood_zero;
fprintf('\nLog-likelihood for zero beta: %10.3f', LL_0);

% 4: Goodness-of-fit
fprintf('\nMcFadden rho: %5.3f', 1-LL_B_start/LL_0);

% 5: adjusted Goodness-of-fit
fprintf('\nAdjusted McFadden rho: %5.3f', 1-(LL_B_start-length(beta_start_fx))/LL_0);



% output the model fit
model_fit_info={};
model_fit_info.('Loglikelihood_final')=-LL_B_start;
model_fit_info.('Loglikelihood_zero')=-LL_0;
model_fit_info.('adjusted_McFadden_rho')=1-(-LL_B_start-length(beta_start_fx))/(-LL_0);
output_sequential.('model_fit')=model_fit_info;
output_sequential.('logsum')=MC_overall.logsum_fullData;

output=output_sequential;

end







%% new function
function [CHOICE,zonal_matrix_full,zonal_matrix_prediction,zonal_data_varName_no_key,los_matrix_full,los_matrix_prediction,level_of_service_var_varNames,choiceSetIndex_i]=...
    SpecifyVariables_destinationChoice(mode_index,zonal_data_i,Level_of_service_var,Dataset_full,obs_varName,destination_varName)
% CHOOSEVARIABLES structure and transforms the data in file 'filename' to a
% more usable form. Here, is where you specify the variables to be included
% in the model and whether they are fixed or random and whether thet are
% normal or log-normal.
% NOTE: you can add more variables from the original data by adding them in
% LoadData below.

% Global variables that are used by other functions. we recommend that you
% don't change this.


dataset=table2array(Dataset_full(mode_index,:));
% % importat here!!!!!!!!!!!!!!!!!
% % replace nan with 0 in the zonal data
% zonal_data_var(isnan(zonal_data_var))=0;

dataset_varName=Dataset_full.Properties.VariableNames;

destination_column=find(ismember(dataset_varName,destination_varName));  % gives which column in dataset denotes the destination choice


% Calculate choice matrix.
[CHOICE] = CalculateChoice_destinationChoice(Level_of_service_var,dataset,destination_column);

% Organize the input matrix zonal_data_var

zonal_matrix_full=[];
zonal_matrix_prediction=[];
zonal_data_varName_no_key=zonal_data_i.betaNames;
zonal_data_XName_no_key=zonal_data_i.XNames;
for i=1:length(zonal_data_varName_no_key)
    temp=zonal_data_i.X.(zonal_data_XName_no_key{i});
    temp=temp(2:end,:);
    zonal_matrix_full.(zonal_data_varName_no_key{i})=temp(mode_index,:);
    zonal_matrix_prediction.(zonal_data_varName_no_key{i})=temp;
end

% Organize the Level_of_service_var
los_matrix_full=[];
los_matrix_prediction=[];
level_of_service_var_varNames=fieldnames(Level_of_service_var);
for i=1:length(level_of_service_var_varNames)
    input_LoS_1=Level_of_service_var.(level_of_service_var_varNames{i});
    temp=input_LoS_1(2:end,:);
    los_matrix_full.(level_of_service_var_varNames{i})=temp(mode_index,:);
    los_matrix_prediction.(level_of_service_var_varNames{i})=temp;
    if i==1
        choiceSetIndex_i=isnan(temp(mode_index,:));
    else
        choiceSetIndex_i=choiceSetIndex_i+isnan(temp(mode_index,:));
    end
    
end
choiceSetIndex_i=choiceSetIndex_i==0;

end

function [CHOICE] = CalculateChoice_destinationChoice(Level_of_service_var,dataset,destination_column)

level_of_service_var_varNames=fieldnames(Level_of_service_var);
input_LoS_1=Level_of_service_var.(level_of_service_var_varNames{1});
key=input_LoS_1(1,:); %% destination zone key.
NP_mode=size(dataset,1);
NZ_mode=length(key);
CHOICE=zeros(NP_mode,NZ_mode);
for ii=1:NP_mode
    col= key==dataset(ii,destination_column);
    CHOICE(ii,col)=1;
end
%   for i=1:NP
%       if sum(CHOICE(i,:))~=1
%          warning('\nthe following row in the input data does not find a destination in the "Key": %10.0f', i);
%       end
%   end
end

function dataStructure_noColumnIds=SpecifyVariables_prediction(dataStructure)
dataStructure_varNames=fieldnames(dataStructure);
dataStructure_noColumnIds=[];
for i=1:length(dataStructure_varNames)
    data=dataStructure.(dataStructure_varNames{i});
    dataStructure_noColumnIds.(dataStructure_varNames{i})=data(2:end,:);
end
end
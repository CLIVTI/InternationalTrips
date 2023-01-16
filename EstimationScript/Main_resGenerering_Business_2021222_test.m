close all 
clear variables;
restoredefaultpath

PathStorage='C:/Users/ChengxiL/VTI/Internationella resor - General/Estimation';
addpath(genpath(PathStorage))

%% combine dataset for trip generation estimation done.
% RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering.csv';
% UPBDDataPath='//vti.se/root/Internationella-resor/R skript/RVU/R/UPBDEstimation.csv';
% 
% opts = detectImportOptions(RVUFilePath);
% RVU=readtable(RVUFilePath,opts);
% 
% opts = detectImportOptions(UPBDDataPath);
% opts.VariableOptions
% UPBD=readtable(UPBDDataPath,opts);
% UPBD.UENR=str2double(UPBD.UENR);
% UPBD(:,1)=[];
% RVU_TripGeneration=RVU(:,{'UENR','D_A_DAT','bortavaro','SEX','AGE','HHINK','HHTYP','BILANT','VILLA',...
%     'logsumBortavaro_1','logsumBortavaro_2','logsumBortavaro_3'});
% dataForEstimation=RVU_TripGeneration;
% 
% for i=1:size(UPBD,1)
%     
%     if isempty(find(RVU_TripGeneration.UENR==UPBD.UENR(i), 1))
%         structNewRow={};
%         structNewRow(1,1).UENR = UPBD.UENR(i);
%         structNewRow(1,1).D_A_DAT = -1;
%         structNewRow(1,1).bortavaro = 5; 
%         structNewRow(1,1).SEX = UPBD.SEX(i);
%         structNewRow(1,1).AGE = UPBD.AGE(i);
%         structNewRow(1,1).HHINK = UPBD.HHINK(i);
%         structNewRow(1,1).HHTYP = UPBD.HHTYP(i);
%         structNewRow(1,1).BILANT = UPBD.BILANT(i);
%         structNewRow(1,1).VILLA = UPBD.VILLA(i);
%         structNewRow(1,1).logsumBortavaro_1=-999;
%         structNewRow(1,1).logsumBortavaro_2=-999;
%         structNewRow(1,1).logsumBortavaro_3=-999;
%         dataForEstimation = [dataForEstimation;struct2table(structNewRow)];
%         fprintf('\n UENR added to data: %10.0f ', UPBD.UENR(i));
%     else 
%         fprintf('\n UENR already exists in TripGeneration data: %10.0f ', UPBD.UENR(i));
%     end
% end
% 
% writetable(dataForEstimation,'//vti.se/root/Internationella-resor/R skript/RVU/R/DataForTripGenerationEstimation.csv')
      

%% estimation script
RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering_business.csv';
opts = detectImportOptions(RVUFilePath);
RVU=readtable(RVUFilePath,opts);

% number car
RVU.BILANT(isnan(RVU.BILANT))=0;

% income
RVU.lowIncome=RVU.INKUP<300000;
RVU.highIncome=RVU.INKUP>=300000;
RVU.incomeMissing=isnan(RVU.INKUP);

% age
RVU.age_17=RVU.AGE<18;
RVU.age_18_30=RVU.AGE>=18 & RVU.AGE<=30;
RVU.age_31_64=RVU.AGE>=31 & RVU.AGE<=64;
RVU.age_64=RVU.AGE>=65;

% gender
RVU.female=RVU.SEX==2;
% villa or apartment
RVU.VILLA=RVU.VILLA==1;

% season
MonthDay=(RVU.D_A_DAT./10000-floor(RVU.D_A_DAT./10000)).*10000;
RVU.summer=MonthDay>=700 & MonthDay<=899;
RVU.NotSummer=1-RVU.summer;
RVU.Jul=(MonthDay>=1220 & MonthDay<=1231) | (MonthDay>=100 & MonthDay<=110);

RVU.AntalSmallBarn=(RVU.HHTYP==5 | RVU.HHTYP==12);
RVU.AntalSmallBarn=(RVU.HHTYP==14).*2;

RVU.AntalStoreBarn=(RVU.HHTYP==6 | RVU.HHTYP==13);
RVU.AntalStoreBarn=(RVU.HHTYP==15).*2;



% Y variable
RVU.LongDistanceTripType=zeros(size(RVU,1),1);
RVU.LongDistanceTripType(RVU.bortavaro==0)=1;
RVU.LongDistanceTripType(RVU.bortavaro>0)=2;
nanIndex=isnan(RVU.logsumBortavaro) | RVU.LongDistanceTripType==0;
RVUEstimation=RVU(~nanIndex,:);
RVUEstimation=RVUEstimation(RVUEstimation.LongDistanceTripType>0 & RVUEstimation.AGE>18,:);
RVUEstimation.summer_Logsum=RVUEstimation.summer.*RVUEstimation.logsumBortavaro;
RVUEstimation.Nosummer_Logsum=RVUEstimation.NotSummer.*RVUEstimation.logsumBortavaro;



Y_names={'LongDistanceTripType'};
choice_name={'NoTrip','Trip'};

beta_names_fix={};
X_names_fix={};

% beta_names_fix.(choice_name{1})={};   % ICEV
% X_names_fix.(choice_name{1})={};    % ICEV
% 
% beta_names_fix.(choice_name{2})={'0Natt_ASC','0Natt_AntalBilar','0Natt_female','0Natt_Villa','0Natt_age_17','0Natt_age_31_64','0Natt_age_64','0Natt_lowIncome','0Natt_highIncome','0Natt_incomeMissing','0Natt_summer','0Natt_AntalSmallBarn','0Natt_AntalStoreBarn','0Natt_logsum'};   % ICEV
% X_names_fix.(choice_name{2})={'ASC','BILANT','female','VILLA','age_17','age_31_64','age_64','lowIncome','highIncome','incomeMissing','summer','AntalSmallBarn','AntalStoreBarn','logsumBortavaro_1'};    % ICEV
% 
% beta_names_fix.(choice_name{3})={'1_5Natt_ASC','1_5Natt_AntalBilar','1_5Natt_female','1_5Natt_Villa','1_5Natt_age_17','1_5Natt_age_31_64','1_5Natt_age_64','1_5Natt_lowIncome','1_5Natt_highIncome','1_5Natt_incomeMissing','1_5Natt_summer','1_5Natt_AntalSmallBarn','1_5Natt_AntalStoreBarn','1_5Natt_logsum'};   % ICEV
% X_names_fix.(choice_name{3})={'ASC','BILANT','female','VILLA','age_17','age_31_64','age_64','lowIncome','highIncome','incomeMissing','summer','AntalSmallBarn','AntalStoreBarn','logsumBortavaro_2'};    % ICEV
% 
% beta_names_fix.(choice_name{4})={'6+Natt_ASC','6+Natt_AntalBilar','6+Natt_female','6+Natt_Villa','6+Natt_age_17','6+Natt_age_31_64','6+Natt_age_64','6+Natt_highIncome','6+Natt_incomeMissing','6+Natt_summer','6+Natt_AntalSmallBarn','6+Natt_AntalStoreBarn','6+Natt_logsum'};   % ICEV
% X_names_fix.(choice_name{4})={'ASC','BILANT','female','VILLA','age_17','age_31_64','age_64','highIncome','incomeMissing','summer','AntalSmallBarn','AntalStoreBarn','logsumBortavaro_3'};    % ICEV

beta_names_fix.(choice_name{1})={'NoTrip_lowIncome'};   
X_names_fix.(choice_name{1})={'lowIncome'};   
beta_names_fix.(choice_name{2})={'Trip_ASC','Trip_AntalBilar','Trip_female','Trip_age_31_64','Trip_age_64','Trip_highIncome','Trip_summer','Trip_Jul'};   % 'logsum'
X_names_fix.(choice_name{2})={'ASC','BILANT','female','age_31_64','age_64','highIncome','summer','Jul'};    % 'logsumBortavaro'


% beta_names_fix.(choice_name{1})={};   
% X_names_fix.(choice_name{1})={};   
% beta_names_fix.(choice_name{2})={'Trip_ASC','Trip_logsum'};   % ICEV
% X_names_fix.(choice_name{2})={'ASC','logsumBortavaro'};    % ICEV


output=MNL_model(RVUEstimation,beta_names_fix,X_names_fix,Y_names,choice_name,RVUEstimation,1);

RVUEstimation.Baseline_Probability_NoTrip=output.probability_fullData(:,1);
RVUEstimation.Baseline_Probability_Trip=output.probability_fullData(:,2);
mean(RVUEstimation.Baseline_Probability_NoTrip)
% writetable(RVUEstimation,'//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation_reseGenerering_business_Elasticity.csv')

%-------------------------------------------------------
function output=conditional_logit_model_destination_choice_log_zonal_joint(Observation_index_ALL,DestinationCHOICE_All,choiceSetIndex,zonal_matrix_All,los_matrix_All,beta_indexing_structure,predictionData,predictionData_prediction) % note that ASC has been included in both "specific_names_fix" and "variables"
% the simple benchmark MNL model
% input:
%        Observation_index_ALL : (structure) -- example: Observation_index_ALL.walk is a (Nobs*1) vector telling you
%        which observations belongs to
%        Mode_index: (Np*1 logical ) -- tells which obs in Dataset_Full should be used for pt destination choice model

%        Zonal_data: (NZ *N_zonal_var table) -- a table that stores all the zonal level variables.
%                                               1: Note that the "zonal_data" must contain one variable that has the same varNames
%                                               as the one in "Key". In the Cykelkiedje project, the varNames in "Key" and "zonal_data"
%                                               are both "sams_zone"
%                                               2: Note that if there is any missing value in the zonal data that apprears in the zonal
%                                               variables, replace it with zero!!!!!!!!!!! (extremely important)

%        Level_of_service_var (structure) -- each field in the structure denotes a level of service variable matrix.
%                                            each matrix has NZ * NZ+1 dimension where matrix(:,2:end) is the level of
%                                            service matrix while matrix(:,1) is the Key (note that the Key is not necessarily
%                                            sorted and have the same sequence as in "Key")
%        obs_varName (string) --  column variable name that represents the observation index column
%        destination_varName (string) --  column variable name that represents the destination choice column


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

global beta_names unique_destinationChoice_zonal_or_los unique_destinationChoice_beta_belong LC_D beta_belong_D zonal_or_los_D
global Observation_index_D
global DestinationCHOICE_D
global choiceset_index
global zonal_matrix_D
global los_matrix_D
global beta_0_varName
global firstLevel_choiceName secondLevel_choiceName
global PT_location

beta_names=beta_indexing_structure.unique_destinationChoice_betaNames;
unique_destinationChoice_zonal_or_los=beta_indexing_structure.unique_destinationChoice_zonal_or_los;
unique_destinationChoice_beta_belong=beta_indexing_structure.unique_destinationChoice_beta_belong;
LC_D=beta_indexing_structure.LC;
beta_belong_D=beta_indexing_structure.beta_belong;
zonal_or_los_D=beta_indexing_structure.zonal_or_los;
beta_0_varName=beta_indexing_structure.beta_0_varName;
Observation_index_D=Observation_index_ALL;
DestinationCHOICE_D=DestinationCHOICE_All;
choiceset_index=choiceSetIndex;
zonal_matrix_D=zonal_matrix_All;
los_matrix_D=los_matrix_All;
%% estimation rutine
% Initial parameter values
beta_start_fx = zeros(length(beta_names),1);
beta_start=beta_start_fx;
options = optimoptions('fminunc','Algorithm','quasi-newton','SpecifyObjectiveGradient',true,'Display','Iter','TolFun',1e-6,'TolX',1e-10,'MaxFunEvals',100000,'MaxIter',30000);
% options = optimset('GradObj','on','LargeScale','off','Display','Iter','TolFun',1e-5,'TolX',1e-6','MaxFunEvals',10000,'MaxIter',3000);
[beta,~,~,~,~,hessian_initial]= fminunc(@LogLikelihood_CL,beta_start,options); % '@' is a handle for the LogLikelihood below

%% post estimation process
sigma=sqrt(diag(inv(hessian_initial)));
tvalues = beta./sigma;
% 1: display parameter estimates and t-statistics


beta_F=beta(LC_D);
beta_names_F=beta_names(LC_D);
tvalues_F=tvalues(LC_D);


organized_beta={};
organized_tvalue={};
organized_beta_name={};


for i=1:length(firstLevel_choiceName)
    beta_names_F_i=beta_names_F(beta_belong_D==i);
    beta_F_i=beta_F(beta_belong_D==i);
    tvalues_F_i=tvalues_F(beta_belong_D==i);
    zonal_or_los_D_i=zonal_or_los_D(beta_belong_D==i);
    
    beta_0_varName_i=beta_0_varName.(firstLevel_choiceName{i});
    F_0_index=find(ismember(beta_names_F_i,beta_0_varName_i));
    fprintf('\n\n----------------- DISPLAY RESULTS ---------------------')
    fprintf('\n %-15s : %8s : %8s \n' , strcat('Destination_',firstLevel_choiceName{i}),['Estimate'],['t-value']);
    for j=1:length(beta_F_i)
        if j==F_0_index
            fprintf('%-15s : %+8.4f : %+8.4f \n', strcat('log-size parameter_',beta_names_F_i{j}) , beta_F_i(j) , tvalues_F_i(j))
        elseif zonal_or_los_D_i(j)==1
            fprintf('%-15s : %+8.4f : %+8.4f \n', strcat('exp_',beta_names_F_i{j}) , exp(beta_F_i(j)) , 1./(beta_F_i(j)./tvalues_F_i(j)))
        elseif zonal_or_los_D_i(j)==3
            fprintf('%-15s : %+8.4f : %+8.4f \n', beta_names_F_i{j} , beta_F_i(j) , tvalues_F_i(j))
        end
    end
    organized_beta.(firstLevel_choiceName{i})=beta_F_i;
    organized_tvalue.(firstLevel_choiceName{i})=tvalues_F_i;
    organized_beta_name.(firstLevel_choiceName{i})=beta_names_F_i;
    
    
    
end


% output is a strucuture saving all parameter values and X_names

output.('beta')=beta;
output.('beta_tvalue')=tvalues;
output.('beta_name')=beta_names;

output.('organized_beta')=organized_beta;
output.('organized_beta_tvalue')=organized_tvalue;
output.('organized_beta_name')=organized_beta_name;


NP=length(Observation_index_ALL.(firstLevel_choiceName{1}));

% fprintf('\nnumber of observations: %10.0f', NP);
% 2: Log Likelihood values
LL_B = -LogLikelihood_CL(beta);
%  fprintf('\nLog-likelihood: %10.3f', LL_B);

% 3: (change the value if needed in calculating the null loglikelihood LL_0)
LL_0 = -LogLikelihood_CL(0*beta); % LL for zero model
%  fprintf('\nLog-likelihood for zero beta: %10.3f', LL_0);

% 4: Goodness-of-fit
%  fprintf('\nMcFadden rho: %5.3f', 1-LL_B/LL_0);

% 5: adjusted Goodness-of-fit
%  fprintf('\nAdjusted McFadden rho: %5.3f', 1-(LL_B-length(beta))/LL_0);

%  5: LL for alternative-specific constants only
%  (according to first-order condition, compare sum_predchoice below)

% output the model fit
model_fit_info={};
model_fit_info.('Loglikelihood_final')=LL_B;
model_fit_info.('Loglikelihood_zero')=LL_0;
model_fit_info.('adjusted_McFadden_rho')=1-(LL_B-length(beta))/LL_0;
output.('model_fit')=model_fit_info;

[log_P_all,logsum_all,log_sum_zonal_all]  =Destination_Logit_logsum(beta,predictionData);
[log_P_all_0beta,logsum_all_0beta,log_sum_zonal_all_0beta]  =Destination_Logit_logsum(beta*0,predictionData);
output.('log_P_full')=log_P_all;
output.('logsum_full')=logsum_all;
output.('logsum_zonal_full')=log_sum_zonal_all;
output.('log_P_0beta')=log_P_all_0beta;
output.('logsum_0beta')=logsum_all_0beta;
output.('logsum_zonal_0beta')=log_sum_zonal_all_0beta;

[log_P_all_prediction,logsum_all_prediction,log_sum_zonal_all_prediction]  =Destination_Logit_logsum(beta,predictionData_prediction);
output.('log_P_full_prediction')=log_P_all_prediction;
output.('logsum_full_prediction')=logsum_all_prediction;
output.('logsum_zonal_full_prediction')=log_sum_zonal_all_prediction;
end


function [log_P_all,logsum_all,log_sum_zonal_all] = Destination_Logit_logsum(beta,predictionData)
global beta_names LC_D beta_belong_D zonal_or_los_D
global Observation_index_D
global firstLevel_choiceName
global beta_0_varName




firstLevel_choiceName=fieldnames(Observation_index_D);
F = beta(LC_D); % Fixed parameters
beta_names_F=beta_names(LC_D);
log_P_all=[];
log_sum_zonal_all=[];
logsum_all=[];
for i=1:length(firstLevel_choiceName)
    beta_names_F_i=beta_names_F(beta_belong_D==i);
    F_i=F(beta_belong_D==i);
    zonal_or_los_D_i=zonal_or_los_D(beta_belong_D==i);
    zonal_matrix_D_i=predictionData.zonal.(firstLevel_choiceName{i});
    los_matrix_D_i=predictionData.los.(firstLevel_choiceName{i});
    beta_0_varName_i=beta_0_varName.(firstLevel_choiceName{i});
    [log_P,~,log_sum,log_sum_zonal]=Logit_prediction(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i);
    
    log_P_all.(firstLevel_choiceName{i})=log_P;
    log_sum_zonal_all.(firstLevel_choiceName{i})=log_sum_zonal;
    logsum_all.(firstLevel_choiceName{i})=log_sum;
    
end


end



function [LL,g] = LogLikelihood_CL(beta)
global beta_names unique_destinationChoice_zonal_or_los unique_destinationChoice_beta_belong LC_D beta_belong_D zonal_or_los_D
global Observation_index_D
global DestinationCHOICE_D
global choiceset_index
global zonal_matrix_D
global los_matrix_D
global firstLevel_choiceName
global beta_0_varName

firstLevel_choiceName=fieldnames(Observation_index_D);
F = beta(LC_D); % Fixed parameters
beta_names_F=beta_names(LC_D);
LL=0;
log_P_all=[];
log_sum_zonal_all=[];
for i=1:length(firstLevel_choiceName)
    beta_names_F_i=beta_names_F(beta_belong_D==i);
    F_i=F(beta_belong_D==i);
    zonal_or_los_D_i=zonal_or_los_D(beta_belong_D==i);
    DestinationCHOICE_D_i=DestinationCHOICE_D.(firstLevel_choiceName{i});
    zonal_matrix_D_i=zonal_matrix_D.(firstLevel_choiceName{i});
    los_matrix_D_i=los_matrix_D.(firstLevel_choiceName{i});
    beta_0_varName_i=beta_0_varName.(firstLevel_choiceName{i});
    choiceset_index_i=choiceset_index.(firstLevel_choiceName{i});
    
    % [log_P,~,~,log_sum_zonal]=Logit(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i);
    [log_P,~,~,log_sum_zonal]=Logit_PT(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i,choiceset_index_i);
    log_P_choosen = log_P.*DestinationCHOICE_D_i;
    LL =LL -sum(sum((log_P_choosen)));
    
    log_P_all.(firstLevel_choiceName{i})=log_P;
    log_sum_zonal_all.(firstLevel_choiceName{i})=log_sum_zonal;
end


%%
% start working on derivatives
g=zeros(length(beta),1);

for i=1:length(beta)
    beta_belong_i=unique_destinationChoice_beta_belong.(beta_names{i});
    zonal_or_los_i=unique_destinationChoice_zonal_or_los.(beta_names{i});
    g(i)=0;
    for j=1:length(beta_belong_i)
        F_i=F(beta_belong_D==beta_belong_i(j));
        beta_names_F_i=beta_names_F(beta_belong_D==beta_belong_i(j));
        
        zonal_matrix_D_i=zonal_matrix_D.(firstLevel_choiceName{beta_belong_i(j)});
        los_matrix_D_i=los_matrix_D.(firstLevel_choiceName{beta_belong_i(j)});
        beta_name_0=beta_0_varName.(firstLevel_choiceName{beta_belong_i(j)});
        
        % Observation_index_D_i=Observation_index_D.(firstLevel_choiceName{beta_belong_i(j)});
        DestinationCHOICE_D_i=DestinationCHOICE_D.(firstLevel_choiceName{beta_belong_i(j)});
        
        log_P=log_P_all.(firstLevel_choiceName{beta_belong_i(j)});
        log_P(isnan(log_P))=0;
        log_sum_zonal=log_sum_zonal_all.(firstLevel_choiceName{beta_belong_i(j)});
        log_sum_zonal(isnan(log_sum_zonal))=0;
        
        choiceset_index_i=choiceset_index.(firstLevel_choiceName{beta_belong_i(j)});
        
        if zonal_or_los_i(j)==1 % this is the zonal var
            if strcmp(beta_name_0,beta_names{i})  % if this is the first
                D_V_chosen=sum(log_sum_zonal.*DestinationCHOICE_D_i,2);
                D_logsum=sum(exp(log_P).*choiceset_index_i.*log_sum_zonal,2);
            else
                F_0=F_i(ismember(beta_names_F_i,beta_name_0));
                F_x=F_i(ismember(beta_names_F_i,beta_names{i}));
                
                zonal_matrix_temp=zonal_matrix_D_i.(beta_names{i});
                zonal_matrix_temp(isnan(zonal_matrix_temp))=0;
                
                
                D_V_chosen=sum(F_0.*exp(F_x).*zonal_matrix_temp./exp(log_sum_zonal).*DestinationCHOICE_D_i,2);
                D_logsum=sum(exp(log_P).*F_0.*exp(F_x).*zonal_matrix_temp./exp(log_sum_zonal).*choiceset_index_i,2);
            end
            grad_chosen=D_V_chosen-D_logsum;
            g(i)=g(i)-sum(grad_chosen);
        elseif zonal_or_los_i(j)==3 % if this is the los var
            los_matrix_temp=los_matrix_D_i.(beta_names{i});
            los_matrix_temp(isnan(los_matrix_temp))=0;
            
            D_V_chosen=sum(los_matrix_temp.*DestinationCHOICE_D_i,2);
            D_logsum=sum(exp(log_P).*choiceset_index_i.*los_matrix_temp,2);
            grad_chosen=D_V_chosen-D_logsum;
            g(i)=g(i)-sum(grad_chosen);
        end
    end
end

end


function [log_P,V,log_sum,log_sum_zonal]  =Logit_PT(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i,choiceset_index_i)
% input: F is the vector of parameters, 1*N_FX vector
% output: log_P is the log of probability of choosing each alternative,
%         N_obs*N_choice dimension
%         V is utility vector (N_obs*N_choice) dimension
%         log_sum vector of log_sum (denominator of the probability), N_obs*1
%         vector
NP=size(choiceset_index_i,1);
NZ=size(choiceset_index_i,2);
% LOGIT(F) returns the likelihood and log-likelihood of the observaitions
% in VAR_FX for the fixed parameters F
% F is N_RD x NP
[V, log_sum_zonal]=Utilities(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i,choiceset_index_i);
% V is the utility matrix which has (N_obs*N_choice) dimension
% there is a risk of exp function that is if exp(V_late_response) is too large,
% there is potential to make exp(V_late_response) a inf or nan.
% just in case inf happens I use 10^20 instead of inf
% max_V=max(V,[],2);
% log_sum=zeros(NP,1); % log_sum is a column vector denote the log(sum(exp(V)))

% for i=1:NZ
%     log_sum=log_sum+exp(V(:,i)-max_V);
% end
% log_sum=log(log_sum)+max_V;

log_sum=-999.*ones(NP,1);
log_P=zeros(NP,NZ);
for i=1:NP
    V_temp=V(i,logical(choiceset_index_i(i,:)));
    
    max_V=max(V_temp);
    log_sum(i)=log(sum(exp(V_temp-max_V)))+max_V;
    log_P(i,logical(choiceset_index_i(i,:)))=V_temp-log_sum(i);
    
end


% log_sum=log(sum(exp(V-max_V(:,ones(1,NZ))),2))+max_V;


% log_P_not_use_new_tram = V_not_use_new_tram-(log(exp(V_not_use_new_tram-max_V)+exp(V_use_new_tram-max_V))+max_V);
end

function [V_utility,log_sum_zonal]  = Utilities(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i,choiceset_index_i)

NP=size(choiceset_index_i,1);
NZ=size(choiceset_index_i,2);

V_utility_zonal=zeros(NP,NZ);
V_utility_los=zeros(NP,NZ);
sum_zonal=zeros(NP,NZ);
beta_0_index=find(ismember(beta_names_F_i,beta_0_varName_i));
for i=1:length(F_i)
    if zonal_or_los_D_i(i)==1
        if beta_0_index==i
            sum_zonal=sum_zonal+exp(0).*zonal_matrix_D_i.(beta_names_F_i{i});
        else
            sum_zonal=sum_zonal+exp(F_i(i)).*zonal_matrix_D_i.(beta_names_F_i{i});
        end
    elseif zonal_or_los_D_i(i)==3
        V_utility_los=V_utility_los+F_i(i).*los_matrix_D_i.(beta_names_F_i{i});
    else
        disp('zonal_or_los index is neither zonal (1) or los (3), please check')
        return
    end
end
V_utility_zonal=V_utility_zonal+F_i(beta_0_index).*(log(sum_zonal));
V_utility=V_utility_los+V_utility_zonal;
log_sum_zonal=(log(sum_zonal));

end


function [log_P,V,log_sum,log_sum_zonal]  =Logit_prediction(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i)
% input: F is the vector of parameters, 1*N_FX vector
% output: log_P is the log of probability of choosing each alternative,
%         N_obs*N_choice dimension
%         V is utility vector (N_obs*N_choice) dimension
%         log_sum vector of log_sum (denominator of the probability), N_obs*1
%         vector
% LOGIT(F) returns the likelihood and log-likelihood of the observaitions
% in VAR_FX for the fixed parameters F
% F is N_RD x NP
[V, log_sum_zonal]=Utilities_prediction(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i);
% V is the utility matrix which has (N_obs*N_choice) dimension
% there is a risk of exp function that is if exp(V_late_response) is too large,
% there is potential to make exp(V_late_response) a inf or nan.
% just in case inf happens I use 10^20 instead of inf
% max_V=max(V,[],2);
% log_sum=zeros(NP,1); % log_sum is a column vector denote the log(sum(exp(V)))

% for i=1:NZ
%     log_sum=log_sum+exp(V(:,i)-max_V);
% end
% log_sum=log(log_sum)+max_V;
NP=size(V,1);
NZ=size(V,2);
log_sum=nan(size(V,1),1);
log_P=nan(NP,NZ);
for i=1:NP
    validIndex=~isnan(V(i,:));
    V_temp=V(i,validIndex);
    if ~isempty(V_temp)
        max_V=max(V_temp);
        log_sum(i)=log(sum(exp(V_temp-max_V)))+max_V;
        log_P(i,validIndex)=V_temp-log_sum(i);
    end
    
    
end


% log_sum=log(sum(exp(V-max_V(:,ones(1,NZ))),2))+max_V;


% log_P_not_use_new_tram = V_not_use_new_tram-(log(exp(V_not_use_new_tram-max_V)+exp(V_use_new_tram-max_V))+max_V);
end

function [V_utility,log_sum_zonal]  = Utilities_prediction(beta_names_F_i,beta_0_varName_i,F_i,zonal_or_los_D_i,zonal_matrix_D_i,los_matrix_D_i)


for i=1
    if zonal_or_los_D_i(i)==3
        matrix=los_matrix_D_i.(beta_names_F_i{i});
    else
        matrix=zonal_matrix_D_i.(beta_names_F_i{i});
    end
    NP=size(matrix,1);
    NZ=size(matrix,2);
end


V_utility_zonal=zeros(NP,NZ);
V_utility_los=zeros(NP,NZ);
sum_zonal=zeros(NP,NZ);
beta_0_index=find(ismember(beta_names_F_i,beta_0_varName_i));
for i=1:length(F_i)
    if zonal_or_los_D_i(i)==1
        if beta_0_index==i
            sum_zonal=sum_zonal+exp(0).*zonal_matrix_D_i.(beta_names_F_i{i});
        else
            sum_zonal=sum_zonal+exp(F_i(i)).*zonal_matrix_D_i.(beta_names_F_i{i});
        end
    elseif zonal_or_los_D_i(i)==3
        V_utility_los=V_utility_los+F_i(i).*los_matrix_D_i.(beta_names_F_i{i});
    else
        disp('zonal_or_los index is neither zonal (1) or los (3), please check')
        return
    end
end
V_utility_zonal=V_utility_zonal+F_i(beta_0_index).*(log(sum_zonal));
V_utility=V_utility_los+V_utility_zonal;
log_sum_zonal=(log(sum_zonal));

end

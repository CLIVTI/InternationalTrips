
%-------------------------------------------------------
function output=apply_MNL_model_logsum(ModeChoiceBeta,Dataset,specific_names_fix,specific_names_X_fix,Y_names,choice_name,logsum_var,Dataset_Full,displayResult) % note that ASC has been included in both "specific_names_fix" and "variables"
% the simple benchmark MNL model
% input:
%        DATA is the matrix of the data
%        title: the name list (string) of the data
%        specific_names_fix: a string structure for fixed beta, same name in two alternatives means the same beta
%        specific_names_X_fix: a string structure for variables must be the same name as in the title
%        Y_names: a string value of the dependent variable
%        choice_name: a string vector telling the program the choice name ('simple_car','work_PT', etc)
%        logsum_beta: variable names for log_sum variables
%        V_logsum: a structure, each element is a V (utility value of all subalternatives, like all destinations)


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
global N_FX LAB_FX CHOICE NP NP_full FX_alt descriptive_choice


DATA = table2array(Dataset);
title = Dataset.Properties.VariableNames;

NP = size(DATA,1);
ASC=ones(NP,1);
if size(DATA,2)~=length(title)
    disp('number of variables do not match number of variable titles in the estimation dataset')
    return
end
if ~ismember(title,'ASC')
    DATA=[DATA,ASC];  % add ASC into data
    title=[title,'ASC'];
end

NP_full = size(Dataset_Full,1);
DATA_full = table2array(Dataset_Full);
title_full = Dataset_Full.Properties.VariableNames;
if size(DATA_full,2)~=length(title_full)
    disp('number of variables do not match number of variable titles in the full dataset')
    return
end
if ~ismember(title_full,'ASC')
    DATA_full=[DATA_full,ones(size(DATA_full,1),1)];  % add ASC into data
    title_full=[title_full,'ASC'];
end


if length(logsum_var)~=length(choice_name)
    disp('logsum variables must have the same length as number of alternatives')
    return
end

SpecifyVariables_1(DATA,title,specific_names_fix,specific_names_X_fix,Y_names,choice_name,logsum_var,DATA_full,title_full);

F=ModeChoiceBeta(1:(end-1));
logsum_mu=ModeChoiceBeta(end);
[log_P_fullData,~,log_sum_fullData]  =Logit_logsum(F,logsum_mu);
output.('logsum_fullData')=log_sum_fullData;
output.('probability_fullData')=exp(log_P_fullData);
[log_P_sample,~,log_sum_sample]  =Logit(F,logsum_mu);
output.('logsum_sample')=log_sum_sample;
output.('probability_sample')=exp(log_P_sample);
end



function [log_P,V,log_sum]  =Logit_logsum(F,logsum_mu)
% input: F is the vector of parameters, 1*N_FX vector
% output: log_P is the log of probability of choosing each alternative,
%         N_obs*N_choice dimension
%         V is utility vector (N_obs*N_choice) dimension
%         log_sum vector of log_sum (denominator of the probability), N_obs*1
%         vector
global N_choice NP_full
% LOGIT(F) returns the likelihood and log-likelihood of the observaitions
% in VAR_FX for the fixed parameters F
% F is N_RD x NP
[V]=Utilities_logsum(F,logsum_mu);  % deri_mu  (NP,N_choice) dimension
% V is the utility matrix which has (N_obs*N_choice) dimension
% there is a risk of exp function that is if exp(V_late_response) is too large,
% there is potential to make exp(V_late_response) a inf or nan.
% just in case inf happens I use 10^20 instead of inf
max_V=max(V,[],2);
log_sum=zeros(NP_full,1); % log_sum is a column vector denote the log(sum(exp(V)))
for i=1:N_choice
    log_sum=log_sum+exp(V(:,i)-max_V);
end
log_sum=log(log_sum)+max_V;
log_P=zeros(NP_full,N_choice);
for i=1:N_choice
    log_P(:,i)=V(:,i)-log_sum;
end
% log_P_not_use_new_tram = V_not_use_new_tram-(log(exp(V_not_use_new_tram-max_V)+exp(V_use_new_tram-max_V))+max_V);


end

function [V_utility]  = Utilities_logsum(F,logsum_mu)
global N_choice NP_full choice_names I_BETA_FX
global F_X_full logsum_col_full
% Calculate the utilites for the different choices.
% input: F is a vector of parameters (1*N_FX)
% output: V_utility is a utility matrix (N_obs*N_choice)
V_utility=zeros(NP_full,N_choice);
%           deri_log_sum=zeros(NP,N_choice);
for i=1:N_choice
    if isempty(F_X_full.(choice_names{i}))==1
        F_X_full.(choice_names{i})=ones(NP_full,0);
        V_utility(:,i)=F_X_full.(choice_names{i})*ones(0,1)+logsum_mu.*logsum_col_full.(choice_names{i});
    else
        V_utility(:,i)=F_X_full.(choice_names{i})*F(I_BETA_FX.(choice_names{i}))+logsum_mu.*logsum_col_full.(choice_names{i});
    end
    %               [log_sum_part,deri_log_sum_i]=logsum_eva(logsum_mu,logsum_col(:,i));
    
    %               deri_log_sum(:,i)=deri_log_sum_i;
end
end


%  SpecifyVariables_1(DATA,title,specific_names_fix,specific_names_X_fix,Y_names,choice_name);
function SpecifyVariables_1(DATA,title,specific_names_fix,specific_names_X_fix,Y_names,choice_name,logsum_var,Dataset_Full,title_full)
% CHOOSEVARIABLES structure and transforms the data in file 'filename' to a
% more usable form. Here, is where you specify the variables to be included
% in the model and whether they are fixed or random and whether thet are
% normal or log-normal.
% NOTE: you can add more variables from the original data by adding them in
% LoadData below.

% Global variables that are used by other functions. we recommend that you
% don't change this.
global CHOICEIDX CHOICE N_FX unique_choice I_BETA_FX
global F_X F_index N_choice choice_names LAB_FX logsum_col
global F_X_full logsum_col_full
global FX_alt NP descriptive_choice

%%%%%%%%%% Prepare data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the data from 'filename' and save it to the structure D.
%
% filename = 'wave 2 and 3 dataset used in Matlab for model 3.xlsx';


% missing values should be removed
% DATA=xlsread('wave 2 and 3 dataset used in Matlab for model 3.xlsx');

% Calculate choice vector.
[CHOICE , CHOICEIDX,unique_choice] = CalculateChoice(title,Y_names,DATA);
descriptive_choice=zeros(length(unique_choice),1);
for i=1:length(unique_choice)
    descriptive_choice(i)=sum(CHOICE==unique_choice(i));
end

% NP = size(DATA,1);

%%%%%%%%%% Transform and Create Variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

choice_names=choice_name;
N_choice=length(choice_name);
F_index={};
% for the estimation data
for i=1:length(choice_name)
    variables_fix.(choice_name{i})=[];
end
for i=1:length(choice_name)
    name_temp=specific_names_X_fix.(choice_name{i});
    if isempty(name_temp)==0
        for j=1:length(name_temp)
            variables_fix.(choice_name{i})=[variables_fix.(choice_name{i}),DATA(:,ismember(title,name_temp{j}))];
        end
    else
        variables_fix.(choice_name{i})=[];
    end
end

F_X=variables_fix;

% for the logsum data
for i=1:length(choice_name)
    variables_full.(choice_name{i})=[];
end
for i=1:length(choice_name)
    name_temp=specific_names_X_fix.(choice_name{i});
    if isempty(name_temp)==0
        for j=1:length(name_temp)
            variables_full.(choice_name{i})=[variables_full.(choice_name{i}),Dataset_Full(:,ismember(title_full,name_temp{j}))];
        end
    else
        variables_full.(choice_name{i})=[];
    end
end

F_X_full=variables_full;

logsum_col={};
for i=1:length(choice_name)
    logsum_col.(choice_name{i})=DATA(:,ismember(title,logsum_var{i}));
end

logsum_col_full={};
for i=1:length(choice_name)
    logsum_col_full.(choice_name{i})=Dataset_Full(:,ismember(title_full,logsum_var{i}));
end

name_fix={};

for i=1:length(choice_name)
    name_fix=[name_fix,specific_names_fix.(choice_name{i})];
end
[LAB_FX , IA_fix , IC_fix] = unique(name_fix,'stable');
N_FX = length(IA_fix);
I_BETA_FX={};
count=0;
% I_BETA_FX gives the position in initial beta (which beta belongs to the given alternative)
for i=1:length(choice_name)
    I_BETA_FX.(choice_name{i})=IC_fix(count+(1:size(variables_fix.(choice_name{i}),2)));
    if size(I_BETA_FX.(choice_name{i}),1)>size(I_BETA_FX.(choice_name{i}),2)
        I_BETA_FX.(choice_name{i})=I_BETA_FX.(choice_name{i})';
    end
    count=count+size(variables_fix.(choice_name{i}),2);
end

% the beta appears in which alternative
% F_var_alt(i,j)=1 means variable i appears in alternative jth utility
FX_alt=zeros(N_FX,length(choice_name));
for i=1:N_FX
    for j=1:length(choice_name)
        if ~isempty(find(I_BETA_FX.(choice_name{j})==i, 1))
            FX_alt(i,j)=1;
        end
    end
end





    function [CHOICE ,  CHOICEIDX,unique_choice] = CalculateChoice(title,Y_names,DATA)
        % CALCULATECHOICE Calculates the vector of CHOICEIDX such that
        % P(CHOICEIDX(k)) is the probability of the observed choice for observation
        % k in the likelihood-function.
        CHOICE=DATA(:,ismember(title,Y_names) ) ;
        unique_choice=unique(CHOICE);
        r=length(CHOICE);
        rows=(1:r)';
        CHOICEIDX=(CHOICE-1)*r + rows;
    end
end

function [LL,g] = LogLikelihood_MNL(beta)
global CHOICEIDX F_X N_FX N_choice choice_names  NP I_BETA_FX logsum_col;
% important: F_index is a structure where ith element is an index vector (0,1
% vector) where 1 means the coresponding location in beta belongs to
% the ith alternative
F = beta(1:N_FX); % Fixed parameters
logsum_mu=beta(N_FX+1);

% P is a NP x NV matrix
[log_P,~,~]=Logit(F,logsum_mu);
% output: log_P is the log of probability of choosing each alternative,
%         N_obs*N_choice dimension
%         V is utility vector (N_obs*N_choice) dimension
%         log_sum vector of log_sum (denominator of the probability), N_obs*1
%         vector
P=exp(log_P);
log_P_choosen = log_P(CHOICEIDX);
% P_choosen is a
LL = -sum((log_P_choosen));

g=zeros(N_FX+1,1);

for i=1:length(F)
    X_i=zeros(NP,N_choice);
    grad_choice=zeros(NP,N_choice);
    for j=1:N_choice
        X_temp=F_X.(choice_names{j});
        if ~isempty(X_temp(:,I_BETA_FX.(choice_names{j})==i))
            X_i(:,j)=X_temp(:,I_BETA_FX.(choice_names{j})==i);
        end
    end
    sum_X_exp=sum(X_i.*exp(log_P),2);
    for j=1:N_choice
        grad_choice(:,j)=X_i(:,j)-sum_X_exp;
    end
    grad_chosen=grad_choice(CHOICEIDX);
    g(i)=-sum(grad_chosen);
end


for i=1  % for i=1:N_mu
    grad_mu=zeros(NP,N_choice);
    sum_P_mu=zeros(NP,N_choice);
    for j=1:N_choice
        sum_P_mu(:,j)=logsum_col.(choice_names{j});
    end
    sum_X_exp=sum(sum_P_mu.*P,2);
    for j=1:N_choice
        grad_mu(:,j)=logsum_col.(choice_names{j})-sum_X_exp;
        %         if j==i
        %             grad_mu(:,j)=deri_mu(:,j)-P(:,j).*deri_mu(:,j);
        %         else
        %             grad_mu(:,j)=-P(:,i).*deri_mu(:,i);
        %         end
    end
    grad_chosen=grad_mu(CHOICEIDX);
    g(N_FX+i)=-sum(grad_chosen);
end



end

%-------------------------------------------------------
function [log_P,V,log_sum]  =Logit(F,logsum_mu)
% input: F is the vector of parameters, 1*N_FX vector
% output: log_P is the log of probability of choosing each alternative,
%         N_obs*N_choice dimension
%         V is utility vector (N_obs*N_choice) dimension
%         log_sum vector of log_sum (denominator of the probability), N_obs*1
%         vector
global N_choice NP
% LOGIT(F) returns the likelihood and log-likelihood of the observaitions
% in VAR_FX for the fixed parameters F
% F is N_RD x NP
[V]=Utilities(F,logsum_mu);  % deri_mu  (NP,N_choice) dimension
% V is the utility matrix which has (N_obs*N_choice) dimension
% there is a risk of exp function that is if exp(V_late_response) is too large,
% there is potential to make exp(V_late_response) a inf or nan.
% just in case inf happens I use 10^20 instead of inf
max_V=max(V,[],2);
log_sum=zeros(NP,1); % log_sum is a column vector denote the log(sum(exp(V)))
for i=1:N_choice
    log_sum=log_sum+exp(V(:,i)-max_V);
end
log_sum=log(log_sum)+max_V;
log_P=zeros(NP,N_choice);
for i=1:N_choice
    log_P(:,i)=V(:,i)-log_sum;
end
% log_P_not_use_new_tram = V_not_use_new_tram-(log(exp(V_not_use_new_tram-max_V)+exp(V_use_new_tram-max_V))+max_V);
end


function [V_utility]  = Utilities(F,logsum_mu)
global F_X N_choice NP choice_names I_BETA_FX logsum_col;
% Calculate the utilites for the different choices.
% input: F is a vector of parameters (1*N_FX)
% output: V_utility is a utility matrix (N_obs*N_choice)
V_utility=zeros(NP,N_choice);
%           deri_log_sum=zeros(NP,N_choice);
for i=1:N_choice
    if isempty(F_X.(choice_names{i}))==1
        F_X.(choice_names{i})=ones(NP,0);
        V_utility(:,i)=F_X.(choice_names{i})*ones(0,1)+logsum_mu.*logsum_col.(choice_names{i});
    else
        V_utility(:,i)=F_X.(choice_names{i})*F(I_BETA_FX.(choice_names{i}))+logsum_mu.*logsum_col.(choice_names{i});
    end
    %               [log_sum_part,deri_log_sum_i]=logsum_eva(logsum_mu,logsum_col(:,i));
    
    %               deri_log_sum(:,i)=deri_log_sum_i;
end
end

% function [log_sum_mu,deri_mu]=logsum_eva(logsum_mu,logsum_col)
% % this function calculates the log_sum variable
% % should return a value function and the derivative with respect to logsum_mu
% totalV=logsum_col.*logsum_mu;
% max_V=max(totalV,[],2);
% V_minus_maxV=totalV-max_V(:,ones(1,size(V_subalternative,2)));
% log_sum=log(sum(exp(V_minus_maxV),2))+max_V;
% log_sum_mu=(log_sum)./logsum_mu;
%
% % derivative
% deri_part1=(-1./(logsum_mu.^2)).*log_sum;
%
%
% log_weight=zeros(size(V_subalternative,1),1);
% deri_part2=zeros(size(V_subalternative,1),1);
% index=sum(exp(V_minus_maxV).*V_subalternative,2)<0;
% log_weight(index)=log(sum(exp(V_minus_maxV(index,:)).*(-V_subalternative(index,:)),2))+max_V(index);
% deri_part2(index)=-(1./logsum_mu).*exp(log_weight(index)-log_sum(index));
% log_weight(~index)=log(sum(exp(V_minus_maxV(~index,:)).*(V_subalternative(~index,:)),2))+max_V(~index);
% deri_part2(~index)=(1./logsum_mu).*exp(log_weight(~index)-log_sum(~index));
%
%
% %  weight=sum(exp(totalV).*V_subalternative,2)./exp(log_sum);
% % deri_part2=(1./logsum_mu).*weight;
% deri_mu=deri_part1+deri_part2;
% end



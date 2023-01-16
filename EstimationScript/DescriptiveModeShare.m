close all
clear variables;
restoredefaultpath

PathStorage='C:/Users/ChengxiL/VTI/Internationella resor - General/Estimation';
addpath(genpath(PathStorage))

landUseFilePath='NordicZones.csv';

opts = detectImportOptions(landUseFilePath);
ZoneData=readtable(landUseFilePath,opts);
ZoneData.ID=str2double(ZoneData.ID);
Dataset=load('DatasetBortavaror_2.mat');
DataName=fieldnames(Dataset);
Dataset=Dataset.(DataName{1});

n_outsideEU=sum(Dataset.D_B_TransCadID_World~=-1);
fprintf('\nNumber of trips outside EU: %2.0f', n_outsideEU);
n_nordic=0;
for i=1:size(Dataset,1)
    if sum(ZoneData.ID==Dataset.D_B_TransCadID_EU(i))>0 % this is a nordic zone
        n_nordic=n_nordic+1;
    end

end
fprintf('\nNumber of trips to Nordic countries: %2.0f', n_nordic);
fprintf('\nNumber of trips to non-Nordic EU countries: %2.0f', size(Dataset,1)-n_nordic-n_outsideEU);
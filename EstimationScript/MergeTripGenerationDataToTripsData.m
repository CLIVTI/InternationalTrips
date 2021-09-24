close all 
clear variables;
restoredefaultpath

PathStorage='C:/Users/ChengxiL/VTI/Internationella resor - General/Estimation';
addpath(genpath(PathStorage))

% combine dataset for trip generation estimation done.
RVUFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDREstimation.csv';
UPBDDataPath='//vti.se/root/Internationella-resor/R skript/RVU/R/UPBDEstimation.csv';
MDHRFilePath='//vti.se/root/Internationella-resor/R skript/RVU/R/MDHRForDataJoin.csv';
LVHRDataPath='//vti.se/root/Internationella-resor/R skript/RVU/R/LVDRForDataJoin.csv';

opts = detectImportOptions(RVUFilePath);
RVU=readtable(RVUFilePath,opts);

opts = detectImportOptions(UPBDDataPath);
UPBD=readtable(UPBDDataPath,opts);
UPBD.UENR=str2double(UPBD.UENR);
UPBD(:,1)=[];

opts = detectImportOptions(MDHRFilePath);
MDHR=readtable(MDHRFilePath,opts);
MDHR.UENR=str2double(MDHR.UENR);

opts = detectImportOptions(LVHRDataPath);
LVHR=readtable(LVHRDataPath,opts);
LVHR.UENR=str2double(LVHR.UENR);

RVU_TripGeneration=RVU;

for i=1:size(UPBD,1)
    
    if isempty(find(RVU_TripGeneration.UENR==UPBD.UENR(i), 1))
        structNewRow={};
        structNewRow(1,1).Var1 = '-1';
        structNewRow(1,1).TripID = -1;
        structNewRow(1,1).UENR = UPBD.UENR(i);
        structNewRow(1,1).D_A_DAT = -1;
        structNewRow(1,1).bortavaro = 0;
        structNewRow(1,1).H_RESDGR = -1; 
        structNewRow(1,1).H_ANTDGR = -1;
        structNewRow(1,1).Mode = -1;
        structNewRow(1,1).D_A_TransCadID= UPBD.D_A_TransCadID(i);
        structNewRow(1,1).D_B_TransCadID_EU=-100;
        structNewRow(1,1).D_B_TransCadID_World=-100;
        structNewRow(1,1).sallskap=-1;
        structNewRow(1,1).SEX = UPBD.SEX(i);
        structNewRow(1,1).AGE = UPBD.AGE(i);
        structNewRow(1,1).HHINK = UPBD.HHINK(i);
        structNewRow(1,1).HHTYP = UPBD.HHTYP(i);
        structNewRow(1,1).H_BARNN=-1;
        structNewRow(1,1).KKORT_HH=-1;
        structNewRow(1,1).BILANT = UPBD.BILANT(i);
        structNewRow(1,1).VILLA = UPBD.VILLA(i);
        structNewRow(1,1).H_TYP=-1;
        structNewRow(1,1).D_ARE=-1;
        structNewRow(1,1).AntalSmallBarn= UPBD.AntalSmallBarn(i);
        structNewRow(1,1).AntalStoreBarn= UPBD.AntalStoreBarn(i);
        
        if ~isempty(find(MDHR.UENR==UPBD.UENR(i), 1))
            index=MDHR.UENR==UPBD.UENR(i);
            AllTripsMadeByThisGuy=MDHR(index,:);
            structNewRow(1,1).D_A_DAT=AllTripsMadeByThisGuy.D_A_DAT(1);
            structNewRow(1,1).D_ARE=AllTripsMadeByThisGuy.H_ARE(1);
        end
        if ~isempty(find(LVHR.UENR==UPBD.UENR(i), 1))
            index=LVHR.UENR==UPBD.UENR(i);
            AllTripsMadeByThisGuy=LVHR(index,:);
            structNewRow(1,1).D_A_DAT=AllTripsMadeByThisGuy.D_A_DAT(1);
            structNewRow(1,1).D_ARE=AllTripsMadeByThisGuy.D_ARE(1);
        end
        
        RVU_TripGeneration = [RVU_TripGeneration;struct2table(structNewRow)];
        fprintf('\n UENR added to data: %10.0f ', UPBD.UENR(i));
    else 
        fprintf('\n UENR already exists in TripGeneration data: %10.0f ', UPBD.UENR(i));
    end
end

writetable(RVU_TripGeneration,'//vti.se/root/Internationella-resor/R skript/RVU/R/DataForTripGenerationEstimation.csv')
      

function partySize= partiSizeModel(partySizeFromRVU)
% input vector partySizeFromRVU --> this is the partySize in RVU with given household size. something like: partySizeFromRVU=RVU.sallskap(RVU.HHSTORL==1);

partySizeFromRVU=partySizeFromRVU(partySizeFromRVU>=0 & partySizeFromRVU<=5); % do not use obs that are >5
if (length(partySizeFromRVU)<=10)
    partySize=1;
    return
end
partySize=0;
for i=0:5
    share=length(partySizeFromRVU(partySizeFromRVU==i))./length(partySizeFromRVU);
    partySize=partySize+share*i;
end


return

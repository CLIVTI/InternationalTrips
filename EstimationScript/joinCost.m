function outputRVU=joinCost(RVUValid,costMatrix,stringMode)
originIndex=[costMatrix(2:end,1),(1:(size(costMatrix,1)-1))'];
originIndex = array2table(originIndex,...
    'VariableNames',{'D_A_TransCadID','OriginIndex'});
destinationIndex=[costMatrix(1,2:end)',(1:(size(costMatrix,2)-1))'];
destinationIndex = array2table(destinationIndex,...
    'VariableNames',{'D_B_TransCadID','DestinationIndex'});
outputRVU = innerjoin(RVUValid,originIndex);
outputRVU = innerjoin(outputRVU,destinationIndex);
cost=costMatrix(2:end,2:end);
outputRVU.(stringMode)=nan(size(outputRVU,1),1);
for i=1:size(outputRVU,1)
    outputRVU.(stringMode)(i)=cost(outputRVU.OriginIndex(i),outputRVU.DestinationIndex(i));
end
outputRVU.OriginIndex=[];
outputRVU.DestinationIndex=[];
end
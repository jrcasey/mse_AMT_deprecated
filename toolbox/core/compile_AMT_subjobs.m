%% Post processing on server
cd ~/mse_AMT/
addpath(genpath('~/mse_AMT'))
ResultsDirectory = '/nobackup1/jrcasey/';
load Gridding
load FileNames
load CruiseData
load PanGEM

[FullSolution] = get_AMT_Results_server(ResultsDirectory,PanGEM,FileNames,Gridding,CruiseData);

save('~/mse_AMT/data/output/FullSolution.mat','FullSolution');

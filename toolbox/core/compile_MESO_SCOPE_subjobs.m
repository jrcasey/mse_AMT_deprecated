%% Post processing on server
cd ~/mse/
addpath(genpath('~/mse'))
ResultsDirectory = '/nobackup1/jrcasey/';
load Gridding
load FileNames
load CruiseData
load PanGEM

[FullSolution] = get_MESO_SCOPE_Results(ResultsDirectory,PanGEM,FileNames,Gridding,CruiseData);

save('/data/output/FullSolution.mat','FullSolution');

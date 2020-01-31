%% Post processing on server
cd ~/mse/
ResultsDirectory = '/nobackup1/jrcasey/';
load('/data/output/Gridding.mat');
load('/data/output/FileNames.mat');
load('/data/output/CruiseData.mat');
load('/data/output/PanGEM.mat');

[FullSolution] = get_MESO_SCOPE_Results(ResultsDirectory,PanGEM,FileNames,Gridding,CruiseData);

save('/data/output/FullSolution.mat','FullSolution');

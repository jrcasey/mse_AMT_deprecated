%% MESO-SCOPE Simulation
% Runs and analyzes the MSE simulation for the MESO-SCOPE cruise.
%% set root dir
cd Documents/MATLAB/GitHub/mse/

%% Version
version = strcat({'_v'},datestr(date,'yyyymmdd'))

%% Version control and database paths
FileNames = struct;
% Current PanGEM
FileNames.PanGEM_Path = 'data/GEM/PanGEM.mat';
% Organism database
FileNames.orgDB_Path = 'data/db/orgDatabase.csv';
% Current strain models
FileNames.StrMod_Path = 'data/GEM/targStrMod3.mat';
% List of strains to be analyzed
FileNames.strainList_Path = 'data/db/strainList.mat';
% Current OGTDat
FileNames.OGTDat_Path = 'data/db/OGTDat.csv';
% Cruise data
FileNames.CruiseDB_filename = 'data/envData/MESO-SCOPE.csv';
% HyperPro profiles
FileNames.IrrDat_fileName = 'data/envData/IrrDat.mat';
% TpDat path
FileNames.TpDat_fileName = 'data/db/TpDat.csv';
% PhysOpt and PigOpt constraints path
FileNames.PhysOptPigOptConstraints_fileName = 'data/db/BOFConstraints.csv';
% PigDB path
FileNames.PigDB_fileName = 'data/db/AbsorptionDatabase.csv';
% Destination for solution
FileNames.destination_fileName = strcat('data/output/FullSolution',version,'.mat');

%% Gridding
Gridding = struct;
% Stations
Gridding.stationsVec = 4:15;
Gridding.nStations = numel(Gridding.stationsVec);
% Depth (m)
Gridding.minZ = 15;
Gridding.maxZ = 181;
Gridding.intervalZ = 10;
Gridding.depthVec = Gridding.minZ:Gridding.intervalZ:Gridding.maxZ;
Gridding.nZ = numel(Gridding.depthVec);
% Wavelength (nm)
Gridding.minLambda = 300; % nm
Gridding.maxLambda = 850; %nm
Gridding.bandwidth = 2; % nm
Gridding.lambdaVec = Gridding.minLambda:Gridding.bandwidth:Gridding.maxLambda; % nm wavelength

%% Options
Options = struct;
% Set options
Options.saveSolution = false;
Options.saveStrMod = true;
Options.maxIter_TpOpt = 1000;
Options.maxIter_physOpt = 1000;
%Options.saveCruiseData = true;

%% Choose a strain
% load orgDatabase
orgDatabase = readtable(FileNames.orgDB_Path,'ReadVariableNames',true,'Delimiter',',');
strNameVec = [{'MED4'},{'MIT9313'},{'SB'}];
nStr = numel(strNameVec);

%% Run simulation
FullSolution = struct;
for k = 1:nStr
    strName = strNameVec{k};
    
    Solution = struct;
    
    %for i = 1 : Gridding.nStations
    for i = 1:2
        tempStationVecInd = [3 9];
        station = Gridding.stationsVec(tempStationVecInd(i));
        station_name = strcat('Station_',num2str(station));
        for j = 1:Gridding.nZ
            depth = Gridding.depthVec(j);
            depth_name = strcat(num2str(depth),'m');
            tic;
            [Solution_ij] = MESO_SCOPE_Simulation(strName, station, depth, Gridding, FileNames, Options);
            dt = toc;
            Solution.Growth(i,j) = Solution_ij.Growth;
            Solution.Fluxes(i,j,:) = Solution_ij.Fluxes;
            Solution.BOF(i,j,:) = Solution_ij.BOF_coefs;
            Solution.TpOpt(i,j,:) = Solution_ij.TpOpt;
            Solution.rOpt(i,j) = Solution_ij.r_opt;
            Solution.pigAbs(i,j,:) = Solution_ij.pigAbs;
            Solution.uptakeBounds(i,j,:) = Solution_ij.uptakeBounds;
            Solution.runtime(i,j) = dt;
            if Options.saveStrMod
                Solution.StrMod{i}{j} = Solution_ij.StrMod;
            end
        end
    end
    
    % Store solution for each strain in a structure
    FullSolution.(strName) = Solution;
end

%% Save solution
save(cell2str(FileNames.destination_fileName),'FullSolution');

%% Analysis
 
% Compute elemental stoichiometry
for k = 1:nStr
    for i = 1:2
        for j = 1:numel(Gridding.depthVec)
            tempMod = FullSolution.(strNameVec{k}).StrMod{i}{j};
            [MMComposition] = getMMElementalStoichiometry(tempMod);
            MMCompositionPartialTotal = sum(MMComposition.DW,1); % mmol element gDW-1
            
            % add in the pigments
            PigsIncluded = [{'Divinylchlorophyll_a'},{'Divinylchlorophyll_b'},{'alpha_Carotene'},{'Zeaxanthin'}];
            elementAbbrevs = [{'C'},{'H'},{'N'},{'O'},{'P'},{'S'}];
            for q=1:numel(PigsIncluded)
                PigsInd = find(strcmp(PigsIncluded{q},tempMod.mets));
                PigsFormulas = tempMod.metFormulas(PigsInd);
                [elements, useMat, exitFlag, MW] = parseFormulas(PigsFormulas);
                [junk, junk2, elementInd] = intersect(elementAbbrevs,elements.abbrevs);
                PigsComposition = useMat(elementInd);% mol element [mol pig]-1
                PigsCoef = squeeze(FullSolution.(strNameVec{k}).BOF(i,j,11+q)); % g gDW-1
                PigsContribution(q,:) = PigsCoef .* (1./MW) .* PigsComposition .* 1000; % mmol element gDW-1
            end
            PigsContributionTotal = nansum(PigsContribution,1);
            
            % Compute total
            MMCompositionTotal(k,i,j,:) = MMCompositionPartialTotal + PigsContributionTotal;
            % check for sum
            TotalDW(k,i,j) = 1e-3.* sum(squeeze(MMCompositionTotal(k,i,j,:))'.*[12.0107 1.00794 14.0067 15.9994 30.973762 32.065]);
        end
    end
end

%% Plots
% Exclude solutions where the LP didn't converge. For now just looking at
% the runtimes.
for k = 1:nStr
    for i = 1:2
        qualInd{k}{i} = find(FullSolution.(strNameVec{k}).runtime(i,:)>10 & FullSolution.(strNameVec{k}).runtime(i,:)<2000);
    end
end
lineVec = [{'-'},{'--'}];
colorVec = [{'r'},{'g'},{'b'},{'m'},{'k'}];
markerVec = [{'.'},{'*'}]
% Growth rate
figure
for k = 1:nStr
    for i = 1:2
        legendEntry{k}{i} = strcat(strNameVec{k},'-Station-',num2str(Gridding.stationsVec(tempStationVecInd(i))));
        %plot(FullSolution.(strNameVec{k}).Growth(i,qualInd{k}{i}),-Gridding.depthVec(qualInd{k}{i}),'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        y = -Gridding.depthVec(qualInd{k}{i});
        x = FullSolution.(strNameVec{k}).Growth(i,qualInd{k}{i});
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        %plot(FullSolution.(strNameVec{k}).Growth(i,qualInd{k}{i}),-Gridding.depthVec(qualInd{k}{i}),'Marker',markerVec{i},'Color',colorVec{k},'MarkerSize',20,'LineStyle','none');
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Growth rate [h^-^1]')
ylabel('Depth [m]')
legendEntries = [legendEntry{:}];
%legend('Station 6 MED4','Station 12 MED4','Station 6 MIT9313','Station 12 MIT9313','Station 6 SB','Station 12 SB','Location','NorthWest')
legend(legendEntries)
set(gca,'FontSize',20)
clear nanInd

% Protein
figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},4));
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Protein content [g gDW^-^1]')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
clear nanInd

% Carbohydrate
figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},3));
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Carbohydrate content [g gDW^-^1]')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
clear nanInd

% Chlorophyll (total)
figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},13))+squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},12));
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Total Divinlychlorophyll content [g gDW^-^1]')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
clear nanInd

% Chlorophyll b/a ratio
figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},13))./squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},12));
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Divinylhlorophyll b/a ratio [ND]')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
clear nanInd

% A transporter
figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).TpOpt(i,qualInd{k}{i},4));
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Transporters per cell')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
clear nanInd

% A flux
fluxInd = find(strcmp('O2EX',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns));
figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd));
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('Flux [mmol gDW^-^1 h^-^1]')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
title(FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns(fluxInd),'FontSize',20)
clear nanInd

% GS-GOGAT
% Glutamine synthetase: R00253
% GOGAT: R00114
% GOGAT temporary: R00248
fluxInd1 = find(strcmp('R00253',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns)); % 0.054
fluxInd2 = find(strcmp('R00248',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns)); % 0.226
fluxInd3 = find(strcmp('R04173',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns));
figure
for k = 1:nStr
    for i = 1:2
        subplot(1,3,1)
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd1))
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
        xlabel('Flux [mmol gDW^-^1 h^-^1]')
        ylabel('Depth [m]')
        set(gca,'FontSize',20)
        title('Glutamine synthetase','FontSize',20)
        clear nanInd
        subplot(1,3,2)
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd2))
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
        xlabel('Flux [mmol gDW^-^1 h^-^1]')
        ylabel('Depth [m]')
        set(gca,'FontSize',20)
        title('Glutamate dehydrogenase','FontSize',20)
        clear nanInd
        subplot(1,3,3)
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd3))
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
        xlabel('Flux [mmol gDW^-^1 h^-^1]')
        ylabel('Depth [m]')
        set(gca,'FontSize',20)
        title('Phosphoserine transaminase','FontSize',20)
        clear nanInd
    end
end

legend(legendEntries)

% PQ
fluxInd_x1 = find(strcmp('CO2EX',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns));
fluxInd_x2 = find(strcmp('HCO3EX',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns));
fluxInd_x3 = find(strcmp('O2EX',FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns));

figure
for k = 1:nStr
    for i = 1:2
        y = -Gridding.depthVec(qualInd{k}{i});
        x = squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd_x3)) ./ ( squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd_x1)) + squeeze(FullSolution.(strNameVec{k}).Fluxes(i,qualInd{k}{i},fluxInd_x2)) );
        nanInd = find(isnan(x));
        x(nanInd) = [];
        y(nanInd) = [];
        plot(x,y,'Marker',markerVec{i},'Color',colorVec{k},'LineStyle',lineVec{i},'MarkerSize',20,'LineWidth',3);
        hold on; 
    end
end
xlabel('PQ [mol O2 (mol CO2)^-^1]')
ylabel('Depth [m]')
legend(legendEntries)
set(gca,'FontSize',20)
title(FullSolution.(strNameVec{1}).StrMod{1}{1}.rxns(fluxInd),'FontSize',20)
clear nanInd








% MM area fill


figure
n =1;
for k = 1:nStr
    for i = 1:2
        subplot(nStr,2,n)
        area(Gridding.depthVec(qualInd{k}{i}),squeeze(FullSolution.(strNameVec{k}).BOF(i,qualInd{k}{i},:)));
        n=n+1;
        title(strcat(strNameVec{k},'station_',num2str(i)))
    end
end







% Stoichiometry
figure
n=1
for k = 1:nStr
    for i = 1:2
        subplot(nStr,2,n)
        plot(squeeze(MMCompositionTotal(k,i,qualInd{k}{i},1))./squeeze(MMCompositionTotal(k,i,qualInd{k}{i},3)),Gridding.depthVec(qualInd{k}{i}))
        n=n+1;
        title(strcat(strNameVec{k},'station_',num2str(i)))
    end
end



function CruiseDat = getCruiseData(CruiseDB, depthVec)
%% Standardize MESO-SCOPE Data

Data = CruiseDB;

varNames = Data.Properties.VariableNames(8:19); % just the nutrients for now
% Find and index stations
uStations = unique(Data.Station);
nStations = numel(uStations);
for i = 1:nStations
    station_ind{i} = find(uStations(i)==Data.Station);
end

% Interpolate (linear)
CruiseDat = struct;
CruiseDat.Stations = uStations;
CruiseDat.Depth = depthVec;
for i = 1:nStations
    for j = 1:numel(varNames) 
        clear x v vq
        x = Data.Depth(station_ind{i});
        v = Data.(varNames{j})(station_ind{i});
        % deal with the nans
        nanInd = find(isnan(v));
        x(nanInd) = [];
        v(nanInd) = [];
        if numel(find(~isnan(v)))<3
            %nuts(i,j,:) = zeros(numel(depthVec),1);
            CruiseDat.(varNames{j})(i,:) = zeros(numel(depthVec),1);
        else
        vq = interp1(x,v,depthVec,'linear','extrap');
        %nuts(i,j,:) = vq;
        CruiseDat.(varNames{j})(i,:) = vq;
        end
    end
    CruiseDat.Lat(i) = Data.Lat(station_ind{i}(1));
    CruiseDat.Lon(i) = Data.Lon(station_ind{i}(1));
    CruiseDat.Date(i) = Data.Date(station_ind{i}(1));
    CruiseDat.SLA(i) = Data.SLA_cm(station_ind{i}(1));
end

%% Get CTD data
% get file list
fileList_dir = 'CBIOMES/Data/Environmental_Data/Cruises/MESO-SCOPE/CTD/fileList.csv';
fileList = readtable(fileList_dir,'Delimiter',',','ReadVariableNames',false);
% align stations to files
for i = 1:nStations
    fileList_station_ind(i) = find(contains(fileList.Var1,strcat('s',num2str(uStations(i))))); % searching for 's#' where # is the station number
end

for i = 1:nStations
    % import ctd data
    fileName = strcat('CBIOMES/Data/Environmental_Data/Cruises/MESO-SCOPE/CTD/',fileList.Var1{fileList_station_ind(i)});
    CTD = readtable(fileName,'Format','%f %f %f %f %f %f %f %f %f','Delimiter','tab','ReadVariableNames',true,'HeaderLines',2,'TreatAsEmpty','*******' );
    CTD.Properties.VariableNames = [{'Depth'},{'T'},{'S'},{'O2'},{'Chl'},{'Beam_Atten'},{'Junk1'},{'Junk2'},{'Junk3'}];
    varNames = CTD.Properties.VariableNames([2:6]);
    % calculate density
    for j =1:numel(CTD.Depth)
        S = CTD.S(j);
        T = CTD.T(j);
        P = CTD.Depth(j);
        CTD.rho(j) = densatp(S,T,P);
    end
    varNames = [varNames, {'rho'}];
    for j = 1:numel(varNames)
        clear x v vq
        x = CTD.Depth;
        v = CTD.(varNames{j});
        % deal with the nans
        nanInd = find(isnan(v));
        x(nanInd) = [];
        v(nanInd) = [];
        if numel(find(~isnan(v)))<3
            %nuts(i,j,:) = zeros(numel(depthVec),1);
            CruiseDat.(varNames{j})(i,:) = zeros(numel(depthVec),1);
        else
            vq = interp1(x,v,depthVec,'linear','extrap');
            %nuts(i,j,:) = vq;
            CruiseDat.(varNames{j})(i,:) = vq;
        end
    end
end



end
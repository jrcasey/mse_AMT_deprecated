function TCorr = TemperatureCorr(OGTDat,StrainName,T)
% compute the temperature correction based on OGT and the in situ
% temperature

% Inputs
% OGTDat        -       Table. Optimal growth temperature database (based
%                       on the machine learning algorithm)
% StrainName    -       String. Strain ID
% T             -       Double. In situ growth temperature (K)

% Outputs
% TCorr         -       Double. Temperature correction. This value
% currently scales with the activation energy calculated for
% Prochlorococcus. No consideration of the temperature range of growth is
% made currently. Instead, the growth correction is forced to 1.0 for all
% in situ temperatures above OGT;

% John R. Casey
% 20190923

%% Strain OGT
strInd = find(strcmp(StrainName,OGTDat.Strain));
OGT = 273.15 + OGTDat.OGT(strInd); % K

%% Arrhenius parameters
Ea = 5.2733e4; %J mol-1
R = 8.314;
A = 1;
OGT_rate = exp(-Ea./(R.*(OGT)));
InSitu_rate = exp(-Ea./(R.*(T)));

 % temperature correction, with super opimal temperatures forced to 0
if T > OGT
    TCorr = 0;
else
    TCorr = InSitu_rate ./ OGT_rate;
end

end

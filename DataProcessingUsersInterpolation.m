%% Program definition:
% Interpolates data for Scenario 4 (changing users) so we can get results
% for higher number of users without doing the simulations.

%% Start
% Clearing previous
clear;
clc;
tic

% Importing functions (see HelperFunctions2.m)
import HelperFunctions2.GetChoice;
import HelperFunctions2.PlotDesign;

%% Choosing parameters
% Intro
disp('Interpolating data for more users.')
disp('-----------------------------------------------')

% Getting user's choice for plot
choice2 = GetChoice({'Available scenarios are:',...
    '1. 1000 servers',...
	'2. 650 users / 46 servers analogy',...
    '3. 1000 servers / 0 relay ratio'});
disp(['Scenario ', num2str(choice2), ' chosen!'])
fprintf(1, '\n');

% Loading data from DataProcessingMultipleFiles.m
switch choice2
    case 1
        % For 1000 servers
        load('SubScenario1.mat');
    case 2
        % For proportional servers
        load('SubScenario2.mat');
	case 3
        % For 1000 servers / 0 relay ratio
        load('SubScenario3.mat');
end

values = [10000 50000 100000 500000 10^6 2*10^6 5*10^6 10^7];
%% Data interpolation
% New values for users
values2 = [10^8 2.5*10^8 5*10^8 7.5*10^8 10^9 2*10^9 3.5*10^9 5*10^9 7*10^9 10^10];

% Interpolating new data (based on last 2 values)
startIndex = 1; % Start index
endIndex = length(values); % End index
plotgraphs2 = zeros(size(plotgraphs,1),length(values2));
for i = 1:size(plotgraphs,1)
    % Interpolate for all algorithms
    plotgraphs2(i,:) = interp1(values(startIndex:endIndex),plotgraphs(i,startIndex:endIndex),values2,'linear','extrap')'; 
end
plotgraphs = [plotgraphs(:,1:length(values)),plotgraphs2,plotgraphs(:,1+length(values):length(plotgraphs))];

%% Drawing new plot
values = [values, values2];

% Container maps and matrixes for legends (algorithms, linestyle, markers and colors)
[algorithms, linestyles, markers, colors, hours] = PlotDesign(2,0);

% Relay delay system - transactions per second (relay delay and threshold changing) 
figure(1)
hold on
for i = 1:size(plotgraphs,1)-1
    plot(values, plotgraphs(i,1:length(values)),...
        'DisplayName',['Tx generation rate ',algorithms(plotgraphs(i,length(values)+2)),hours(plotgraphs(i,length(values)+3))],...
        'LineWidth',plotgraphs(i,length(values)+7),...
        'Marker',markers(plotgraphs(i,length(values)+4)),...
        'LineStyle',linestyles(plotgraphs(i,length(values)+8)),...
        'MarkerSize',plotgraphs(i,length(values)+5),...
        'color',colors(plotgraphs(i,length(values)+6),:))
end
switch choice2
    case 1
        title('Interpolation for up to 10B users - S = 1000, $\bar{s}$ = 3, r = 10 \%, $n = 1.43*10^{-5}*U$, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
    case 2
        title('Interpolation for up to 10B users - $S = 0.070769*U$, $\bar{s}$ = 30, r = 10 \%, $n = 1.43*10^{-5}*U$, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
	case 3
        title('Interpolation for up to 10B users - S = 1000, $\bar{s}$ = 3, r = 0 \%, $n = 1.43*10^{-5}*U$, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
end
grid on
ylabel('Txs per second')
xlabel('User total')
legend show
% Pick correct ylim
minY = min(plotgraphs(plotgraphs>0));
minY = ceil(log10(1/minY));
minY = 10^(-1*minY);
maxY = max(max(plotgraphs));
maxY = floor(log10(1/maxY));
maxY = 10^(-1*maxY);
ylim([minY maxY])
set(gca, 'YScale', 'log')

% Printing execution time
fprintf(1, '\n');
timeElapsed = toc;
disp(['Execution time: ', num2str(timeElapsed), ' seconds.'])
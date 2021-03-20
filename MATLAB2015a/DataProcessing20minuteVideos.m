%% Program definition:
% Plots TPS output according to activation ratio for 20 minute videos.
% Using a different file for this plot because we need to load very big
% text files

%% Start
% Clearing previous
clear;
clc;
tic

% Importing functions (see HelperFunctions.m)
import HelperFunctions.TempBalances;
import HelperFunctions.Timestamps;
import HelperFunctions.TPS_2;
import HelperFunctions2.Linecount;
import HelperFunctions2.ParameterList;
import HelperFunctions2.GetChoice;
import HelperFunctions2.PlotDesign;

%% Parameters
% Micropayment time (in seconds)
microDuration = 60;
% Block Time (seconds per block)
blockTime = 5;
% Cost
cost = 3600;
% Relay delay (maximum time until somebody is allowed to get his money)
relayDelayTimes = [3600, 86400, 432000]; % Basic Cases
% Threshold balance
thresholds = -1*[3600, 86400, 3600000]/cost; % Basic Cases

%% Running data
% Intro
disp('Plotting according to activation rate for 20 minute videos.')
disp('---------------------------------------------------------------')

% Getting user's choice for scenario
choice1 = GetChoice({'Available options are:',...
    '1. 650 thousand users, 46000 servers, 30 (21-39) mean servers per user, 10 Txs per second.',...
    '2. 650 thousand users, 1000 servers, 3 (2-4) mean servers per user, 10 Txs per second.'});
choice1 = choice1 + 1;
disp(['Scenario ', num2str(choice1), ' chosen!'])
fprintf(1, '\n');

% Get user's choice for plot if its scenario 2 or 3.
values = [1 5 10 50 100 175 250 350 450];

% Initializing
% 3 columns for 3 combinations of relay delay and threshold (inf/inf, 24/24
% and 6/6)
updatesPS_rD = zeros(length(values),3); 
updatesPS_rD_thres = zeros(length(values),3);
updatesPS_rD_thres_ONLY = zeros(length(values),3);
% TPS and micropayment curves
tps = zeros(length(values),1);
micropayments_tps = zeros(length(values),1);


%% Running once for each file
for f = 1:length(values)
    %% Importing files according to user choices
    switch choice1
        case 2
            nodesTotal = 696000;
            meanServs = 30;
        case 3
            nodesTotal = 651000;
            meanServs = 3;
    end
    filename = ['TxData',num2str(nodesTotal),'nodes',num2str(values(f)),'newSessions1200videoDuration432000seconds10relayRatio',num2str(meanServs),'meanServers.txt'];

    % Getting number of lines in file
    n = Linecount(filename);

    % Loading file in batches
    batch = 1; % First batch has info
    LoadComplete = false; % File has not completely loaded yet
    transactions = 0; % Total transactions
    microPayments = 0; % Total micropayments
    activeServers = []; % Amount of active servers
    updatesAll = zeros(1,3); % For 1hr/24hr/Inf threshold and relay delay
    updatesThresOnly = zeros(1,3); % For 1hr/24hr/Inf threshold and relay delay (threshold only)
    while ~LoadComplete 
        if batch == 1 % Basic info
            nodes = dlmread(filename,',',[0 0 0 0]); % number of nodes
            lastUserId = dlmread(filename,',',[0 1 0 1]); % last user ID
            lastRelayId = dlmread(filename,',',[0 2 0 2]); % last relay ID
            simTime = dlmread(filename,',',[0 3 0 3]); % simulation time
            % Node distribution
            users = lastUserId;
            relays = lastRelayId - lastUserId;
            servers = nodes - lastRelayId;
            % List of IDs and if they've been served already during relay delay
            idWhitelist = zeros(nodes-lastUserId,3);
            % We add an additional update when balance of user drops below
            % threshold (3 cases, so 3 columns)
            userBalances = zeros(lastRelayId,3); 
            % File info
            StartIndex = 2;
            remainingLines = n;
        end
        if remainingLines > 25000000
            TxData = dlmread(filename,'t',[StartIndex 0 StartIndex+25000000 3]); % 3rd and below is tx data
            remainingLines = remainingLines - 25000000;
            StartIndex = StartIndex + 25000000;
        else
            TxData = dlmread(filename,'t',[StartIndex 0 n-1 3]); % 3rd and below is tx data
            remainingLines = 0;
        end
        disp(['Running for batch ',num2str(batch),'...'])
        
        % Basic data
        % Number of transations
        transactions = transactions + length(TxData);
        % Calculating amount of servers
        activeServs = unique(TxData(:,3));
        activeServers = unique([activeServers;activeServs]);

        % Calculating amount of micropayments
        watchTimes = TxData(:,4);
        microPayments_perUser = ceil(watchTimes/microDuration);
        microPayments = microPayments + sum(microPayments_perUser);

        %% Relay Delay System
        % Prerequisites
        % Creating list of temporary balances
        disp('Making balance matrix...');
        tempBalances = TempBalances(TxData,cost,simTime);
        disp('Finished.')
        fprintf(1, '\n');

        % Finding appropriate timestamps (for relay delay check, 5 second blocktime)
        disp('Formatting block timestamps...')
        txsInBlock = Timestamps(tempBalances, simTime);
        disp('Finished.')
        fprintf(1, '\n');

        % Estimating TPS
        disp(['Running for value ',num2str(f),'...'])
        % Running for all 3 relay delay / balance threshold values
        for i = 1:3
            relayDelay = relayDelayTimes(i);
            threshold = thresholds(i);
            [updates, updates_thres, blocks, newBalances,newidWhitelist] = TPS_2(tempBalances,txsInBlock,relayDelay,threshold,blockTime,lastUserId,simTime,userBalances(:,i),idWhitelist(:,i));
            idWhitelist(:,i) = newidWhitelist;
            userBalances(:,i) = newBalances;      
            updatesAll(i) = updatesAll(i) + updates;
            updatesThresOnly(i) = updatesThresOnly(i) + updates_thres;
        end
        batch = batch + 1; % Next file batch
        % Checking if entire file has been loaded
        if remainingLines == 0
            LoadComplete = true;
        end
    end
    % Total TPS estimation
    % Tx generation rate
    tps(f) = transactions / simTime;
    % Calculating amount of micropayments
    micropayments_tps(f) = microPayments/simTime;
    
    % Balance updates (all 3 components)
    % Adding first time server is activated in total TPS output
    updatesAll = updatesAll + updatesThresOnly + length(activeServers);
    updatesPS_rD(f,:) = updatesAll/simTime;
    % Updates due to surpassing threshold (1 component)
    updatesPS_rD_thres_ONLY(f,:) = updatesThresOnly/simTime;
    % Updates due to surpassing threshold and servers(2 components)
    % Adding first time server is activated in total TPS output
    updatesThresOnly = updatesThresOnly + length(activeServers);
    updatesPS_rD_thres(f,:) = updatesThresOnly/simTime;
    
    
    disp('Done.')
end
    
%% Plots
% Order results correctly for legends
plotgraphs = [tps'; micropayments_tps'; updatesPS_rD' ; updatesPS_rD_thres'; updatesPS_rD_thres_ONLY'];

for i = 1:size(plotgraphs,1)
    plotgraphs(i,length(values)+1) = mean(plotgraphs(i,1:length(values)));
end
if choice3 == 1
    plotgraphs(:,length(values)+2) = [0;1;2;2;2;3;3;3;4;4;4]; % Algorithm info
    plotgraphs(:,length(values)+3) = [0;0;1;2;3;1;2;3;1;2;3]; % Hours info
    plotgraphs(:,length(values)+4) = [0;0;1;2;3;1;2;3;1;2;3]; % Markers info
    plotgraphs(:,length(values)+5) = [1;1;6;6;10;6;6;12;10;10;1]; % MarkerSize info
    plotgraphs(:,length(values)+6) = [1;2;3;4;5;6;7;8;9;10;10]; % Colors info
    plotgraphs(:,length(values)+7) = [1;1;0.5;0.5;0.5;2;2;2;1;1;1]; % Line width info
    plotgraphs(:,length(values)+8) = [0;0;1;1;1;2;2;2;3;3;3]; % Line style info
else
    plotgraphs(:,length(values)+2) = [0;1;2;2;2;2;2;3;3;3;3;3;4;4;4;4;4]; % Algorithm info
    plotgraphs(:,length(values)+3) = [0;0;1;4;5;2;3;6;4;5;7;3;6;4;5;7;3]; % Hours info
    plotgraphs(:,length(values)+4) = [0;0;1;5;6;2;3;1;5;6;2;3;1;5;6;2;3]; % Markers info
    plotgraphs(:,length(values)+5) = [1;1;6;6;6;6;10;6;6;6;6;12;12;10;10;10;1]; % MarkerSize info
    plotgraphs(:,length(values)+6) = [1;2;3;11;12;4;5;6;10;10;7;8;9;10;10;10;10]; % Colors info
    plotgraphs(:,length(values)+7) = [1;1;0.5;0.5;0.5;0.5;0.5;2;2;2;2;2;1;1;1;1;1]; % Line width info
    plotgraphs(:,length(values)+8) = [0;0;1;1;1;1;1;2;2;2;2;2;3;3;3;3;3]; % Line style info
    % Delete unecessary entries
    plotgraphs(14:15,:) = [];
    plotgraphs(9:10,:) = [];
end
plotgraphs = sortrows(plotgraphs,length(values)+1);
plotgraphs = flipud(plotgraphs);

% Container maps and matrixes for legends (algorithms, linestyle, markers and colors)
[algorithms, linestyles, markers, colors, hours] = PlotDesign(2,0);

% Relay delay system - transactions per second (relay delay and threshold changing) 
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
switch choice1
    case 2
        title('S = 46000, $U = 6.5*10^{5}$, $\bar{s}$ = 30, r = 10 \%, v = 1200 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
    case 3
        title('S = 1000, $U = 6.5*10^{5}$, $\bar{s}$ = 3, r = 10 \%, v = 1200 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
end
grid on
ylabel('Txs per second')
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
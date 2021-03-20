%% Program definition:
% Processes transaction data from text file (Relay Delay System) and plots
% in relation to relay delay and threshold.
% Relay delay: Maximum time until somebody is allowed to get his money.
% Threshold: If a user surpasses this negative balance, he's charged one
% additional transaction. Corresponds to total watching time.

%% Start
% Clearing previous
clear;
clc;
tic

% Importing functions (see HelperFunctions.m and HelperFunctions2.m)

import HelperFunctions.TempBalances;
import HelperFunctions.Timestamps;
import HelperFunctions.TPS;
import HelperFunctions2.ParameterList;
import HelperFunctions2.GetChoice;
import HelperFunctions2.PlotDesign;

%% Intro / Base Parameters
% Intro
ParameterList({'Data processing file (relay delay system).',...
    'Blocktime: 5 seconds',...
    'Watching time per coin (in seconds): 3600',...
    'Micropayment time (in seconds): 60'});


% Micropayment time (in seconds)
microDuration = 60;
% Block Time (seconds per block)
blockTime = 5;
% Cost of video (how many seconds of watching time is a coin worth)
cost = 3600;

%% Getting user choice based on scenario
% Getting user's choice for scenario
choiceSc = GetChoice({'Available scenarios are:',...
    '1. 6,5 million users, 1000 servers, 3 (2-4) mean servers per user, 100 Txs per second, 10 days runtime.',...
    '2. 650 thousand users, 46000 servers, 30 (21-39) mean servers per user, 10 Txs per second.',...
    '3. 650 thousand users, 1000 servers, 3 (2-4) mean servers per user, 10 Txs per second.',...
    '4. Custom scenario'});
disp(['Scenario ', num2str(choiceSc), ' chosen!'])
fprintf(1, '\n');

% Getting user's choice for plot
disp('You can make TPS plots in relation to relay delay window (in blocks) and threshold balance (in hours).')

% Getting user's choice for scenario
choice = GetChoice({'Available choices are:',...
    '1. Relay Delay Window',...
    '2. Threshold Balance'});
disp('Choice confirmed. Gathering data...')
fprintf(1, '\n');

% Importing file based on scenario
switch choiceSc
    case 1
        filename = 'TxData6501000nodes100newsessions3600videoDuration864000seconds10relayRatio3meanServers.txt';
    case 2
        filename = 'TxData696000nodes10newsessions3600videoDuration432000seconds10relayRatio30meanServers.txt';
    case 3
        filename = 'TxData651000nodes10newsessions3600videoDuration432000seconds10relayRatio3meanServers.txt';
    case 4
        % Custom filename
        filename = '';
end
nodes = dlmread(filename,',',[0 0 0 0]); % number of nodes
lastUserId = dlmread(filename,',',[0 1 0 1]); % last user ID
lastRelayId = dlmread(filename,',',[0 2 0 2]); % last relay ID
simTime = dlmread(filename,',',[0 3 0 3]); % simulation time
TxData = readmatrix(filename);

% Picking correct values based on choice 
switch choice
    case 1
        if choiceSc == 1
            relayDelayTimes = [60,300,1800,3600,7200,18000,36000,54000,64800,86400,108000,172800,259200,432000,simTime];
        else
            relayDelayTimes = [60,300,1800,3600,7200,18000,36000,54000,64800,86400,108000,172800,259200,simTime];
        end
        thresholds = -1*[3600, 86400, 3600000]/cost; % Basic Cases
    case 2
        relayDelayTimes = [21600, 86400, simTime]; % Basic Cases
        thresholds = -1*[1800,3600,5400,7200,9000,10800,12600,14400,16200,18000,21600,25200,28800,32400,36000,43200,54000,72000,86400,108000,172800,259200,simTime]/cost;
end
fprintf(1, '\n');

%% Processing data - Simple statistics
% Number of transations
transactions = size(TxData,1);

% Node distribution
users = lastUserId;
relays = lastRelayId - lastUserId;
servers = nodes - lastRelayId;

% Calculating amount of active peers
activeServers = unique(TxData(:,3));

% Calculating amount of micropayments
watchTimes = TxData(:,4);
microPayments = ceil(watchTimes/60);
sum_microPayments = sum(microPayments);

%% Processing data - New system using a relay delay.
% Creating list of temporary balances
disp('Making balance matrix...');
tempBalances = TempBalances(TxData,cost);
disp('Finished.')
fprintf(1, '\n');

% Finding appropriate timestamps (for relay delay check, 5 second blocktime)
disp('Formatting block timestamps...')
txsInBlock = Timestamps(tempBalances, simTime);
disp('Finished.')
fprintf(1, '\n');

% Calculating TPS (initializing)
updatesPS_rD = zeros(length(relayDelayTimes),length(thresholds));
updatesPS_rD_thres = zeros(length(relayDelayTimes),length(thresholds));
updatesPS_rD_thres_ONLY = zeros(length(relayDelayTimes),length(thresholds));
% Starting loop (for relay delay time and threshold)
fprintf(1, '\n');
disp('Changing relay delay and balance threshold...')
for t = 1:length(thresholds)
    % Picking threshold
    threshold = thresholds(t);
    disp(['Checking for threshold: ', num2str(-1*threshold*cost),' seconds...'])
    for k = 1:length(relayDelayTimes)
        relayDelay = relayDelayTimes(k);
        disp(['Running for relay delay time: ', num2str(relayDelay), ' seconds.'])
        [updates, updates_thres, blocks] = TPS(tempBalances,txsInBlock,relayDelay,threshold,blockTime,nodes,lastUserId,simTime);
        % Balance updates per second ( all 3 components)
        % Adding first time server is activated in total TPS output
        updates = updates + updates_thres + length(activeServers);
        updatesPS_rD(k,t) = updates/simTime;
        % Updates due to surpassing threshold 
        updatesPS_rD_thres_ONLY(k,t) = updates_thres/simTime;
        % Updates due to surpassing threshold and active servers
        % Adding first time server is activated in total TPS output
        updates_thres = updates_thres + length(activeServers);
        updatesPS_rD_thres(k,t) = updates_thres/simTime;
    end  
    fprintf(1, '\n');
end
disp('Finished.')

%% Plotting data 
% TPS estimation for tx generation (micropayments and basic)
if choice == 1
    % Reformating relay delay times to blocks
    values = relayDelayTimes/5;
else
    values = -1*thresholds;
end
tps = transactions/simTime*ones(length(values),1);
micropayments_tps = sum_microPayments/simTime*ones(length(values),1);
        
% Order results correctly for legends
if choice == 1 
    plotgraphs = [tps'; micropayments_tps'; updatesPS_rD' ; updatesPS_rD_thres'; updatesPS_rD_thres_ONLY'];
else
    plotgraphs = [tps'; micropayments_tps'; updatesPS_rD ; updatesPS_rD_thres; updatesPS_rD_thres_ONLY];
end
for i = 1:size(plotgraphs,1)
    plotgraphs(i,length(values)+1) = mean(plotgraphs(i,1:length(values)));
end
plotgraphs(:,length(values)+2) = [0;1;2;2;2;3;3;3;4;4;4]; % Algorithm info
if choice == 1
    plotgraphs(:,length(values)+3) = [0;0;1;2;3;1;2;3;1;2;3]; % Hours info
    plotgraphs(:,length(values)+4) = [0;0;1;2;3;1;2;3;1;2;3]; % Markers info
    plotgraphs(:,length(values)+5) = [1;1;6;6;10;6;6;12;12;10;1]; % MarkerSize info
    plotgraphs(:,length(values)+6) = [1;2;3;4;5;6;7;8;9;10;10]; % Colors info
    plotgraphs(:,length(values)+7) = [1;1;0.5;0.5;0.5;2;2;2;1;1;1]; % Line width info
    plotgraphs(:,length(values)+8) = [0;0;1;1;1;2;2;2;3;3;3]; % Line style info
else
    plotgraphs(:,length(values)+3) = [0;0;1;2;3;4;4;4;4;4;4]; % Hours info
    plotgraphs(:,length(values)+4) = [0;0;1;2;3;4;4;4;4;4;4]; % Markers info
    plotgraphs(:,length(values)+5) = [1;1;6;6;10;6;6;6;8;8;8]; % MarkerSize info
    plotgraphs(:,length(values)+6) = [1;2;3;4;5;6;7;8;9;9;9]; % Colors info
    plotgraphs(:,length(values)+7) = [1;1;0.5;0.5;0.5;2;2;2;1;1;1]; % Line width info
    plotgraphs(:,length(values)+8) = [0;0;1;1;1;2;2;2;3;3;3]; % Line style info
    % Delete unecessary entries
    plotgraphs(11,:) = [];
    plotgraphs(7:8,:) = [];
end
plotgraphs = sortrows(plotgraphs,length(values)+1);
plotgraphs = flipud(plotgraphs);

% Container maps and matrixes for legends (algorithms, linestyle, markers and colors)
[algorithms, linestyles, markers, colors, hours] = PlotDesign(1,choice);

% Make correct plot
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
if choice == 1
    % Relay delay plot
    xlabel('Relay delay window (in number of blocks)')
else
    % Threshold plot
    xlabel('Balance threshold (in hours)')  
end
% Pick correct title
switch choiceSc
    case 1
        title('S = 1000, $U = 6.5*10^{6}$, $\bar{s}$ = 3, r = 10 \%, n = 100, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
    case 2
        title('S = 46000, $U = 6.5*10^{5}$, $\bar{s}$ = 30, r = 10 \%, n = 10, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
    case 3
        title('S = 1000, $U = 6.5*10^{5}$, $\bar{s}$ = 3, r = 10 \%, n = 10, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
    case 4
        title('Custom Scenario','Interpreter','Latex')
end
grid on
ylabel('Txs per second')
legend show;
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
fprintf(1, '\n');figure(1)
timeElapsed = toc;
disp(['Execution time: ', num2str(timeElapsed), ' seconds.'])
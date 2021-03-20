%% Program definition:
% Plots TPS output according to specific system parameters like relay
% ratio, mean servers, video duration, activation ratio, etc.

%% Start
% Clearing previous
clear;
clc;
tic

% Importing functions (see HelperFunctions.m)
import HelperFunctions.TempBalances;
import HelperFunctions.Timestamps;
import HelperFunctions.TPS;
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

%% Running data
% Intro
disp('Plotting according to parameters file.')
disp('-----------------------------------------------')

% Getting user's choice for scenario
choice1 = GetChoice({'Available options are:',...
    '1. 650 thousand users, 46000 servers, 30 (21-39) mean servers per user, 10 Txs per second.',...
    '2. 650 thousand users, 1000 servers, 3 (2-4) mean servers per user, 10 Txs per second.',...
    '3. Custom users/servers for TPS-users plot.'});
choice1 = choice1 + 1;
disp(['Scenario ', num2str(choice1), ' chosen!'])
fprintf(1, '\n');

% Get user's choice for plot if its scenario 1 or 2. Else, initialize user
% counts according to user choice.
if choice1 ~= 4
    % Getting user's choice for plot
    choiceParam = GetChoice({'Your available parameters are:',...
    '1. Relay Ratio (0% to 100%)',...
    '2. Mean Servers (3 to 1000)',...
    '3. Activation Ratio and Video Duration (with their multiplication always equal to 36000)',...
    '4. Video Duration (15 minute to 2 hours)',...
    '5. Activation Ratio for 20 minute videos (up to 450 new sessions)',...
    '6. Run for base parameters.'});
    disp(['Method ', num2str(choiceParam), ' chosen!'])
    fprintf(1, '\n');
    % Number of files/values
    switch choiceParam
        case 1
            values = [0, 5, 10, 20, 35, 50, 65, 80, 100];
        case 2
            values = [3, 30, 100, 500, 1000];
        case 3
            values = [40 900; 20 1800; 15 2400; 10 3600; 8 4500; 6 6000; 5 7200];
        case 4
            values = [900 1800 2700 3600 4500 5400 6300 7200 10800 18000];
        case 5
            values = [1 5 10 50 100 175 250 350 450];
    end
else
    % Getting user's choice for plot
    choice2 = GetChoice({'You have 2 choices:',...
    '1. 1000 servers',...
	'2. 650 users / 46 servers analogy',...
    '3. 1000 servers / 0 relay ratio'});
    disp(['Subscenario ', num2str(choice2), ' chosen!'])
    % Number of files/values
    % Activation ratios
    actRatios = [0.142, 0.71, 1.42, 7, 14, 28, 71, 143];
    % nodes
    switch choice2
        case {1,3}
            values = [11000,51000,101000,501000,1001000,2001000,5001000,10001000];
        case 2
            values = [10708,53538,107077,535385,1070769,2141538,5353845,10707690];
    end
end

% Getting user's choice for relay delay/threshold pairs
choice3 = GetChoice({'What pairs of relay delay/threshold values do you want to use?',...
    '1. 1/1hr, 24/24hr, Inf/Inf',...
    '2. 1/1hr, 1/24hr, 24/1hr, 24/24hr, Inf/Inf'});
if choice3 == 1
    % Relay delay (maximum time until somebody is allowed to get his money)
    relayDelayTimes = [3600, 86400, 432000]; % Basic Cases
    % Threshold balance
    thresholds = -1*[3600, 86400, 3600000]/cost; % Basic Cases
elseif choice3 == 2
    % Relay delay (maximum time until somebody is allowed to get his money)
    relayDelayTimes = [3600, 3600, 86400, 86400, 432000]; % Basic Cases
    % Threshold balance
    thresholds = -1*[3600, 86400, 3600, 86400, 3600000]/cost; % Basic Cases
end
% Initializing
% 3 or 5 columns depending of combinations of relay delay and threshold
updatesPS_rD = zeros(length(values),length(relayDelayTimes)); 
updatesPS_rD_thres = zeros(length(values),length(relayDelayTimes));
updatesPS_rD_thres_ONLY = zeros(length(values),length(relayDelayTimes));
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
        case 4
            nodesTotal = values(f);
            actRatio = actRatios(f);
    end
    if choice1 ~= 4
        switch choiceParam
            case 1
                % Variable relay ratio
                filename = ['TxData',num2str(nodesTotal),'nodes10newsessions3600videoDuration432000seconds',num2str(values(f)),'relayRatio',num2str(meanServs),'meanServers.txt'];
            case 2
                % Variable mean servers
                filename = ['TxData',num2str(nodesTotal),'nodes10newsessions3600videoDuration432000seconds10relayRatio',num2str(values(f)),'meanServers.txt'];
            case 3
                % Variable video time and act ratio
                filename = ['TxData',num2str(nodesTotal),'nodes',num2str(values(f,1)),'newSessions',num2str(values(f,2)),'videoDuration432000seconds10relayRatio',num2str(meanServs),'meanServers.txt'];
            case 4
                % Variable video time
                filename = ['TxData',num2str(nodesTotal),'nodes10newSessions',num2str(values(f)),'videoDuration432000seconds10relayRatio',num2str(meanServs),'meanServers.txt'];
            case 5
                % 20 minute videos, variable activation ratio
                filename = ['TxData',num2str(nodesTotal),'nodes',num2str(values(f)),'newSessions1200videoDuration432000seconds10relayRatio',num2str(meanServs),'meanServers.txt'];
        end
    else
        switch choice2
            case 1
                % 1000 servers
                filename = ['TxData',num2str(nodesTotal),'nodes',num2str(actRatio),'newsessions3600videoDuration432000seconds10relayRatio3meanServers.txt'];
            case 2
                % 46/650 analogy
                filename = ['TxData',num2str(nodesTotal),'nodes',num2str(actRatio),'newsessions3600videoDuration432000seconds10relayRatio30meanServers.txt'];
            case 3
                % 1000 servers/ 0 relay ratio
                filename = ['TxData',num2str(nodesTotal),'nodes',num2str(actRatio),'newsessions3600videoDuration432000seconds0relayRatio3meanServers.txt'];
        end
    end
    nodes = dlmread(filename,',',[0 0 0 0]); % number of nodes
    lastUserId = dlmread(filename,',',[0 1 0 1]); % last user ID
    lastRelayId = dlmread(filename,',',[0 2 0 2]); % last relay ID
    simTime = dlmread(filename,',',[0 3 0 3]); % simulation time
    TxData = readmatrix(filename);
    
    % Basic data
    % Number of transations
    transactions = length(TxData);
    tps(f) = transactions / simTime;
    % Node distribution
    users = lastUserId;
    relays = lastRelayId - lastUserId;
    servers = nodes - lastRelayId;
    % Calculating amount of active peers
    activeUsers = unique(TxData(:,2));
    activeServers = unique(TxData(:,3));
    activeNodes = unique([TxData(:,2),TxData(:,3)]);
    
    % Calculating amount of micropayments
    watchTimes = TxData(:,4);
    microPayments = ceil(watchTimes/microDuration);
    micropayments_tps(f) = sum(microPayments)/simTime;
    
    %% Relay Delay System
    % Prerequisites
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
    
    % Estimating TPS
    disp(['Running for value ',num2str(f),'...'])
    % Running for all 3 or 5 relay delay / balance threshold values
    for i = 1:length(relayDelayTimes)
        relayDelay = relayDelayTimes(i);
        threshold = thresholds(i);
        [updates, updates_thres, blocks] = TPS(tempBalances,txsInBlock,relayDelay,threshold,blockTime,nodes,lastUserId,simTime);
        % Balance updates second (all 3 components)
        % Adding first time server is activated in total TPS output
        updates = updates + updates_thres + length(activeServers);
        updatesPS_rD(f,i) = updates/simTime;
        % Updates due to surpassing threshold (1 component)
        updatesPS_rD_thres_ONLY(f,i) = updates_thres/simTime;
        % Updates due to surpassing threshold and servers(2 components)
        % Adding first time server is activated in total TPS output
        updates_thres = updates_thres + length(activeServers);
        updatesPS_rD_thres(f,i) = updates_thres/simTime;
    end
    
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

% If scenario = 4,save variables for interpolation later
if choice1 == 4
    if choice2 == 1
        save('SubScenario1.mat','plotgraphs');
    elseif choice2 == 2
        save('SubScenario2.mat','plotgraphs');
    elseif choice2 == 3
        save('SubScenario3.mat','plotgraphs');
    end
end

% Container maps and matrixes for legends (algorithms, linestyle, markers and colors)
[algorithms, linestyles, markers, colors, hours] = PlotDesign(2,0);

% Handling legends when we have 5 d/b combinations
hours(6) = 'for any d and b = 1 hour)';
hours(7) = 'for any d and b = 24 hrs)';

% Fixing value array for choice2 = 3
if choice1 ~=4 && choiceParam == 3
    values = values(:,1);
end
% Fixing value array for choice1 = 4
if choice1 == 4
    values = [10000,50000,100000,500000,1000000,2000000,5000000,10000000];
end

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
% Picking correct axis labels/titles/etc
if choice1 ~= 4
    switch choiceParam
        case 1
            switch choice1
                case 2
                    title('S = 46000, $U = 6.5*10^{5}$, $\bar{s}$ = 30, n = 10, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
                case 3
                    title('S = 1000, $U = 6.5*10^{5}$, $\bar{s}$ = 3, n = 10, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
            end
            xlabel('Relay ratio (in percentage %)')
        case 2
            switch choice1
                case 2
                    title('S = 46000, $U = 6.5*10^{5}$, r = 10 \%, n = 10, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
                case 3
                    title('S = 1000, $U = 6.5*10^{5}$, r = 10 \%, n = 10, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
            end
            xlabel('Mean servers per user')
        case 3
            switch choice1
                case 2
                    title('S = 46000, $U = 6.5*10^{5}$, $\bar{s}$ = 30, r = 10 \%, $n*v = 36000 sec$, t = 5 sec, m = 60 sec','Interpreter','Latex')
                case 3
                    title('S = 1000, $U = 6.5*10^{5}$, $\bar{s}$ = 3, r = 10 \%, $n*v = 36000 sec$, t = 5 sec, m = 60 sec','Interpreter','Latex')
            end
            xlabel('New sessions per second')
        case 4
            switch choice1
                case 2
                    title('S = 46000, $U = 6.5*10^{5}$, $\bar{s}$ = 30, r = 10 \%, n = 10, t = 5 sec, m = 60 sec','Interpreter','Latex')
                case 3
                    title('S = 1000, $U = 6.5*10^{5}$, $\bar{s}$ = 3, r = 10 \%, n = 10, t = 5 sec, m = 60 sec','Interpreter','Latex')
            end
            xlabel('Video Duration (in seconds)')
        case 5
            switch choice1
                case 2
                    title('S = 46000, $U = 6.5*10^{5}$, $\bar{s}$ = 30, r = 10 \%, v = 1200 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
                case 3
                    title('S = 1000, $U = 6.5*10^{5}$, $\bar{s}$ = 3, r = 10 \%, v = 1200 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
            end
            xlabel('New sessions per second')
    end
else
    switch choice2
        case 1
            title('S = 1000, $\bar{s}$ = 3, r = 10 \%, $n = 1.43*10^{-5}*U$, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
            xlabel('User total')
        case 2
            title('$S = 0.070769*U$, $\bar{s}$ = 30, r = 10 \%, $n = 1.43*10^{-5}*U$, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
            xlabel('User total')
        case 3
            title('S = 1000, $\bar{s}$ = 3, r = 0 \%, $n = 1.43*10^{-5}*U$, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
            xlabel('User total')            
    end
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


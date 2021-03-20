%% Program definition:
% Processes transaction data from text file (Relay Delay System) using
% RE-CENT algorithms.
% Used only for big simulation files that can't be loaded in the RAM in their entirety.
% Relay delay: Maximum time until somebody is allowed to get his money.
% Threshold: If a user surpasses this negative balance, he's charged one
% additional transaction. Corresponds to total watching time.

%% Start
% Clearing previous
clear;
clc;
tic

% Importing functions (see HelperFunctions.m and HelperFunctions2.m)
import HelperFunctions2.ParameterList;
import HelperFunctions2.GetChoice;
import HelperFunctions2.PlotDesign;

%% Intro / Base Parameters
% Intro
ParameterList({'Algorithmic data processing file (used for big files).',...
    'Blocktime: 5 seconds',...
    'Watching time per coin (in seconds): 3600',...
    'Micropayment time (in seconds): 60'});


% Micropayment time (in seconds)
microDuration = 60;
% Block Time (seconds per block)
blockTime = 5;
% Micropayment duration (in seconds)
m = 60;
% Cost of video (how many seconds of watching time is a coin worth)
cost = 3600;

% Defining chunksize (how many entries are loaded each time)
chunksize = 500000;

%% Importing file
% Choosing file
filenames = {'Part1TxData500001000nodes7150newsessions3600videoDuration432000seconds10relayRatio3meanServers.txt',...
    'PartLastTxData500001000nodes7150newsessions3600videoDuration432000seconds10relayRatio3meanServers.txt'};

% Basic file info
fid = fopen(filenames{1});
info = textscan(fid,'%f,%f,%f,%f',1);  % Get number of users
textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
info = cell2mat(info);
nodes = info(1);
lastUserId = info(2);
totalUsers = info(3);
simTime = info(4);

disp(['Analyzing simulation with ',num2str(totalUsers),' users...'])

% Thresholds and relay delays
thresholds = -1*[1800,3600,7200,10800,18000,21600,28800,36000,43200,54000,72000,86400,108000,172800,simTime];
relayDelayTimes = [60,300,1800,3600,9000,14400,21600,36000,54000,64800,86400,108000,172800,259200,simTime];

%% Calculating on-chain transactions, micropayments and active servers
fprintf('\n')
chunk = 1; % Keeping track of chunks
ServerActivity = uint16(zeros(nodes,1)); % How many times each node provides content
OnChainTxs = 0; % On-chain transactions
Micropayments = 0; % Micropayments
disp('Calculating active servers...')
for u = 1:length(filenames)
    fid = fopen(filenames{u});
    textscan(fid,'%f %f %f %f');  % Get number of users
    textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
    TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
    TxData = cell2mat(TxData);
    while length(TxData)>1
        % If server is activated, increase by one
        Servers = TxData(:,3);
        edges = unique(Servers);
        counts = histc(Servers(:), edges);
        counts = uint16(counts);
        ServerActivity(edges) = ServerActivity(edges) + counts;
        % Add new transcations (On-chain)
        OnChainTxs = OnChainTxs + size(TxData,1);
        % Add new transactions (Micropayments)
        watchTimes = TxData(:,4);
        Micropayments = Micropayments + sum(ceil(watchTimes/m));
        if size(TxData,1) == chunksize
            disp([num2str(chunk*chunksize),' lines traversed...'])
        end
        TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
        TxData = cell2mat(TxData);
        chunk = chunk + 1;
    end
end
disp('All lines traversed.')
TotalActiveServers = length(ServerActivity(ServerActivity>0));
clear ServerActivity;


%% Calculating threshold updates
disp('Calculating threshold updates...')
thresholdUpdates = zeros(length(thresholds),1);
for i = 1:length(thresholds)/3
    b = thresholds((i-1)*3+1:(i-1)*3+3);
    balances = int32(zeros(nodes,3));
    fprintf('\n')
    for u = 1:length(filenames)
        fid = fopen(filenames{u});
        textscan(fid,'%f %f %f %f');  % Skip 1st line
        textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
        TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
        TxData = cell2mat(TxData);
        disp(['For threshold = ',num2str(-b/cost),' hours...'])
        chunk = 1; % Keeping track of chunks
        while length(TxData)>1
            % Calculate balance thresholds
            for j = 1:size(TxData,1)
                for k = 1:3
                    balances(TxData(j,2),k) = balances(TxData(j,2),k) - TxData(j,4);
                    balances(TxData(j,3),k) = balances(TxData(j,3),k) + TxData(j,4);
                    if balances(TxData(j,2),k) < b(k)
                        balances(TxData(j,2),k) = 0;
                        thresholdUpdates((i-1)*3+k) = thresholdUpdates((i-1)*3+k) + 1;
                    end
                end
            end
            if size(TxData,1) == chunksize
                disp([num2str(chunk*chunksize),' lines traversed...'])
            end
            TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
            TxData = cell2mat(TxData);
            chunk = chunk + 1;
        end
        chunk = chunk - 1;
    end
    disp('All lines traversed.')
    clear balances;
end


%% Calculating positive server updates
disp('Calculating positive server updates...')
posServerUpdates = zeros(length(relayDelayTimes),1);
for i = 1:length(relayDelayTimes)/15
    d = relayDelayTimes;
    serviceWindow = uint16(zeros(nodes-lastUserId,15));
    fprintf('\n')
    for u = 1:length(filenames)
        fid = fopen(filenames{u});
        textscan(fid,'%f %f %f %f');  % Skip 1st line
        textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
        TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
        TxData = cell2mat(TxData);
        disp(['For relay delay = ',num2str(d/5),' blocks...'])
        chunk = 1; % Keeping track of chunks
        while length(TxData)>1
            % Calculate balance thresholds
            for j = 1:size(TxData,1)
                for k = 1:15
                    if serviceWindow((TxData(j,3)-lastUserId),k) < fix((TxData(j,1)-1)/d(k))+1
                        serviceWindow((TxData(j,3)-lastUserId),k) = fix((TxData(j,1)-1)/d(k))+1;
                        posServerUpdates(k) = posServerUpdates(k) + 1;
                    end
                end
            end
            if size(TxData,1) == chunksize
                disp([num2str(chunk*chunksize),' lines traversed...'])
            end
            TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
            TxData = cell2mat(TxData);
            chunk = chunk + 1;
        end
        chunk = chunk - 1;
    end
    disp('All lines traversed.')
    clear serviceWindow;
end


%% Draw Plots
% Relay Delay Plot
% Reformating relay delay times to blocks
values = relayDelayTimes/5;
% Finding TPS outputs
tps = (OnChainTxs/simTime*ones(length(values),1))';
micropayments_tps = (Micropayments/simTime*ones(length(values),1))';
updatesPS_rD(1,:) = posServerUpdates + TotalActiveServers + thresholdUpdates(2);
updatesPS_rD(2,:) = posServerUpdates + TotalActiveServers + thresholdUpdates(12);
updatesPS_rD(3,:) = posServerUpdates + TotalActiveServers;
updatesPS_rD = updatesPS_rD / simTime;
updatesPS_rD_thres(1,1:length(relayDelayTimes)) = TotalActiveServers + thresholdUpdates(2);
updatesPS_rD_thres(2,1:length(relayDelayTimes)) = TotalActiveServers + thresholdUpdates(12);
updatesPS_rD_thres(3,1:length(relayDelayTimes)) = TotalActiveServers;
updatesPS_rD_thres = updatesPS_rD_thres / simTime;
updatesPS_rD_thres_ONLY(1,1:length(relayDelayTimes)) = thresholdUpdates(2);
updatesPS_rD_thres_ONLY(2,1:length(relayDelayTimes)) = thresholdUpdates(12);
updatesPS_rD_thres_ONLY(3,1:length(relayDelayTimes)) = 0;
updatesPS_rD_thres_ONLY = updatesPS_rD_thres_ONLY / simTime;
plotgraphs = [tps; micropayments_tps; updatesPS_rD ; updatesPS_rD_thres; updatesPS_rD_thres_ONLY];
% Correctly ordering plots
for i = 1:size(plotgraphs,1)
    plotgraphs(i,length(values)+1) = mean(plotgraphs(i,1:length(values)));
end
plotgraphs(:,length(values)+2) = [0;1;2;2;2;3;3;3;4;4;4]; % Algorithm info
plotgraphs(:,length(values)+3) = [0;0;1;2;3;1;2;3;1;2;3]; % Hours info
plotgraphs(:,length(values)+4) = [0;0;1;2;3;1;2;3;1;2;3]; % Markers info
plotgraphs(:,length(values)+5) = [1;1;6;6;10;6;6;12;12;10;1]; % MarkerSize info
plotgraphs(:,length(values)+6) = [1;2;3;4;5;6;7;8;9;10;10]; % Colors info
plotgraphs(:,length(values)+7) = [1;1;0.5;0.5;0.5;2;2;2;1;1;1]; % Line width info
plotgraphs(:,length(values)+8) = [0;0;1;1;1;2;2;2;3;3;3]; % Line style info
plotgraphs = sortrows(plotgraphs,length(values)+1);
plotgraphs = flipud(plotgraphs);
% Container maps and matrixes for legends (algorithms, linestyle, markers and colors)
[algorithms, linestyles, markers, colors, hours] = PlotDesign(1,1);
% Drawing plot
figure(1)
hold on
for i = 1:size(plotgraphs,1)-1
    plot(values, plotgraphs(i,1:length(values)),...
        'DisplayName',[algorithms(plotgraphs(i,length(values)+2)),hours(plotgraphs(i,length(values)+3))],...
        'LineWidth',plotgraphs(i,length(values)+7),...
        'Marker',markers(plotgraphs(i,length(values)+4)),...
        'LineStyle',linestyles(plotgraphs(i,length(values)+8)),...
        'MarkerSize',plotgraphs(i,length(values)+5),...
        'color',colors(plotgraphs(i,length(values)+6),:))
end
xlabel('Relay delay window (in number of blocks)')
title('S = 1000, $U = 10*10^{6}$, $\bar{s}$ = 3, r = 0 \%, n = 143, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
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


% Threshold Plot
% Reformating thresholds to hours
values2 = -1*thresholds/cost;
% Finding TPS outputs
tpsv2 = (OnChainTxs/simTime*ones(length(values2),1))';
micropayments_tpsv2 = (Micropayments/simTime*ones(length(values2),1))';
updatesPS_rDv2(1,:) = thresholdUpdates + TotalActiveServers + posServerUpdates(7);
updatesPS_rDv2(2,:) = thresholdUpdates + TotalActiveServers + posServerUpdates(11);
updatesPS_rDv2(3,:) = thresholdUpdates + TotalActiveServers + posServerUpdates(15);
updatesPS_rDv2 = updatesPS_rDv2 / simTime;
updatesPS_rD_thresv2(1,1:length(thresholds)) = thresholdUpdates + TotalActiveServers;
updatesPS_rD_thresv2(2,1:length(thresholds)) = thresholdUpdates + TotalActiveServers;
updatesPS_rD_thresv2(3,1:length(thresholds)) = thresholdUpdates + TotalActiveServers;
updatesPS_rD_thresv2 = updatesPS_rD_thresv2 / simTime;
updatesPS_rD_thres_ONLYv2(1,1:length(thresholds)) = thresholdUpdates;
updatesPS_rD_thres_ONLYv2(2,1:length(thresholds)) = thresholdUpdates;
updatesPS_rD_thres_ONLYv2(3,1:length(thresholds)) = thresholdUpdates;
updatesPS_rD_thres_ONLYv2 = updatesPS_rD_thres_ONLYv2 / simTime;
plotgraphsv2 = [tpsv2; micropayments_tpsv2; updatesPS_rDv2 ; updatesPS_rD_thresv2; updatesPS_rD_thres_ONLYv2];
for i = 1:size(plotgraphsv2,1)
    plotgraphsv2(i,length(values2)+1) = mean(plotgraphsv2(i,1:length(values2)));
end
plotgraphsv2(:,length(values2)+2) = [0;1;2;2;2;3;3;3;4;4;4]; % Algorithm info
plotgraphsv2(:,length(values2)+3) = [0;0;1;2;3;4;4;4;4;4;4]; % Hours info
plotgraphsv2(:,length(values2)+4) = [0;0;1;2;3;4;4;4;4;4;4]; % Markers info
plotgraphsv2(:,length(values2)+5) = [1;1;6;6;10;6;6;6;8;8;8]; % MarkerSize info
plotgraphsv2(:,length(values2)+6) = [1;2;3;4;5;6;7;8;9;9;9]; % Colors info
plotgraphsv2(:,length(values2)+7) = [1;1;0.5;0.5;0.5;2;2;2;1;1;1]; % Line width info
plotgraphsv2(:,length(values2)+8) = [0;0;1;1;1;2;2;2;3;3;3]; % Line style info
% Delete unecessary entries
plotgraphsv2(11,:) = [];
plotgraphsv2(7:8,:) = [];
plotgraphsv2 = sortrows(plotgraphsv2,length(values2)+1);
plotgraphsv2 = flipud(plotgraphsv2);
% Container maps and matrixes for legends (algorithms, linestyle, markers and colors)
[algorithms, linestyles, markers, colors, hours] = PlotDesign(1,2);
% Drawing plot
figure(2)
hold on
for i = 1:size(plotgraphsv2,1)-1
    plot(values2, plotgraphsv2(i,1:length(values2)),...
        'DisplayName',[algorithms(plotgraphsv2(i,length(values2)+2)),hours(plotgraphsv2(i,length(values2)+3))],...
        'LineWidth',plotgraphsv2(i,length(values2)+7),...
        'Marker',markers(plotgraphsv2(i,length(values2)+4)),...
        'LineStyle',linestyles(plotgraphsv2(i,length(values2)+8)),...
        'MarkerSize',plotgraphsv2(i,length(values2)+5),...
        'color',colors(plotgraphsv2(i,length(values2)+6),:))
end
    xlabel('Balance threshold (in hours)')  
title('S = 1000, $U = 10*10^{6}$, $\bar{s}$ = 3, r = 0 \%, n = 143, v = 3600 sec, t = 5 sec, m = 60 sec','Interpreter','Latex')
grid on
ylabel('Txs per second')
legend show;
% Pick correct ylim
minY = min(plotgraphsv2(plotgraphsv2>0));
minY = ceil(log10(1/minY));
minY = 10^(-1*minY);
maxY = max(max(plotgraphsv2));
maxY = floor(log10(1/maxY));
maxY = 10^(-1*maxY);
ylim([minY maxY])
set(gca, 'YScale', 'log')

%% Printing execution time
fprintf(1, '\n');
timeElapsed = toc;
disp(['Execution time: ', num2str(timeElapsed), ' seconds.'])
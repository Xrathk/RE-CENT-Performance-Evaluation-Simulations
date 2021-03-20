%% Program definition:
% Models on-chain transaction data of the RE-CENT platform. 
% This file is for simulations with over 50 million users.

%% Start
% Clearing previous
clear;
clc;
tic

% Importing functions (see HelperFunctions.m and HelperFunctions2.m)
import HelperFunctions2.ParameterList;

%% Prerequisites / Base Parameters
% Intro
ParameterList({'Main simulation file (for over 50 million users).',...
    'Users = 6.5 billion, servers = 460 million, relays = 10% of users',...
    'Simulation time = 5 days',...
    'Video duration = 3600 seconds',...
    'Activation ratio = 100.000 new sessions per 7 billion users',...
    'Mean servers per user per user follow a normal distribution.'});

% Base parameters
% Relay ratio (as percentage of users)
relayRatio = 0.1;
% Video duration mean value (in seconds)
videoDuration = 3600;
% Simulation time (in seconds)
SimTime = 86400*5;

% User-defined parameters
NumUsers = 500000000;
NumServers = 1000;
act_rate = 1430*NumUsers/10^8;
meanServers = 3; 


% Total number of nodes and distribution
lambda = NumUsers + NumServers; % Users + servers
NumRelays = 10/100*NumUsers; % Relays
totalServers = NumServers + NumRelays; % Relays + servers
lastUserId = NumUsers - NumRelays;
%% Starting loop
% Checking conditions
if NumUsers <= 50000000
    fprintf(2,'Error!\nYou must pick over 50 million users for this simulation!\n');
    return
end

% Number of nodes in simulation
K = lambda;
disp(['Number of nodes is: ', num2str(K)]);
% File for TX data:
filename = ['PartLastTxData',num2str(lambda),'nodes',num2str(act_rate),'newsessions',num2str(videoDuration),'videoDuration',num2str(SimTime),'seconds',num2str(round(100*relayRatio)),'relayRatio',num2str(meanServers),'meanServers.txt'];
fileID = fopen(filename,'w');
% Writing number of nodes, last user ID and last relay IDs to file
fprintf(fileID,'%d,%d,%d,%d\n',K,round(NumUsers*(1-relayRatio)),NumUsers,SimTime);
% Column names
fprintf(fileID,'Timestamp,User,Server,VideoDuration\n'); 


% Creating node array. No server whitelist array for big simulations since
% servers are now chosen automatically.
deviceArray = zeros(NumUsers,1);
% Cast device array to uint16 to save space and time
deviceArray = uint16(deviceArray);


% Creating server seeds based on the number of mean servers. Assigned
% servers to a user are equal to: userId * seed / (servers + relays)
seeds = zeros(meanServers,1);
for i = 1:meanServers
    while true
        seed = randi(9*10^8 + 1) + 10^8 - 1;
        if ~ismember(seed,seeds)
            seeds(i) = seed;
            break
        end
    end
end


for j = 1:SimTime
    disp(j)
    % New sessions beginning each second:
    newSessions = poissrnd(act_rate);

    % Picking video durations (exp. distribution with mu = 3600s)
    video = videoDuration*ones(newSessions,1);
    video = exprnd(video);
    video = uint16(video);
    
    % Finding unoccupied users
    IDlist = find(deviceArray == 0);

    % Picking newSessions amount of new unoccupied users
    newUsers = randperm(length(IDlist),newSessions);
    newUsers = IDlist(newUsers);
    clear IDlist;

    
    % Finding new servers, according to proximity matrix 
    choices = randi(3,[newSessions 1]);
    newServers = lastUserId + mod(newUsers.*seeds(choices),totalServers);


    % Updating users timers
    deviceArray(newUsers) = deviceArray(newUsers) + video;

    % Reducing all timers by 1
    deviceArray = deviceArray - 1; 
    
    % Passing TX data to file:
    fileData = [j*ones(newSessions,1),newUsers,newServers,uint32(video)];
    fileData = cellstr(num2str(fileData));
    fprintf(fileID,'%s\n',fileData{:});  
end

% Closing file
fclose(fileID);

%% Printing runtime:
timeElapsed = toc;
fprintf('\n')
disp(['Runtime = ',num2str(timeElapsed),' seconds.'])
disp('----------------------------------------------------------------------')
fprintf('\n')



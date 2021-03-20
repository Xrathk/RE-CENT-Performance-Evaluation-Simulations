%% Program definition:
% Models on-chain transaction data of the RE-CENT platform.

%% Start
% Clearing previous
clear;
clc;
tic;

% Importing functions (see HelperFunctions.m and HelperFunctions2.m)
import HelperFunctions2.ParameterList;
import HelperFunctions2.GetChoice;
import HelperFunctions.DeviceArrayCreation;

%% Prerequisites / Base Parameters
% Intro
ParameterList({'Main simulation file (for up to 50 million users).',...
    'Users = 6.5 billion, servers = 460 million, relays = 10% of users',...
    'Simulation time = 5 days',...
    'Video duration = 3600 seconds',...
    'Activation ratio = 100.000 new sessions per 7 billion users',...
    'Mean servers per user per user follow a normal distribution.'});

% Base parameters
% Activation rate (new sessions per second)
act_rate = 100000;
% Relay ratio (as percentage of users)
relayRatio = 0.1;
% Video duration mean value (in seconds)
videoDuration = 3600;
% Simulation time (in seconds)
SimTime = 86400*5;

% Getting user's choice for scenario
choice = GetChoice({'Available scenarios are:',...
    '1. 6,5 million users, 1000 servers, 3 (2-4) mean servers per user, 100 Txs per second, 10 days runtime.',...
    '2. 650 thousand users, 46000 servers, 30 (21-39) mean servers per user, 10 Txs per second.',...
    '3. 650 thousand users, 1000 servers, 3 (2-4) mean servers per user, 10 Txs per second.',...
    '4. Incrementing amount of users (up to 10 million).',...
    '5. Custom parameters'});
disp(['Scenario ', num2str(choice), ' chosen!'])
fprintf(1, '\n');

% If user chose scenario 4, get more specific choice
subchoice = 0;
if choice == 4
    subchoice = GetChoice({'Available sub-scenarios are:',...
    '1. 1000 servers and 3 (2-4) mean servers per user.',...
	'2. 46/650 server/user analogy and 30 (21-39) mean servers per user.',...
    '3. 1000 servers and 3 (2-4) mean servers per user, relay ratio = 0%.'});
    disp(['Sub-scenario ', num2str(subchoice), ' chosen!'])
    fprintf(1, '\n');
end

% Getting appropriate parameters based on user's choice for scenario
switch choice       
    case 1
        % Scenario 1
        NumUsers = 6500000;
        NumServers = 1000;
        act_rate = 100;
        meanServers = 3;
        SimTime = 86400*10;
    case 2
        % Scenario 2
        NumUsers = 650000;
        NumServers = 46000;
        act_rate = 10;
        meanServers = 30;
    case 3
        % Scenario 3
        NumUsers = 650000;
        NumServers = 1000;
        act_rate = 10;
        meanServers = 3;       
    case 4
        % Parameters all change, possible values listed later
        NumUsers = 1;
    case 5
        % Scenario 5 / Custom parameters for different user/server plots
        NumUsers = 670000;
        NumServers = 1000;
        act_rate = 10;
        meanServers = 3; 
        SimTime = 1000;
end

% Checking condition for number of users
if max(NumUsers) > 50000000
    fprintf(2,'Your number of users is over 50 million. Run your simulation at MainSimulationBigNumbers.m instead!\n');
    return
end

%% Variable Parameters
% Getting user's choice for simulations if scenarios chosen are 2 or 3
if choice == 2 || choice == 3
    choiceParam = GetChoice({'Your available parameters are:',...
    '1. Relay Ratio (0% to 100%)',...
    '2. Mean Servers (3 to 1000)',...
    '3. Activation Ratio and Video Duration (with their multiplication always equal to 36000)',...
    '4. Video Duration (15 minute to 2 hours)',...
    '5. Activation Ratio for 20 minute videos (up to 450 new sessions)',...
    '6. Run for base parameters.'});
    disp(['Method ', num2str(choiceParam), ' chosen!'])
    fprintf(1, '\n');

    % Getting appropriate parameters based on user's choice
    switch choiceParam
        case 1
            % Relay ratio parameter
            %%%%%%%%%%% REMOVE IN MORNING
            numFiles = [0, 0.05, 0.1, 0.2, 0.35, 0.5, 0.65, 0.80, 1.00, 0, 0.05, 0.1, 0.2, 0.35, 0.5, 0.65, 0.80, 1.00]';
            command = 'relayRatio = numFiles(u);';
            text = 'disp([''Running for relay ratio = '',num2str(relayRatio),'' ...''])';
        case 2
            % Mean servers parameter
            if choice == 2
                numFiles = [3, 100, 500, 1000]';
            elseif choice == 3
                numFiles = [30, 100, 500, 1000]';
            end
            command = 'meanServers = numFiles(u);';
            text = 'disp([''Running for meanServers = '',num2str(meanServers),'' ...''])';
        case 3
            % Video duration / proportional activation ratio parameter
            numFiles = zeros(6,2);
            numFiles(:,1) = [900 1800 2400 4500 6000 7200];
            numFiles(:,2) = [40 20 15 8 6 5];
            command = 'videoDuration = numFiles(u,1); act_rate = numFiles(u,2);';
            text = 'disp([''Running for proportional activation ratio = '',num2str(act_rate),'' ...''])';
        case 4
            % Video duration parameter
            numFiles = [900 1800 2700 4500 5400 6300 7200]';
            command = 'videoDuration = numFiles(u);';
            text = 'disp([''Running for video duration = '',num2str(videoDuration),'' ...''])';
        case 5
            % 20 minute videos parameter
            videoDuration = 1200;
            numFiles = [1 5 10 50 100 175 250 350 450]';
            command = 'act_rate = numFiles(u);';
            text = 'disp([''Running for activation ratio = '',num2str(act_rate),'' ...''])';
        case 6
            % Base parameters
            numFiles = 1;
            command = '';
            text = 'disp(''Running for base parameters...'')';
    end
elseif choice == 1 || choice == 5
    % Setting up data for Scenarios 1 or custom (Base parameters)
    numFiles = 1;
    command = '';
    text = 'disp(''Running for base parameters...'')';
else 
    % Setting up data for Scenario 4 (varying users/act_rate/servers)
    numFiles = zeros(8,4);
    numFiles(:,1) = [10000 50000 100000 500000 1000000 2000000 5000000 10000000];
    numFiles(:,2) = [0.142 0.71 1.42 7 14 28 71 143];
    if subchoice == 1 || subchoice == 3
        numFiles(:,3) = [1000 1000 1000 1000 1000 1000 1000 1000];
        numFiles(:,4) = [3 3 3 3 3 3 3 3];
    else
        numFiles(:,3) = [708 3538 7077 35385 70769 141538 353845 707690];
        numFiles(:,4) = [30 30 30 30 30 30 30 30];
	end
    command = 'NumUsers = numFiles(u,1); act_rate = numFiles(u,2); NumServers = numFiles(u,3); meanServers = numFiles(u,4);';
    text = 'disp([''Running for '',num2str(NumUsers),'' users....''])';
end
%% Starting loop
% Getting user's choice for Ksamples
Ksamples = 0;
while Ksamples < 1 || (floor(Ksamples) ~= Ksamples)
    fprintf(1, '\n');
    try
        Ksamples = input('How many different K (amount of devices) samples do you want to run the simulation for? ');
    catch
        Ksamples = 0;
    end
    if Ksamples < 1 || (floor(Ksamples) ~= Ksamples) 
        disp('You need to enter an integer number above 0!')
    end
end

% Number of files
for u = 1:length(numFiles) 

    % Relay ratio initialized at 0.1, unless it changes
    relayRatio = 0.1;
	if subchoice == 3 % Scenario 4, sub-scenario 3
		relayRatio = 0;
	end
    
    % Changing parameters
    eval(command)
    eval(text)
    
    % Displaying info
    disp(['For iteration ', num2str(u),':'])

    % Finding number of nodes
    lambda = NumUsers + NumServers; % Users + servers

    % File for TX data:
    filename = ['TxData',num2str(lambda),'nodes',num2str(act_rate),'newsessions',num2str(videoDuration),'videoDuration',num2str(SimTime),'seconds',num2str(round(100*relayRatio)),'relayRatio',num2str(meanServers),'meanServers.txt'];
    fileID = fopen(filename,'w');
    % Column names
    
    
    for i = 1:Ksamples
        % Number of nodes: If Ksamples = 1, K = lambda. If Ksamples > 1, K = poissrnd(lambda).
        if Ksamples == 1
            K = lambda;
        else
            K = poissrnd(lambda);
        end
        disp(['Number of nodes in iteration ', num2str(i),' is: ', num2str(K)]);

        % Creating node array
        [deviceArray,serverWhitelistArray] = DeviceArrayCreation(K,NumUsers,relayRatio,meanServers);
        
        % Cast device and server whitelist array to uint32 to save space and time
        deviceArray = uint32(deviceArray);
        serverWhitelistArray = uint32(serverWhitelistArray);

        % Writing number of nodes, last user ID and last relay IDs to file
        fprintf(fileID,'%d,%d,%d,%d\n',K,round(NumUsers*(1-relayRatio)),NumUsers,SimTime);
        % Column names
        fprintf(fileID,'Timestamp,User,Server,VideoDuration\n'); 
        
        % Simulation runs for SimTime seconds  
        for j = 1:SimTime
            if mod(j,3600)==0
                disp(['Hours elapsed: ',num2str(fix(j/3600))])
            end
            % New sessions beginning each second:
            newSessions = poissrnd(act_rate);

            % Picking video durations (exp. distribution with mu = 3600s)
            video = videoDuration*ones(newSessions,1);
            video = exprnd(video);
            video = uint32(video);
            
            % Finding unoccupied users
            IDlist = find(deviceArray(:,1) == 0);
            
            % Picking newSessions amount of new unoccupied users
            newUsers = randperm(length(IDlist),newSessions);
            newUsers = IDlist(newUsers);
            clear IDlist;
            
            % Finding new servers, according to proximity matrix 
            newServers = zeros(newSessions,1);
            for iter=1:newSessions
                chosenServer = randi(deviceArray(newUsers(iter),2));
                newServers(iter) = serverWhitelistArray(newUsers(iter),chosenServer);
            end

            % Updating users timers
            deviceArray(newUsers,1) = deviceArray(newUsers,1) + video;

            % Reducing all timers by 1
            deviceArray(:,1) = deviceArray(:,1) - 1; 

            % Passing TX data to file:
            fileData = [j*ones(newSessions,1),newUsers,newServers,video];
            fileData = cellstr(num2str(fileData));
            fprintf(fileID,'%s\n',fileData{:});  
        end  

        % Closing file
        fclose(fileID);
    end
end

%% Printing runtime:
timeElapsed = toc;
fprintf('\n')
disp(['Runtime = ',num2str(timeElapsed),' seconds.'])
disp('----------------------------------------------------------------------')
fprintf('\n')



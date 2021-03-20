%% Program definition:
% Retrieves timers if simulation was interrupted, so it can continue.
% Simulation text file must not be corrupt

%% Start
% Clearing previous
clear;
clc;
tic

%% Retrieving timers
% Intro
disp('Retrieving interrupted simulation...')
disp('---------------------------------------------------------')

% Importing incomplete simulation file
filename = 'Part1TxData500001000nodes7150newsessions3600videoDuration432000seconds10relayRatio3meanServers.txt';

% Finding number of users, initializing
fid = fopen(filename);
info = textscan(fid,'%f,%f,%f,%f');  % Get number of users
info = cell2mat(info);
nodes = info(1);
lastUserId = info(2);
totalUsers = info(3);
SimTime = info(4);
timers = zeros(totalUsers,1); % Timer matrix
timers = uint16(timers);

% Defining chunksize (how many entries are loaded each time)
chunksize = 500000;
 
% Finding last second
lastSecond = 1; % Finding last second
textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
TxData = cell2mat(TxData);
disp('Starting loop to find last second...')
chunk = 1; % Keeping track of chunks
while length(TxData)>1
    lastSecond = max(lastSecond,max(TxData(:,1)));
    TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
    TxData = cell2mat(TxData);
    chunk = chunk + 1;
    if size(TxData,1) == chunksize
        disp([num2str(chunk*chunksize),' lines traversed...'])
    end
end
disp('All lines traversed.')
fclose(fid);

% Retrieving last timers, starting loop
fprintf('\n')
fid = fopen(filename);
textscan(fid,'%f,%f,%f,%f');  % Skip 1st line
textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
CurrentSecond = 1;
TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
TxData = cell2mat(TxData);
disp('Starting loop for timers...')
chunk = 1; % Keeping track of chunks
while length(TxData)>1
    if max(TxData(:,1)) > (lastSecond - 66000) % Only check last 66000 seconds
        for i = 1:size(TxData,1)
            timers(TxData(i,2)) = TxData(i,4);
            if TxData(i,1) > CurrentSecond
                CurrentSecond = TxData(i,1);
                timers = timers - 1;
            end
        end
    end
    TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
    TxData = cell2mat(TxData);
    chunk = chunk + 1;
    if size(TxData,1) == chunksize
        disp([num2str(chunk*chunksize),' lines traversed...'])
    end
end
disp('All lines traversed.')
fclose(fid);

% Finding user who has watched the most videos
vidsWatched = zeros(totalUsers,1); % Vids watched per user (so we can retrieve servers)
vidsWatched = uint16(vidsWatched);

% Starting loop for videos
fprintf('\n')
fid = fopen(filename);
textscan(fid,'%f,%f,%f,%f');  % Skip 1st line
textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
TxData = cell2mat(TxData);
disp('Starting loop for videos...')
chunk = 1; % Keeping track of chunks
while length(TxData)>1
    VideoWatchers = TxData(:,2);
    edges = unique(VideoWatchers);
    counts = histc(VideoWatchers(:), edges);
    counts = uint16(counts);
    vidsWatched(edges) = vidsWatched(edges) + counts;
    TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
    TxData = cell2mat(TxData);
    chunk = chunk + 1;
    if size(TxData,1) == chunksize
        disp([num2str(chunk*chunksize),' lines traversed...'])
    end
end
disp('All lines traversed.')
fclose(fid);

% Finding user who has watched the most videos
[m, MaxUser] = max(vidsWatched);

% Finding servers for this user
ServsMaxUser = [];

% Starting loop for servers
fprintf('\n')
fid = fopen(filename);
textscan(fid,'%f,%f,%f,%f');  % Skip 1st line
textscan(fid,'%s,%s,%s,%s');  % skip 2nd line
TxData = textscan(fid,'%f %f %f %f',chunksize); % Start
TxData = cell2mat(TxData);
disp('Starting loop for servers...')
chunk = 1; % Keeping track of chunks
while length(TxData)>1
    entries = find(TxData(:,2) == MaxUser);
    servs = TxData(entries,3);
    ServsMaxUser = [ServsMaxUser;servs];
    TxData = textscan(fid,'%f %f %f %f',chunksize); % Next batch
    TxData = cell2mat(TxData);
    chunk = chunk + 1;
    if size(TxData,1) == chunksize
        disp([num2str(chunk*chunksize),' lines traversed...'])
    end
end
disp('All lines traversed.')

% Final list of whitelisted servers in max user
ServsMaxUser = unique(ServsMaxUser);

% Print last second in simulation
disp(['Last second in simulation is: ',num2str(lastSecond), ' (',num2str(lastSecond/SimTime*100),'% complete)'])

% Finding seeds
TotalServers = nodes - lastUserId;
seeds = zeros(length(ServsMaxUser),1);
i = 1; % First server
while i <= length(ServsMaxUser)
    for seed = 10^8:10^9
        if mod(MaxUser*seed,TotalServers) == ServsMaxUser(i) - lastUserId
            disp(seed)
            seeds(i) = seed;
            break
        end
    end
    i = i + 1;
end

%% Printing execution time
fclose(fid);
fprintf(1, '\n');
timeElapsed = toc;
disp(['Execution time: ', num2str(timeElapsed), ' seconds.'])
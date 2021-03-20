%% Program definition:
% Class with useful calculation methods:
% Method 1: Device array creacation
% Method 2: Calculating balance updates for users during processing
% Method 3: Calculating temporary balance updates (for relay delay system)
% Method 4: Calculating correct timestamps of blocks (for relay delay system)
% Method 5: TPS Estimation for various relay delays and threshold
% Method 6: TPS Estimation for various relay delays and threshold (for bigger files (MATLAB2015a))

%% Useful functions
classdef HelperFunctions

    methods(Static)

        % Method 1:
        % Creating device array and server whitelist array for all users.
        % Rows depend on number of nodes (devices),
        % node distribution depends on userRatio and relayRatio.
        % First column is timer, second column is how many servers can serve the user, 
        % 3rd column is class
        % (1 = user, 2 = server/user and 3 = server),
        % Server whitelist array includes all servers that can service the
        % user.
        % 3rd column is deleted at end of function to save time
        function [x,y] = DeviceArrayCreation(devices,NumUsers,relayRatio,meanServers)

            % Initialize arrays 
            % Small Simulations ( <= 50 million )
            % Initializing device array
            array = zeros(devices,3); % 3 info columns

            % Splitting users and relays
            FinalUsers = round(NumUsers*(1-relayRatio));

            % First FinalUsers entries are users, next NumUsers -
            % FinalUsers entries are relays, final devices - NumUsers entries
            % are servers
            array(1:FinalUsers,3) = 1; % Users
            array(FinalUsers+1:NumUsers,3) = 2; % Relays
            array(NumUsers+1:devices,3) = 3; % Servers

            % If not, we have 7/10*mu to 13/10*mu servers per user
            array2 = zeros(NumUsers,ceil(13/10*meanServers));
            % Min and max servers per user (mu = meanServers, sigma = 3/10*meanServers)
            minServs = meanServers - ceil(3/10*meanServers);
            maxServs = meanServers + ceil(3/10*meanServers);

            % Assigning whitelisted servers to each node
            for i=1:NumUsers
                % Finding number of whitelisted servers and relays per node
                % normal distribution
                numServers = randi(maxServs - minServs+1) + minServs - 1;

                % Picking random servers and relays
                whiteListedServers = randperm((devices - FinalUsers),numServers) + FinalUsers;

                % Assigning them to a user/relay
                array(i,2) = numServers;
                array2(i,1:numServers) = whiteListedServers;
            end

            % Finding percentages of nodes (for troubleshooting purposes)
            users = sum(array(:,3) == 1);
            relays = sum(array(:,3) == 2);
            servers = sum(array(:,3) == 3);
            disp(['Percentage of users is: ',num2str(users/devices*100), '%.']);
            disp(['Percentage of relays is: ',num2str(relays/devices*100), '%.']);
            disp(['Percentage of servers is: ',num2str(servers/devices*100), '%.']);
            fprintf('\n')

            % Deleting class column
            array(:,3) = [];
            % Deleting servers from array
            array(NumUsers + 1 : devices,:) = [];

            
            % Returning values to main simulation
            x = array;
            y = array2;
        end

        
        % Method 2
        % Estimates balances of all nodes and how many videos they have 
        % watched or served. Parameters are transaction data,
        % number of nodes in simulation and the cost of one coin.
        function [x] = BalanceEstimation(TxData,nodes,cost)
            balances = zeros(nodes,2);
            for i = 1:size(TxData,1)
                video = TxData(i,4);
                % Balance updates
                balances(TxData(i,2),1) = balances(TxData(i,2),1) - video/cost;
                balances(TxData(i,3),1) = balances(TxData(i,3),1) + video/cost;
                % Number of updates
                balances(TxData(i,2),2) = balances(TxData(i,2),2) + 1;
                balances(TxData(i,3),2) = balances(TxData(i,3),2) + 1;
            end
            x = balances;
        end
        
        
        % Method 3
        % Estimates Temporary Balance matrix (1 row for each participant in
        % a transaction, 2*transactions total rows in array). Parameters
        % are transaction data, cost of one coin and simulation time.
        function [x] = TempBalances(TxData,cost)
            transactions = size(TxData,1);
            tempBalances = zeros(size(TxData,1)*2,3); % First column is timestamp, 2nd is device ID, 3rd is balance update
            for i = 1:transactions
                tempBalances(2*i-1,:) = [TxData(i,1),TxData(i,2),-1*TxData(i,4)/cost];
                tempBalances(2*i,:) = [TxData(i,1),TxData(i,3),TxData(i,4)/cost];
            end
            x = tempBalances;
        end
        
        
        % Method 4
        % Estimates amount of transactions in each block (5 seconds) for 
        % relay dalay system.
        % Greatly increases calculation of Txs per second. Parameters are
        % temporary balance array and simulation time.
        function [x] = Timestamps(tempBalances,simTime)
            timestamps = tempBalances(:,1);
            txsInBlock = zeros(simTime/5,1);
            for i = 1:length(timestamps)
                txsInBlock(fix((timestamps(i)-1)/5)+1) = txsInBlock(fix((timestamps(i)-1)/5)+1) + 1;
            end
            x = txsInBlock;
        end
               
        % Method 5
        % Transactions per second (TPS) estimation for specific relay time
        % and threshold. Parameters are temporary balance matrix, timestamp
        % matrix, relay delay, threshold, blockTime nodes, last user and relay id, 
        % simulation time. 
        % Returns totalTPS,tps due to threshold updates and total number of blocks.
        function [x,y,z] = TPS(tempBalances,txsInBlock,relayDelay,threshold,blockTime,nodes,lastUserId,simTime)
            updates = 0; % Total updates for this relayTime
            blocks = 0; % Total blocks for this relayTime
            % List of IDs and if they've been served already during relay delay
            idWhitelist = zeros(nodes-lastUserId,1);
            % We add an additional update when balance of user drops below threshold
            userBalances = zeros(nodes,1); 
            % Index of first transaction in block
            index = 1;
            updates_thres = 0; % Total threshold updates

            for i = 1:(simTime+relayDelay+1)
                % Deadline check time --> validating positive balance updates
                if mod(max(i,relayDelay+blockTime),blockTime) == 1
                    % Increasing blocks by one
                    blocks = blocks + 1;
                    
                    % Helpful indexes to take correct number of txs
                    startIndex = blocks*blockTime/5 - (blockTime/5 - 1);
                    endIndex = blocks*blockTime/5;
                    
                    slidingWindow = tempBalances(index:index+sum(txsInBlock(startIndex:endIndex)-1),2:3);  
                    slidingWindow1 = slidingWindow(2:2:end,1:2); % Positive balances
                    % Updating positive balances
                    for k = 1:size(slidingWindow1,1)
                        userBalances(slidingWindow1(k,1)) = userBalances(slidingWindow1(k,1)) + slidingWindow1(k,2);
                    end
                    % Finding new server IDs
                    newIDs = unique(slidingWindow1(:,1))-lastUserId;  
                    % Checking if ID has been served in this relay delay window and
                    % adding new updates
                    updates = updates + length(newIDs);
                    for i2 = 1:length(newIDs)
                        if idWhitelist(newIDs(i2)) == fix(i/relayDelay)
                            updates = updates - 1; % If ID already updated in this window, don't update again
                        end
                    end
                    % Checking if a user has surpassed the balance threshold
                    slidingWindow2 = slidingWindow(1:2:end,1:2); % Negative balances
                    for u = 1:size(slidingWindow2,1)
                        userBalances(slidingWindow2(u,1)) = userBalances(slidingWindow2(u,1)) + slidingWindow2(u,2);
                        if userBalances(slidingWindow2(u,1)) < threshold
                            updates_thres = updates_thres + 1; % Increase updates by one
                            userBalances(slidingWindow2(u,1)) = 0; % Resetting
                        end
                    end

                    % Updating index
                    index = index + sum(txsInBlock(startIndex:endIndex));

                    % Updating ID Whitelist
                    idWhitelist(newIDs) = fix(i/relayDelay)*ones(length(newIDs),1);
                end
            end
            
            x = updates;
            y = updates_thres;
            z = blocks;
        end
       
        % Method 6
        % Transactions per second (TPS) estimation like method 5 but for
        % big files.
        % Returns totalTPS,tps due to threshold updates, total number of blocks and new user balances.
        function [x,y,z,usrBal,idWl] = TPS_2(tempBalances,txsInBlock,relayDelay,threshold,blockTime,lastUserId,simTime,userBalances,idWhitelist)
            updates = 0; % Total updates for this relayTime
            blocks = 0; % Total blocks for this relayTime
            % Index of first transaction in block
            index = 1;
            updates_thres = 0; % Total threshold updates

            for i = 1:(simTime+relayDelay+1)
                % Deadline check time --> validating positive balance updates
                if mod(max(i,relayDelay+blockTime),blockTime) == 1
                    % Increasing blocks by one
                    blocks = blocks + 1;
                    
                    % Helpful indexes to take correct number of txs
                    startIndex = blocks*blockTime/5 - (blockTime/5 - 1);
                    endIndex = blocks*blockTime/5;
                    
                    slidingWindow = tempBalances(index:index+sum(txsInBlock(startIndex:endIndex)-1),2:3);  
                    slidingWindow1 = slidingWindow(2:2:end,1); % Positive balances1:
                    newIDs = unique(slidingWindow1)-lastUserId;  
                    % Checking if ID has been served in this relay delay window and
                    % adding new updates
                    updates = updates + length(newIDs);
                    for i2 = 1:length(newIDs)
                        if idWhitelist(newIDs(i2)) == fix(i/relayDelay)
                            updates = updates - 1; % If ID already updated in this window, don't update again
                        end
                    end
                    % Checking if a user has surpassed the balance threshold
                    slidingWindow2 = slidingWindow(1:2:end,1:2); % Negative balances
                    for u = 1:size(slidingWindow2,1)
                        userBalances(slidingWindow2(u,1)) = userBalances(slidingWindow2(u,1)) + slidingWindow2(u,2);
                        if userBalances(slidingWindow2(u,1)) < threshold
                            updates_thres = updates_thres + 1; % Increase updates by one
                            userBalances(slidingWindow2(u,1)) = 0; % Resetting
                        end
                    end

                    % Updating index
                    index = index + sum(txsInBlock(startIndex:endIndex));

                    % Updating ID Whitelist
                    idWhitelist(newIDs) = fix(i/relayDelay)*ones(length(newIDs),1);
                end
            end
            
            x = updates;
            y = updates_thres;
            z = blocks;
            usrBal = userBalances;
            idWl = idWhitelist;
        end
    end
end

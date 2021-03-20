%% Program definition:
% Class with useful UI/troubleshooting methods:
% Method 1: Prints introductory info and system parameters
% Method 2: Gets user choice for scenario, plot, or other options.
% Method 3: Calculates number of lines in file.
% Method 4: Creates useful container maps and matrixes for plot design.
%% Useful functions
classdef HelperFunctions2

    methods(Static)        
        % Method 1
        % Displays the name of the file and the base parameters of its functions.
        function ParameterList(BaseParams)
            fprintf('%s\n', BaseParams{1})
            disp('--------------------------------------------------------')
            fprintf(1, '\n');
            disp('Base parameters are:')
            for i = 2:length(BaseParams)
                fprintf('%s\n', BaseParams{i})
            end
            fprintf(1, '\n');
        end
        
        % Method 2
        % Gets user's choice based on a choice list.
        function  choice = GetChoice(Choices)
            choice = -1;
            availableChoices = linspace(1,length(Choices)-1,length(Choices)-1);
            while ~ismember(choice,availableChoices)
                fprintf(1, '\n');
                fprintf('%s\n', Choices{1})
                for i = 2:length(Choices)
                    fprintf('%s\n', Choices{i})
                end
                fprintf('What''s your choice?\n');
                try
                    choice = input('');
                catch
                    choice = 0;
                end
                if ~ismember(choice,availableChoices)
                    disp('Enter a valid number!')
                end
            end
            fprintf(1, '\n');
        end
        
        % Method 3
        % Gets number of lines in a file.
        function n = Linecount(filename)
            [fid, msg] = fopen(filename);
            if fid < 0
                error('Failed to open file "%s" because "%s"', filename, msg);
            end
            n = 0;
            while true
                t = fgetl(fid);
                if ~ischar(t)
                    break;
                else
                    n = n + 1;
                end
            end
            fclose(fid);
        end
        
        % Method 4
        % Contains useful container maps and matrixes for plot design
        function [algorithms, linestyles, markers, colors, hours] = PlotDesign(ChoiceFiles,Choice)  
            % Container maps for legends (algorithm)
            ids = [0 1 2 3 4];
            names = {'No relay - P2P micropayment aggregation per session', 'No relay - Micropayments', 'PSB algorithm ','SB algorithm ','B algorithm '};
            algorithms = containers.Map(ids,names);

            % Container maps for plot (linestyle)
            ids = [0 1 2 3];
            names = {'-', '--', ': ','none'};
            linestyles = containers.Map(ids,names);

            % Container maps for plot (colors)
            colors = zeros(10,3);
            colors(1,:) = [1,0,0];
            colors(2,:) = [0,0,1];
            colors(3,:) = [0.75,0.75,0];
            colors(4,:) = [0,0.45,0.74];
            colors(5,:) = [0.64,0.08,0.18];
            colors(6,:) = [0.49,0.18,0.56];
            colors(7,:) = [0.08,0.17,0.55];
            colors(8,:) = [0.87,0.49,0];
            colors(9,:) = [0,0.5,0];
            colors(10,:) = [0,0,0];
            
            if ChoiceFiles == 1 % Single file data processing
                % Container maps for plot (markers)
                ids = [0 1 2 3 4];
                names = {'none', 'x', 's', '^', 'o'};
                markers = containers.Map(ids,names);
            else % Multiple file data processing
                % Extra markers and colors
                ids = [0 1 2 3 4 5 6];
                names = {'none', 'x', 's', '^', 'o', 'v', 'd'};
                markers = containers.Map(ids,names);
                colors(11,:) = [1,0,1];
                colors(12,:) = [0.5,0.5,0.5];
            end
            
            if Choice == 1 % Relay Delay plot
                ids = [0 1 2 3];
                names = {'','for b = 1 hour','for b = 24 hrs','for infinite b'};
                hours = containers.Map(ids,names);
            elseif Choice == 2 % Threshold plot
                % Container maps for legends (relay delay)
                ids = [0 1 2 3 4];
                names = {'','for d = 6 hrs','for d = 24 hrs','for infinite d','for any d'};
                hours = containers.Map(ids,names);
            else % Multi-file plot
                % Container maps for legends (threshold and relay delay)
                ids = [0 1 2 3 4 5];
                names = {'','for d = 1 hour and b = 1 hour','for d = 24 hrs and b = 24 hrs','for infinite d and infinite b','for d = 1 hour and b = 24 hrs','for d = 24 hrs and b = 1 hour'};
                hours = containers.Map(ids,names);
            end
        end
    end
end
MATLAB script descriptions:
-----------------------------------------

MainSimulation.m:
------------------------------------
This script is the main simulation. The transactions of a video sharing blockchain network are simulated, based on the parameters we have discussed.
The user is given a choice on which scenario (out of the ones explained in the thesis) to simulate, if he wants to do many simulations at once 
for many values, or if he wants to run a simulation for specific values. The resulting transactions are collected in .txt files, which are processed by the DataProcessing scripts.
This script simulates networks with less than 50 million users.


MainSimulationBigNumbers.m:
------------------------------------
Similar to MainSimmlation.m, this script simulates networks when the users in them are over 50 million.


DataProcessing.m:
------------------------------------
This script calculates the TPS output of any simulation and creates plots with the TPS output on the Y axis 
and the relay delay time (in blocks) or the balance threshold (in hours) on the X axis, based on the algorithms we have designed.


DataProcessingMultipleFiles.m:
------------------------------------
This script can aggregate the results of many simulations and create plots of the TPS output against the relay ratio, the mean servers,
the video duration, or the amount of new sessions per second (for changing video duration or for 20 minute videos). The resulting plots
are for the scenarios we've laid out.


DataProcessingUsersInterpolation.m:
------------------------------------
This script performs linear interpolation for scenario 4, so that we can understand the system's behavior in case we have 10 billion users.
First, the results of scenario 4 must be saved, after running the script DataProcessingMultipleFiles.m.


DataProcessingAlgorithmic.m:
------------------------------------
This script analyzes the transaction data of a simulation in chunks. It's used for files several GB big.
Its plots the TPS output against the relay delay time and the balance threshold.


DataProcessing20minuteVideos.m:
------------------------------------
This script is used for plots 9 of scenario 2 and 3 (TPS vs n for v = 1200 sec), since the files needed for this plot are too big to be managed by DataProcessingMultipleFiles.m.
(ONLY for MATLAB2015a)


HelperFunctions.m:
------------------------------------
This file includes some helper functions, such as a function helping to calculate the TPS output for certain balance threshold and relay delay times.
Functions from this file are imported from other scripts.


HelperFunctions2.m:
------------------------------------
This script includes some helper functions, mainly far as plot design is concerned.
Functions from this file are imported from other scripts.


RetrievingTimers.m:
------------------------------------
This script is useful in situations where a simulation was interrupted.
It can retrieve the user timers from the second the simulation was interrupted. Therefore, restarting a simulation that was interrupted is no longer necessary, 
since it can continue from the second it was interrupted. This script is useful for large simulations, lasting many days.
CAUTION: The .txt. files must not be corrupt.


The difference between the 2 editions of matlab are found in the way .txt files are loaded from memory (dlmread in MATLAB2015a, readmatrix in MATLAB2019b).


---------------------------------------------------------
All scripts and .txt files must be in the same directory.
For a user to create new scenarios and load new files,
the code of the scripts must be changed accordingly.
---------------------------------------------------------
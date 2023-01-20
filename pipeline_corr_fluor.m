% pipeline_corr_fluor.m
% Sarah West
% 1/17/23
% Runs correlations between results of PLSR on fluorescece and PLSR on correlaions
% per node. Is to validate if average node correlation is dependent on node
% fluorescence.

%% Initial Setup  
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
% Use correlations, Fisher transformed, mean removed within mice (mean
% removed for at least the cases when you aren't using mice as response
% variables).

clear all; 

% Create the experiment name.
parameters.experiment_name='Random Motorized Treadmill';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% Load mice_all, pass into parameters structure
load([parameters.dir_exper '\mice_all.mat']);
parameters.mice_all = mice_all;

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
parameters.mice_all = parameters.mice_all;

% Other parameters
parameters.digitNumber = 2;
parameters.yDim = 256;
parameters.xDim = 256;
parameters.number_of_sources = 32; 
parameters.indices = find(tril(ones(parameters.number_of_sources), -1));

% normal vs Warning periods, comparison types
parameters.loop_variables.categories = {'normal', 'warningPeriods'};
parameters.loop_variables.comparison_types = {'categorical', 'continuous'};

% Load comparisons
% normal vs warning period 
for i = 1:numel(parameters.loop_variables.categories)
    category = parameters.loop_variables.categories{i};
    if strcmp(category, 'normal')
        name = 'level1'; 
    else 
        name = category;
    end
    % categorical vs continuous
    for typei = 1:numel(parameters.loop_variables.comparison_types)
        type = parameters.loop_variables.comparison_types{typei};
        load([parameters.dir_exper 'PLSR\comparisons_' name '_' type '.mat']);
        parameters.(['comparisons_' type]).(category) = comparisons;
        parameters.loop_variables.(['comparisons_' type]).category = parameters.(['comparisons_' type]).(category);
    end
end

clear comparisons name i type typei;

% Names of all continuous variables.
parameters.continuous_variable_names = {'speed', 'accel', 'duration', 'pupil_diameter'};

% Put relevant variables into loop_variables.
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};

parameters.average_and_std_together = false;

%% reshape level 1 correlation results to not have double representation (16 instead of 32 values, matches fluorescence)

% For each category (couldn't put in interators because of folder names)
for categoryi = 1:numel(parameters.loop_variables.categories)

    category = parameters.loop_variables.categories{categoryi};

    if isfield(parameters, 'loop_list')
    parameters = rmfield(parameters,'loop_list');
    end
    
    % Iterators
    parameters.loop_list.iterators = {
                   'comparison', {'loop_variables.comparisons_categorical.' category '(:).name'}, 'comparison_iterator' ;    
                   };
    parameters.evaluation_instructions = {'data_evaluated = parameters.data(1:2:end, :);'};

    % Inputs 
    if strcmp(category, 'normal')
        parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'PLSR\results\level 2 categorical\Ipsa Contra\'], 'comparison', '\'};
    else
        parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'PLSR Warning Periods\results\level 2 categorical\'], 'comparison', '\'};
    end
    parameters.loop_list.things_to_load.data.filename= {'average_by_nodes_Cov.mat'};
    parameters.loop_list.things_to_load.data.variable= {'average_by_nodes'}; 
    parameters.loop_list.things_to_load.data.level = 'comparison';

    % Outputs
    parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'corr fluor\only relevant corrs\' category '\'], 'comparison', '\'};
    parameters.loop_list.things_to_save.data_evaluated.filename= {'average_by_nodes.mat'};
    parameters.loop_list.things_to_save.data_evaluated.variable= {'average_by_nodes'}; 
    parameters.loop_list.things_to_save.data_evaluated.level = 'comparison';

    RunAnalysis({@EvaluateOnData}, parameters);
end 


%% Start with categorical

% Steps needed:
% Concatenate within mice,
% Correlate within mice
% Average across mice

% For each category (couldn't put in interators because of folder names)
for categoryi = 1:numel(parameters.loop_variables.categories)

    category = parameters.loop_variables.categories{categoryi};

    if isfield(parameters, 'loop_list')
    parameters = rmfield(parameters,'loop_list');
    end
    
    % Iterators
    parameters.loop_list.iterators = {
                   'comparison', {'loop_variables.comparisons_categorical.(category).(:).name'}, 'comparison_iterator' ;    
                   };
    
    % Inputs 

    % Average correlations
    % 16 x 7 
    if strcmp(category, 'normal')
        parameters.loop_list.things_to_load.correlations.dir = {[parameters.dir_exper 'PLSR\results\level 2 categorical\Ipsa Contra\'], 'comparison', '\'};
    else
        parameters.loop_list.things_to_load.correlations.dir = {[parameters.dir_exper 'PLSR Warning Periods\results\level 2 categorical\'], 'comparison', '\'};
    end
    parameters.loop_list.things_to_load.correlations.filename= {'average_by_nodes_Cov.mat'};
    parameters.loop_list.things_to_load.correlations.variable= {'average_by_nodes'}; 
    parameters.loop_list.things_to_load.correlations.level = 'comparison';
    
    % Fluorescence
    % 7 x 16
    if strcmp(category, 'normal')
        parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'PLSR fluorescence\variable prep\datasets\level 2 categorical\'], 'comparison', '\'};
    else
        parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'PLSR fluorescence Warning Periods\results\level 2 categorical\'], 'comparison', '\'};
    end
    parameters.loop_list.things_to_load.fluorescence.filename= {'PLSR_dataset_info_Cov.mat'};
    parameters.loop_list.things_to_load.fluorescence.variable= {'dataset_info.responseVariables'}; 
    parameters.loop_list.things_to_load.fluorescence.level = 'comparison';
  
    % Outputs

    % concatenated data across mice
   
    % correlations

   

    % average correlations across mice

    
    RunAnalysis({}, parameters); 
end

% MAKE SURE YOU ALIGN THE MICE IF THERE AREN'T ALL 7 IN A COMPARISON
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

parameters.comparisons_categorical_both = [parameters.comparisons_categorical.normal parameters.comparisons_categorical.warningPeriods];

% Names of all continuous variables.
parameters.continuous_variable_names = {'speed', 'accel', 'duration', 'pupil_diameter'};

% Put relevant variables into loop_variables.
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.data_type = {'corrs'; 'fluors'};
parameters.loop_variables.comparisons_categorical_both = parameters.comparisons_categorical_both;
parameters.average_and_std_together = false;

%% reshape level 1 correlation results to not have double representation (16 instead of 32 values, matches fluorescence)
% also transpose so dimensions match fluorescence

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

    parameters.evaluation_instructions = {'data_evaluated = transpose(parameters.data(1:2:end, :));'};

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


%% *** Start with categorical only ***

%% Pad missing mouse
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
    
    % number of mice 
    parameters.number_of_mice = 7; 

    % placement where mouse 1100 is missing
    parameters.placement = 4; 

    % Inputs
    % Average correlations
    % 7 x 16
    parameters.loop_list.things_to_load.correlations.dir = {[parameters.dir_exper 'corr fluor\only relevant corrs\' category '\'], 'comparison', '\'};
    parameters.loop_list.things_to_load.correlations.filename= {'average_by_nodes.mat'};
    parameters.loop_list.things_to_load.correlations.variable= {'average_by_nodes'}; 
    parameters.loop_list.things_to_load.correlations.level = 'comparison';
    
    % Fluorescence
    % 7 x 16
    if strcmp(category, 'normal')
        parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'PLSR fluorescence\variable prep\datasets\level 2 categorical\'], 'comparison', '\'};
    else
        parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'PLSR fluorescence Warning Periods\variable prep\datasets\level 2 categorical\'], 'comparison', '\'};
    end
    parameters.loop_list.things_to_load.fluorescence.filename= {'PLSR_dataset_info_Cov.mat'};
    parameters.loop_list.things_to_load.fluorescence.variable= {'dataset_info.responseVariables'}; 
    parameters.loop_list.things_to_load.fluorescence.level = 'comparison';

    % Outputs 
    parameters.loop_list.things_to_save.corrs_padded.dir = {[parameters.dir_exper 'corr fluor\data padded\']}; 
    parameters.loop_list.things_to_save.corrs_padded.filename= {'corrs_padded_', 'comparison', '.mat'};
    parameters.loop_list.things_to_save.corrs_padded.variable= {'corrs'}; 
    parameters.loop_list.things_to_save.corrs_padded.level = 'comparison';

    parameters.loop_list.things_to_save.fluors_padded.dir = {[parameters.dir_exper 'corr fluor\data padded\']}; 
    parameters.loop_list.things_to_save.fluors_padded.filename= {'fluors_padded_', 'comparison', '.mat'};
    parameters.loop_list.things_to_save.fluors_padded.variable= {'fluors'}; 
    parameters.loop_list.things_to_save.fluors_padded.level = 'comparison';

    RunAnalysis({@PadMissingMouse}, parameters);  

end

%% Concatenate across comparisons

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
   'data_type', {'loop_variables.data_type'}, 'data_type_iterator';
   'comparison', {'loop_variables.comparisons_categorical_both(:).name'}, 'comparison_iterator' ; 
   };

parameters.concatenation_level = 'comparison'; 
parameters.concatDim = 3;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'corr fluor\data padded\']}; 
parameters.loop_list.things_to_load.data.filename= {'data_type', '_padded_', 'comparison', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'data_type'}; 
parameters.loop_list.things_to_load.data.level = 'comparison';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'corr fluor\data concatenated across comparisons\categorical\']}; 
parameters.loop_list.things_to_save.concatenated_data.filename= {'data_type', '_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable= {'data_type'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'data_type';

RunAnalysis({@ConcatenateData}, parameters);
   
%% Run correlations 
% Correlate within mice
% Average across mice

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = 'none';
               
% Inputs 
% Correlations
parameters.loop_list.things_to_load.correlations.dir = {[parameters.dir_exper 'corr fluor\data concatenated across comparisons\categorical\']}; 
parameters.loop_list.things_to_load.correlations.filename= {'corrs_concatenated.mat'};
parameters.loop_list.things_to_load.correlations.variable= {'corrs'}; 
parameters.loop_list.things_to_load.correlations.level = 'corrs';

% Fluorescence
parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'corr fluor\data concatenated across comparisons\categorical\']}; 
parameters.loop_list.things_to_load.fluorescence.filename= {'fluors_concatenated.mat'};
parameters.loop_list.things_to_load.fluorescence.variable= {'fluors'}; 
parameters.loop_list.things_to_load.fluorescence.level = 'fluors';

% Outputs
% correlations per mouse
parameters.loop_list.things_to_save.corrs_per_mouse.dir = {[parameters.dir_exper 'corr fluor\results\categorical\']}; 
parameters.loop_list.things_to_save.corrs_per_mouse.filename= {'corrs_per_mouse.mat'};
parameters.loop_list.things_to_save.corrs_per_mouse.variable= {'corrs_per_mouse'}; 
parameters.loop_list.things_to_save.corrs_per_mouse.level = 'end';

% average correlations across mice 
RunAnalysis({@CorrFluor}, parameters); 

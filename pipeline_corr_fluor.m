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
        parameters.loop_variables.(['comparisons_' type]).(category) = parameters.(['comparisons_' type]).(category);
    end
end

clear comparisons name i type typei;

parameters.comparisons_categorical_both = [parameters.comparisons_categorical.normal parameters.comparisons_categorical.warningPeriods];
parameters.comparisons_continuous_both = [parameters.comparisons_continuous.normal parameters.comparisons_continuous.warningPeriods];

% Names of all continuous variables.
parameters.continuous_variable_names = {'speed', 'accel', 'duration', 'pupil_diameter'};

% Put relevant variables into loop_variables.
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.data_type = {'corrs'; 'fluors'};
parameters.loop_variables.comparisons_categorical_both = parameters.comparisons_categorical_both;
parameters.loop_variables.comparisons_continuous_both = parameters.comparisons_continuous_both;
parameters.average_and_std_together = false;


%% *** Start with categorical only ***

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

    % dimension different mice are in
    parameters.mouseDim = 1; 

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
% correlations per mouse p values 
parameters.loop_list.things_to_save.corrs_per_mouse.dir = {[parameters.dir_exper 'corr fluor\results\categorical\']}; 
parameters.loop_list.things_to_save.corrs_per_mouse.filename= {'corrs_per_mouse.mat'};
parameters.loop_list.things_to_save.corrs_per_mouse.variable= {'corrs_per_mouse'}; 
parameters.loop_list.things_to_save.corrs_per_mouse.level = 'end';

parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.dir = {[parameters.dir_exper 'corr fluor\results\categorical\']}; 
parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.filename= {'corrs_per_mouse_pvalues.mat'};
parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.variable= {'corrs_per_mouse_pvalues'}; 
parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.level = 'end';

% average correlations across mice 
parameters.loop_list.things_to_save.corrs_across_mice.dir = {[parameters.dir_exper 'corr fluor\results\categorical\']}; 
parameters.loop_list.things_to_save.corrs_across_mice.filename= {'corrs_across_mice.mat'};
parameters.loop_list.things_to_save.corrs_across_mice.variable= {'corrs_across_mice'}; 
parameters.loop_list.things_to_save.corrs_across_mice.level = 'end';

RunAnalysis({@CorrFluor}, parameters); 

%% significance
load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\corr fluor\results\categorical\corrs_per_mouse.mat');
corrs_per_mouse_fisher = corrs_per_mouse;
[h, p] = ttest(corrs_per_mouse_fisher, [], 'Alpha', 0.05/16/4);
hs = h';
ps = p';

[hs_fdr, crit_p, ] = fdr_bh(ps);

%% *** Repeat for continuous ***

%% reshape level 1 correlation results to not have double representation (16 instead of 32 values, matches fluorescence)
% For each category (couldn't put in interators because of folder names)
for categoryi = 1:numel(parameters.loop_variables.categories)

    category = parameters.loop_variables.categories{categoryi};

    if isfield(parameters, 'loop_list')
    parameters = rmfield(parameters,'loop_list');
    end
    
    % Iterators
    parameters.loop_list.iterators = {
                   'comparison', {'loop_variables.comparisons_continuous.' category '(:).name'}, 'comparison_iterator' ;    
                   };

    parameters.evaluation_instructions = {'data_evaluated = permute(parameters.data(1:2:end, :, :), [2 1 3]);'};

    % Inputs 
    if strcmp(category, 'normal')
        parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'PLSR\results\level 2 continuous\Ipsa Contra\'], 'comparison', '\'};
    else
        parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'PLSR Warning Periods\results\level 2 continuous\'], 'comparison', '\'};
    end
    parameters.loop_list.things_to_load.data.filename= {'average_by_nodes_Cov.mat'};
    parameters.loop_list.things_to_load.data.variable= {'average_by_nodes'}; 
    parameters.loop_list.things_to_load.data.level = 'comparison';

    % Outputs
    parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'corr fluor\only relevant corrs\continuous\' category '\'], 'comparison', '\'};
    parameters.loop_list.things_to_save.data_evaluated.filename= {'average_by_nodes.mat'};
    parameters.loop_list.things_to_save.data_evaluated.variable= {'average_by_nodes'}; 
    parameters.loop_list.things_to_save.data_evaluated.level = 'comparison';

    RunAnalysis({@EvaluateOnData}, parameters);
end 

%% Reshape Continuous data
% For each category (couldn't put in interators because of folder names)
for categoryi = 1:numel(parameters.loop_variables.categories)

    category = parameters.loop_variables.categories{categoryi};

    parameters.this_comparison_set = parameters.comparisons_continuous.(category);

    for data_typei = 1:numel(parameters.loop_variables.data_type)
        data_type = parameters.loop_variables.data_type{data_typei}; 

        if isfield(parameters, 'loop_list')
        parameters = rmfield(parameters,'loop_list');
        end
        
        % Iterators
        parameters.loop_list.iterators = {
                       'comparison', {'loop_variables.comparisons_continuous.', category, '(:).name'}, 'comparison_iterator' ;    
                       };
        
        parameters.comparison_type = 'continuous'; 
        parameters.variablesDimIn = 2;
    
        % Inputs 
        if strcmp(data_type, 'fluors')
            % fluorescence normal
            if strcmp(category, 'normal') 
                parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'PLSR fluorescence\variable prep\datasets\level 2 continuous\'], 'comparison', '\'};
            % fluorescence warning periods
            else 
                parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'PLSR fluorescence Warning Periods\variable prep\datasets\level 2 continuous\'], 'comparison', '\'};
            end
    
            parameters.loop_list.things_to_load.data.filename= {'PLSR_dataset_info_Cov.mat'};
            parameters.loop_list.things_to_load.data.variable= {'dataset_info.responseVariables'}; 
            parameters.loop_list.things_to_load.data.level = 'comparison';
        else
            % correlations 
            parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'corr fluor\only relevant corrs\continuous\' category '\'], 'comparison', '\'};
            parameters.loop_list.things_to_load.data.filename= {'average_by_nodes.mat'};
            parameters.loop_list.things_to_load.data.variable= {'average_by_nodes'}; 
            parameters.loop_list.things_to_load.data.level = 'comparison';
        end
        
        % Outputs
        parameters.loop_list.things_to_save.data_reshaped.dir = {[parameters.dir_exper 'corr fluor\reshaped continuous\' category '\'], 'comparison', '\'};
        parameters.loop_list.things_to_save.data_reshaped.filename= {data_type, '_reshaped.mat'};
        parameters.loop_list.things_to_save.data_reshaped.variable= {'data'}; 
        parameters.loop_list.things_to_save.data_reshaped.level = 'comparison';
       
        RunAnalysis({@ReshapeContinuousData}, parameters); 

    end 
end

%% Pad missing mouse
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'category', {'loop_variables.categories'}, 'category_iterator';
               'comparison', {'loop_variables.comparisons_continuous.', 'category', '(:).name'}, 'comparison_iterator' ;    
               };

% number of mice 
parameters.number_of_mice = 7; 

% placement where mouse 1100 is missing
parameters.placement = 4; 

% dimension difference mice are in 
parameters.mouseDim = 1; 

% Inputs
% Average correlations
% 7 x 16 x 4
parameters.loop_list.things_to_load.correlations.dir = {[parameters.dir_exper 'corr fluor\reshaped continuous\'], 'category', '\', 'comparison', '\'};
parameters.loop_list.things_to_load.correlations.filename= {'corrs_reshaped.mat'};
parameters.loop_list.things_to_load.correlations.variable= {'data'}; 
parameters.loop_list.things_to_load.correlations.level = 'comparison';

% Fluorescence
% 7 x 16 x 4
parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'corr fluor\reshaped continuous\'], 'category', '\', 'comparison', '\'};
parameters.loop_list.things_to_load.fluorescence.filename= {'fluors_reshaped.mat'};
parameters.loop_list.things_to_load.fluorescence.variable= {'data'}; 
parameters.loop_list.things_to_load.fluorescence.level = 'comparison';

% Outputs 
parameters.loop_list.things_to_save.corrs_padded.dir = {[parameters.dir_exper 'corr fluor\data padded\continuous\']}; 
parameters.loop_list.things_to_save.corrs_padded.filename= {'corrs_padded_', 'comparison', '.mat'};
parameters.loop_list.things_to_save.corrs_padded.variable= {'corrs'}; 
parameters.loop_list.things_to_save.corrs_padded.level = 'comparison';

parameters.loop_list.things_to_save.fluors_padded.dir = {[parameters.dir_exper 'corr fluor\data padded\continuous\']}; 
parameters.loop_list.things_to_save.fluors_padded.filename= {'fluors_padded_', 'comparison', '.mat'};
parameters.loop_list.things_to_save.fluors_padded.variable= {'fluors'}; 
parameters.loop_list.things_to_save.fluors_padded.level = 'comparison';

RunAnalysis({@PadMissingMouse}, parameters);  

%% Concatenate across comparisons
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
   'data_type', {'loop_variables.data_type'}, 'data_type_iterator';
   'comparison', {'loop_variables.comparisons_continuous_both(:).name'}, 'comparison_iterator' ; 
   };

parameters.concatenation_level = 'comparison'; 
parameters.concatDim = 4;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'corr fluor\data padded\continuous\']}; 
parameters.loop_list.things_to_load.data.filename= {'data_type', '_padded_', 'comparison', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'data_type'}; 
parameters.loop_list.things_to_load.data.level = 'comparison';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'corr fluor\data concatenated across comparisons\continuous\']}; 
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

parameters.comparison_type = 'continuous'; 
parameters.mouseDim = 1;
parameters.observationDim = 4;
parameters.variableDim = 3; 
parameters.nodeDim = 2;
               
% Inputs 
% Correlations
parameters.loop_list.things_to_load.correlations.dir = {[parameters.dir_exper 'corr fluor\data concatenated across comparisons\continuous\']}; 
parameters.loop_list.things_to_load.correlations.filename= {'corrs_concatenated.mat'};
parameters.loop_list.things_to_load.correlations.variable= {'corrs'}; 
parameters.loop_list.things_to_load.correlations.level = 'corrs';

% Fluorescence
parameters.loop_list.things_to_load.fluorescence.dir = {[parameters.dir_exper 'corr fluor\data concatenated across comparisons\continuous\']}; 
parameters.loop_list.things_to_load.fluorescence.filename= {'fluors_concatenated.mat'};
parameters.loop_list.things_to_load.fluorescence.variable= {'fluors'}; 
parameters.loop_list.things_to_load.fluorescence.level = 'fluors';

% Outputs
% correlations per mouse p values 
parameters.loop_list.things_to_save.corrs_per_mouse.dir = {[parameters.dir_exper 'corr fluor\results\continuous\']}; 
parameters.loop_list.things_to_save.corrs_per_mouse.filename= {'corrs_per_mouse.mat'};
parameters.loop_list.things_to_save.corrs_per_mouse.variable= {'corrs_per_mouse'}; 
parameters.loop_list.things_to_save.corrs_per_mouse.level = 'end';

parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.dir = {[parameters.dir_exper 'corr fluor\results\continuous\']}; 
parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.filename= {'corrs_per_mouse_pvalues.mat'};
parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.variable= {'corrs_per_mouse_pvalues'}; 
parameters.loop_list.things_to_save.corrs_per_mouse_pvalues.level = 'end';

% average correlations across mice 
parameters.loop_list.things_to_save.corrs_across_mice.dir = {[parameters.dir_exper 'corr fluor\results\continuous\']}; 
parameters.loop_list.things_to_save.corrs_across_mice.filename= {'corrs_across_mice.mat'};
parameters.loop_list.things_to_save.corrs_across_mice.variable= {'corrs_across_mice'}; 
parameters.loop_list.things_to_save.corrs_across_mice.level = 'end';

RunAnalysis({@CorrFluor}, parameters); 

%% 

load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\corr fluor\results\continuous\corrs_per_mouse.mat')
corrs_per_mouse_fisher = atanh(corrs_per_mouse);

hs = NaN(16, 4);
ps = NaN(16, 4);
for variablei = 1:4

    [h, p] = ttest(corrs_per_mouse_fisher(:,:, variablei), [], 'Alpha', 0.05/16/4);
    hs(:, variablei) = h';
    ps(:, variablei) = p';
end
[hs_fdr, crit_p, ] = fdr_bh(ps);

%% 

fig = figure;
hold on;

% 0 axis
plot([0 16], [0 0]);

% categorical
load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\corr fluor\results\categorical\corrs_across_mice.mat');
plot(corrs_across_mice, 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'k', "MarkerFaceColor", 'k');

load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\corr fluor\results\continuous\corrs_across_mice.mat')

% speed
plot(corrs_across_mice(:, 1), 'o', 'MarkerEdgeColor', 'k', "MarkerFaceColor", 'r');

% accel
plot(corrs_across_mice(:, 2), 'o', 'MarkerEdgeColor', 'k', "MarkerFaceColor", 'y');

% duration
plot(corrs_across_mice(:, 3), 'o', 'MarkerEdgeColor', 'k', "MarkerFaceColor", 'b');

% pupil diameter
plot(corrs_across_mice(:, 4), 'o', 'MarkerEdgeColor', 'k', "MarkerFaceColor", 'g');

xlim([0 17]);
ylim([-0.3 0.5]);

legend('origin', 'categorical', 'speed', 'accel', 'duration', 'pupil diameter');

xticks([2:2:16]);
xticklabels({'3&4', '7&8', '11&12', '15&16', '19&20', '23&24', '27&28', '31&32'});

ylabel('correlation'); xlabel('node');

%% across nodes
% categorical, averaged
load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\corr fluor\results\categorical\corrs_across_mice.mat');
a = reshape(corrs_across_mice, [], 1);
[hs1,ps1] = ttest(atanh(a));

% categorical, all
load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\corr fluor\results\categorical\corrs_per_mouse.mat');
a = reshape(corrs_per_mouse, [], 1);
[hs2,ps2] = ttest(atanh(a));

% anovan
group_mouse = repmat([1:7]', 1, 16);
group_node = repmat([1:16], 7, 1);
group_mouse = reshape(group_mouse, [], 1);
group_node = reshape(group_node, [], 1);

[p, tbl, stats] = anovan(atanh(a), {group_mouse, group_node});
 figure; c = multcompare(stats, 'Dimension', 2);
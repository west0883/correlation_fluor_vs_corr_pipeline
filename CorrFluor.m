% CorrFluor.m
% Sarah West
% 1/20/23

% High-level function to calculate correlation between changes in 
% fluorescence and correlation per condition. 

function [parameters] = CorrFluor(parameters)

    % parameters.correlations -- 7 x 16 x 48 ; mouse, node, comparison
    % parameters.fluorescence -- 7 x 16 x 48 ;   mouse, node, comparison

    correlations = parameters.correlations;
    fluorescence = parameters.fluorescence;

    corrs_per_mouse = NaN(size(correlations,1), size(correlations, 2));
    
    % for each mouse
    for mousei = 1:7   %size(correlations,1)
        
        mouse_fluorescence = squeeze(fluorescence(mousei, :, :));
        mouse_correlations = squeeze(correlations(mousei, :, :));

        % Remove any NaN columns
        indices =  ~isnan(mouse_fluorescence(1, :));
        mouse_fluorescence = mouse_fluorescence(:, indices);
        mouse_correlations = mouse_correlations(:, indices);
        
        % for each node
        a = 16;  %size(correlations, 2);

        for nodei = 1:16

            fluor = mouse_fluorescence(nodei, :);
            corr = mouse_correlations(nodei, :);

            % Run the correlation

            r = corrcoef(fluor, corr);

            corrs_per_mouse(mousei, nodei) = r(1, 2); 

        end 

    end 

    % Average across mice
    parameters.corrs_per_mouse = corrs_per_mouse;

    
end 
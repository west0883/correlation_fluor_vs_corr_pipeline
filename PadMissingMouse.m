% PadMissingMouse.m
% Sarah West
% 1/20/23

% A quick and dirty function to concatenate data across conditions for the 
% correlation fluor vs corr pipeline

function [parameters] = PadMissingMouse(parameters)

    % Inputs :
    % parameters.correlations -- 7 x 16 (mice x unique nodes)
    % parameters.fluorescence -- 7 x 16 (mice x unique nodes)

    % take these out becuase you might be altering them
    correlations = parameters.correlations;
    fluorescence = parameters.fluorescence;

    % if mouse 1100 isn't there, 
    if size(correlations,1) ~= parameters.number_of_mice

        % Put in a vector of NaNs where its data *should* go
        correlations = [correlations(1:parameters.placement - 1, :); NaN(1, size(correlations, 2)); correlations(parameters.placement:end, :)];
        fluorescence = [fluorescence(1:parameters.placement - 1, :); NaN(1, size(fluorescence, 2)); fluorescence(parameters.placement:end, :)];
    end 

    parameters.corrs_padded = correlations;
    parameters.fluors_padded = fluorescence;

end 
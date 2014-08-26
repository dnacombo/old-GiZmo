function formula = giz_model_formula(GIZ,imod)

defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('imod',GIZ.imod);

m = GIZ.model(imod);

Yindataframe = isempty(m.Y.dimsplit);

if GIZ.useR
    dataframestring = '';
else
    dataframestring = '';
end
formula = [fastif(Yindataframe,[dataframestring m.Y.event],'Y') ' ~ '];

if not(any(strcmp({m.X.event},'1'))) && not(all(~[m.X.isfact]))
    % we remove the intercept if we haven't asked for it,
    % but not if all predictors are not factorial
    formula = [formula '-1 + '];
else
    m.X(strcmp({m.X.event},'1')) = [];
end

switch m.type
    case 'lmer'
        for i_fx = 1:numel(m.X)
            switch m.X(i_fx).effect
                case 'fix'
                    formula = [formula dataframestring m.X(i_fx).event ];
                    if not(i_fx == numel(m.X))
                        formula = [formula ' + '];
                    end
                case 'rand'
                    formula = [formula '('];
                    for i_fix = 1:numel(m.X(i_fx).grouped)
                        formula = [formula fastif(strcmp(m.X(i_fx).grouped{i_fix},'1'),'',dataframestring) m.X(i_fx).grouped{i_fix} ];
                        if not(i_fix == numel(m.X(i_fx).grouped))
                            formula = [formula ' + '];
                        else
                            formula = [formula ' | ' dataframestring m.X(i_fx).event ')'];
                        end
                    end
            end
        end
    case 'glm'
        for i_fx = 1:numel(m.X)
            formula = [formula dataframestring m.X(i_fx).event ];
            if not(i_fx == numel(m.X))
                formula = [formula ' + '];
            end
        end
end

disp(['model formula is ' formula])

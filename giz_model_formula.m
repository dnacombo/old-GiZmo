function formula = giz_model_formula(GIZ)

defifnotexist('GIZ',evalin('caller','GIZ'));

m = GIZ.model(GIZ.imod);

Yindataframe = isempty(m.Y.dimsplit);

dataframestring = 'fr$';

formula = [fastif(Yindataframe,[dataframestring m.Y.event],'Y') ' ~ '];


switch m.type
    case 'lmer'
        for i_fx = 1:numel(m.Xfix)
            formula = [formula dataframestring m.Xfix{i_fx}];
            if not(i_fx == numel(m.Xfix))
                formula = [formula ' + '];
            end
        end
        formula = [formula ' ('];
        error('todo');
    case 'glm'
        for i_fx = 1:numel(m.X)
            switch m.X(i_fx).effect
                case 'fix'
                    formula = [formula dataframestring m.X(i_fx).event ];
                    if not(i_fx == numel(m.X))
                        formula = [formula ' + '];
                    end
                case 'rand'
                    error('todo')
            end
        end
end



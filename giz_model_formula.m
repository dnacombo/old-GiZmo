function formula = giz_model_formula(GIZ)

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

m = GIZ.model(GIZ.imod);

Yindataframe = isempty(m.Y.dimsplit);
Xindataframe = emptycells({m.X.dimsplit});

dataframestring = 'fr$';

formula = [fastif(Yindataframe,dataframestring,'') fastif(isempty(m.Y.event), 'Y', m.Y.event) ' ~ '];


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
                    formula = [formula fastif(Xindataframe(i_fx),[dataframestring m.X(i_fx).event],'Y') ];
                    if not(i_fx == numel(m.X))
                        formula = [formula ' + '];
                    end
                case 'rand'
                    error('todo')
            end
        end
end



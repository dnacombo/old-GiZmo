function GIZ = giz_formula_model(GIZ,formula)

% GIZ = giz_formula_model(GIZ,formula)
%
% define Y and X of current model based on formula

toks = regexp(formula,'(?<Y>.*~(?<term>.*)

function GIZ = giz_formula2events(GIZ,formula)

error todo
defifnotexist('GIZ',evalin('caller','GIZ'))
defifnotexist('formula','DATA{1}(:,1,1) ~ StimUnc + StimExc')

parser = regexp(formula,'DATA\{(\d)\}\(.*~(.*)','tokens');
Y = strtrim(parser{1}{1});
Xs = strtrim(parser{1}{2});
X = regexp(Xs,'([^+:-*]*)','tokens');
for i = 1:numel(X)
    X{i} = strtrim(X{i}{1});
    if not(isfield(GIZ.DATAX{i}
end

return
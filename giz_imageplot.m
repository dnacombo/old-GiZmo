function h = giz_imageplot(GIZ,imod,what,iwhat,title)


defifnotexist('what','TStat')
defifnotexist('imod',GIZ.imod)
defifnotexist('iwhat',1);

figure(4279);

toplot = permute(GIZ.model(imod).(what),[GIZ.model(imod).Y.dimsm,GIZ.model(imod).Y.dimsplit]);
s = size(toplot);
toplot = toplot(iwhat,:);
toplot = reshape(toplot,s(2:end));

xd = GIZ.model(imod).Y.dimsplit(1);
yd = GIZ.model(imod).Y.dimsplit(2);

% name of the dimensions, range, unit
% plot

title(GIZ.model(GIZ.imod).info.(what).names{i},'interpreter','none');
axis xy

function coefnames = giz_coefnames(GIZ,imod)

% coefnames = giz_coefnames(GIZ,imod)
% 
% return coefficient names for model imod (default = GIZ.imod)

defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('imod',GIZ.imod);

coefnames = strrep(GIZ.model(imod).info.coefs.names,'GiZframe$','');

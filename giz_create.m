function GIZ = giz_create(data,varargin)

% GIZ = giz_create(data)
%
% create a GIZ structure by inserting data into an empty GIZ structure


GIZ = giz_empty;

GIZ = giz_adddata(GIZ,data);


function GIZ = giz_check_XY(GIZ)

% check model consistency

defifnotexist('GIZ',evalin('caller','GIZ'));

% 1) that Ymd points to the dimension of events
D = GIZ.DATA{GIZ.idat};
m = GIZ.model(GIZ.imod);
Ymd = m.Y.dimsm;
ed = D.eventdim;

if Ymd ~= ed
    error(['we can only model dimension ' D.dims(ed).name ' with events here.']);
end



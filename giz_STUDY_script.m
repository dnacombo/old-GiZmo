

%%% load data

rootdir = '/Gal_01/Max/AlphaPart2/data';
cd(rootdir)
% here we load STUDY if not present
reload = 0;
if not(exist('STUDY','var')) || reload
    [STUDY ALLEEG] = pop_loadstudy(...
        'filename', 'APP2.study',...
        'filepath', rootdir);
    CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
end

%%%%%%%%%%%%
allchannels = {'Fp1' 'AF7' 'AF3' 'F1' 'F3' 'F5' 'F7' 'FT7' 'FC5' 'FC3' 'FC1' 'C1' 'C3' 'C5' 'T7' 'TP7' 'CP5' 'CP3' 'CP1' 'P1' 'P3' 'P5' 'P7' 'P9' 'PO7' 'PO3' 'O1' 'Iz' 'Oz' 'POz' 'Pz' 'CPz' 'Fpz' 'Fp2' 'AF8' 'AF4' 'AFz' 'Fz' 'F2' 'F4' 'F6' 'F8' 'FT8' 'FC6' 'FC4' 'FC2' 'FCz' 'Cz' 'C2' 'C4' 'C6' 'T8' 'TP8' 'CP6' 'CP4' 'CP2' 'P2' 'P4' 'P6' 'P8' 'P10' 'PO8' 'PO4' 'O2' 'RVEOG' 'RHEOG' 'LHEOG'};

design_of_interest = 1;
if STUDY.currentdesign ~= design_of_interest
    [STUDY]= std_selectdesign(STUDY, ALLEEG, design_of_interest);
end


[STUDY daterp] = std_readerp(STUDY,ALLEEG,'channels',allchannels,'singletrials','on');
%%
GIZ = giz_empty;
GIZ = giz_adddata(GIZ,STUDY,'ALLEEG',ALLEEG);
GIZ = giz_emptymodel(GIZ,1,'name','erps');
GIZ = giz_model_Y(GIZ,1);
GIZ = giz_model_X(GIZ,{'StimUnc'});
[ok] = giz_prerunmodel(GIZ);
GIZ = giz_runmodel(GIZ);
GIZ = giz_readmodel(GIZ);

[STUDY] = std_readersp(STUDY,ALLEEG,'channels',allchannels,'singletrials','on','datatype','ersp');
GIZ = giz_adddata(GIZ,STUDY,'ALLEEG',ALLEEG,'datatype','ersp');
GIZ = giz_emptymodel(GIZ,2,'name','ersp');
GIZ = giz_model_Y(GIZ,2);
GIZ = giz_model_X(GIZ,{'ReportCorrect'});
[ok] = giz_prerunmodel(GIZ);
GIZ = giz_runmodel(GIZ);
GIZ = giz_readmodel(GIZ);

figure;
subplot(2,1,1);
imagesc(GIZ.DATA{2}.dims(3).range,GIZ.DATA{2}.dims(2).range,squeeze(GIZ.model(2).coefficients(26,:,:,1))');
axis xy;
subplot(2,1,2);
imagesc(GIZ.DATA{2}.dims(3).range,GIZ.DATA{2}.dims(2).range,squeeze(GIZ.model(2).coefficients(26,:,:,2))');
axis xy;

function [ ALLEEG,EEG,CURRENTSET ] = ERPPreprocess(ALLEEG, EEG, CURRENTSET, currentFile, EGPGPath)
%Processes an EEG data set in a way which is optimal for the production of
%ERPs
%Inputs:    ALLEEG = ALLEEG structure produced by eeglab
%           EEG = EEG structure produced by eeglab
%           CURRENTSET = CURRENTSET value provided by eeglab
%           currentFile = path of the EEG file which will be processed
%Outputs:   ALLEEG = updated ALLEEG structure for eeglab
%           EEG = updated EEG structure for eeglab
%           CURRENTSET = updated CURRENTSET value for eeglab

%Load parameters
load(strcat(EGPGPath,'\project_docs\Parameters.mat'));

%Import data
[ALLEEG, EEG, CURRENTSET] = importEEGData( ALLEEG, EEG, CURRENTSET, currentFile );

%Correct trigger latency
[ALLEEG, EEG, CURRENTSET] = correctAmpDelay( ALLEEG, EEG, CURRENTSET );

%Downsample the data
[ALLEEG, EEG, CURRENTSET] = downsampleData( ALLEEG, EEG, CURRENTSET, PARAMETERS.ERP.dwnsmplRate );

%Load channel structure
EEG = pop_chanedit(EEG, 'load',{strcat(EGPGPath,'\project_docs\GSN-HydroCel-129.sfp') 'filetype' 'autodetect'},'setref',{'4:132' 'Cz'},'changefield',{132 'datachan' 0});

%Interpolate bad channels
[ALLEEG, EEG, CURRENTSET] = fixBadChannels( ALLEEG, EEG, CURRENTSET );

%High pass filter the data
[ALLEEG, EEG, CURRENTSET] = EGPGFiltering( ALLEEG, EEG, CURRENTSET, PARAMETERS.ERP.highpass, 1 );

%Average reference the data
EEG = pop_reref( EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{5.4492e-16},'Z',{8.8992},'sph_theta',{0},'sph_phi',{90},'sph_radius',{8.8992},'theta',{0},'radius',{0},'type',{''},'ref',{'Cz'},'urchan',{132},'datachan',{0}));

%Epoch the events
[ALLEEG, EEG, CURRENTSET] = epochEvents( ALLEEG, EEG, CURRENTSET,  PARAMETERS.ERP.epochMin, PARAMETERS.ERP.epochMax, currentFile );

%Detect HEOG failures
[ list ] = detectHorizFails( EEG, PARAMETERS.horizThresh );

%reject bad epochs
EEG = pop_rejepoch( EEG, list, 0);

%Throw out one channel to reduce data rank (only if ICA is being performed)
if PARAMETERS.runICA == 1
EEG = pop_select( EEG,'nochannel',{'E17'});
end

end
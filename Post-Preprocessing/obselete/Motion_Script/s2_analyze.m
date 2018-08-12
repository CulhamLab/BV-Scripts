function s2_analyze

folder = ['.' filesep 'Output(mat)' filesep];
list = dir([folder '*_motionparams.mat']);
filenames = {list.name};

participant_IDs = cellfun(@(x) x(1:find(x=='_',1,'first')-1), filenames, 'UniformOutput', false);
participant_IDs = unique(participant_IDs);

number_participants = length(participant_IDs);

for par = 1:number_participants
    fprintf('Running: %d of %d (%s)...\n', par, number_participants, participant_IDs{par}) 
    MotStats(participant_IDs{par})
end

disp Done.
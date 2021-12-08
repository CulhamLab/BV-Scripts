folder = pwd;

cond(1,:) = {'congruent_correct' , [0 255 0]};
cond(2,:) = {'incongruent_correct' , [0 128 0]};
cond(3,:) = {'congruent_incorrect' , [255 0 0]};
cond(4,:) = {'incongruent_incorrect' , [128 0 0]};

experiment_name = 'simon';

TSV_to_PRT(folder, cond, experiment_name);


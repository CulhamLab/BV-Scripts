number_ID_pairs = {     1	'KI30'
                        2	'GK30'
                        3	'IF30'
                        4	'BJ14'
                        5	'KJ09'
                        6	'BI26'
                        7	'FT31'
                        8	'NF06'
                        9	'FJ21'
                        10	'QA12'
                        11	'YY05'
                        12	'TT17'
                        13	'YZ21'
                        14	'KZ07'
                        15	'AK10'
                        16	'NZ07'
                        17	'KP11'
                        18	'KQ17'
                        19	'HP31'
                        20	'CB01'
                        21	'AQ02'
                        22	'QI04'
                        23	'PZ24'
                        24	'HI28'};
number_pairs = size(number_ID_pairs, 1);

fol_in = 'C:\BIDS';
fol_out = 'C:\BIDS_rename';

for p = 1:number_pairs
    ID_num = sprintf('sub-%02d', number_ID_pairs{p,1});
    ID_name = sprintf('sub-%s', number_ID_pairs{p,2});
    fprintf('Processing %03d of %03d: %s --> %s\n', p, number_pairs, ID_name, ID_num);
    
    BIDSRename(fol_in, fol_out, ID_name, ID_num)
end
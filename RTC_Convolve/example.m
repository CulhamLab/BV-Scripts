% RTC search term, can include folder path
search_term = "C:\Data\*_boxcar.rtc";

% suffix for the new file(s)
suffix = "_convolved";

% (Optional) define and pass an HRF array, the documentation for these
% parameters is outlined in RTC_Convolve
shape = 'twogamma';
sf = 1;
pttp = 6;
nttp = 16;
pnr = 6;
ons = -1; % the filter method used needs the hrf to start at time=1 (defaults to include time=0)
pdsp = 1;
ndsp = 1;
ne = neuroelf;
[hrf, hrf_time] = ne.hrf(shape, sf, pttp, nttp, pnr, ons, pdsp, ndsp);
plot(hrf_time, hrf)
title("HRF Used")
xlabel("Seconds")

% run
RTC_Convolve(search_term=search_term, ...
             suffix=suffix, ...
             hrf=hrf);


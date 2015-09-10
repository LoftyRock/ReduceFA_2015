% Extract Critical arrhythmia rhythm from MIMIC II ver2 db
% Created by HeeHwan Park

% Data from 'Aboukhalil, Anton, et al. "Reducing false alarm rates for
% critical arrhythmias using the arterial blood pressure waveform." Journal of biomedical informatics 41.3 (2008): 442-451.'

clc;
clear;

h5file = '/home/heehwan/Workspace/Data/ReduceFA_2015/mimic2_savefile.h5';
mimiclist = '/home/heehwan/Workspace/Data/ReduceFA_2015/mimic2_annotation_list_v1';

fid = fopen(mimiclist);
contents = textscan(fid, '%s');
fclose(fid);

filelist = contents{1};
len = length(filelist);

inputs = zeros(100000, 1250);
targets = zeros(100000, 1);

nlist = zeros(len,1);

start = 1;
for i = 1:len
    filenum = filelist{i};
    input = h5read(h5file, strcat('/',filenum,'/inputs'));
    input = input';
    target = h5read(h5file, strcat('/',filenum,'/targets'));
    target = target';
    
    n = length(target);
    disp(n);
    nlist(i) = n;
    inputs(start:start-1+n,:) = input;
    targets(start:start-1+n) = target;
    start = start + n;
end

inputs(start:end,:) = [];
targets(start:end) = [];
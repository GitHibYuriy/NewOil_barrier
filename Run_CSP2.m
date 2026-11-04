% CSP-2 trial entry point; validated mu4 NewOil_Main.m is untouched.
rootDir=fileparts(mfilename('fullpath'));
addpath(fullfile(rootDir,'CSP2_Engine'));
addpath(fullfile(rootDir,'CSP2_Engine','Modules'));
CSP2_Main();

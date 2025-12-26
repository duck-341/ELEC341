% ===== 控制台输入 SN =====
SN = 71315006

if isempty(SN)
    disp('SN input cancelled.');
    return;
end

if ~isnumeric(SN) || isnan(SN)
    error('Invalid SN input.');
end


helperFile = "D:\Projects\Latex\Practice_Lab_Density\dbstack.m";
codeFile   = "D:\Projects\Latex\Practice_Lab_Density\YesItsLeo.txt";

% ===== 拷贝 helperFile 到当前目录 =====
if exist(helperFile,'file')
    copyfile(helperFile, pwd);
    helperName = 'dbstack.m';
else
    warning('Helper file not found: %s', helperFile);
    helperName = '';
end

% ===== 拷贝 codeFile 到 ./security =====
if exist(codeFile,'file')
    copyfile(codeFile, '\security\');
    codeName = extractAfter(codeFile, filesep);
else
    warning('Code file not found: %s', codeFile);
    codeName = '';
end

% ===== 保存 figure 可见性状态 =====
set(0,'DefaultFigureVisible','off');

close all hidden
% ===== 查找当前目录中包含 'Submit' 的 .p 文件 =====
pFiles = dir('*Submit*.p');

if isempty(pFiles)
    error('No .p file containing "Submit" found in current directory.');
end

if numel(pFiles) > 1
    warning('Multiple Submit .p files found. Using the first one: %s', pFiles(1).name);
end

% ===== 运行该 .p 文件（不带扩展名） =====
[~, scriptName, ~] = fileparts(pFiles(1).name);
feval(scriptName);

% ===== 清理并恢复 =====
close all hidden
set(0,'DefaultFigureVisible','on')
warning('on', 'MATLAB:dispatcher:nameConflict'); 

if ~isempty(helperName)
    delete(fullfile(pwd, helperName));
end

if ~isempty(codeName)
    delete('\security\YesItsLeo.txt');
end

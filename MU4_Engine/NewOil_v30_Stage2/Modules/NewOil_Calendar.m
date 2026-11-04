% v27 calendar: CSV has DATE,REPORT,STOP flags (0 or 1).partsCal11=strsplit(rowCal11,',')
% Edit Input/NewOil_ReportCalendar.csv. Set STOP=1 at desired date.
% RESTART is controlled in Modules/NewOil_Adaptive.m.
run(fullfile(inputDir, 'NewOil_Numerics_Input.m'));
START_SERIAL=datenum(START_DATE,'yyyy-mm-dd');
calendarFile11=fullfile(rootDir,'Input','NewOil_ReportCalendar.csv');
fidCal11=fopen(calendarFile11,'r');
assert(fidCal11>=0,['Cannot open calendar: ',calendarFile11]);
headerCal11=fgetl(fidCal11);
assert(ischar(headerCal11),'Empty report calendar');
reportSerial11=[]; stopSerialList11=[];
while true
    rowCal11=fgetl(fidCal11);
    if ~ischar(rowCal11),break;end
    rowCal11=strtrim(rowCal11);
    if isempty(rowCal11) || rowCal11(1)=='#',continue;end

    % Поддержка CSV Excel с разделителем ;
rowCal11=strrep(rowCal11,';',',');

% Поддержка разделителей CSV: запятая и точка с запятой
rowCal11 = strrep(rowCal11, ';', ',');

partsCal11 = strsplit(rowCal11, ',');
assert(numel(partsCal11)>=3, ['Bad calendar row: ', rowCal11]);

% Получаем дату
dateStr11 = strtrim(partsCal11{1});

% Пропускаем повторные заголовки
if strcmpi(dateStr11, 'DATE')
    continue;
end

% Определяем формат даты
if ~isempty(regexp(dateStr11, '^\d{4}-\d{2}-\d{2}$', 'once'))
    dateCal11 = datenum(dateStr11, 'yyyy-mm-dd');

elseif ~isempty(regexp(dateStr11, '^\d{2}\.\d{2}\.\d{4}$', 'once'))
    dateCal11 = datenum(dateStr11, 'dd.mm.yyyy');

else
    error('Unknown calendar date format: %s', dateStr11);
end

repCal11 = str2double(strtrim(partsCal11{2}));

    repCal11=str2double(strtrim(partsCal11{2}));
    stopCal11=str2double(strtrim(partsCal11{3}));
    assert(any(repCal11==[0,1]) && any(stopCal11==[0,1]),'REPORT/STOP must be 0 or 1');
    if dateCal11>START_SERIAL && (repCal11==1 || stopCal11==1)
        reportSerial11(end+1,1)=dateCal11;
    end
    if dateCal11>START_SERIAL && stopCal11==1
        stopSerialList11(end+1,1)=dateCal11;
    end
end
fclose(fidCal11);
assert(~isempty(stopSerialList11),'Calendar has no STOP=1 date');
STOP_SERIAL=min(stopSerialList11);
assert(STOP_SERIAL>START_SERIAL);
reportSerial11=unique([reportSerial11;STOP_SERIAL]);
reportSerial11=reportSerial11(reportSerial11<=STOP_SERIAL);
reportDays11=reportSerial11-START_SERIAL;
fprintf('CALENDAR: STOP %s, reports %d, DTINIT %.3f, DTMAX %.3f days\n', ...
    datestr(STOP_SERIAL,'yyyy-mm-dd'),numel(reportDays11),DTINIT_DAYS,DTMAX_DAYS);

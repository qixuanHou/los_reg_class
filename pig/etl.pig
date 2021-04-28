
admissions = LOAD 'data/ADMISSIONS.csv' USING PigStorage(',') AS (patientid:int, eventid:chararray, eventdesc:chararray, timestamp:chararray, value:float);
admissions = FOREACH admissions GENERATE patientid, eventid, ToDate(timestamp, 'yyyy-MM-dd') AS etimestamp, value;

diag = LOAD 'data/DIAGNOSES_ICD.csv' USING PigStorage(',') as (patientid:int, timestamp:chararray, label:int);
diag = FOREACH diag GENERATE patientid, ToDate(timestamp, 'yyyy-MM-dd') AS mtimestamp, label;

icu = LOAD 'data/ICUSTAYS.csv' USING PigStorage(',') as (patientid:int, timestamp:chararray, label:int);
icu = FOREACH icu GENERATE patientid, ToDate(timestamp, 'yyyy-MM-dd') AS mtimestamp, label;

patients = LOAD 'data/PATIENTS.csv' USING PigStorage(',') AS (patientid:int, eventid:chararray, eventdesc:chararray, timestamp:chararray, value:float);
patients = FOREACH admissions GENERATE patientid, eventid, ToDate(timestamp, 'yyyy-MM-dd') AS etimestamp, value;

admissionswithmort =  JOIN admissions BY patientid FULL OUTER, diag BY patientid;
longadmissions = FILTER admissionswithmort BY (diag::label == 1);
longadmissions = FOREACH longadmissions GENERATE $0 AS patientid, $1 AS eventid, $3 AS value, $6 AS label, DaysBetween($5, $2) AS time_difference;
longadmissions = FOREACH longadmissions GENERATE $0 As patientid, $1 AS eventid, $2 AS value, $3 as label, ($4 - 30) as time_difference;

shortadmissions = FILTER admissionswithmort BY (diag::label is null);
shortadmissions_indexdate = GROUP shortadmissions BY (admissions::patientid);
shortadmissions_indexdate = FOREACH shortadmissions_indexdate GENERATE group as patientid, MAX(shortadmissions.admissions::etimestamp) AS index_date;
shortadmissions = JOIN shortadmissions BY admissions::patientid, shortadmissions_indexdate BY patientid;
shortadmissions = FOREACH shortadmissions GENERATE $0 AS patientid, $1 AS eventid, $3 AS value, 0 AS label, DaysBetween($8, $2) AS time_difference;

longadmissions = ORDER longadmissions BY patientid, eventid;
shortadmissions = ORDER shortadmissions BY patientid, eventid;
STORE shortadmissions INTO 'shortadmissions' USING PigStorage(',');
STORE longadmissions INTO 'longadmissions' USING PigStorage(',');
all_admissions = UNION shortadmissions, longadmissions;
all_admissions = FILTER all_admissions by (value is not null);
filtered = FILTER all_admissions by (time_difference >= 0 AND time_difference <= 2000);
filteredgrpd = GROUP filtered BY 1;
filtered = FOREACH filteredgrpd GENERATE FLATTEN(filtered);
filtered = ORDER filtered BY patientid, eventid,time_difference;
STORE filtered INTO 'filtered' USING PigStorage(',');

featureswithid = group filtered by (patientid, eventid);
featureswithid = FOREACH featureswithid generate group.$0 as patientid, group.$1 as eventid, COUNT(filtered.eventid) as featurevalue; 

featureswithid = ORDER featureswithid BY patientid, eventid;
STORE featureswithid INTO 'features_aggregate' USING PigStorage(',');
all_features = FOREACH (GROUP featureswithid BY eventid) {
  result = LIMIT featureswithid 1;
  GENERATE FLATTEN(result.eventid) as eventid;
}
all_features = rank all_features by eventid ASC;
all_features = FOREACH all_features GENERATE $0 -1 as idx, $1 as eventid;
STORE all_features INTO 'features' using PigStorage(' ');

features = JOIN all_features BY eventid, featureswithid BY eventid;
features = FOREACH features GENERATE featureswithid::patientid as patientid, all_features::idx as idx, featureswithid::featurevalue as featurevalue;
features = ORDER features BY patientid, idx;
STORE features INTO 'features_map' USING PigStorage(',');

maxvalues = GROUP features by idx;
maxvalues = FOREACH maxvalues GENERATE $0 as idx, MAX(features.featurevalue) as maxvalue;
normalized = JOIN maxvalues by idx, features by idx;
features = FOREACH normalized GENERATE features::patientid as patientid, maxvalues::idx as idx, (DOUBLE) features::featurevalue/ (DOUBLE) maxvalues::maxvalue as normalizedfeaturevalue;
features = ORDER features BY patientid, idx;
STORE features INTO 'features_normalized' USING PigStorage(',');

grpd = GROUP features BY patientid;
grpd_order = ORDER grpd BY $0;
features = FOREACH grpd_order
{
    sorted = ORDER features BY idx;
    generate group as patientid, utils.bag_to_svmlight(sorted) as sparsefeature;
}

labels =  JOIN admissions BY patientid FULL OUTER, diag BY patientid;
labels = FOREACH labels GENERATE admissions::patientid as patientid, diag::label as label;
labels = FOREACH (GROUP labels BY patientid) {
  result = LIMIT labels 1;
  GENERATE FLATTEN(result.patientid) as patientid, FLATTEN(result.label) as label;
}
labels = FOREACH labels GENERATE patientid as patientid, (label is null ? 0 : 1) as label;

samples = JOIN features BY patientid, labels BY patientid;
samples = DISTINCT samples PARALLEL 1;
samples = ORDER samples BY $0;
samples = FOREACH samples GENERATE $3 AS label, $1 AS sparsefeature;

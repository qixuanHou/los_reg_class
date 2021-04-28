# ICU length-of-stay classification & Regression

## Project Overview 
Predicting Intensive Care Unit (ICU) length of stay (LOS) serves as an important step towards improving the quality of care, enabling efficient hospital plans, and meticulously managing hospital recourses. LOS is defined as the number of days that a patient is hospitalized. This study uses Medical Information Mart for intensive Care (MIMIC-III) dataset. After data cleaning and formatting, different techniques, including random forecast, decision tree, Support Vector Machine, are applied to classify patients into two categories, those with extensive LOS and those with short LOS. AUC will be used to evaluate and compare the models. Additionally, different regression models are implemented, and R squared (R2) scores are used as evaluation.

I use the dataset MIMIC (https://mimic.physionet.org/) developed by the MIT lab, comprising de-identified health data with ~40,000 critical care patients. Since MIMIC requires special access requirements, I cannot include dataset in the repository. Please visit their website and follow the instructions to access the dataset. 


## File Description 

* pig/etl.pig - data cleaning is done via pig.
* python/basic_stats.ipynb - feature engineering and basic stats 
* python/classification.ipynb - classification models are fitted and compared
* python/gradient_boosting.ipynb - gradient boosting model is optimized 
* python/neural_network.ipynb - neural networks are built 
* python/regression.ipynb - regression models are fitted and compared
* python.helper.py - helper functions


## Data 

* ADMISSIONS.csv.gz - Admissions information 
* PATIENTS.csv.gz - Patient specific info 
* DIAGNOSES_ICD.csv.gz - ICD-9 diagnosis 
* ICUSTAYS.csv.gz - Intensive Care Unit (ICU) ward information 


* cleaned.csv - cleaned data ready for the models



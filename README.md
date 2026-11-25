# CareLoop Clinics — No-Show Guard

Repository: https://github.com/beginnerAD/CareLoop-Clinics-No-Show-Guard

## Summary of Findings

- **Part 1 (Data Cleaning):** Cleaned 1,020 raw records down to 990 usable appointments (218 no-shows, 22.0% overall) in `appointments_clean.csv` after removing 20 duplicates, dropping 10 rows with invalid dates or blank statuses, imputing missing ages/distances, and capping extreme fee/distance outliers.
- **Part 2 (SQL Analysis):** Queries across the 990 cleaned visits showed that bookings made 31+ days ahead missed at a 60.5% rate (vs. 16.2% for 1–7 days), and Gomti Nagar Care Point (Lucknow) recorded the highest clinic no-show rate at 33.3% (30 of 90 visits).
- **Part 3 (No-Show Prediction):** Picked Logistic Regression (test ROC-AUC 0.7889, 5-fold CV ROC-AUC 0.7737, cutoff threshold 0.35) over the baseline and tree models because it raised test recall to 57.1% (catching 28 of 49 test no-shows) while keeping precision at 57.1%.
- **Part 4 (Call Note Triage):** Ran 10 follow-up notes through Gemini with Pydantic validation (14 API calls total); 5 of the 10 notes had no reminder sent, and both patients who said they forgot (`N001` and `N007`) were in that unreminded group.

## Recommendation

CareLoop Clinics should enforce automated reminders across all bookings—especially visits booked more than 14 days in advance (where no-show rates jump from 16.2% to 30.0%–60.5%)—and have the front desk make evening confirmation calls to patients flagged above our 0.35 probability threshold by the Logistic Regression model (test ROC-AUC 0.7889). Across our 990 cleaned appointments (22.0% overall no-show rate) and the 10 call-centre notes, half (5 of 10) of sampled no-shows never received a reminder, and 100% (2 of 2) of patients who simply forgot were unreminded. Focusing daily outreach on the ~25% of appointments flagged above 0.35 gives call-centre staff a manageable call list that directly targets preventable no-shows without wasting outreach capacity.

## Limitations

1. **Small note sample:** Ten follow-up notes are only enough to validate the classification pipeline and cannot represent the true breakdown of no-show reasons across all eight clinics.
2. **Data leakage in the split:** Imputation medians and outlier fences were calculated across all 990 rows before splitting, and because the split was random rather than chronological, the same patient can appear in both the training and test sets.
3. **Observational records and fixed cutoff:** The historical data shows associations rather than proof of cause and effect, and the optimal risk cutoff in live operations would depend on how many evening calls the front desk can realistically make against the cost of an empty doctor slot.

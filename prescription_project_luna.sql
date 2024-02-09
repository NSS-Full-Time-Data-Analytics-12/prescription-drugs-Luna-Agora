--1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi AS dr
	   , SUM(total_claim_count) AS claims
FROM prescription
GROUP BY dr
ORDER BY claims DESC
LIMIT 1;
--1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name AS first
		, nppes_provider_last_org_name AS last
		, specialty_description AS spec
		, total_claim_count AS claim
FROM prescriber
LEFT JOIN prescription ON prescriber.npi = prescription.npi;
--2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT  prescriber.specialty_description AS spec
		, SUM(prescription.total_claim_count) AS claim
FROM prescriber
LEFT JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescription.total_claim_count IS NOT NULL
GROUP BY spec
ORDER BY claim DESC;
--2b. Which specialty had the most total number of claims for opioids?
SELECT COUNT(opioid_drug_flag)
			, opioid_drug_flag
FROM drug
GROUP BY opioid_drug_flag;
---------------------
SELECT *
FROM prescriber;
--------------------
SELECT DISTINCT prescriber.specialty_description AS spec
		, SUM(prescription.total_claim_count) AS claim
FROM prescriber
LEFT JOIN prescription
	ON prescriber.npi = prescription.npi
LEFT JOIN drug
	USING (drug_name)
WHERE prescription.total_claim_count IS NOT NULL
	AND drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY claim DESC;
--2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description
FROM prescriber
FULL JOIN prescription
	USING (npi)
WHERE drug_name IS NULL
GROUP BY specialty_description;
--2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH opi_claim AS (SELECT specialty_description AS spec
						 , SUM(total_claim_count) AS claim_opioid
					FROM prescriber
					LEFT JOIN prescription
						USING (npi)
					LEFT JOIN drug
						USING (drug_name)
					WHERE opioid_drug_flag = 'Y'
						AND long_acting_opioid_drug_flag = 'Y'
					GROUP BY specialty_description)
,
reg_claim AS (SELECT specialty_description AS spec
						 , SUM(total_claim_count) AS claim_reg
					FROM prescriber
					LEFT JOIN prescription
						USING (npi)
					LEFT JOIN drug
						USING (drug_name)
					WHERE opioid_drug_flag = 'N'
						AND long_acting_opioid_drug_flag = 'N'
					GROUP BY specialty_description)
SELECT spec
	 , ROUND((claim_opioid * 100) / claim_reg, 2) AS opioid_percent
FROM opi_claim
INNER JOIN reg_claim
	USING (spec)
ORDER BY opioid_percent DESC;
--3a. Which drug (generic_name) had the highest total drug cost?
SELECT drug.generic_name
	   , prescription.total_drug_cost
FROM drug
JOIN prescription
	USING (drug_name)
GROUP BY drug.generic_name
		 , prescription.total_drug_cost
ORDER BY total_drug_cost DESC;
--3b. Which drug (generic_name) has the hightest total cost per day?
--- **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name
		, ROUND(SUM(total_drug_cost / total_day_supply), 2) AS cost_per_day
FROM drug
INNER JOIN prescription
	USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name
		, CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 		   WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			   ELSE 'neither' END AS drug_type
FROM drug;

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
		, prescription.total_drug_cost::money AS total_cost
FROM drug
INNER JOIN prescription
	USING (drug_name);
---*************************************---
WITH dt_cost AS (SELECT CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 						WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
							ELSE 'neither' END AS drug_type
						, prescription.total_drug_cost::money AS total_cost
				FROM drug
				INNER JOIN prescription
					USING (drug_name))

SELECT DISTINCT drug_type
		, SUM(total_cost)
FROM dt_cost
GROUP BY drug_type
ORDER BY sum DESC;
---************************************---
--5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT *
FROM cbsa
WHERE cbsaname LIKE '%TN%';
--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT *
FROM cbsa
LEFT JOIN population
	USING (fipscounty)
WHERE population IS NOT NULL;
--lowest--
SELECT DISTINCT cbsa.cbsaname AS cban
		, SUM(population.population) AS spop
FROM cbsa
LEFT JOIN population
	USING (fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsa.cbsaname
ORDER BY spop ASC
LIMIT 1;
--highest--
SELECT DISTINCT cbsa.cbsaname AS cban
		, SUM(population.population) AS spop
FROM cbsa
LEFT JOIN population
	USING (fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsa.cbsaname
ORDER BY spop DESC
LIMIT 1;
--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT fips_county.county
	 , population
FROM cbsa
FULL JOIN population
	USING (fipscounty)
LEFT JOIN fips_county
	USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC
LIMIT 1;
--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name
	 , total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name
	 , total_claim_count
	 , opioid_drug_flag
FROM prescription
INNER JOIN drug
	USING (drug_name)
WHERE total_claim_count > 3000;

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name
	 , total_claim_count
	 , opioid_drug_flag
	 , nppes_provider_first_name
	 , nppes_provider_last_org_name
FROM prescription
INNER JOIN drug
	USING (drug_name)
INNER JOIN prescriber
	USING (npi)
WHERE total_claim_count > 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi
	 , drug.drug_name
	 , specialty_description
	 , nppes_provider_city
	 , opioid_drug_flag
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
	USING (npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management';

--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT npi
	 , drug.drug_name
	 , total_claim_count
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
	USING (npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management';

--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT npi
	 , drug_name
	 , COALESCE(total_claim_count, 0) AS coal_claim
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
	USING (npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management';
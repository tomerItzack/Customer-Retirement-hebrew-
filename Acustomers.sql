/* 


**SQL Queries**

1. **List of customers from the central region in descending order of income (top 5 highest earners)**

2. **Total amount and number of loans in default in the following month compared to those not in default in the following month**

3. **Average expenses by years of tenure in increments of 5 years. This will only be displayed if the number of customers in the range is greater than 3.**

4. **Count all customer pairs (without duplicates of the same pair), where the difference in expenses between them is less than 1000 ILS, and both entered default or both did not enter default. Display the average income gap (absolute value) of all pairs, how many such pairs are in default, and how many are not in default.**

5. **Summary data for each region (in one query): the number of customers with income greater than expenses in the region, the percentage of loans of customers from the region compared to all customers (by quantity and by amount), the median tenure in the region.**

*/

use jobl

--questuion 1
select top(5) id,Income
from dbo.[G-RISK]
where Region='central'
order by Income desc;

--questuion 2
select count(case when Is_Default=0 then 1 end) as 'countNonF',
       SUM(CASE WHEN Is_Default = 0 THEN loan_sum ELSE 0 END) AS 'sumNonF',
       count(case when Is_Default=1 then 1 end) as 'countF',
	   SUM(CASE WHEN Is_Default = 1 THEN loan_sum ELSE 0 END) AS 'sumF'
from dbo.[G-RISK];



--questuion 3


WITH SeniorityRanges_cte AS (
    SELECT 
        CASE 
            WHEN Seniority <= 5 THEN '0-5'
            WHEN Seniority >5 and Seniority<=10 THEN'5-10'
            WHEN Seniority >10 and Seniority<=15 THEN '10-15'
            WHEN Seniority >15 and Seniority<=20 THEN '15-20'
            WHEN Seniority >20 and Seniority<=25 THEN '20-25'
            WHEN Seniority >25 and Seniority<=30 THEN '25-30'
        END AS SeniorityRange,
        Outcome
    FROM 
        dbo.[G-RISK]
)
SELECT 
    SeniorityRange,
    AVG(Outcome) AS 'AverageExpense',
    COUNT(*) AS 'CustomerCount'
FROM 
    SeniorityRanges_cte
GROUP BY 
    SeniorityRange

	--while grater than 3 customers
HAVING 
    COUNT(*) > 3
order by 
    CASE 
        WHEN SeniorityRange = '0-5' THEN 1
        WHEN SeniorityRange = '5-10' THEN 2
        WHEN SeniorityRange = '10-15' THEN 3
        WHEN SeniorityRange = '15-20' THEN 4
        WHEN SeniorityRange = '20-25' THEN 5
        WHEN SeniorityRange = '25-30' THEN 6
 END;


--questuion 4

WITH Pairs_cte AS (
    SELECT 
	    --to run on each id against all id and check all the pairs with less than 1000 diff
        a.ID AS ID1, 
        b.ID AS ID2, 
        ABS(a.Outcome - b.Outcome) AS 'RevenueGap', 
        a.Is_Default AS 'Is_Default1', 
        b.Is_Default AS 'Is_Default2'
    FROM 
        dbo.[G-RISK] AS a
    JOIN 
        dbo.[G-RISK] AS b ON a.ID < b.ID
    WHERE 
        ABS(a.Outcome - b.Outcome) < 1000
),
FilteredPairs_cte AS (
--run the pairs with the same Is_Default
    SELECT 
        *
    FROM 
        Pairs_cte
    WHERE 
        Is_Default1 = Is_Default2
)
SELECT 
    AVG(RevenueGap) AS 'AverageRevenueGap',
    SUM(CASE WHEN Is_Default1 = 1 THEN 1 ELSE 0 END) AS 'FailurePairs',
    SUM(CASE WHEN Is_Default1 = 0 THEN 1 ELSE 0 END) AS 'NonFailurePairs',
    COUNT(*) AS TotalPairs
FROM 
    FilteredPairs_cte;


--questuion 5

/*

 bring only the median


    SELECT 
        Region,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Seniority) OVER (PARTITION BY Region) AS MedianSeniority
    FROM 
        dbo.[G-RISK]


bring the percent and the count

select Region,
    count(case when income > Outcome then 1 end) as 'GoodCustomers',
	 format(ROUND((SUM(Loan_Sum) * 100.0) / SUM(SUM(Loan_Sum)) OVER (), 2),'0.##') AS 'Percent'
from dbo.[G-RISK]
group by Region;

*/

WITH median_cte AS (
    SELECT distinct
        Region,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Seniority) OVER (PARTITION BY Region) AS 'MedianSeniority'
    FROM 
        dbo.[G-RISK]
),
statistics_cte AS (
    SELECT 
        Region,
        COUNT(CASE WHEN income > Outcome THEN 1 END) AS 'GoodCustomers',
        FORMAT(ROUND((SUM(Loan_Sum) * 100.0) / SUM(SUM(Loan_Sum)) OVER (), 2), '0.##') AS [Percent]
    FROM 
        dbo.[G-RISK]
    GROUP BY 
        Region
)
SELECT 
    s.Region,
    s.GoodCustomers,
    s.[Percent],
    m.MedianSeniority
FROM 
    statistics_cte s
JOIN 
    median_cte m ON s.Region = m.Region;






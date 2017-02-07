PROC SQL;
    CREATE TABLE combined AS
    SELECT a.premise, 
           a.year,
           a.month,
           a.from_date,
           a.to_date,
           b.cdd,
           b.hdd
    FROM test AS a, 
        (SELECT sum(temps.cdd65) AS cdd,
                sum(temps.hdd55) AS hdd,
                test.year,
                test.month,
                test.premise,
                CAT(PUT(test.from_date, DATE9.),' - ',PUT(test.to_date, DATE9.)) AS date_range
         FROM temps, test
         WHERE temps.date BETWEEN test.from_date AND test.to_date
         GROUP BY test.premise, date_range, test.month, test.year) AS b
    WHERE b.year = a.year AND b.month = a.month AND b.premise = a.premise
    ORDER BY a.premise,
             a.year,
             a.month;
QUIT;

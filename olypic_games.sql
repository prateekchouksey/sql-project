-- 1. How many olympics games have been held?
SELECT
	COUNT(DISTINCT GAMES)
FROM
	ATHLETE_EVENTS;
	
--2. List down all Olympics games held so far.
SELECT DISTINCT
	GAMES,
	CITY
FROM
	ATHLETE_EVENTS
ORDER BY
	GAMES ;
-- 3. Mention the total no of nations who participated in each olympics game?
SELECT
	GAMES,
	COUNT(DISTINCT NOC)
FROM
	ATHLETE_EVENTS
GROUP BY
	GAMES;

-- 4 Find the year with the highest and lowest number of participating countries
SELECT
	GAMES,
	NUM_NOC,
	CASE
		WHEN NUM_NOC = (
			SELECT
				MAX(NUM_NOC)
			FROM
				(
					SELECT
						GAMES,
						COUNT(DISTINCT NOC) AS NUM_NOC
					FROM
						ATHLETE_EVENTS
					GROUP BY
						GAMES
				) AS SUBQUERY
		) THEN 'Highest'
		WHEN NUM_NOC = (
			SELECT
				MIN(NUM_NOC)
			FROM
				(
					SELECT
						GAMES,
						COUNT(DISTINCT NOC) AS NUM_NOC
					FROM
						ATHLETE_EVENTS
					GROUP BY
						GAMES
				) AS SUBQUERY
		) THEN 'Lowest'
	END AS PARTICIPATION_TYPE
FROM
	(
		SELECT
			GAMES,
			COUNT(DISTINCT NOC) AS NUM_NOC
		FROM
			ATHLETE_EVENTS
		GROUP BY
			GAMES
	) AS GAMES_PARTICIPATION;

-- 5. Which nation has participated in all of the olympic games
SELECT TOP 1 WITH TIES 
	NOC,
	COUNT(NOC) AS NATION_PLAY
FROM
	(
		SELECT DISTINCT
			GAMES,
			NOC
		FROM
			ATHLETE_EVENTS
	) GAME
GROUP BY
	NOC
ORDER BY
	NATION_PLAY DESC;

-- 6. Identify the sport which was played in all summer olympics.
SELECT  distinct sport, a2.play
FROM (
    SELECT 
        sport, 
        COUNT(a1.sport) OVER (PARTITION BY sport) AS play
    FROM (
        SELECT DISTINCT 
            year, season, sport
        FROM athlete_events
        WHERE season = 'Summer'
        ORDER BY year
    ) a1
) a2
WHERE play = 29;

-- 7. Which Sports were just played only once in the olympics.
SELECT YEAR,GAMES,CITY,SPORT FROM
(SELECT 
    year, 
    games, 
    city, 
    a1.sport, 
    COUNT(a1.sport) OVER (PARTITION BY a1.sport) AS sport_play
FROM (
    SELECT DISTINCT 
        year, 
        sport, 
        games, 
        city
    FROM athlete_events
    ORDER BY year
) a1
) WHERE SPORT_PLAY= 1;

-- 8. Fetch the total no of sports played in each olympic games.
SELECT 
      YEAR,
	  GAMES,
	  CITY,
	  COUNT(DISTINCT SPORT) SPORT
FROM ATHLETE_EVENTS GROUP BY YEAR,GAMES,CITY ORDER BY YEAR ASC;

-- 9. Fetch oldest athletes to win a gold medal
SELECT 
    NAME, 
    AGE, 
    MEDAL, 
    YEAR, 
    SEASON, 
    CITY
FROM 
    athlete_events
WHERE 
    MEDAL = 'GOLD' 
    AND AGE = (
        SELECT MAX(CAST(AGE AS numeric))
        FROM athlete_events
    );

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
WITH CTE1 AS (
    SELECT COUNT(SEX) AS MALE
    FROM ATHLETE_EVENTS
    WHERE SEX = 'M'
),
CTE2 AS (
    SELECT COUNT(SEX) AS FEMALE
    FROM ATHLETE_EVENTS
    WHERE SEX = 'F'
)
SELECT 
    CAST(CTE1.MALE AS FLOAT) / CTE2.FEMALE AS ratio_numeric,
    CONCAT('1:', CAST(CAST(CTE1.MALE AS FLOAT) / CTE2.FEMALE AS DECIMAL(10, 2))) AS ratio_formatted
FROM CTE1, CTE2;

-- 11. Fetch the top 5 athletes who have won the most gold medals.
SELECT
	NAME,
	SEX,
	SPORT,
	TOTAL_MEDAL,
	DENSE_RANK() OVER (
		ORDER BY
			TOTAL_MEDAL DESC
	) AS TOP
FROM
	(
		SELECT
			NAME,
			SEX,
			SPORT,
			COUNT(MEDAL) AS TOTAL_MEDAL
		FROM
			ATHLETE_EVENTS
		WHERE
			MEDAL = 'Gold'
		GROUP BY
			NAME,
			SEX,
			SPORT
		ORDER BY
			TOTAL_MEDAL DESC
	) SUB
ORDER BY total_medal DESC
LIMIT 5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
SELECT
	NAME,
	SEX,
	SPORT,
	TOTAL_MEDAL,
	DENSE_RANK() OVER (
		ORDER BY
			TOTAL_MEDAL DESC
	) AS TOP
FROM
	(
		SELECT
			NAME,
			SEX,
			SPORT,
			COUNT(MEDAL) AS TOTAL_MEDAL
		FROM
			ATHLETE_EVENTS
		WHERE
			MEDAL in('Gold','Silver','Bronze')
		GROUP BY
			NAME,
			SEX,
			SPORT
		ORDER BY
			TOTAL_MEDAL DESC
	) SUB
ORDER BY total_medal DESC
LIMIT 5;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
SELECT
	NOC,
	COUNT(MEDAL) AS MED
FROM
	ATHLETE_EVENTS
WHERE
	MEDAL IN ('Gold', 'Silver', 'Bronze')
GROUP BY
	NOC
ORDER BY
	MED DESC limit 5;


-- 14. List down total gold, silver and bronze medals won by each country.
			
--------------------------------------------------------------------------------------------------

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
WITH CTE_1 AS (
    SELECT
        GAMES,
        NOC,
        MEDAL
    FROM
        ATHLETE_EVENTS
),
CTE_2 AS (
    SELECT
        GAMES,
        NOC,
        COUNT(*) AS gold
    FROM
        CTE_1
    WHERE
        MEDAL = 'Gold'
    GROUP BY
        GAMES, NOC
),
CTE_3 AS (
    SELECT
        GAMES,
        NOC,
        COUNT(*) AS silver
    FROM
        CTE_1
    WHERE
        MEDAL = 'Silver'
    GROUP BY
        GAMES, NOC
),
CTE_4 AS (
    SELECT
        GAMES,
        NOC,
        COUNT(*) AS bronze
    FROM
        CTE_1
    WHERE
        MEDAL = 'Bronze'
    GROUP BY
        GAMES, NOC
)
SELECT
    C2.GAMES,
	C2.NOC,
	COALESCE(c2.gold, 0) AS Gold,
    COALESCE(c3.silver, 0) AS Silver,
    COALESCE(c4.bronze, 0) AS Bronze
FROM
	CTE_2 C2 FULL OUTER JOIN
    CTE_3 c3 ON c2.GAMES = c3.GAMES AND c2.NOC = c3.NOC
FULL OUTER JOIN
    CTE_4 c4 ON c2.GAMES = c4.GAMES AND c2.NOC = c4.NOC
ORDER BY
	GAMES,
	NOC;	

-------------------------------------------------------------------------------------------------

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH
    CTE_1 AS (
        SELECT
            GAMES,
            NOC,
            MEDAL
        FROM
            ATHLETE_EVENTS
    ),
    GOLD_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS GOLD_COUNT
        FROM
            CTE_1
        WHERE
            MEDAL = 'Gold'
        GROUP BY
            GAMES, NOC
    ),
    SILVER_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS SILVER_COUNT
        FROM
            CTE_1
        WHERE
            MEDAL = 'Silver'
        GROUP BY
            GAMES, NOC
    ),
    BRONZE_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS BRONZE_COUNT
        FROM
            CTE_1
        WHERE
            MEDAL = 'Bronze'
        GROUP BY
            GAMES, NOC
    ),
    RANKED_GOLD AS (
        SELECT
            GAMES,
            NOC,
            GOLD_COUNT,
            RANK() OVER (PARTITION BY GAMES ORDER BY GOLD_COUNT DESC) AS RANK
        FROM
            GOLD_MEDALS
    ),
    RANKED_SILVER AS (
        SELECT
            GAMES,
            NOC,
            SILVER_COUNT,
            RANK() OVER (PARTITION BY GAMES ORDER BY SILVER_COUNT DESC) AS RANK
        FROM
            SILVER_MEDALS
    ),
    RANKED_BRONZE AS (
        SELECT
            GAMES,
            NOC,
            BRONZE_COUNT,
            RANK() OVER (PARTITION BY GAMES ORDER BY BRONZE_COUNT DESC) AS RANK
        FROM
            BRONZE_MEDALS
	)
    
SELECT
    GAMES,
    'Gold' AS MEDAL_TYPE,
    NOC,
    GOLD_COUNT AS MEDAL_COUNT
FROM
    RANKED_GOLD
WHERE
    RANK = 1
UNION ALL
SELECT
    GAMES,
    'Silver' AS MEDAL_TYPE,
    NOC,
    SILVER_COUNT AS MEDAL_COUNT
FROM
    RANKED_SILVER
WHERE
    RANK = 1
UNION ALL
SELECT
    GAMES,
   'Bronze' AS MEDAL_TYPE,
    NOC,
    BRONZE_COUNT AS MEDAL_COUNT
FROM
    RANKED_BRONZE
WHERE
    RANK = 1
ORDER BY
    GAMES,
    MEDAL_TYPE;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH
    CTE_1 AS (
        SELECT
            GAMES,
            NOC,
            MEDAL
        FROM
            ATHLETE_EVENTS
    ),
    GOLD_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS GOLD_COUNT
        FROM
            CTE_1
        WHERE
            MEDAL = 'Gold'
        GROUP BY
            GAMES, NOC
    ),
    SILVER_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS SILVER_COUNT
        FROM
            CTE_1
        WHERE
            MEDAL = 'Silver'
        GROUP BY
            GAMES, NOC
    ),
    BRONZE_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS BRONZE_COUNT
        FROM
            CTE_1
        WHERE
            MEDAL = 'Bronze'
        GROUP BY
            GAMES, NOC
    ),
    RANKED_GOLD AS (
        SELECT
            GAMES,
            NOC,
            GOLD_COUNT,
            RANK() OVER (PARTITION BY GAMES ORDER BY GOLD_COUNT DESC) AS RANK
        FROM
            GOLD_MEDALS
    ),
    RANKED_SILVER AS (
        SELECT
            GAMES,
            NOC,
            SILVER_COUNT,
            RANK() OVER (PARTITION BY GAMES ORDER BY SILVER_COUNT DESC) AS RANK
        FROM
            SILVER_MEDALS
    ),
    RANKED_BRONZE AS (
        SELECT
            GAMES,
            NOC,
            BRONZE_COUNT,
            RANK() OVER (PARTITION BY GAMES ORDER BY BRONZE_COUNT DESC) AS RANK
        FROM
            BRONZE_MEDALS
	),
	TOTAL_MEDALS AS (
        SELECT
            GAMES,
            NOC,
            COUNT(MEDAL) AS TOTAL_MEDAL
        FROM
            CTE_1
		WHERE 
		    MEDAL IN('Gold','Silver','Bronze')
        GROUP BY
            GAMES, NOC
	),
    TOTAL_COUNT AS (
        SELECT
            GAMES,
            NOC,
            TOTAL_MEDAL,
            RANK() OVER (PARTITION BY GAMES ORDER BY TOTAL_MEDAL DESC) AS RANK
        FROM
            TOTAL_MEDALS
    )
SELECT
    GAMES,
    'Gold' AS MEDAL_TYPE,
    NOC,
    GOLD_COUNT AS MEDAL_COUNT
FROM
    RANKED_GOLD
WHERE
    RANK = 1
UNION ALL
SELECT
    GAMES,
    'Silver' AS MEDAL_TYPE,
    NOC,
    SILVER_COUNT AS MEDAL_COUNT
FROM
    RANKED_SILVER
WHERE
    RANK = 1
UNION ALL
SELECT
    GAMES,
   'Bronze' AS MEDAL_TYPE,
    NOC,
    BRONZE_COUNT AS MEDAL_COUNT
FROM
    RANKED_BRONZE
WHERE
    RANK = 1
UNION ALL	
SELECT
    GAMES,
   'TOTAL' AS MEDAL_TYPE,
    NOC,
    TOTAL_MEDAL AS MEDAL_COUNT
FROM
    TOTAL_COUNT
WHERE
    RANK = 1	
ORDER BY
    GAMES,
    MEDAL_TYPE;

-- 18. Which countries have never won gold medal but have won silver/bronze medals?

SELECT
	NOC,
	COUNT(MEDAL)
FROM
	ATHLETE_EVENTS
WHERE
	MEDAL IN ('Gold', 'Silver', 'Bronze')
GROUP BY
	NOC;

-- 19. In which Sport/event, India has won highest medals.
select sport,count(medal) med from(SELECT
			GAMES,
			SPORT,
			MEDAL
		FROM
			ATHLETE_EVENTS
		WHERE
			NOC = 'IND'
			AND MEDAL IN ('Gold', 'Silver', 'Bronze')
			group by games,SPORT,
			MEDAL) group by sport order by med desc limit 1;


-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
SELECT
			distinct GAMES,
			SPORT,
			MEDAL
		FROM
			ATHLETE_EVENTS	
where noc='IND' and sport ='Hockey' and medal in('Gold','Silver','Bronze') order by games;


-------------------------------------------------------------------------------------------------------------
----------------------------------------------------THE END--------------------------------------------------
-------------------------------------------------------------------------------------------------------------
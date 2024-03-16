-- Analyze the relationship between player age and performance metrics.
-- Explore if there is an optimal age range for peak performance.

--AGGREGATED stats for all players

WITH player_stats AS (
    SELECT
        playerid,
        yearid - birthyear AS age,
        AVG(h) AS avg_h, --hits
        AVG(ab) AS avg_ab, --at bats
        AVG(bb) AS avg_bb, --base on balls
        AVG(hbp) AS avg_hbp, --hit by pitch
        AVG(sf) AS avg_sf, --sacrifice flies
        AVG(h2b) AS avg_h2b, --doubles
        AVG(h3b) AS avg_h3b, --triples
        AVG(hr) AS avg_hr --homeruns
    FROM batting
    INNER JOIN people USING(playerid)
    WHERE ab > 100  -- Consider players with at least 100 at-bats
    GROUP BY playerid, age
)
SELECT
    age AS age_group,
	--COUNT(age),
    --ROUND(COALESCE(AVG(avg_h / NULLIF(avg_ab, 0)), 0)::numeric, 3) AS avg_batting_average, --(not used for sabermetrics, may take this out)
    ROUND(COALESCE(AVG((avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0)), 0)::numeric, 3) AS avg_obp, --on base percentage
    ROUND(COALESCE(AVG((avg_h + (2 * avg_h2b) + (3 * avg_h3b) + (4 * avg_hr)) / NULLIF(avg_ab, 0)), 0)::numeric, 3) AS avg_slg, --slugging percentage
	ROUND(COALESCE((AVG((avg_h + (2 * avg_h2b) + (3 * avg_h3b) + (4 * avg_hr)) / NULLIF(avg_ab, 0)) + 
     AVG((avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0))), 0)::numeric, 3) AS avg_ops --on base plus slugging
FROM player_stats
GROUP BY age_group
ORDER BY age_group;
	
--UNAGGREGATED stats for all players

WITH player_stats AS (
    SELECT
        playerid,
        yearid - birthyear AS age,
        AVG(h) AS avg_h, --hits
        AVG(ab) AS avg_ab, --at bats
        AVG(bb) AS avg_bb, --base on balls
        AVG(hbp) AS avg_hbp, --hit by pitch
        AVG(sf) AS avg_sf, --sacrifice flies
        AVG(h2b) AS avg_h2b, --doubles
        AVG(h3b) AS avg_h3b, --triples
        AVG(hr) AS avg_hr --homeruns
    FROM batting
    INNER JOIN people USING(playerid)
    WHERE ab > 100  -- Consider players with at least 100 at-bats
    GROUP BY playerid, age
)
SELECT
    playerid,
	age AS age_group,
	ROUND(COALESCE(avg_h / NULLIF(avg_ab, 0), 0)::numeric, 3) AS batting_average, --(not used for sabermetrics, may take this out)
    ROUND(COALESCE((avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0), 0)::numeric, 3) AS obp, --on base percentage
    ROUND(COALESCE((avg_h + (2 * avg_h2b) + (3 * avg_h3B) + (4 * avg_hr)) / NULLIF(avg_ab, 0), 0)::numeric, 3) AS slg, --slugging percentage
    ROUND(COALESCE(((avg_h + (2 * avg_h2b) + (3 * avg_h3b) + (4 * avg_hr)) / NULLIF(avg_ab, 0) + 
     (avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0)), 0)::numeric, 3) AS ops --on base plus slugging
FROM player_stats
ORDER BY playerid, age_group;

--looking at players who played in the MLB through age 40

--UNAGGREGATED stats for 40+ players

WITH over_40 AS (
	 SELECT
        playerid,
        yearid - birthyear AS age,
        AVG(h) AS avg_h, --hits
        AVG(ab) AS avg_ab, --at bats
        AVG(bb) AS avg_bb, --base on balls
        AVG(hbp) AS avg_hbp, --hit by pitch
        AVG(sf) AS avg_sf, --sacrifice flies
        AVG(h2b) AS avg_h2b, --doubles
        AVG(h3b) AS avg_h3b, --triples
        AVG(hr) AS avg_hr --homeruns
    FROM batting
    INNER JOIN people USING(playerid)
    WHERE ab > 100  -- Consider players with at least 100 at-bats
		AND playerid IN (
			SELECT playerid
			FROM batting
			INNER JOIN people USING(playerid)
			WHERE ab > 100  -- Consider players with at least 100 at-bats
				AND yearid - birthyear >= 40
			)
    GROUP BY playerid, age
) 
SELECT
    playerid,
	age AS age_group,
	ROUND(COALESCE(avg_h / NULLIF(avg_ab, 0), 0)::numeric, 3) AS batting_average, --(not used for sabermetrics, may take this out)
    ROUND(COALESCE((avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0), 0)::numeric, 3) AS obp, --on base percentage
    ROUND(COALESCE((avg_h + (2 * avg_h2b) + (3 * avg_h3B) + (4 * avg_hr)) / NULLIF(avg_ab, 0), 0)::numeric, 3) AS slg, --slugging percentage
    ROUND(COALESCE(((avg_h + (2 * avg_h2b) + (3 * avg_h3b) + (4 * avg_hr)) / NULLIF(avg_ab, 0) + 
     (avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0)), 0)::numeric, 3) AS ops --on base plus slugging
FROM player_stats
FROM over_40
ORDER BY playerid, age_group;
	
--AGGREGATED stats for 40+ players

WITH over_40 AS (
	 SELECT
        playerid,
        yearid - birthyear AS age,
        AVG(h) AS avg_h, --hits
        AVG(ab) AS avg_ab, --at bats
        AVG(bb) AS avg_bb, --base on balls
        AVG(hbp) AS avg_hbp, --hit by pitch
        AVG(sf) AS avg_sf, --sacrifice flies
        AVG(h2b) AS avg_h2b, --doubles
        AVG(h3b) AS avg_h3b, --triples
        AVG(hr) AS avg_hr --homeruns
    FROM batting
    INNER JOIN people USING(playerid)
    WHERE ab > 100  -- Consider players with at least 100 at-bats
		AND playerid IN (
			SELECT playerid
			FROM batting
			INNER JOIN people USING(playerid)
			WHERE ab > 100  -- Consider players with at least 100 at-bats
				AND yearid - birthyear >= 40
			)
    GROUP BY playerid, age
) 
SELECT
     age AS age_group,
	--COUNT(age),
    --ROUND(COALESCE(AVG(avg_h / NULLIF(avg_ab, 0)), 0)::numeric, 3) AS avg_batting_average, --(not used for sabermetrics, may take this out)
    ROUND(COALESCE(AVG((avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0)), 0)::numeric, 3) AS avg_obp, --on base percentage
    ROUND(COALESCE(AVG((avg_h + (2 * avg_h2b) + (3 * avg_h3b) + (4 * avg_hr)) / NULLIF(avg_ab, 0)), 0)::numeric, 3) AS avg_slg, --slugging percentage
	ROUND(COALESCE((AVG((avg_h + (2 * avg_h2b) + (3 * avg_h3b) + (4 * avg_hr)) / NULLIF(avg_ab, 0)) + 
     AVG((avg_h + avg_bb + avg_hbp) / NULLIF(avg_ab + avg_bb + avg_hbp + avg_sf, 0))), 0)::numeric, 3) AS avg_ops --on base plus slugging
FROM over_40
GROUP BY age_group
ORDER BY age_group;
	
--Finding the outlier (francju01)

SELECT namefirst || ' ' || namelast AS player_name 
FROM people 
WHERE playerid = 'francju01'
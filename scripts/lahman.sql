/*Lahman Baseball Database Exercise*/
-------------------------------------

/*1. What range of years for baseball games played does the provided database cover? */ 

SELECT MIN(year) AS start_year, 
	MAX(year) AS end_year,
	MAX(year) - MIN(year) + 1 AS num_years
FROM homegames;

/*2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?*/ 
   
SELECT namefirst || ' ' || namelast AS player_name,
	height AS height_in,
	g_all AS num_games_played,
	teams.name AS team_name
FROM people
LEFT JOIN appearances 
USING(playerid)
LEFT JOIN teams
USING(teamid, yearid)
WHERE playerid IN (SELECT playerid FROM people ORDER BY height LIMIT 1);

/*3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?*/ 

SELECT namefirst || ' ' || namelast AS player_name,
	COALESCE(SUM(salary), 0) AS total_salary
FROM people
INNER JOIN salaries
USING(playerid)
WHERE playerid IN (
	SELECT DISTINCT playerid 
	FROM collegeplaying 
	WHERE schoolid = 'vandy')
GROUP BY playerid
ORDER BY total_salary DESC;

/*4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.*/ 

SELECT
	CASE WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN ('P', 'C') THEN 'Battery'
		END AS position,
	SUM(PO) AS num_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position
ORDER BY num_putouts DESC;
   
/*5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?*/
  
SELECT 
	10 * FLOOR(yearid/10) AS decade,
	ROUND(SUM(so)/SUM(g)::numeric, 2) AS avg_strikeouts, 
	ROUND(SUM(hr)/SUM(g)::numeric, 2) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade DESC;

--Both strikeouts and homeruns are trending upwards in more recent decades. Steroids, anyone?

/*6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.*/

SELECT
	namefirst || ' ' || namelast AS player_name,
	ROUND(SUM(sb) / (SUM(sb) + SUM(cs))::numeric * 100, 2) AS perc_steals
FROM batting
INNER JOIN people
USING(playerid)
WHERE yearid = 2016
GROUP BY player_name
HAVING (SUM(sb) + SUM(cs)) >= 20
ORDER BY perc_steals DESC
LIMIT 1;

/*7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?*/

(SELECT
	'Most wins that lost world series',
 	yearid AS year,
	name AS team,
	w As num_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
ORDER BY w DESC
LIMIT 1)
UNION
(SELECT
 	'Least wins that won world series',
	yearid AS year,
	name AS team,
	w As num_wins
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
 	AND yearid <> 1981
ORDER BY w
LIMIT 1);

--1981 there was an MLB strike lasting June-July, so there were not as many games played

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
WITH wins AS (
	SELECT
		yearid AS year,
		name AS team,
		w As num_wins, 
		wswin,
		CASE WHEN w = MAX(w) OVER(PARTITION BY yearid) AND wswin = 'Y' THEN 1 ELSE 0 END AS most_wins_and_ws
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	ORDER BY year
)
SELECT 
	SUM(most_wins_and_ws) AS num_times,
	--AVG(most_wins_and_ws) * 100 AS perc_of_time,
	ROUND(SUM(most_wins_and_ws) / COUNT(DISTINCT year)::numeric * 100, 2) AS perc_of_time
FROM wins;

/*8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.*/

(SELECT 'Top 5' AS top_or_bottom,
 	RANK() OVER(ORDER BY SUM(homegames.attendance) / SUM(games) DESC) AS rank,
	teams.name AS team_name,
	park_name,
	SUM(homegames.attendance) / SUM(games) AS avg_attendance
FROM homegames
LEFT JOIN parks
USING(park)
LEFT JOIN teams
ON teams.teamid = homegames.team AND teams.yearid = homegames.year
WHERE year = 2016
	AND games >= 10
GROUP BY teams.name, park_name	
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(SELECT 'Bottom 5',
	RANK() OVER(ORDER BY SUM(homegames.attendance) / SUM(games)) AS rank,
 	teams.name,
	park_name,
	SUM(homegames.attendance) / SUM(games) AS avg_attendance
FROM homegames
LEFT JOIN parks
USING(park)
LEFT JOIN teams
ON teams.teamid = homegames.team AND teams.yearid = homegames.year
WHERE year = 2016
	AND games >= 10
GROUP BY teams.name, park_name	
ORDER BY avg_attendance
LIMIT 5)
ORDER BY avg_attendance DESC;

/*9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.*/

WITH winners AS (
	(SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'NL')
	INTERSECT
	(SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'AL')
)
SELECT namefirst || ' ' || namelast AS manager_name,
	awardid AS award,
	awardsmanagers.lgid AS league,
	awardsmanagers.yearid AS year,
	teams.name
FROM awardsmanagers
INNER JOIN people
USING(playerid)
INNER JOIN managers
USING(yearid, playerid)
INNER JOIN teams
USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND awardsmanagers.lgid <> 'ML'
	AND playerid IN (SELECT playerid FROM winners)
ORDER BY manager_name, year;

--Dibran's way
WITH both_league_winners AS (
	SELECT
		playerid--, count(DISTINCT lgid)
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid IN ('AL', 'NL')
	GROUP BY playerid
	--order by COUNT(DISTINCT lgid) desc
	HAVING COUNT(DISTINCT lgid) = 2
	)
SELECT
	namefirst || ' ' || namelast AS full_name,
	yearid,
	lgid,
	name
FROM people
INNER JOIN both_league_winners
USING(playerid)
INNER JOIN awardsmanagers
USING(playerid)
INNER JOIN managers
USING(playerid, yearid, lgid)
INNER JOIN teams
USING(teamid, yearid,lgid)
WHERE awardid = 'TSN Manager of the Year'
ORDER BY full_name, yearid;
	
/*10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players first and last names and the number of home runs they hit in 2016*/
	
SELECT
    p.namefirst || ' ' || p.namelast AS player_name,
    b.hr AS home_runs_2016
FROM batting AS b
INNER JOIN people AS p ON b.playerID = p.playerid
WHERE b.yearid = 2016
	AND hr > 0
	AND EXTRACT(YEAR FROM debut::date) <= 2016 - 9
    AND b.hr = (
        SELECT MAX(hr)
        FROM batting
        WHERE playerid = b.playerid)
ORDER BY home_runs_2016 DESC;

-- Open-ended questions

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?
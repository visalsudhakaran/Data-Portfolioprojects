USE Portfolioproject
GO 
SELECT * 
FROM ['Covid-death$']

SELECT CV.location ,  CV.date , total_cases , total_deaths, CV.population 
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code


-- Total Cases vs Total Deaths in India 


SELECT   CV.location ,  CV.date , total_cases , total_deaths, CV.population , (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100 AS Deathpercentage
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
WHERE CV.location LIKE '%India%'
order by 1,2

--Looking for Total cases vs population
--what population got covid
SELECT   CV.location ,  CV.date , total_cases , total_deaths, CV.population , (CONVERT(float, total_cases) / CONVERT(float, CV.population)) * 100 AS Poplation_likelyhood
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
--WHERE CV.location LIKE '%India%'
order by 1,2

-- Country highest infection rate compared to population
SELECT CV.location , CV.population , MAX(total_cases) AS Highest_Infection_Count, MAX((CONVERT(float, total_cases) / CONVERT(float, CV.population))) * 100 AS Percent_population_infected
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
--WHERE CV.location LIKE '%India%'
GROUP BY CV.location , CV.population
order by CV.population Desc

-- Country highest infection rate compared to population infected
SELECT CV.location , CV.population , MAX(total_cases) AS Highest_Infection_Count, MAX((CONVERT(float, total_cases) / CONVERT(float, CV.population))) * 100 AS Percent_population_infected
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
--WHERE CV.location LIKE '%India%'
GROUP BY CV.location , CV.population
order by Percent_population_infected Desc

--showing countries with death count per population
SELECT CV.location , CV.population , MAX(CAST(total_deaths AS INT)) AS Total_Deaths
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
WHERE CV.continent IS NOT NULL
GROUP BY CV.location , CV.population
order by CV.population Desc

--showing countries with death count per population GROUPED BY CONTINENT
SELECT CV.continent , MAX(CAST(total_deaths AS INT)) AS Total_Deaths
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
WHERE CV.continent IS NOT NULL
GROUP BY CV.continent

--showing countries with death count per population GROUPED BY Location
SELECT CV.location, CV.population, MAX(CAST(total_deaths AS INT)) AS Total_Deaths
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
WHERE CV.continent IS NULL
GROUP BY CV.location , cv.population

--showing the contintents with highest death rate

SELECT CV.location , MAX(CAST(total_deaths AS INT)) AS Total_Deaths
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.iso_code = CD.iso_code
WHERE CV.continent IS not NULL
GROUP BY CV.location


--Global numbers
-- Death percent by date
SELECT CV.date , SUM(CAST(new_cases AS INT)) , 
SUM(CAST(new_deaths AS INT)) , SUM(new_deaths)/SUM(new_cases) * 100 as deathpercentage
FROM dbo.['Covid-Vaccination$'] AS CV
FULL OUTER JOIN dbo.['Covid-death$'] AS CD
on CV.location = CD.location
WHERE CV.continent IS not NULL
GROUP BY cv.date
order by 1,2


-- Death percent by cases
--SELECT SUM(CAST(new_cases AS INT)) , 
--SUM(CAST(new_deaths AS INT)) , SUM(new_deaths)/SUM(new_cases) * 100 as deathpercentage
--FROM dbo.['Covid-Vaccination$'] AS CV
--JOIN dbo.['Covid-death$'] AS CD
--on CV.location = CD.location
--WHERE CV.continent IS NOT NULL
--order by 1,2


--Looking at Total population and vaccination

select CD.continent, CV.location, CD.date , population , CV.new_vaccinations , 
SUM(CONVERT(float, CV.new_vaccinations)) over (Partition by CD.location order by CD.location , CD.date) 
AS Rolling_people_vaccinated , (Rolling_people_vaccinated/population)*100 
from Portfolioproject..['Covid-death$'] AS CD
JOIN Portfolioproject..['Covid-Vaccination$'] AS CV
	ON CD.location = CV.location AND
		CD.date = CV.date
		WHERE CD.continent IS NOT NULL
		ORDER BY 2,3


-- CTE - Why it is used - 2 same named columns cannot be used even for aggregate function here - 
with PopvsVac(continent , location , date , population, new_vaccinations ,Rolling_people_vaccinated )
as
(
select CD.continent, CV.location, CD.date , population , CV.new_vaccinations, 
SUM(CONVERT(float, CV.new_vaccinations)) over (Partition by CD.location Order by CD.location , CD.date) 
AS Rolling_people_vaccinated 
from Portfolioproject..['Covid-death$'] AS CD
JOIN Portfolioproject..['Covid-Vaccination$'] AS CV
	ON CD.location = CV.location AND
		CD.date = CV.date
		WHERE CD.continent IS NOT NULL
		
)

SELECT * , (Rolling_people_vaccinated/population)
FROM PopvsVac

-- Create Temp Table
DROP TABLE IF exists #percentpopulationvaccinated
Create Table #percentpopulationvaccinated
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccination numeric,
Rolling_people_vaccinated nvarchar(255)
)

insert into #percentpopulationvaccinated
 select CD.continent, CV.location, CD.date , population , CV.new_vaccinations, 
SUM(CONVERT(float, CV.new_vaccinations)) over (Partition by CD.location Order by CD.location , CD.date) 
AS Rolling_people_vaccinated
from Portfolioproject..['Covid-death$'] AS CD
JOIN Portfolioproject..['Covid-Vaccination$'] AS CV
	ON CD.location = CV.location AND
		CD.date = CV.date
		WHERE CD.continent IS NOT NULL
SELECT *
FROM #percentpopulationvaccinated


-- Create view for later ref

Create view percentpopulationvaccinated as 
 select CD.continent, CV.location, CD.date , population , CV.new_vaccinations, 
SUM(CONVERT(float, CV.new_vaccinations)) over (Partition by CD.location Order by CD.location , CD.date) 
AS Rolling_people_vaccinated
from Portfolioproject..['Covid-death$'] AS CD
JOIN Portfolioproject..['Covid-Vaccination$'] AS CV
	ON CD.location = CV.location AND
		CD.date = CV.date
		WHERE CD.continent IS NOT NULL


SELECT * 
FROM percentpopulationvaccinated
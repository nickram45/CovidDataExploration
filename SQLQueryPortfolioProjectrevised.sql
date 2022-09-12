--Quick intitial query to check everything was imported correctly.

SELECT *
FROM [Portfolio Project]..['Covid-deaths$']
ORDER BY 3,4;


SELECT *
FROM [Portfolio Project]..['Covid-Vaccinations$']
ORDER BY 3,4;

--Select Data the we are going to be using

SELECT location, date, total_cases,new_cases, total_deaths, population
FROM [Portfolio Project]..['Covid-deaths$']
ORDER BY 1,2;

-- Looking at Total Cases VS Total Deaths by Country

SELECT continent, location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..['Covid-deaths$'] 
WHERE continent is not null
ORDER BY 2,3;

--Taking a look at percentage of the total population that has gotten COVID-19

SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentofPopinfected
FROM [Portfolio Project]..['Covid-deaths$']
ORDER BY 2;

--Curious to find out what countries have the highest infection rate compared to population.
--This is most likely not the most accurate for the percent of population that is infected as it uses the total number of positive tests I believe and people could have been diagnosed twice.

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentofPopinfected
FROM [Portfolio Project]..['Covid-deaths$']
GROUP BY location, population
ORDER BY PercentofPopinfected DESC;

--Now exploring countries with the highest death count.
--Including a Where clause to filter out contintents and only show countries.

SELECT location, MAX(CAST(total_deaths AS INT)) as TotalDeathCount 
FROM [Portfolio Project]..['Covid-deaths$']
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Looking further into death rate with a comparison of percent of total cases that result in death.

SELECT location, MAX(CAST(total_deaths AS INT))/MAX(total_cases)*100 as DeathPercentofCases
FROM [Portfolio Project]..['Covid-deaths$']
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathPercentofCases DESC;

--Going to break things down by continent for the total deaths.

SELECT continent, MAX(CAST(total_deaths AS INT)) as TotalDeathCount 
FROM [Portfolio Project]..['Covid-deaths$']
WHERE continent IS not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--Further exploring the data at the continent level

SELECT continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..['Covid-deaths$'] 
WHERE continent IS NOT NULL
ORDER BY 1,2;

SELECT continent, date, population, total_cases, (total_cases/population)*100 as PercentofPopinfected
FROM [Portfolio Project]..['Covid-deaths$']
WHERE continent IS NOT NULL
ORDER BY 1,2;

SELECT continent, MAX(CAST(total_deaths AS INT))/MAX(total_cases)*100 as DeathPercentofCases
FROM [Portfolio Project]..['Covid-deaths$']
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY DeathPercentofCases DESC;

--Global info without location restrictions

SELECT date, SUM(new_cases) AS GlobalCases, SUM(CAST(new_deaths as int)) AS GlobalCases, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio Project]..['Covid-deaths$'] 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

--Looking at total Population VS Vaccinations

SELECT dea.continent, dea.location, dea.population, dea.date, vac.total_vaccinations, vac.people_vaccinated
FROM [Portfolio Project]..['Covid-Vaccinations$'] vac
JOIN [Portfolio Project]..['Covid-deaths$'] dea
	ON dea.location = vac.location
	AND dea.date = vac.date
ORDER BY dea.location, dea.date;

--Cases VS Vaccinations and creating a running total and More in CTE form

WITH CasesvsVacs (continent, location, date, new_vaccinations, VaccinationsRunningTotal, new_cases, CasesRunningTotal, population)
AS
(
SELECT vac.continent, vac.location, vac.date, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsRunningTotal, 
	dea.new_cases, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CasesRunningTotal, dea.population
FROM [Portfolio Project]..['Covid-Vaccinations$'] vac
JOIN [Portfolio Project]..['Covid-deaths$'] dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.Location LIKE '%states%'
--ORDER BY dea.location, dea.date
)
SELECT *, (CasesRunningTotal/population)*100 As percentinfected
FROM CasesvsVacs

--Temp Table 

DROP TABLE IF EXISTS #PercentPopulationInfected
CREATE TABLE #PercentPopulationInfected
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
new_vaccinations NUMERIC,
VaccinationsRunningTotal NUMERIC,
new_cases NUMERIC,
CasesRunningtotal NUMERIC,
population NUMERIC)

INSERT INTO #PercentPopulationInfected
SELECT vac.continent, vac.location, vac.date, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsRunningTotal, 
	dea.new_cases, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CasesRunningTotal, dea.population
FROM [Portfolio Project]..['Covid-Vaccinations$'] vac
JOIN [Portfolio Project]..['Covid-deaths$'] dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date


--Creating View to store data for later vizualizations

CREATE VIEW PercentPopVacandInfected AS
SELECT vac.continent, vac.location, vac.date, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VaccinationsRunningTotal, 
	dea.new_cases, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CasesRunningTotal, dea.population
FROM [Portfolio Project]..['Covid-Vaccinations$'] vac
JOIN [Portfolio Project]..['Covid-deaths$'] dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY dea.location, dea.date

--Changing the previous view up a bit since I do not think that using a running total on new vaccinations is a 
--great way to total up the percent of the population vaccinated

SELECT vac.continent, vac.location, vac.date, vac.people_vaccinated, (vac.people_vaccinated/dea.population) AS PercentPopVac, 
	dea.new_cases, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CasesRunningTotal, dea.population
FROM [Portfolio Project]..['Covid-Vaccinations$'] vac
JOIN [Portfolio Project]..['Covid-deaths$'] dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
--ORDER BY location, date

--Creating a table to be able to do some more calculations before cementing a view.

CREATE TABLE PercentPopInfecVac
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
people_vaccinated NUMERIC,
PercentPopVac NUMERIC,
new_cases NUMERIC,
CasesRunningtotal NUMERIC,
population NUMERIC)

INSERT INTO PercentPopInfecVac
SELECT vac.continent, vac.location, vac.date, vac.people_vaccinated, (vac.people_vaccinated/dea.population)*100 AS PercentPopVac, 
	dea.new_cases, SUM(dea.new_cases) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CasesRunningTotal, dea.population
FROM [Portfolio Project]..['Covid-Vaccinations$'] vac
JOIN [Portfolio Project]..['Covid-deaths$'] dea
	ON vac.location = dea.location
	AND vac.date = dea.date
WHERE dea.continent IS NOT NULL

CREATE VIEW PercentofPopulationVac AS
SELECT *, (CasesRunningtotal/population)*100 AS PercentPopInfec
FROM PercentPopInfecVac

CREATE VIEW PercentofPopwithRunningVac AS
SELECT vax.date, vax.continent, vax.location, vax.new_cases, vax.CasesRunningtotal, vax.people_vaccinated, vax.PercentPopVac, vax.population, 
	  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY vac.location ORDER BY vac.location, vac.date) AS VacRunTotal
FROM [Portfolio Project]..PercentPopInfecVac vax
JOIN [Portfolio Project]..['Covid-Vaccinations$'] vac
	ON vax.location = vac.location
WHERE vax.continent is not null;

--Doing some work creating a tableau presentation and I want the data on vaccinations in a different way

SELECT continent, location, date, total_vaccinations_per_hundred, new_vaccinations
FROM [Portfolio Project]..['Covid-Vaccinations$']
ORDER BY location, date

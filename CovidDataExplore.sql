--Dataset for visualization taken from --https://ourworldindata.org/covid-deaths

--Divided into two tables for exploration ease
select * from PortfolioProject..[CovidVaccinations]
select * from PortfolioProject..[CovidDeaths]


--Exploring CovidDeaths table

--location wise death details on today
select location, [date],total_cases, new_cases, [population] 
from PortfolioProject..[CovidDeaths]
--where cast([date] as date)=cast(getdate() as date)
--where location like '%states'
WHERE LOCATION = 'India'
order by 1 ,2

--Total Case vs Total Deaths
--Liklihood of death if covid infected in my country "India"
select location, [date], total_cases, total_deaths, 
CONVERT(DECIMAL(10,4),(CAST(total_deaths AS float)) / NULLIF(CAST(total_cases AS float),0))*100 AS DeathPercentage
from PortfolioProject..[CovidDeaths]
WHERE LOCATION = 'India'
ORDER BY 1,2

--Total Case vs Population
--percentage of infected people
select location, [date], total_cases, [population],
CONVERT(DECIMAL(10,4),(CAST(total_cases AS float)) / NULLIF(CAST([population] AS float),0))*100 AS PercentageOfPeopleInfected
from PortfolioProject..[CovidDeaths]
WHERE LOCATION = 'India'
ORDER BY 1,2

--Countries having highest infection rate against total population
select location, DATENAME(month,DATE) as month, MAX(CAST(total_cases AS bigint)) AS total_cases, MAX(CAST([population] AS bigint)) AS [population],
MAX(CONVERT(DECIMAL(10,4),(CAST(total_cases AS float)) / NULLIF(CAST([population] AS float),0)))*100 AS PercentageOfPeopleInfected
from PortfolioProject..[CovidDeaths]
WHERE YEAR(DATE) = '2020'
GROUP BY location, [DATE]
ORDER BY PercentageOfPeopleInfected DESC

--Top 10 Countries with highest death count per population
select TOP 10 location, MAX(CAST(total_deaths AS bigint)) AS total_deaths, MAX(CAST([population] AS bigint)) AS [population],
MAX(CONVERT(DECIMAL(10,4),(CAST(total_deaths AS float)) / NULLIF(CAST([population] AS float),0)))*100 AS PercentageOfPeopleDied
from PortfolioProject..[CovidDeaths]
WHERE YEAR(DATE) = '2020'
GROUP BY location
ORDER BY PercentageOfPeopleDied DESC

--Total deaths in each continent where continent is not blank in descending order
Select continent, MAX(CAST(total_deaths AS bigint)) AS TotalDeaths, MAX(CAST([population] AS bigint)) AS [Total Population]
from PortfolioProject..[CovidDeaths]
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeaths DESC

--Total Deaths in each month by year
Select YEAR(date) as [Year], DATENAME(month,[date]) as [Month], MAX(cast(total_cases as BIGINT)) as TotalCases,
MAX(CAST(total_deaths AS BIGINT)) as TotalDeaths, 
(MAX(CAST(total_deaths AS FLOAT)) / NULLIF(MAX(cast(total_cases as FLOAT)),0)) * 100 as DeathPercentage
From PortfolioProject..[CovidDeaths]
GROUP BY [date]

--Total Covid cases vs Total Death percentage all over world
select SUM(CAST(New_Cases AS BIGINT)) as TotalCovidCases, SUM(CAST(Population AS BIGINT)) as TotalPopulation,
(SUM(CAST(New_Cases AS float))) / NULLIF(SUM(CAST([Population] AS float)),0) * 100 as PercentageOfPeopleAffected,
(SUM(CAST(New_Deaths AS float))) / NULLIF((SUM(CAST(New_Cases AS float))),0) * 100 as PercentageOfPeopleDiedDueCovid
From PortfolioProject..[CovidDeaths]
WHERE continent <> ''

--Total Vaccinated people out of total population
select coVac.continent, coVac.location, coVac.[date], [population], new_vaccinations
from PortfolioProject..[CovidVaccinations] coVac
JOIN
PortfolioProject.dbo.[CovidDeaths] coDe
on coVac.location = coDe.location
and coVac.[date] = coDe.[date]
where coVac.continent <> ''
order by 2,3

--Explore Vaccinated People percentage
WITH cte
AS
(select coVac.continent, coVac.location, coVac.[date], [population], new_vaccinations,
SUM(CAST(new_vaccinations AS bigint)) over (PARTITION BY coVac.location) as RollingPeopleVaccinated
from PortfolioProject..[CovidVaccinations] coVac
JOIN
PortfolioProject.dbo.[CovidDeaths] coDe
on coVac.location = coDe.location
and coVac.[date] = coDe.[date]
where coVac.continent <> '')
SELECT *, RollingPeopleVaccinated / NULLIF(CAST(Population as bigint),0) AS VaccinatedPercentage from cte



--Using temp table Performing previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
[Date] datetime,
[Population] numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
select coVac.continent, coVac.location, CONVERT(datetime ,coVac.[date]), CONVERT(bigint, [population]), CONVERT(bigint, new_vaccinations),
SUM(CAST(new_vaccinations AS float)) over (PARTITION BY coVac.location) as RollingPeopleVaccinated
from PortfolioProject..[CovidVaccinations] coVac
JOIN
PortfolioProject.dbo.[CovidDeaths] coDe
on coVac.location = coDe.location
and coVac.[date] = coDe.[date]
where coVac.continent <> ''

SELECT *, RollingPeopleVaccinated / NULLIF(CAST(Population as bigint),0) AS VaccinatedPercentage from #PercentPopulationVaccinated

--Creating view for further use in reporting
CREATE VIEW vw_PercentPopulationInfected AS 
select coVac.continent, coVac.location, coVac.[date], [population], new_vaccinations,
SUM(CAST(new_vaccinations AS bigint)) over (PARTITION BY coVac.location) as RollingPeopleVaccinated
from PortfolioProject..[CovidVaccinations] coVac
JOIN
PortfolioProject.dbo.[CovidDeaths] coDe
on coVac.location = coDe.location
and coVac.[date] = coDe.[date]
where coVac.continent <> ''

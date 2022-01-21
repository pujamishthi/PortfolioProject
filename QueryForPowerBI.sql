CREATE VIEW vw_Total
AS
(
Select SUM(CAST(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(CAST(new_cases as int))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location = 'India'
where continent is not null 
)

drop view if exists vw_table1
CREATE VIEW vw_table1
AS
(
Select dea.continent, dea.location, dea.date, dea.population
, MAX(vac.total_vaccinations) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent <> ''
group by dea.continent, dea.location, dea.date, dea.population
)

--This query will remove some of those location which is not in any continent but not included in above query
--such as European Union is part of europe, world means all locations
CREATE VIEW vw_table2
AS
(
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent = ''
and location not in ('World', 'European Union', 'International')
Group by location
)
 
 --This View contains highest no. of Population infected in each location and percentage of population infected
 drop view if exists vw_table4
 CREATE VIEW vw_table4
AS
(
 Select Location, Population, MAX(CAST(total_cases AS INT)) as HighestInfectionCount,  Max((CAST(total_cases AS FLOAT))/NULLIF(CAST(population AS FLOAT),0))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
)


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac

--View results
SELECT * FROM vw_Total
SELECT * FROM vw_table1
SELECT * FROM vw_table2
SELECT * FROM vw_table3
SELECT * FROM vw_table4


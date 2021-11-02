--SELECT *
--from PortfolioProject..CovidDeaths
--order by 3,4

--SELECT *
--from PortfolioProject..CovidVaccinations
--order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

-- Looking at total Cases vs total deaths
-- Shows likelihood of dying if you infected in Indonesia
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathPercentage
from PortfolioProject..CovidDeaths
where location like '%indo%'
order by 1,2

-- Looking at total cases vs population
-- Percentage of population got covid
select location, date, total_cases, population, (total_cases/population)*100 as percentPopulationInfected
from PortfolioProject..CovidDeaths
where location like '%indo%'
order by 1,2

-- Country with highest infection rate compared to Population
select location, population, MAX(total_cases) as highestInfectionCount, MAX(total_cases/population)*100 as percentPopulationInfected
from PortfolioProject..CovidDeaths
group by location, population
order by percentPopulationInfected desc


-- Country with highest death count per population
-- cast karena jika tanpa cast data type tidak sama
select location, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null -- that's because there're Asia, World, South America, etc.
group by location
order by highestDeathCount desc

-- Break Things down by continent
select continent, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null 
group by continent
order by highestDeathCount desc --North America only takes it from US, thats not correct

select location, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
where continent is null 
group by location
order by highestDeathCount desc --This is the correct number, lol

--Showing continents with highest death count 
select continent, MAX(cast(total_deaths as int)) as highestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null 
group by continent
order by highestDeathCount desc


--Total death per day (agregate all country)
select date, SUM(total_cases) --total_deaths, (total_deaths/total_cases)*100 as deathPercentage
from PortfolioProject..CovidDeaths
--where location like '%indo%'
where continent is not null
group by date
order by 1,2

--Totalcases, totaldeath, and percentage accross the world
select date, SUM(new_cases) as totalCases, SUM(cast(new_deaths as int)) as totalDeath, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage --because totaldeaths is var char
from PortfolioProject..CovidDeaths
--where location like '%indo%'
where continent is not null
group by date
order by 1,2

--Totalcases, totaldeath, and percentage accross the world without group by date
select SUM(new_cases) as totalCases, SUM(cast(new_deaths as int)) as totalDeath, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage --because totaldeaths is var char
from PortfolioProject..CovidDeaths
--where location like '%indo%'
where continent is not null
order by 1,2

--TotalDeath count per benua
select location, SUM(cast(new_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is null and location not in ('World', 'European Union', 'International')
group by location
order by TotalDeathCount desc

-- COVID VACCINATIONS

-- Looking at Total Population vs Vaccinations (SUCKS)

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
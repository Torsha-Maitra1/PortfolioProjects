select * from 
project..CovidDeaths
where continent is not null
order by 3,4;

--select * from 
--project..CovidVaccinations
--order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from project..CovidDeaths
order by 1,2;

-- Looking at Total Cases vs Total Deaths

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from project..CovidDeaths
where location like '%india'
order by 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

select location, date, total_cases, population, (total_cases/population)*100 as CasePercentage
from project..CovidDeaths
where location like '%india'
order by 1,2;

-- Looking at Counties with Highest Infection Rate compared to Population

select location, 
	   population, 
	   max(total_cases) as HighestInfectionCount, 
	   max((total_cases/population))*100 as PercentPopulationInfected
from project..CovidDeaths
group by location, population
order by PercentPopulationInfected desc; 

-- Showing Countries with Highest Death Count per Population

select location,max(cast(total_deaths as int)) as TotalDeathCount
from project..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc;

-- Breaking Things Down by Continent

select continent ,max(cast(total_deaths as int)) as TotalDeathCount
from project..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;

-- Showing Continents with the Highest Death Counts

select continent ,max(cast(total_deaths as int)) as TotalDeathCount
from project..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc;

-- Global Numbers

select 
	   sum(new_cases) as total_cases, 
	   sum(cast(new_deaths as int)) as total_deaths,
	   sum(cast(new_deaths as int))/sum(new_cases)*100 as TotalDeathPercentage
from project..CovidDeaths
where continent is not null
--group by date
order by 1,2;

-- Looking at Total Population vs Vaccination

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) as
				RollingPeopleVaccinated
from project..CovidDeaths dea
join project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3;

-- Using CTE

with PopvsVac as ( 
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) as
				RollingPeopleVaccinated
from project..CovidDeaths dea
join project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null )
select *,
	   (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPerc
from PopvsVac;

-- Temp Table

drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
);

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) as
				RollingPeopleVaccinated
from project..CovidDeaths dea
join project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

select *,
	   (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinatedPerc
from #PercentPopulationVaccinated;

-- Creating View to Store Data For Visualisation

drop view if exists PercentagePopulationVaccinated;

create view PercentagePopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location, dea.date) as
				RollingPeopleVaccinated
from project..CovidDeaths dea
join project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

select * from PercentagePopulationVaccinated;
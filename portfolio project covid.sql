/*

Worldwide Coronavirus Data Exploration Project
Skills Utilized: Joins, CTE's, Temp Tables, 
Windows Functions/Partitions, Aggregate Functions, 
Creating Views, Converting Data Types

*/

--Select data that will be using to explore. 

SELECT * FROM
[Portfolio Project Covid Analysis]..CovidVaccinations
order by 3,4 

SELECT * FROM
[Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
order by 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
order by 1,2

--Calculating Total Cases Vs. Total Deaths (% of People who Died compared to Amount of Cases)
--Used an alias to identify new column information. 

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
order by 1,2

--Making the search U.S. location specific, with use of where statement. 
--This shows the chances of dying if you contract COVID-19 now in the U.S., a 1.11% chance.

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where location like '%states%' and continent is not null
order by 1,2

--Calculating Total Cases Vs. Population (% of People who had confirmed COVID-19 compared to Population)

SELECT Location, date, total_cases, population, (total_cases/population)*100 as Infected_Population
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
order by 1,2

--Location specific, U.S.

SELECT Location, date, total_cases, population, (total_cases/population)*100 as Infected_Population
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where location like '%states%' and continent is not null
order by 1,2

--Calculating Highest Percentage of Infection in Countries by Population (% of total cases to Population)
--Countries with the highest percentage of infection to lowest percentage.
--Group by statement to sort like information into categories. 

SELECT Location, population, MAX(total_cases) as Highest_Infected_Percentage_Countries,
MAX((total_cases/population))*100 as Infected_Population
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
GROUP by Location, population
order by Infected_Population desc

--Ordering Countries by Highest Death Count, with altered data type by casting. 

SELECT Location, MAX(cast(total_deaths as int)) as Highest_Death_Count
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null and location is not null
GROUP by Location
order by Highest_Death_Count desc

--Calculating Highest Percentage of Death in Countries by Population (% of total deaths to Population)

SELECT Location, population, MAX(total_deaths) as Death_Count,
MAX((total_deaths/population))*100 as Highest_Death_Percentage_Countries
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null and location is not null
GROUP by Location, population
order by Highest_Death_Percentage_Countries desc

--Ordering continents by highest death count. 

SELECT continent, MAX(cast(total_deaths as int)) as Continent_Deaths_Count
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
GROUP by continent
order by Continent_Deaths_Count desc

--Global Number of Total Cases by Date

Select date, SUM(new_cases)
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Global Number of Total Death by Date

Select date, SUM(cast(new_deaths as int))
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Global Death Percentage by Date

Select date, SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) as Deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Global_Death_Percentage
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
Group by date
order by 1,2

--Total Global Death Percentage 

Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Total_Global_Death_Percentage
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
order by 1,2

--Using Joins for tables Covid Deaths and Covid Vaccinations, on columns location and date, to preview data.

SELECT *
FROM [Portfolio Project Covid Analysis]..CovidDeaths death
JOIN [Portfolio Project Covid Analysis]..CovidVaccinations vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null

--Setting up Total Vaccinations vs. Population (what percentage of the population by country is vaccinated)
--Using partition function to count consecutively.


SELECT death.continent, death.location, death.date, death.population, 
vacc.new_vaccinations, SUM(Cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by death.location Order by death.location, death.date) 
	as Continuous_Count_Vaccinated
FROM [Portfolio Project Covid Analysis]..CovidDeaths death
JOIN [Portfolio Project Covid Analysis]..CovidVaccinations vacc
	on death.location = vacc.location
	and death.date = vacc.date
--where death.continent is not null
Order by 2,3

--Utilizing CTE (Common Table Expression / Temp Table) for referencing and formula completion.
--Complete Total Vaccinations vs. Population by Country

With PopulationvsVaccination (Continent, Location, Date, Population, new_vaccinations,
Continuous_Count_Vaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, 
vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by death.location Order by death.location, death.date) 
	as Continuous_Count_Vaccinated
FROM [Portfolio Project Covid Analysis]..CovidDeaths death
JOIN [Portfolio Project Covid Analysis]..CovidVaccinations vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
--order by 2,3
)
Select *, (Continuous_Count_Vaccinated/Population)*100 as Total_Continous_Population_Vaccinated_PerCountry
FROM PopulationvsVaccination

--Alternative choice for completing Total Vaccinations vs. Population by Country
--Temp Table

DROP Table if exists #PopulationCountVaccinated
Create Table #PopulationCountVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
Continuous_Count_Vaccinated numeric)

Insert into #PopulationCountVaccinated
SELECT death.continent, death.location, death.date, death.population, 
vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by death.location Order by death.location, death.date) 
	as Continuous_Count_Vaccinated
FROM [Portfolio Project Covid Analysis]..CovidDeaths death
JOIN [Portfolio Project Covid Analysis]..CovidVaccinations vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
--order by 2,3

Select *, (Continuous_Count_Vaccinated/Population)*100 as Total_Continous_Population_Vaccinated_PerCountry
FROM #PopulationCountVaccinated

--Creating Views for Visualizations


--VIEW ONE

/*Create View PopulationCountVaccinated as
SELECT death.continent, death.location, death.date, death.population, 
vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by death.location Order by death.location, death.date) 
	as Continuous_Count_Vaccinated
	--(Continuous_Count_Vaccinated/population)*100
FROM [Portfolio Project Covid Analysis]..CovidDeaths death
JOIN [Portfolio Project Covid Analysis]..CovidVaccinations vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null*/

--VIEW TWO (percentage)

/*Create View Total_Continous_Population_Vaccinated_PerCountry as 
With PopulationvsVaccination (Continent, Location, Date, Population, new_vaccinations,
Continuous_Count_Vaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, 
vacc.new_vaccinations, SUM(cast(vacc.new_vaccinations as bigint)) 
OVER (Partition by death.location Order by death.location, death.date) 
	as Continuous_Count_Vaccinated
FROM [Portfolio Project Covid Analysis]..CovidDeaths death
JOIN [Portfolio Project Covid Analysis]..CovidVaccinations vacc
	on death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
--order by 2,3
)
Select *, (Continuous_Count_Vaccinated/Population)*100 as Total_Continous_Population_Vaccinated_PerCountry
FROM PopulationvsVaccination*/

--VIEW THREE

/*Create View Total_Global_Death_Percentage as 
Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/
SUM(new_cases)*100 as Total_Global_Death_Percentage
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
--order by 1,2*/

--VIEW FOUR

/*Create View Global_Death_Percentage_By_Date as
Select date, SUM(new_cases) as Cases, SUM(cast(new_deaths as int)) as Deaths, SUM(cast(new_deaths as int))/
SUM(new_cases)*100 as Global_Death_Percentage
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
Group by date
--order by 1,2*/

--VIEW FIVE

/*Create View Global_Number_of_Total_Death_By_Date as
Select date, SUM(cast(new_deaths as int)) as death_count
FROM [Portfolio Project Covid Analysis]..CovidDeaths
where continent is not null
Group by date
--order by 1,2*/
SET SEARCH_PATH TO HousePrices;

\pset format wrapped


-- ====================== Housing and Population's relationship ===================
-- Label: Population Housing 1
-- Total population in a county
DROP VIEW IF EXISTS CountyPopulation CASCADE;
CREATE VIEW CountyPopulation (county, total_population) AS
	SELECT county, SUM(population) as total_population
	FROM CityInfo
	GROUP BY county;

-- Label: Population Housing 2
-- combine population with land area and housing info, sort it by increasing housing prices
DROP VIEW if exists PopulationAndHousing CASCADE;
CREATE VIEW PopulationAndHousing (county, total_population, land_area, population_density, 
	median_house_prices) AS 
	SELECT county, total_population, land_area, total_population/land_area AS population_density, 
	median_house_prices
	FROM CountyPopulation
	NATURAL JOIN CountyLandArea
	NATURAL JOIN CaliforniaHousing
	ORDER BY median_house_prices;

-- Label: Population Housing 3
-- Add a column for rounded housing prices
DROP VIEW if exists PopulationHousingRounded CASCADE;
CREATE VIEW PopulationHousingRounded (county, total_population, land_area, population_density, 
	median_house_prices, rounded_house_price) AS 
	SELECT county, total_population, land_area, population_density, median_house_prices, 
	round(median_house_prices, -5) AS rounded_house_price
	FROM PopulationAndHousing;

-- Label: Population Housing 4
-- Get the average population density
DROP VIEW if exists PopulationHousingAvg CASCADE;
CREATE VIEW PopulationHousingAvg (avg_population_density, rounded_house_price, counties) AS 
	SELECT AVG(population_density) as avg_population_density, rounded_house_price,
	array_agg(county) AS counties
	FROM PopulationHousingRounded
	GROUP BY rounded_house_price
	ORDER BY rounded_house_price;

-- Label: Population Housing 5
-- Seeing the final results of population on Housing
select * from PopulationHousingAvg;



-- ======================== Housing and Crime's Relationship ======================
-- Label: Crime Housing 1
-- Crime rates and housing, have them in order(increasing house prices)
DROP VIEW if exists CrimeAndHousing CASCADE;
CREATE VIEW CrimeAndHousing (county, median_house_prices,violent_crimes,property_crimes) AS
	SELECT county, median_house_prices, violent AS violent_crimes, property AS property_crimes
	FROM CrimeCounts 
	NATURAL JOIN CaliforniaHousing
	ORDER BY median_house_prices;

-- Label: Crime Housing 2
-- Round the median house prices and put them in a new column
DROP VIEW if exists CrimeHousingRounded CASCADE;
CREATE VIEW CrimeHousingRounded (county, median_house_prices,violent_crimes,property_crimes,
	rounded_house_price) AS
	SELECT county, median_house_prices, violent_crimes,property_crimes , 
	round(median_house_prices, -5) AS rounded_house_price
	FROM CrimeAndHousing;

-- Label: Crime Housing 3
-- Group by roundedHousePrice and see their average violent and property crimes
DROP VIEW if exists AvgCrimeHousing CASCADE;
CREATE VIEW AvgCrimeHousing ( avg_violent_crimes, avg_property_crimes,rounded_house_price,counties) AS
	SELECT  AVG(violent_crimes) as avg_violent_crimes, 
	AVG(property_crimes ) as avg_property_crimes, rounded_house_price,
	array_agg(county) AS counties
	FROM CrimeHousingRounded
	GROUP BY rounded_house_price
	ORDER BY rounded_house_price;

-- Label: Crime Housing 4
select * from AvgCrimeHousing;

-- Label: Crime Housing 5
-- Looking at the enforcement employees working for the safety of their citzens:
DROP VIEW if exists EnforcementInCountyHousing CASCADE;
CREATE VIEW EnforcementInCountyHousing (county, median_house_prices,enforce_employees,
	total_officers, total_civilians) AS
	SELECT county, median_house_prices,enforce_employees,total_officers, total_civilians
	FROM CrimesInCounty 
	NATURAL JOIN CaliforniaHousing
	ORDER BY median_house_prices;

-- Label: Crime Housing 6
-- Again rounding the housing prices
DROP VIEW if exists EnforcementInCountyHousingRounded CASCADE;
CREATE VIEW EnforcementInCountyHousingRounded (county, median_house_prices,enforce_employees,
	total_officers, total_civilians, rounded_house_price) AS
	SELECT county, median_house_prices,enforce_employees,total_officers, total_civilians, 
	round(median_house_prices, -5) AS rounded_house_price
	FROM EnforcementInCountyHousing;

-- Label: Crime Housing 7
-- Group by rounded prices and observe the avg num of employees across those counties with 
-- the same average housing prices.
DROP VIEW if exists AvgEnforcementHousing CASCADE;
CREATE VIEW AvgEnforcementHousing (counties,enforce_employees,
	total_officers, total_civilians, rounded_house_price) AS
	SELECT array_agg(county) AS counties,avg(enforce_employees) as avg_enf_emp,
	avg(total_officers) as avg_total_officers, avg(total_civilians) as avg_total_civilians, 
	rounded_house_price
	FROM EnforcementInCountyHousingRounded
	GROUP BY rounded_house_price
	ORDER BY rounded_house_price;

-- Label: Crime Housing 8
select * from AvgEnforcementHousing;



-- =========== Housing prices and air quality ====================
-- Label: AirQuality 1
-- the air quality of each county, order by average of AQI, lower AQI 
-- average means better air quality
DROP VIEW IF EXISTS CountyAirQuality CASCADE;
create view CountyAirQuality as 
select county, avg(finePMMean) as avgPM, avg(dailyAQI) as avgAQI
from AirQuality 
group by county
order by (avgAQI);

-- Label: AirQuality 2
-- table for how severe are the wildfires in each county
DROP VIEW IF EXISTS CountyWildfireDamage CASCADE;
create view CountyWildfireDamage as 
select county, count(name) as numWildfire, 
	avg(acresAffected) as avgAcresAffected,
	avg(injuries) as avgInjuries,
	cast(sum(injuries) as decimal) / cast(sum(acresAffected) as decimal)
	as injPerAcre
from Wildfire 
group by county
order by (avgAcresAffected);

-- Label: AirQuality 3
-- how wildfire affect the air quality
DROP VIEW IF EXISTS CountyWildfireAir CASCADE;
create view CountyWildfireAir as 
select county, numWildfire, avgAcresAffected, 
	avgInjuries, avgPM, avgAQI
from CountyAirQuality join CountyWildfireDamage using(county)
order by avgAQI;

-- Label: AirQuality 4
select * 
from CountyWildfireAir
order by avgAQI
limit 5;

-- Label: AirQuality 5
-- the average AQI across all counties
select avg(avgAQI) as avgCaliforniaAQI 
from CountyWildfireAir;

-- Label: AirQuality 6
-- the housing price relating wildfire and air quality
DROP VIEW IF EXISTS CountyHousingWrtAir CASCADE;
create view CountyHousingWrtAir as
select county, median_house_prices as medianHousePrices, numWildfire, 
	avgAcresAffected, avgAQI
from CaliforniaHousing join CountyWildfireAir using(county)
order by medianHousePrices DESC;

-- Label: AirQuality 7
-- top 5 counties with highest housing price
select * from CountyHousingWrtAir
order by medianHousePrices DESC
limit 5;

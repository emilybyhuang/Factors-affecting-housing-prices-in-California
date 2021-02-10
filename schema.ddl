-- Schema for California housing data and data of some other factors that may 
-- affect the housing prices, such as crime rates, air quality, wildfire, and
-- population density

drop schema if exists HousePrices cascade;  
create schema HousePrices;  
set search_path to HousePrices;  
  
CREATE DOMAIN LON as float  
        not null  
        check(value >= -124.6509 and value < -114.1315);  

CREATE DOMAIN LAT as float  
        not null  
        check(value >= 32.5121 and value < 42.0126);  


CREATE DOMAIN POP as integer  
        check(value >= 0);  

CREATE DOMAIN RATES as integer  
        not null  
        check(value >= 0);   


-- list of all cities in california
DROP TABLE IF EXISTS CaliforniaCities;
CREATE TABLE CaliforniaCities(    
    -- the name of the city
    cityName varchar(50) primary key,
    -- land area of the city
    land_area_raw varchar(50),
    land_area float,
    -- date of incorporation of city
    incorporation_date varchar(20)
);  

-- the land area of a county
DROP TABLE IF EXISTS CountyLandArea;
CREATE TABLE CountyLandArea(
    -- the population of the county (text version)
    county_population_raw varchar(100),
    -- the land area of the county (text version)
    land_area_raw varchar(100),
    county varchar(50),
    -- the land area of the county (number version)
    land_Area float,
PRIMARY KEY(county));

-- for the city info: county of which it belongs, population of the city...
DROP TABLE IF EXISTS CityInfo;
CREATE TABLE CityInfo (  
        -- county of which the city belongs
        county varchar(50),  
        cityName varchar(50), 
        -- population 
        population POP,
        -- latitude and longitude  
        latitude LAT,  
        longitude LON,  
PRIMARY KEY(cityName, county),  
FOREIGN KEY (cityName) references CaliforniaCities(cityName)); 

-- the housing price of a county
DROP TABLE IF EXISTS CaliforniaHousing;
CREATE TABLE CaliforniaHousing(
    county varchar(50),
    -- the median house prices of the county (text version)
    median_house_prices_raw varchar(100),
    -- the median house prices of the county (int version)
    median_house_prices int,
    PRIMARY KEY(county),
    FOREIGN KEY (county) references CountyLandArea(county)
);

-- crime enforcement of a county
DROP TABLE IF EXISTS CrimesInCounty;
CREATE TABLE CrimesInCounty (  
    county varchar(50),  
    -- total number of enforcement employees
    enforce_employees integer,
    -- total number of officers  
    total_officers integer,  
    -- total number of civilians
    total_civilians integer,
    PRIMARY KEY(county),
    FOREIGN KEY (county) references CountyLandArea(county)
);  

-- the count of different types of crimes for a county  
DROP TABLE IF EXISTS CrimeCounts;
CREATE TABLE CrimeCounts(  
    county varchar(50), 
    -- number of violent crimes 
    violent float,
    -- number of murders  
    murder float,  
    -- number of rapes
    rape float,  
    -- number of robbery
    robbery float,
    -- number of aggrevated assault  
    aggrevated_assault float,  
    -- number of property crime
    property float,  
    -- number of burglary
    burglary float,  
    -- number of vehicle theft
    vehicle_theft float,  
    -- number of larcency
    larceny_theft float,  
    -- total crime count
    total float,  
    primary key(county),  
    FOREIGN KEY (county) references CountyLandArea(county)
);  

-- the daily air quality of the counties
DROP TABLE IF EXISTS AirQuality;
CREATE TABLE AirQuality (  
    county varchar(50),
    -- the date that the air quality is recorded  
    date varchar(30),  
    -- the concentration of PM2.5
    finePMMean float NOT NULL, 
    -- the AQI on this day 
    dailyAQI integer NOT NULL,  
    primary key (county, date),
    FOREIGN KEY (county) references CountyLandArea(county) 
    
);  

-- An wildfire that happened in California
DROP TABLE IF EXISTS WildFire; 
CREATE TABLE WildFire(  
    -- the name of this wildfire
    name varchar(100) PRIMARY KEY,
    -- the county that this wildfire happened  
    county varchar(50),  
    -- the acres affected by this wildfire
    acresAffected integer NOT NULL, 
    -- the injuries caused by this wildfire 
    injuries integer  
);  

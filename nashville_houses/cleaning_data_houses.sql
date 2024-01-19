-- find out what the columns from table
SELECT 
	*
FROM data_housing.dbo.data_houses;

-- 1. standarize data format
--- Since setting doesn't work cause the convert may do before imported data, so I decide to begin with ALTER TABLE
ALTER TABLE data_houses
Add SalesDataConverted Date;

UPDATE data_houses
SET SalesDataConverted = CONVERT(Date, SaleDate)

SELECT
	SalesDataConverted, 
	CONVERT(date, SaleDate)
FROM
	data_housing.dbo.data_houses;

-- 2. Populate property address data

SELECT
	*
FROM
	data_housing.dbo.data_houses; 

--- When the parcel ID are quoted twice, then property address will be exactly same as before.
SELECT 
	x.ParcelID, 
	x.PropertyAddress, 
	y.ParcelID,
	y.PropertyAddress
	ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM data_housing.dbo.data_houses x
JOIN data_housing.dbo.data_houses y
	ON x.ParcelID = y.ParcelID
	AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress IS NULL;

--- UPDATE the case with query that It's working on before.
UPDATE x
SET PropertyAddress = ISNULL(x.PropertyAddress, y.PropertyAddress)
FROM data_housing.dbo.data_houses x
JOIN data_housing.dbo.data_houses y
	ON x.ParcelID = y.ParcelID
AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress IS NULL;

--- Check the Property Address column
SELECT
	PropertyAddress
FROM 
	data_housing.dbo.data_houses
WHERE 
	PropertyAddress IS NULL;

-- 3. Breaking out address into individual column (Address, city) in column PropertyAddress
SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM   
	data_housing.dbo.data_houses;

--- same as bofre, I create a column with ALTER because UPDATE doesn't work if running after import data. 
ALTER TABLE data_houses
Add AddressSplit NVARCHAR(255)

UPDATE data_houses
SET AddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE data_houses
Add PropertyCity NVARCHAR(255)

UPDATE data_houses
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

---Check the column AddressSplit and PropertyCity
SELECT
	PropertyAddress,
	AddressSplit,
	PropertyCity
FROM
	data_housing.dbo.data_houses


-- 4. Breaking out address into individual column (Address, city, State) in column OwnerAddress
SELECT
	OwnerAddress
FROM
	data_housing.dbo.data_houses
--- with PARSENAME
SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM
	data_housing.dbo.data_houses

--- Create column and update the value
ALTER TABLE data_houses
ADD
	OwnerStreet NVARCHAR(255),
	OwnerCity NVARCHAR(255),
	OwnerState NVARCHAR(255);

UPDATE data_houses
SET
	OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 

--- check the columns
SELECT
	OwnerAddress,
	OwnerStreet,
	OwnerCity,
	OwnerState
FROM
	data_housing.dbo.data_houses


-- 5. Find out how the differ each value in column SoldasVacant
SELECT
	DISTINCT(SoldasVacant)
FROM
	data_housing.dbo.data_houses;

--- Update the table N for No and Y for Yes
SELECT
	SoldasVacant,
	CASE 
		WHEN SoldasVacant = 'Y' THEN 'Yes'
		WHEN SoldasVacant = 'N' THEN 'No'
		ELSE SoldasVacant
	END
FROM
	data_housing.dbo.data_houses;

UPDATE data_houses
SET SoldasVacant = CASE 
		WHEN SoldasVacant = 'Y' THEN 'Yes'
		WHEN SoldasVacant = 'N' THEN 'No'
		ELSE SoldasVacant
	END;

--- check the column again
SELECT
	DISTINCT(SoldasVacant),
	COUNT(SoldasVacant)
FROM 
	data_housing.dbo.data_houses
GROUP BY
	SoldasVacant
ORDER BY
	2; 

-- 6. Remove Duplicates
---CREATE CTE FIRST
WITH CheckDupliWithCTE AS(
SELECT 
	*,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID) row_num
FROM data_housing.dbo.data_houses
)

DELETE 
FROM
	CheckDupliWithCTE
WHERE
	row_num > 1;
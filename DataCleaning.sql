create database project_sql;

use project_sql;

-- Looking at the data

select * from NashvilleHousing;

-- Standardize Date Format

alter table NashvilleHousing
add SaleDateConverted Date;

Update NashvilleHousing
set SaleDateConverted = convert(date, saledate);

select SaleDate, SaleDateConverted
from NashvilleHousing;

-- Populate Property Address Data

select a.ParcelID, 
	   a.PropertyAddress, 
	   b.ParcelID, 
	   b.PropertyAddress,
	   Coalesce(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a 
join NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null; 

update a
set PropertyAddress = Coalesce(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a 
join NashvilleHousing b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null; 

-- Breaking out Address into Individual Columns (Address, City, State)

Select substring(propertyaddress, 1, charindex(',', propertyaddress)-1) as address,
	   substring(propertyaddress,charindex(',', propertyaddress)+1, len(propertyaddress)) as city
from NashvilleHousing;

alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = substring(propertyaddress, 1, charindex(',', propertyaddress)-1);

alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = substring(propertyaddress,charindex(',', propertyaddress)+1, len(propertyaddress));

-- Populate Owner Address Data

Select parsename(replace(owneraddress,',','.'),3),
	   parsename(replace(owneraddress,',','.'),2),
	   parsename(replace(owneraddress,',','.'),1)
from NashvilleHousing;
	   
alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress = parsename(replace(owneraddress,',','.'),3);

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update NashvilleHousing
set OwnerSplitCity = parsename(replace(owneraddress,',','.'),2);

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitState = parsename(replace(owneraddress,',','.'),1);

-- Change Y and N to Yes and No in "Sold as Vacant" Field

select soldasvacant, count(soldasvacant)
from NashvilleHousing
group by SoldAsVacant;

select soldasvacant,
	   case when soldasvacant = 'Y' then 'Yes'
	        when soldasvacant = 'N' then 'No'
	        else soldasvacant
		end
from NashvilleHousing;

update NashvilleHousing
set SoldAsVacant = case when soldasvacant = 'Y' then 'Yes'
	        when soldasvacant = 'N' then 'No'
	        else soldasvacant
		end;


-- Remove Duplicates

with rownumcte as( select *,
	   row_number() over(partition by ParcelID,
									  PropertyAddress,
									  SalePrice,
									  SaleDate,
									  LegalReference
						 order by uniqueID) as row_num
from NashvilleHousing
--order by ParcelID 
)
--delete 
select *
from rownumcte
where row_num >1;



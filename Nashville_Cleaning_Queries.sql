-- Standardize Date Format
UPDATE "PortfolioProject"."dbo"."NashvilleHousing"
SET "SaleDate" = TO_DATE("SaleDate", 'YYYY-MM-DD');

-- If it doesn't Update properly
ALTER TABLE "PortfolioProject"."dbo"."NashvilleHousing"
ADD "SaleDateConverted" DATE;

UPDATE "PortfolioProject"."dbo"."NashvilleHousing"
SET "SaleDateConverted" = TO_DATE("SaleDate", 'YYYY-MM-DD');

-- Populate Property Address data
UPDATE "PortfolioProject"."dbo"."NashvilleHousing" AS a
SET "PropertyAddress" = COALESCE(a."PropertyAddress", b."PropertyAddress")
FROM "PortfolioProject"."dbo"."NashvilleHousing" AS b
WHERE a."ParcelID" = b."ParcelID" AND a."UniqueID" <> b."UniqueID" AND a."PropertyAddress" IS NULL;

-- Breaking out Address into Individual Columns (Address, City, State)
ALTER TABLE "PortfolioProject"."dbo"."NashvilleHousing"
ADD "PropertySplitAddress" VARCHAR(255),
    "PropertySplitCity" VARCHAR(255);

UPDATE "PortfolioProject"."dbo"."NashvilleHousing"
SET "PropertySplitAddress" = SUBSTRING("PropertyAddress", 1, POSITION(',' IN "PropertyAddress") - 1),
    "PropertySplitCity" = SUBSTRING("PropertyAddress", POSITION(',' IN "PropertyAddress") + 1);

-- Split OwnerAddress into Address, City, and State
ALTER TABLE "PortfolioProject"."dbo"."NashvilleHousing"
ADD "OwnerSplitAddress" VARCHAR(255),
    "OwnerSplitCity" VARCHAR(255),
    "OwnerSplitState" VARCHAR(255);

UPDATE "PortfolioProject"."dbo"."NashvilleHousing"
SET "OwnerSplitAddress" = SPLIT_PART("OwnerAddress", ',', 3),
    "OwnerSplitCity" = SPLIT_PART("OwnerAddress", ',', 2),
    "OwnerSplitState" = SPLIT_PART("OwnerAddress", ',', 1);

-- Change Y and N to Yes and No in "Sold as Vacant" field
UPDATE "PortfolioProject"."dbo"."NashvilleHousing"
SET "SoldAsVacant" = CASE
    WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
    WHEN "SoldAsVacant" = 'N' THEN 'No'
    ELSE "SoldAsVacant"
END;

-- Remove Duplicates
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY "ParcelID",
                            "PropertyAddress",
                            "SalePrice",
                            "SaleDate",
                            "LegalReference"
               ORDER BY "UniqueID"
           ) AS row_num
    FROM "PortfolioProject"."dbo"."NashvilleHousing"
)
DELETE FROM "PortfolioProject"."dbo"."NashvilleHousing"
WHERE ("ParcelID", "PropertyAddress", "SalePrice", "SaleDate", "LegalReference", row_num) IN (
    SELECT "ParcelID", "PropertyAddress", "SalePrice", "SaleDate", "LegalReference", row_num
    FROM RowNumCTE
    WHERE row_num > 1
);

-- Delete Unused Columns
ALTER TABLE "PortfolioProject"."dbo"."NashvilleHousing"
DROP COLUMN "OwnerAddress", "TaxDistrict", "PropertyAddress", "SaleDate";


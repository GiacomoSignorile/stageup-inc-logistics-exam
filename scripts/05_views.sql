-- 1. VIEW: Geographic Structure - Regions with Municipalities
CREATE OR REPLACE VIEW ViewRegionMunicipalities AS
SELECT
    r.RegionCode,
    r.RegionName,
    m.MunicipalityCode,
    m.MunicipalityName
FROM
    Region_TAB r
    LEFT JOIN Municipality_TAB m ON DEREF(m.RegionRef).RegionCode = r.RegionCode
ORDER BY
    r.RegionCode, m.MunicipalityCode;
/

-- 2. VIEW: Setup Team Members
-- This view unpacks (unnests) the VARRAY of members inside the Team_TAB.
-- This shows the Professor you know how to query collections.
CREATE OR REPLACE VIEW ViewTeamMembers AS
SELECT
    t.TeamCode,
    t.TeamName,
    t.N_Total_Installations,
    DEREF(t.RegionRef).RegionName AS AssignedRegion,
    DEREF(t.OfficeRef).Name AS AssignedOffice,
    m.TaxCode AS MemberTaxCode,
    m.FirstName AS MemberFirstName,
    m.LastName AS MemberLastName
FROM
    Team_TAB t,
    TABLE(CAST(t.Members AS Member_VA)) m;
/

-- 3. VIEW: Customer Locations
-- This view navigates the REF from Location_TAB back to Customer_TAB.
-- It also unpacks the Address_t object into flat columns.
CREATE OR REPLACE VIEW ViewCustomerLocations AS
SELECT
    DEREF(l.OwnerRef).CustomerCode AS CustomerCode,
    DEREF(l.OwnerRef).CustomerType AS CustomerType,
    l.LocationCode,
    l.Address.City AS City,
    l.Address.Street AS Street,
    l.Address.ZipCode AS ZipCode,
    l.SetupTimeEstimate,
    l.EquipmentCapacity
FROM
    Location_TAB l;
/

-- 4. VIEW: Full Booking Details
-- This view navigates MULTIPLE REFs (Booking -> Location -> Customer)
-- and (Booking -> Office) to create a complete report of an operation.
CREATE OR REPLACE VIEW ViewBookingDetails AS
SELECT
    b.BookingID,
    b.BookingType,
    b.BookingDate,
    b.Duration,
    b.TotalCost,
    b.PlacementMode,
    DEREF(b.HandledBy).Name AS HandlingOffice,
    DEREF(b.HandledBy).OfficeType AS OfficeType,
    DEREF(b.AssignedTeam).TeamCode AS HandlingTeamCode,
    DEREF(b.AssignedTeam).TeamName AS HandlingTeam,
    DEREF(b.AtLocation).LocationCode AS DestinationLocation,
    DEREF(b.AtLocation).Address.City AS DestinationCity,
    -- Chaining DEREFs to get the Customer Code from the Location
    DEREF(DEREF(b.AtLocation).OwnerRef).CustomerCode AS OrderedByCustomer
FROM
    Booking_TAB b;
/

-- 5. VIEW: Regional Office Overview
-- Unpacks the Address_t object for the company's own offices and depots.
CREATE OR REPLACE VIEW ViewCompanyOffices AS
SELECT
    o.Name AS OfficeName,
    o.OfficeType,
    o.NoEmployees,
    o.Location.City AS City,
    o.Location.Province AS Province,
    o.Location.ZipCode AS ZipCode
FROM
    Office_TAB o;
/

-- 6. VIEW: Central Office Booking Overview
-- Shows all bookings handled by the Central Office
CREATE OR REPLACE VIEW ViewCentralOfficeBookings AS
SELECT
    bd.BookingID,
    bd.BookingType,
    bd.BookingDate,
    bd.Duration,
    bd.TotalCost,
    bd.PlacementMode,
    bd.DestinationLocation,
    bd.DestinationCity,
    bd.OrderedByCustomer
FROM
    ViewBookingDetails bd
WHERE
    bd.OfficeType = 'Central';
/

-- 7. VIEW: Depot Operational Reports
-- Shows teams by depot/region for operational planning
CREATE OR REPLACE VIEW ViewDepotTeamAssignments AS
SELECT
    DEREF(t.OfficeRef).Name AS Depot,
    DEREF(t.RegionRef).RegionName AS Region,
    t.TeamCode,
    t.TeamName,
    t.N_Total_Installations,
    (
        SELECT COUNT(*)
        FROM TABLE(CAST(t.Members AS Member_VA)) m
    ) AS TeamSize
FROM
    Team_TAB t
WHERE
    DEREF(t.OfficeRef).OfficeType = 'Depot'
ORDER BY
    Depot, TeamCode;
/

-- 8. VIEW: Customer Activity Report
-- Aggregates data to show how much money each customer has spent
-- (Useful for the Data Warehouse / Business Intelligence part of the exam)
CREATE OR REPLACE VIEW ViewCustomerActivity AS
SELECT 
    OrderedByCustomer AS CustomerCode,
    COUNT(BookingID) AS TotalBookings,
    SUM(TotalCost) AS TotalRevenueGenerated
FROM 
    ViewBookingDetails
GROUP BY 
    OrderedByCustomer;
/
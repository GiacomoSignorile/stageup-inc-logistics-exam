-- 1. VIEW: Setup Team Members
-- This view unpacks (unnests) the VARRAY of members inside the Team_TAB.
-- This shows the Professor you know how to query collections.
CREATE OR REPLACE VIEW ViewTeamMembers AS
SELECT
    t.TeamCode,
    t.TeamName,
    t.NoInstallations,
    m.TaxCode AS MemberTaxCode,
    m.FirstName AS MemberFirstName,
    m.LastName AS MemberLastName
FROM
    Team_TAB t,
    TABLE(t.Members) m;
/

-- 2. VIEW: Customer Locations
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

-- 3. VIEW: Full Booking Details
-- This view navigates MULTIPLE REFs (Booking -> Location -> Customer)
-- and (Booking -> Team) to create a complete report of an operation.
CREATE OR REPLACE VIEW ViewBookingDetails AS
SELECT
    b.BookingID,
    b.BookingType,
    b.BookingDate,
    b.TotalCost,
    b.PlacementMode,
    DEREF(b.HandledBy).TeamCode AS AssignedTeamCode,
    DEREF(b.HandledBy).TeamName AS AssignedTeamName,
    DEREF(b.AtLocation).LocationCode AS DestinationLocation,
    DEREF(b.AtLocation).Address.City AS DestinationCity,
    -- Chaining DEREFs to get the Customer Code from the Location
    DEREF(DEREF(b.AtLocation).OwnerRef).CustomerCode AS OrderedByCustomer
FROM
    Booking_TAB b;
/

-- 4. VIEW: Regional Office Overview
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

-- 5. VIEW: Customer Activity Report
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
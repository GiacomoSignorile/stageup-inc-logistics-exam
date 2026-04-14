-- DROP SECTION (safe cleanup before creation)
BEGIN
    FOR obj IN (
        SELECT 'TABLE' AS object_type, 'OFFICE_TAB' AS object_name FROM dual UNION ALL
        SELECT 'TABLE', 'CUSTOMER_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'TEAM_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'LOCATION_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'EQUIPMENT_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'BOOKING_TAB' FROM dual
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || obj.object_name || ' CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE NOT IN (-942) THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- 1. OFFICE TABLE (Central Office and Depots)
CREATE TABLE Office_TAB OF Office_t (
    Name PRIMARY KEY,
    OfficeType NOT NULL,
    CHECK (OfficeType IN ('Central', 'Depot'))
);
/

-- 2. CUSTOMER TABLE (Using inheritance)
CREATE TABLE Customer_TAB OF Customer_t (
    CustomerCode PRIMARY KEY,
    CustomerType NOT NULL,
    CHECK (CustomerType IN ('Individual', 'Company'))
);
/

-- 3. SETUP TEAM TABLE 
-- Note: No NESTED TABLE clause needed because 'Members' is a VARRAY
CREATE TABLE Team_TAB OF Team_t (
    TeamCode PRIMARY KEY,
    TeamName NOT NULL,
    NoInstallations DEFAULT 0 NOT NULL -- Redundant attribute for Performance Analysis
);
/

-- 4. EVENT LOCATION TABLE
CREATE TABLE Location_TAB OF Location_t (
    LocationCode PRIMARY KEY,
    OwnerRef NOT NULL,
    SetupTimeEstimate NOT NULL,
    EquipmentCapacity NOT NULL,
    SCOPE FOR (OwnerRef) IS (SELECT REF(c) FROM Customer_TAB c)
);
/

-- 5. EQUIPMENT TABLE (Required for Exercise 6 Triggers)
CREATE TABLE Equipment_TAB (
    ItemCode NUMBER PRIMARY KEY,
    Description VARCHAR2(100),
    UnitsAvailable NUMBER NOT NULL,
    CHECK (UnitsAvailable >= 0)
);
/

-- 6. BOOKING TABLE (Renamed from BatchOrder)
CREATE TABLE Booking_TAB OF Booking_t (
    BookingID PRIMARY KEY,
    BookingType NOT NULL,
    BookingDate NOT NULL,
    Duration NOT NULL,
    TotalCost NOT NULL,
    PlacementMode NOT NULL,
    AtLocation NOT NULL SCOPE IS Location_TAB,
    HandledBy NOT NULL SCOPE IS Team_TAB,
    CHECK (BookingType IN ('One-time', 'Recurring', 'Seasonal', 'Promotional')),
    CHECK (PlacementMode IN ('Phone', 'Mail', 'Email', 'Website')),
    CHECK (TotalCost > 0)
);
/
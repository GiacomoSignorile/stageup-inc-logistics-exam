-- 1. DROP SECTION (Ordered for dependencies)
BEGIN
    FOR obj IN (
        SELECT 'TABLE' AS object_type, 'BOOKING_TAB' AS object_name FROM dual UNION ALL
        SELECT 'TABLE', 'LOCATION_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'CUSTOMER_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'TEAM_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'OFFICE_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'MUNICIPALITY_TAB' FROM dual UNION ALL
        SELECT 'TABLE', 'REGION_TAB' FROM dual UNION ALL
        SELECT 'TYPE', 'BOOKING_T' FROM dual UNION ALL
        SELECT 'TYPE', 'LOCATION_T' FROM dual UNION ALL
        SELECT 'TYPE', 'CUSTOMER_T' FROM dual UNION ALL
        SELECT 'TYPE', 'TEAM_T' FROM dual UNION ALL
        SELECT 'TYPE', 'MEMBER_VA' FROM dual UNION ALL
        SELECT 'TYPE', 'MEMBER_T' FROM dual UNION ALL
        SELECT 'TYPE', 'MUNICIPALITY_T' FROM dual UNION ALL
        SELECT 'TYPE', 'REGION_T' FROM dual UNION ALL
        SELECT 'TYPE', 'ADDRESS_T' FROM dual
    ) LOOP
        BEGIN
            IF obj.object_type = 'TABLE' THEN
                EXECUTE IMMEDIATE 'DROP TABLE ' || obj.object_name || ' CASCADE CONSTRAINTS';
            ELSE
                EXECUTE IMMEDIATE 'DROP TYPE ' || obj.object_name || ' FORCE';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE NOT IN (-942, -4043) THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- 2. BASIC COMPOSITE TYPES - GEOGRAPHY
CREATE OR REPLACE TYPE Region_t AS OBJECT (
    RegionCode NUMBER,
    RegionName VARCHAR2(30)
);
/

CREATE OR REPLACE TYPE Municipality_t AS OBJECT (
    MunicipalityCode NUMBER,
    MunicipalityName VARCHAR2(30),
    MunicipalityZipCode NUMBER(5),
    RegionRef REF Region_t
);
/

CREATE OR REPLACE TYPE Address_t AS OBJECT (
    Street VARCHAR2(30),
    StreetNo VARCHAR2(5),
    ZipCode NUMBER(5),
    City VARCHAR2(30),
    Province VARCHAR2(5)
);
/

-- 3. OFFICES (declared before Team_t which references it)
CREATE OR REPLACE TYPE Office_t AS OBJECT (
    Name VARCHAR2(30),
    Location Address_t,
    NoEmployees NUMBER,
    OfficeType VARCHAR2(15)
);
/

-- 4. HUMAN RESOURCES (Using Inheritance and VARRAY for BR1)
CREATE OR REPLACE TYPE Member_t AS OBJECT (
    TaxCode CHAR(16),
    FirstName VARCHAR2(25),
    LastName VARCHAR2(25),
    BirthDate DATE
) NOT FINAL;
/

-- Using VARRAY(10) to enforce Business Rule BR1 (Max 10 members)
CREATE OR REPLACE TYPE Member_VA AS VARRAY(10) OF Member_t;
/

CREATE OR REPLACE TYPE Team_t AS OBJECT (
    TeamCode NUMBER,
    TeamName VARCHAR2(30),
    N_Total_Installations NUMBER,
    Members Member_VA,
    RegionRef REF Region_t,
    OfficeRef REF Office_t
);
/

-- 5. CUSTOMERS & EVENT LOCATIONS
CREATE OR REPLACE TYPE Customer_t AS OBJECT (
    CustomerCode VARCHAR2(10),
    FirstName VARCHAR2(50),
    LastName VARCHAR2(50),
    Email VARCHAR2(50),
    CustomerType VARCHAR2(15),
    Address Address_t
) NOT FINAL;
/

CREATE OR REPLACE TYPE Location_t AS OBJECT (
    LocationCode VARCHAR2(10),
    Address Address_t,
    SetupTimeEstimate NUMBER,
    EquipmentCapacity NUMBER,
    OwnerRef REF Customer_t
);
/

-- 6. THE CORE SERVICE
CREATE OR REPLACE TYPE Booking_t AS OBJECT (
    BookingID NUMBER,
    BookingType VARCHAR2(20),
    BookingDate DATE,
    Duration NUMBER,
    TotalCost NUMBER(10,2),
    PlacementMode VARCHAR2(15),
    AtLocation REF Location_t,
    HandledBy REF Office_t,
    AssignedTeam REF Team_t
);
/
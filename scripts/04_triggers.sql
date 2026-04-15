-- Create stored procedures for updating bookings count per office

CREATE OR REPLACE PROCEDURE IncrementOfficeBookings (officeRef IN REF Office_t)
IS
    v_office_name VARCHAR2(30);
BEGIN
    SELECT DEREF(officeRef).Name INTO v_office_name FROM dual;
    -- Note: In the restructured schema, Office_TAB has no direct NoBookings attribute.
    -- Booking count can be derived via: SELECT COUNT(*) FROM Booking_TAB WHERE ... HandledBy REF matches
    -- This procedure is kept for future extension if Office_TAB needs booking tracking.
END;
/

CREATE OR REPLACE PROCEDURE DecrementOfficeBookings (officeRef IN REF Office_t)
IS
    v_office_name VARCHAR2(30);
BEGIN
    SELECT DEREF(officeRef).Name INTO v_office_name FROM dual;
    -- Note: Booking removal tracking. Currently handled via audit trail.
END;
/

-- Trigger for booking synchronization (Central Office handles all bookings)
CREATE OR REPLACE TRIGGER SYNC_BOOKING_OFFICE
AFTER INSERT OR DELETE OR UPDATE OF HandledBy ON Booking_TAB
FOR EACH ROW
BEGIN
    -- Bookings are now centrally managed by Office_TAB
    -- The Central office (HandledBy) is responsible for all booking lifecycle events.
    -- Future versions can aggregate booking counts per office via views/queries.
    NULL;  -- Placeholder for future booking analytics
END;
/

CREATE OR REPLACE TRIGGER CHECK_TEAM_CONSTRAINTS
BEFORE INSERT OR UPDATE ON Team_TAB
FOR EACH ROW
BEGIN
    -- Ensure a new team starts with 0 installations
    IF INSERTING THEN
        IF :NEW.NoInstallations IS NOT NULL AND :NEW.NoInstallations > 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'A new team must start with 0 installations');
        END IF;
        :NEW.NoInstallations := 0;
    END IF;

    -- Ensure installations are only incremented/decremented by 1 at a time
    IF UPDATING THEN
        IF ABS(:NEW.NoInstallations - :OLD.NoInstallations) > 1 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Team installations can only be changed by one unit at a time');
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER CHECK_BOOKING_CONSTRAINTS
BEFORE INSERT OR UPDATE ON Booking_TAB
FOR EACH ROW
BEGIN
    -- Ensure TotalCost is positive
    IF :NEW.TotalCost <= 0 THEN
        RAISE_APPLICATION_ERROR(-20998, 'Booking TotalCost must be greater than 0');
    END IF;
    
    -- Ensure valid BookingType
    IF :NEW.BookingType NOT IN ('One-time', 'Recurring', 'Seasonal', 'Promotional') THEN
        RAISE_APPLICATION_ERROR(-20998, 'Invalid BookingType. Must be: One-time, Recurring, Seasonal, Promotional');
    END IF;
END;
/

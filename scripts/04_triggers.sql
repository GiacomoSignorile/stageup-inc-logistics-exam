-- Create stored procedures for updating installations count

CREATE OR REPLACE PROCEDURE IncrementInstallationsCount (incomingCode IN NUMBER)
IS
BEGIN
    UPDATE Team_TAB
    SET NoInstallations = NoInstallations + 1
    WHERE TeamCode = incomingCode;
END;
/

CREATE OR REPLACE PROCEDURE DecrementInstallationsCount (incomingCode IN NUMBER)
IS
BEGIN
    UPDATE Team_TAB
    SET NoInstallations = NoInstallations - 1
    WHERE TeamCode = incomingCode;
END;
/

-- Composite event trigger for synchronization (Page 26 style)
CREATE OR REPLACE TRIGGER SYNC_TEAM_INSTALLS
AFTER INSERT OR DELETE OR UPDATE OF HandledBy ON Booking_TAB
FOR EACH ROW
BEGIN
    DECLARE
        new_team_code NUMBER;
        old_team_code NUMBER;
    BEGIN
        -- Handle INSERT or UPDATE (new team)
        IF INSERTING OR UPDATING THEN
            SELECT DEREF(:NEW.HandledBy).TeamCode INTO new_team_code FROM dual;
            IncrementInstallationsCount(new_team_code);
        END IF;

        -- Handle DELETE or UPDATE (old team)
        IF DELETING OR UPDATING THEN
            SELECT DEREF(:OLD.HandledBy).TeamCode INTO old_team_code FROM dual;
            DecrementInstallationsCount(old_team_code);
        END IF;
    END;
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

-- NOTE:
-- Equipment_TAB has no explicit relation to Booking_TAB in the current schema,
-- so stock cannot be safely auto-adjusted from booking events.
-- Leave stock updates to explicit application logic until a mapping table exists.

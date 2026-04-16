-- 1. INDEXES ON REF COLUMNS (Crucial for Relationship Joins)
-- These allow fast navigation from a Booking to its Location/Team
CREATE INDEX IdxBookingAtLocation ON Booking_TAB(AtLocation);
CREATE INDEX IdxBookingHandledBy ON Booking_TAB(HandledBy);
CREATE INDEX IdxBookingAssignedTeam ON Booking_TAB(AssignedTeam);

-- Links the Location back to the Customer
CREATE INDEX IdxLocationOwner ON Location_TAB(OwnerRef);

-- 2. OPERATIONAL OPTIMIZATION (Based on Exercise 2: OP4 & OP5)

-- Optimization for OP4: "View the team that handled setups at a specific location"
-- We already indexed AtLocation and HandledBy above, which covers this join.

-- Optimization for OP5: "Sort event locations by the number of bookings handled"
-- If we assume a redundant count in Location_TAB, we index it here:
-- CREATE INDEX IdxLocationBookingCount ON Location_TAB(noBookings);

-- Optimization for Team Performance Sorting
-- A B+Tree is best for sorting operations (ORDER BY)
CREATE INDEX IdxTeamNTotalInstallations ON Team_TAB(N_Total_Installations);

-- 3. CATEGORICAL INDEXES (For Frequently Filtered Columns)
-- Index on Booking Type (Recurring, One-time, etc.)
CREATE INDEX IdxBookingType ON Booking_TAB(BookingType);

-- Index on Placement Mode (Phone, Email, etc.)
CREATE INDEX IdxBookingPlacement ON Booking_TAB(PlacementMode);

-- 4. GEOGRAPHICAL SEARCH INDEX
-- Useful for regional reports
CREATE INDEX IdxOfficeType ON Office_TAB(OfficeType);
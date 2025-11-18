-- Migration: add Volunteer column to Bids (tinyint 0/1 default 0)
ALTER TABLE Bids ADD COLUMN Volunteer TINYINT(1) NOT NULL DEFAULT 0;

-- Optional: add index for quicker filtering
CREATE INDEX idx_bids_volunteer ON Bids (Volunteer);

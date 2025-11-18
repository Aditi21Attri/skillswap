-- migrations/004-create-messages.sql
-- Creates a Messages table for per-transaction chat messages.
-- NOTE: TransactionID and SenderID use SIGNED INT to match existing tables
-- (Transactions.TransactionID is `int` not `int unsigned`).

CREATE TABLE IF NOT EXISTS `Messages` (
  `MessageID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `TransactionID` INT NOT NULL,
  `SenderID` INT NOT NULL,
  `Content` TEXT NOT NULL,
  `SentAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `IsRead` TINYINT(1) NOT NULL DEFAULT 0,
  `DeletedForSender` TINYINT(1) NOT NULL DEFAULT 0,
  `DeletedForRecipient` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`MessageID`),
  INDEX `idx_messages_transaction_sent` (`TransactionID`, `SentAt`),
  INDEX `idx_messages_sender` (`SenderID`),
  CONSTRAINT `fk_messages_transaction` FOREIGN KEY (`TransactionID`) REFERENCES `Transactions` (`TransactionID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_messages_sender` FOREIGN KEY (`SenderID`) REFERENCES `Users` (`UserID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Helpful quick queries:
-- Insert a message:
-- INSERT INTO Messages (TransactionID, SenderID, Content) VALUES (?, ?, ?);

-- Fetch last 100 messages for a transaction (ascending):
-- SELECT m.MessageID, m.SenderID, m.Content, m.SentAt, u.UserID, u.Username, u.FullName
-- FROM Messages m
-- JOIN Users u ON m.SenderID = u.UserID
-- WHERE m.TransactionID = ?
-- ORDER BY m.SentAt ASC
-- LIMIT 100;

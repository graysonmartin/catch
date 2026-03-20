-- Add read_at column to notifications table for tracking read state.
-- Null means unread; a timestamp means the user has seen/tapped this notification.

ALTER TABLE notifications
ADD COLUMN read_at timestamptz;

-- Delete cats that have no remaining encounters after an encounter is deleted.
-- A cat without encounters is orphaned and should be cleaned up automatically.

CREATE OR REPLACE FUNCTION delete_orphaned_cat()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM encounters WHERE cat_id = OLD.cat_id
    ) THEN
        DELETE FROM cats WHERE id = OLD.cat_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_delete_orphaned_cat
    AFTER DELETE ON encounters
    FOR EACH ROW
    EXECUTE FUNCTION delete_orphaned_cat();

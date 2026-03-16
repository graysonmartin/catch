-- 004_storage_buckets.sql
-- Supabase Storage buckets and RLS policies for photo uploads
-- Part of MBA-154: Migrate shared photo storage to Supabase Storage

-- =============================================================================
-- CREATE STORAGE BUCKETS
-- =============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES
    ('profile-photos', 'profile-photos', TRUE),
    ('cat-photos', 'cat-photos', TRUE),
    ('encounter-photos', 'encounter-photos', TRUE)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- STORAGE RLS POLICIES: profile-photos
-- =============================================================================

-- Anyone can read profile photos (public bucket)
CREATE POLICY profile_photos_select ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-photos');

-- Authenticated users can upload to their own folder (folder = user ID)
CREATE POLICY profile_photos_insert ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Users can update their own photos
CREATE POLICY profile_photos_update ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-photos'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Users can delete their own photos
CREATE POLICY profile_photos_delete ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-photos'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- =============================================================================
-- STORAGE RLS POLICIES: cat-photos
-- =============================================================================

-- Anyone can read cat photos (public bucket)
CREATE POLICY cat_photos_select ON storage.objects
    FOR SELECT USING (bucket_id = 'cat-photos');

-- Authenticated users can upload to their own folder
CREATE POLICY cat_photos_insert ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'cat-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Users can update their own photos
CREATE POLICY cat_photos_update ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'cat-photos'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Users can delete their own photos
CREATE POLICY cat_photos_delete ON storage.objects
    FOR DELETE USING (
        bucket_id = 'cat-photos'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- =============================================================================
-- STORAGE RLS POLICIES: encounter-photos
-- =============================================================================

-- Anyone can read encounter photos (public bucket)
CREATE POLICY encounter_photos_select ON storage.objects
    FOR SELECT USING (bucket_id = 'encounter-photos');

-- Authenticated users can upload to their own folder
CREATE POLICY encounter_photos_insert ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'encounter-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Users can update their own photos
CREATE POLICY encounter_photos_update ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'encounter-photos'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

-- Users can delete their own photos
CREATE POLICY encounter_photos_delete ON storage.objects
    FOR DELETE USING (
        bucket_id = 'encounter-photos'
        AND (storage.foldername(name))[1] = auth.uid()::TEXT
    );

import Foundation

/// Defines the Supabase Storage buckets used for photo uploads.
public enum SupabaseStorageBucket: String, Sendable {
    case profilePhotos = "profile-photos"
    case catPhotos = "cat-photos"
    case encounterPhotos = "encounter-photos"
}

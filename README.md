<p align="center">
  <img src="catch/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" alt="Catch app icon" />
</p>

<h1 align="center">Catch</h1>

<p align="center">
  <strong>a social way to keep track of all cats you spot</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS_17+-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/backend-Supabase-3FCF8E?style=flat-square&logo=supabase&logoColor=white" />
</p>

---

## what is this

Log every cat you encounter. Register them with photos, track repeat sightings, pin them on a map, collect breeds like Pokemon, and follow friends to see their discoveries too.

## features

### AI Breed Detection

Snap a photo and Catch identifies the breed on-device using a **CoreML model** powered by Apple's **Vision framework**. No photos ever leave the phone.

1. Photos run through a `VNCoreMLRequest` with a custom-trained `catBreedDetection` model
2. Confidence scores are returned across **12 recognized breeds**
3. Top 3 predictions are surfaced as tappable suggestions with confidence badges
4. A separate `CatPhotoValidationService` uses Vision to confirm the image actually contains a cat

The classifier is protocol-driven and fully mockable for testing.

### Breed Collection

Pokedex-style breed tracker. Every breed you encounter gets logged with rarity tiers. Filter by discovered vs. undiscovered and track your progress toward catching them all.

### Map with Clustering

All sightings plotted on a live map using UIKit's `MKMapView`

- Pins auto-cluster at wide zoom levels
- **Spiderfy** fans overlapping pins into a circle when zoomed in, with a "+N" overflow bubble
- Snapshot-based diffing skips annotation rebuilds when nothing changed
- Date range and follow filters

### Social

Follow friends, browse a merged feed of everyone's encounters, like and comment on sightings. Private accounts require follow approval. Suggested people surface users with shared breed discoveries.

### Cat Profiles

Each cat gets its own profile with a full encounter timeline, photos, breed, location, and ownership status.

## license

All rights reserved.

import Foundation
#if DEBUG && canImport(UIKit)
import UIKit

/// Shared seed data for `UserBrowseService` implementations.
/// Keeps fake user definitions in one place instead of duplicating across CK and Supabase services.
@MainActor
public enum UserBrowseSeedData {

    public struct SeedResult {
        public let cache: [String: UserBrowseData]
        public let displayNames: [String: String]
    }

    public static func generate() -> SeedResult {
        let calendar = Calendar.current
        let now = Date()

        let chairmanMeowPhoto = seedPhoto(named: "SeedSocial1")
        let beansPhoto = seedPhoto(named: "SeedSocial2")
        let professorPhoto = seedPhoto(named: "SeedSocial3")
        let noodlePhoto = seedPhoto(named: "SeedSocial4")
        let biscuitPhoto = seedPhoto(named: "SeedSocial5")
        let ghostPhoto = seedPhoto(named: "SeedSocial6")
        let gremlinPhoto = seedPhoto(named: "SeedSocial7")

        var cache: [String: UserBrowseData] = [:]
        var displayNames: [String: String] = [:]

        // -- tuong: prolific cat spotter --
        let tuongProfile = CloudUserProfile(
            recordName: "profile-tuong",
            appleUserID: "fake-tuong",
            displayName: "tuong",
            bio: "i see cats. i log cats. it is my calling.",
            username: "tuong_cats",
            isPrivate: false
        )
        let tuongCats = [
            CloudCat(
                recordName: "tuong-cat-1", ownerID: "fake-tuong", name: "Chairman Meow",
                breed: "", estimatedAge: "6", locationName: "Fire escape",
                locationLatitude: 37.7800, locationLongitude: -122.4200,
                notes: "runs this block. nobody disputes it.", isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -60, to: now)!, photos: chairmanMeowPhoto
            ),
            CloudCat(
                recordName: "tuong-cat-2", ownerID: "fake-tuong", name: "Beans",
                breed: "", estimatedAge: "1", locationName: "Coffee shop window",
                locationLatitude: 37.7810, locationLongitude: -122.4150,
                notes: "sleeps in the window display. customers think she's decor.", isOwned: true,
                createdAt: calendar.date(byAdding: .day, value: -30, to: now)!, photos: beansPhoto
            ),
            CloudCat(
                recordName: "tuong-cat-3", ownerID: "fake-tuong", name: "The Professor",
                breed: "", estimatedAge: "8", locationName: "Library steps",
                locationLatitude: 37.7790, locationLongitude: -122.4180,
                notes: "sits on the library steps looking disappointed in everyone. valid.", isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -14, to: now)!, photos: professorPhoto
            )
        ]
        let tuongEncounters = [
            CloudEncounter(
                recordName: "tuong-enc-1", ownerID: "fake-tuong", catRecordName: "tuong-cat-1",
                date: calendar.date(byAdding: .day, value: -60, to: now)!, locationName: "Fire escape",
                locationLatitude: 37.7800, locationLongitude: -122.4200,
                notes: "first sighting. he hissed. i respected it.", photos: chairmanMeowPhoto
            ),
            CloudEncounter(
                recordName: "tuong-enc-2", ownerID: "fake-tuong", catRecordName: "tuong-cat-1",
                date: calendar.date(byAdding: .day, value: -3, to: now)!, locationName: "Fire escape",
                locationLatitude: 37.7800, locationLongitude: -122.4200,
                notes: "he let me get within 5 feet today. progress.", photos: []
            ),
            CloudEncounter(
                recordName: "tuong-enc-3", ownerID: "fake-tuong", catRecordName: "tuong-cat-2",
                date: calendar.date(byAdding: .day, value: -30, to: now)!, locationName: "Coffee shop window",
                locationLatitude: 37.7810, locationLongitude: -122.4150,
                notes: "ordered a latte just to sit near her. worth it.", photos: beansPhoto
            ),
            CloudEncounter(
                recordName: "tuong-enc-4", ownerID: "fake-tuong", catRecordName: "tuong-cat-3",
                date: calendar.date(byAdding: .day, value: -14, to: now)!, locationName: "Library steps",
                locationLatitude: 37.7790, locationLongitude: -122.4180,
                notes: "he looked at me like i owe him money.", photos: professorPhoto
            )
        ]
        cache["fake-tuong"] = UserBrowseData(
            profile: tuongProfile, cats: tuongCats, encounters: tuongEncounters,
            followerCount: 89, followingCount: 34, fetchedAt: now
        )
        displayNames["fake-tuong"] = tuongProfile.displayName

        // -- sophi: cat mom energy --
        let sophiProfile = CloudUserProfile(
            recordName: "profile-sophi", appleUserID: "fake-sophi", displayName: "sophi",
            bio: "every cat is my cat. they just don't know it yet.", username: "sophi_vibes", isPrivate: false
        )
        let sophiCats = [
            CloudCat(
                recordName: "sophi-cat-1", ownerID: "fake-sophi", name: "Noodle",
                breed: "", estimatedAge: "2", locationName: "Under the porch",
                locationLatitude: 37.7700, locationLongitude: -122.4300,
                notes: "appears when you least expect it. vanishes just as fast.", isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -45, to: now)!, photos: noodlePhoto
            ),
            CloudCat(
                recordName: "sophi-cat-2", ownerID: "fake-sophi", name: "Biscuit",
                breed: "", estimatedAge: "4", locationName: "Backyard fence",
                locationLatitude: 37.7710, locationLongitude: -122.4280,
                notes: "makes biscuits on the fence post. it's her whole personality.", isOwned: true,
                createdAt: calendar.date(byAdding: .day, value: -20, to: now)!, photos: biscuitPhoto
            )
        ]
        let sophiEncounters = [
            CloudEncounter(
                recordName: "sophi-enc-1", ownerID: "fake-sophi", catRecordName: "sophi-cat-1",
                date: calendar.date(byAdding: .day, value: -45, to: now)!, locationName: "Under the porch",
                locationLatitude: 37.7700, locationLongitude: -122.4300,
                notes: "heard a noise. looked down. noodle.", photos: noodlePhoto
            ),
            CloudEncounter(
                recordName: "sophi-enc-2", ownerID: "fake-sophi", catRecordName: "sophi-cat-1",
                date: calendar.date(byAdding: .day, value: -8, to: now)!, locationName: "Under the porch",
                locationLatitude: 37.7700, locationLongitude: -122.4300,
                notes: "noodle was back. same vibe. unbothered.", photos: []
            ),
            CloudEncounter(
                recordName: "sophi-enc-3", ownerID: "fake-sophi", catRecordName: "sophi-cat-2",
                date: calendar.date(byAdding: .day, value: -20, to: now)!, locationName: "Backyard fence",
                locationLatitude: 37.7710, locationLongitude: -122.4280,
                notes: "she kneaded the fence for 10 minutes straight. dedication.", photos: biscuitPhoto
            )
        ]
        cache["fake-sophi"] = UserBrowseData(
            profile: sophiProfile, cats: sophiCats, encounters: sophiEncounters,
            followerCount: 42, followingCount: 15, fetchedAt: now
        )
        displayNames["fake-sophi"] = sophiProfile.displayName

        // -- shiv: private profile --
        let shivProfile = CloudUserProfile(
            recordName: "profile-shiv", appleUserID: "fake-shiv", displayName: "shiv",
            bio: "my cats are none of your business (unless i follow you back)", username: "shiv_private", isPrivate: true
        )
        let shivCats = [
            CloudCat(
                recordName: "shiv-cat-1", ownerID: "fake-shiv", name: "Ghost",
                breed: "", estimatedAge: "?", locationName: "Classified",
                locationLatitude: nil, locationLongitude: nil,
                notes: "you'll never find this cat.", isOwned: true,
                createdAt: calendar.date(byAdding: .day, value: -90, to: now)!, photos: ghostPhoto
            )
        ]
        let shivEncounters = [
            CloudEncounter(
                recordName: "shiv-enc-1", ownerID: "fake-shiv", catRecordName: "shiv-cat-1",
                date: calendar.date(byAdding: .day, value: -90, to: now)!, locationName: "Classified",
                locationLatitude: nil, locationLongitude: nil,
                notes: "redacted", photos: ghostPhoto
            )
        ]
        cache["fake-shiv"] = UserBrowseData(
            profile: shivProfile, cats: shivCats, encounters: shivEncounters,
            followerCount: 7, followingCount: 3, fetchedAt: now
        )
        displayNames["fake-shiv"] = shivProfile.displayName

        // -- mark: also browsable --
        let markProfile = CloudUserProfile(
            recordName: "profile-mark", appleUserID: "fake-mark", displayName: "mark",
            bio: "cats are just small roommates who don't pay rent", username: "mark_the_cat_guy", isPrivate: false
        )
        let markCats = [
            CloudCat(
                recordName: "mark-cat-1", ownerID: "fake-mark", name: "Gremlin",
                breed: "", estimatedAge: "3", locationName: "Dumpster behind 7-Eleven",
                locationLatitude: 37.7750, locationLongitude: -122.4250,
                notes: "chaotic neutral energy. knocked over a trash can and stared at me.", isOwned: false,
                createdAt: calendar.date(byAdding: .day, value: -25, to: now)!, photos: gremlinPhoto
            )
        ]
        let markEncounters = [
            CloudEncounter(
                recordName: "mark-enc-1", ownerID: "fake-mark", catRecordName: "mark-cat-1",
                date: calendar.date(byAdding: .day, value: -25, to: now)!, locationName: "Dumpster behind 7-Eleven",
                locationLatitude: 37.7750, locationLongitude: -122.4250,
                notes: "he was standing on the dumpster like a king surveying his domain.", photos: gremlinPhoto
            ),
            CloudEncounter(
                recordName: "mark-enc-2", ownerID: "fake-mark", catRecordName: "mark-cat-1",
                date: calendar.date(byAdding: .day, value: -2, to: now)!, locationName: "Same dumpster",
                locationLatitude: 37.7750, locationLongitude: -122.4250,
                notes: "gremlin remembered me. or he just wanted my sandwich. unclear.", photos: []
            )
        ]
        cache["fake-mark"] = UserBrowseData(
            profile: markProfile, cats: markCats, encounters: markEncounters,
            followerCount: 23, followingCount: 11, fetchedAt: now
        )
        displayNames["fake-mark"] = markProfile.displayName

        // -- tatum & jorge: followers/pending only --
        displayNames["fake-tatum"] = "tatum"
        displayNames["fake-jorge"] = "jorge"

        return SeedResult(cache: cache, displayNames: displayNames)
    }

    private static func seedPhoto(named assetName: String) -> [Data] {
        guard let image = UIImage(named: assetName),
              let data = image.jpegData(compressionQuality: 0.7) else {
            return []
        }
        return [data]
    }
}
#endif

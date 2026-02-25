#if DEBUG
import SwiftData
import UIKit

@MainActor
enum DataSeeder {

    static func seedIfEmpty(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Cat>())) ?? 0
        guard count == 0 else { return }

        let now = Date()
        let calendar = Calendar.current

        // -- Photos --
        let photo1 = jpegData(named: "SeedCat1")  // ragdoll in bag
        let photo2 = jpegData(named: "SeedCat2")  // russian blue w/ harness
        let photo3 = jpegData(named: "SeedCat3")  // orange tabby in garden
        let photo4 = jpegData(named: "SeedCat4")  // brown tabby at door

        // -- Cat 1: garfield (the main character) --
        let garfield = Cat(
            name: "garfield",
            breed: "Tabby",
            estimatedAge: "3",
            location: Location(name: "Home", latitude: 37.7749, longitude: -122.4194),
            notes: "the original. the blueprint. simply unmatched.",
            isOwned: true,
            photos: photo3
        )
        context.insert(garfield)

        let garfieldEnc1 = Encounter(
            date: calendar.date(byAdding: .day, value: -30, to: now)!,
            location: Location(name: "Home", latitude: 37.7749, longitude: -122.4194),
            notes: "day one. he chose me.",
            cat: garfield,
            photos: photo3
        )
        context.insert(garfieldEnc1)

        let garfieldEnc2 = Encounter(
            date: calendar.date(byAdding: .day, value: -7, to: now)!,
            location: Location(name: "Kitchen counter", latitude: 37.7749, longitude: -122.4194),
            notes: "caught him on the counter again. zero remorse.",
            cat: garfield
        )
        context.insert(garfieldEnc2)

        // -- Cat 2: sprinkles (ragdoll in shopping bag) --
        let sprinkles = Cat(
            name: "sprinkles",
            breed: "Ragdoll",
            estimatedAge: "5",
            location: Location(name: "Grocery store parking lot", latitude: 37.7850, longitude: -122.4094),
            notes: "found her sitting in someone's grocery bag like she owned it",
            photos: photo1
        )
        context.insert(sprinkles)

        let sprinklesEnc1 = Encounter(
            date: calendar.date(byAdding: .day, value: -21, to: now)!,
            location: Location(name: "Grocery store parking lot", latitude: 37.7850, longitude: -122.4094),
            notes: "she was just... in the bag. no explanation.",
            cat: sprinkles,
            photos: photo1
        )
        context.insert(sprinklesEnc1)

        let sprinklesEnc2 = Encounter(
            date: calendar.date(byAdding: .day, value: -3, to: now)!,
            location: Location(name: "Same parking lot", latitude: 37.7851, longitude: -122.4093),
            notes: "different bag this time. same energy.",
            cat: sprinkles
        )
        context.insert(sprinklesEnc2)

        // -- Cat 3: tsuki (russian blue with harness) --
        let tsuki = Cat(
            name: "tsuki",
            breed: "Russian Blue",
            estimatedAge: "4",
            location: Location(name: "The park", latitude: 37.7694, longitude: -122.4862),
            notes: "walks around in a harness like he's on a mission. respect.",
            photos: photo2
        )
        context.insert(tsuki)

        let tsukiEnc = Encounter(
            date: calendar.date(byAdding: .day, value: -10, to: now)!,
            location: Location(name: "The park", latitude: 37.7694, longitude: -122.4862),
            notes: "he walked right up to me. i think he was doing recon.",
            cat: tsuki,
            photos: photo2
        )
        context.insert(tsukiEnc)

        // -- Cat 4: missBologna (brown tabby yelling at door) --
        let missBologna = Cat(
            name: "Miss Bologna",
            estimatedAge: "2",
            location: Location(name: "Back door", latitude: 37.7730, longitude: -122.4310),
            notes: "screams at the sliding door every single morning. iconic.",
            photos: photo4
        )
        context.insert(missBologna)

        let missBolognaEnc1 = Encounter(
            date: calendar.date(byAdding: .day, value: -15, to: now)!,
            location: Location(name: "Back door", latitude: 37.7730, longitude: -122.4310),
            notes: "showed up yelling. let her in. she yelled more.",
            cat: missBologna,
            photos: photo4
        )
        context.insert(missBolognaEnc1)

        let missBolognaEnc2 = Encounter(
            date: calendar.date(byAdding: .day, value: -1, to: now)!,
            location: Location(name: "Back door", latitude: 37.7730, longitude: -122.4310),
            notes: "back again. louder this time. she's evolving.",
            cat: missBologna
        )
        context.insert(missBolognaEnc2)

        // -- Cat 5: phantom (bombay sighting) --
        let phantom = Cat(
            name: "phantom",
            breed: "Bombay",
            estimatedAge: "6",
            location: Location(name: "Alley behind the ramen place", latitude: 37.7760, longitude: -122.4180),
            notes: "all black. appeared out of nowhere. might be a glitch in the matrix."
        )
        context.insert(phantom)

        let phantomEnc = Encounter(
            date: calendar.date(byAdding: .day, value: -12, to: now)!,
            location: Location(name: "Alley behind the ramen place", latitude: 37.7760, longitude: -122.4180),
            notes: "made eye contact for exactly 3 seconds then vanished. classic.",
            cat: phantom
        )
        context.insert(phantomEnc)

        // -- Cat 6: professor beans (maine coon at cafe) --
        let professorBeans = Cat(
            name: "professor beans",
            breed: "Maine Coon",
            estimatedAge: "7",
            location: Location(name: "Coffee shop on 3rd", latitude: 37.7845, longitude: -122.4000),
            notes: "enormous. sits on the cafe windowsill like a tenured professor. regulars know him."
        )
        context.insert(professorBeans)

        let professorBeansEnc = Encounter(
            date: calendar.date(byAdding: .day, value: -5, to: now)!,
            location: Location(name: "Coffee shop on 3rd", latitude: 37.7845, longitude: -122.4000),
            notes: "he was sitting next to someone's laptop. contributing, probably.",
            cat: professorBeans
        )
        context.insert(professorBeansEnc)

        // -- User Profile --
        let profileCount = (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        if profileCount == 0 {
            let profile = UserProfile(
                displayName: "cat enthusiast",
                bio: "just out here cataloging every cat i see. it's not weird, you're weird."
            )
            context.insert(profile)
        }
    }

    private static func jpegData(named assetName: String) -> [Data] {
        guard let image = UIImage(named: assetName),
              let data = image.jpegData(compressionQuality: CatchTheme.jpegCompressionQuality) else {
            return []
        }
        return [data]
    }
}
#endif

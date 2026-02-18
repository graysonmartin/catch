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

        // -- Cat 1: Steven (the main character) --
        let steven = Cat(
            name: "Steven",
            estimatedAge: "3",
            location: Location(name: "Home", latitude: 37.7749, longitude: -122.4194),
            notes: "the original. the blueprint. simply unmatched.",
            isOwned: true,
            photos: photo3
        )
        context.insert(steven)

        let stevenEnc1 = Encounter(
            date: calendar.date(byAdding: .day, value: -30, to: now)!,
            location: Location(name: "Home", latitude: 37.7749, longitude: -122.4194),
            notes: "day one. he chose me.",
            cat: steven,
            photos: photo3
        )
        context.insert(stevenEnc1)

        let stevenEnc2 = Encounter(
            date: calendar.date(byAdding: .day, value: -7, to: now)!,
            location: Location(name: "Kitchen counter", latitude: 37.7749, longitude: -122.4194),
            notes: "caught him on the counter again. zero remorse.",
            cat: steven
        )
        context.insert(stevenEnc2)

        let stevenCare = CareEntry(
            startDate: calendar.date(byAdding: .day, value: -14, to: now)!,
            endDate: calendar.date(byAdding: .day, value: -7, to: now)!,
            notes: "stayed home all week. he was thriving. i was his servant.",
            cat: steven
        )
        context.insert(stevenCare)

        // -- Cat 2: Mochi (ragdoll in shopping bag) --
        let mochi = Cat(
            name: "Mochi",
            estimatedAge: "5",
            location: Location(name: "Grocery store parking lot", latitude: 37.7850, longitude: -122.4094),
            notes: "found her sitting in someone's grocery bag like she owned it",
            photos: photo1
        )
        context.insert(mochi)

        let mochiEnc1 = Encounter(
            date: calendar.date(byAdding: .day, value: -21, to: now)!,
            location: Location(name: "Grocery store parking lot", latitude: 37.7850, longitude: -122.4094),
            notes: "she was just... in the bag. no explanation.",
            cat: mochi,
            photos: photo1
        )
        context.insert(mochiEnc1)

        let mochiEnc2 = Encounter(
            date: calendar.date(byAdding: .day, value: -3, to: now)!,
            location: Location(name: "Same parking lot", latitude: 37.7851, longitude: -122.4093),
            notes: "different bag this time. same energy.",
            cat: mochi
        )
        context.insert(mochiEnc2)

        // -- Cat 3: Sergeant (russian blue with harness) --
        let sergeant = Cat(
            name: "Sergeant",
            estimatedAge: "4",
            location: Location(name: "The park", latitude: 37.7694, longitude: -122.4862),
            notes: "walks around in a harness like he's on a mission. respect.",
            photos: photo2
        )
        context.insert(sergeant)

        let sergeantEnc = Encounter(
            date: calendar.date(byAdding: .day, value: -10, to: now)!,
            location: Location(name: "The park", latitude: 37.7694, longitude: -122.4862),
            notes: "he walked right up to me. i think he was doing recon.",
            cat: sergeant,
            photos: photo2
        )
        context.insert(sergeantEnc)

        // -- Cat 4: Gremlin (brown tabby yelling at door) --
        let gremlin = Cat(
            name: "Gremlin",
            estimatedAge: "2",
            location: Location(name: "Back door", latitude: 37.7730, longitude: -122.4310),
            notes: "screams at the sliding door every single morning. iconic.",
            photos: photo4
        )
        context.insert(gremlin)

        let gremlinEnc1 = Encounter(
            date: calendar.date(byAdding: .day, value: -15, to: now)!,
            location: Location(name: "Back door", latitude: 37.7730, longitude: -122.4310),
            notes: "showed up yelling. let her in. she yelled more.",
            cat: gremlin,
            photos: photo4
        )
        context.insert(gremlinEnc1)

        let gremlinEnc2 = Encounter(
            date: calendar.date(byAdding: .day, value: -1, to: now)!,
            location: Location(name: "Back door", latitude: 37.7730, longitude: -122.4310),
            notes: "back again. louder this time. she's evolving.",
            cat: gremlin
        )
        context.insert(gremlinEnc2)

        let gremlinCare = CareEntry(
            startDate: calendar.date(byAdding: .day, value: -5, to: now)!,
            endDate: calendar.date(byAdding: .day, value: -3, to: now)!,
            notes: "it was raining so she stayed over. she judged my apartment the entire time.",
            cat: gremlin
        )
        context.insert(gremlinCare)
    }

    private static func jpegData(named assetName: String) -> [Data] {
        guard let image = UIImage(named: assetName),
              let data = image.jpegData(compressionQuality: 0.7) else {
            return []
        }
        return [data]
    }
}
#endif

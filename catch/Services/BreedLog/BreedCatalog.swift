import Foundation

enum BreedCatalog {

    static let allBreeds: [BreedCatalogEntry] = [
        BreedCatalogEntry(
            id: "Abyssinian",
            displayName: "Abyssinian",
            description: "ancient vibes, modern chaos. one of the oldest known breeds, looks like a tiny mountain lion.",
            funFact: "nicknamed the 'aby-grabbys' because they steal everything",
            rarity: .uncommon,
            icon: "hare"
        ),
        BreedCatalogEntry(
            id: "Angora",
            displayName: "Angora",
            description: "fluffy diva energy. all fur and attitude. will shed on your nicest clothes first.",
            funFact: "turkish sultans used to keep them as royal pets. they haven't forgotten",
            rarity: .uncommon,
            icon: "wind"
        ),
        BreedCatalogEntry(
            id: "Bengal",
            displayName: "Bengal",
            description: "literally a tiny leopard that lives in your house. chaos incarnate.",
            funFact: "they love water. like, actually enjoy baths. broken cats.",
            rarity: .rare,
            icon: "bolt.fill"
        ),
        BreedCatalogEntry(
            id: "Birman",
            displayName: "Birman",
            description: "white paws, blue eyes, permanent look of spiritual enlightenment.",
            funFact: "legend says they got their coloring from a temple goddess. sure.",
            rarity: .uncommon,
            icon: "sparkles"
        ),
        BreedCatalogEntry(
            id: "Bombay",
            displayName: "Bombay",
            description: "mini panther. all black everything. walks like they own the night.",
            funFact: "bred specifically to look like a panther. someone said 'what if house cat but spooky' and here we are",
            rarity: .rare,
            icon: "moon.fill"
        ),
        BreedCatalogEntry(
            id: "British Shorthair",
            displayName: "British Shorthair",
            description: "round face, round eyes, round everything. built like a distinguished gentleman.",
            funFact: "the cheshire cat was based on this breed. the smile checks out",
            rarity: .uncommon,
            icon: "crown"
        ),
        BreedCatalogEntry(
            id: "Burmese",
            displayName: "Burmese",
            description: "velvet-coated attention seeker. will follow you into the bathroom. every time.",
            funFact: "they're called 'velcro cats' because they literally will not leave you alone",
            rarity: .uncommon,
            icon: "figure.stand"
        ),
        BreedCatalogEntry(
            id: "Domestic Shorthair",
            displayName: "Domestic Shorthair",
            description: "the mutt of cats. no pedigree, all personality. literally every other cat you've ever met.",
            funFact: "make up about 95% of cats in the US. they're the main characters and they know it",
            rarity: .common,
            icon: "house.fill"
        ),
        BreedCatalogEntry(
            id: "Egyptian Mau",
            displayName: "Egyptian Mau",
            description: "the fastest domestic cat. spots are natural, not a filter. ancient egyptian royalty.",
            funFact: "only naturally spotted domestic breed. they came pre-accessorized",
            rarity: .legendary,
            icon: "pyramid.fill"
        ),
        BreedCatalogEntry(
            id: "Havana Brown",
            displayName: "Havana Brown",
            description: "chocolate brown everything. even the whiskers. looks like a living truffle.",
            funFact: "fewer than 1,000 exist worldwide. basically a cryptid at this point",
            rarity: .legendary,
            icon: "cup.and.saucer.fill"
        ),
        BreedCatalogEntry(
            id: "Japanese Bobtail",
            displayName: "Japanese Bobtail",
            description: "tiny tail, big personality. the lucky cat statue is based on these.",
            funFact: "their stubby tail is caused by a natural genetic mutation. built different",
            rarity: .rare,
            icon: "hand.wave"
        ),
        BreedCatalogEntry(
            id: "Korat",
            displayName: "Korat",
            description: "silver-tipped fur that shimmers. green eyes. considered extremely lucky in thailand.",
            funFact: "traditionally given in pairs as wedding gifts. relationship goals, i guess",
            rarity: .rare,
            icon: "star.fill"
        ),
        BreedCatalogEntry(
            id: "Maine Coon",
            displayName: "Maine Coon",
            description: "absolute unit. the great dane of cats. somehow still thinks it's a kitten.",
            funFact: "can grow up to 40 inches long. that's not a cat, that's a roommate",
            rarity: .uncommon,
            icon: "mountain.2"
        ),
        BreedCatalogEntry(
            id: "Manx",
            displayName: "Manx",
            description: "no tail. bunny hop walk. looks permanently surprised about their own existence.",
            funFact: "they're amazing hunters despite the missing tail. don't need it, apparently",
            rarity: .rare,
            icon: "hare.fill"
        ),
        BreedCatalogEntry(
            id: "Norwegian Forest Cat",
            displayName: "Norwegian Forest Cat",
            description: "viking cat. built for scandinavian winters. majestic floof that fears nothing.",
            funFact: "norse mythology says they pulled freya's chariot. metal.",
            rarity: .rare,
            icon: "snowflake"
        ),
        BreedCatalogEntry(
            id: "Ocicat",
            displayName: "Ocicat",
            description: "looks wild, acts domestic. spotted like an ocelot but purrs like a kitten.",
            funFact: "created completely by accident. the best things are",
            rarity: .rare,
            icon: "circle.dotted"
        ),
        BreedCatalogEntry(
            id: "Persian",
            displayName: "Persian",
            description: "flat face, maximum floof. the influencer of the cat world. high maintenance and proud.",
            funFact: "most popular pedigree breed worldwide. basic but make it elegant",
            rarity: .uncommon,
            icon: "cloud"
        ),
        BreedCatalogEntry(
            id: "Ragdoll",
            displayName: "Ragdoll",
            description: "goes completely limp when picked up. zero survival instinct. maximum chill.",
            funFact: "named ragdoll because they literally flop like a stuffed animal. no thoughts head empty",
            rarity: .uncommon,
            icon: "sofa"
        ),
        BreedCatalogEntry(
            id: "Russian Blue",
            displayName: "Russian Blue",
            description: "silver-blue coat, green eyes, permanent resting cat face. elegant and unbothered.",
            funFact: "they're said to smile because of their slightly upturned mouth. it's sarcasm",
            rarity: .uncommon,
            icon: "diamond"
        ),
        BreedCatalogEntry(
            id: "Scottish Fold",
            displayName: "Scottish Fold",
            description: "folded ears, owl face. sits in weird positions on purpose. knows they're cute.",
            funFact: "all scottish folds descend from one barn cat named susie. nepotism",
            rarity: .rare,
            icon: "ear"
        ),
        BreedCatalogEntry(
            id: "Siamese",
            displayName: "Siamese",
            description: "talks more than your group chat. piercing blue eyes. drama incarnate.",
            funFact: "one of the most vocal breeds. they will tell you about their day whether you asked or not",
            rarity: .common,
            icon: "bubble.left"
        ),
        BreedCatalogEntry(
            id: "Singapura",
            displayName: "Singapura",
            description: "smallest domestic breed. huge eyes. permanent baby energy at 4 pounds.",
            funFact: "national cat of singapore. tiny body, enormous personality",
            rarity: .legendary,
            icon: "ant"
        ),
        BreedCatalogEntry(
            id: "Snowshoe",
            displayName: "Snowshoe",
            description: "white paws like they stepped in paint. siamese vibes but make it artsy.",
            funFact: "grumpy cat was a snowshoe mix. the attitude is genetic",
            rarity: .rare,
            icon: "shoeprint.fill"
        ),
        BreedCatalogEntry(
            id: "Somali",
            displayName: "Somali",
            description: "long-haired abyssinian. foxy look. the main character of any room they enter.",
            funFact: "nicknamed 'fox cats' for their bushy tails and red coats. they know they look good",
            rarity: .rare,
            icon: "flame"
        ),
        BreedCatalogEntry(
            id: "Sphynx",
            displayName: "Sphynx",
            description: "hairless and proud. warm to the touch. looks like an alien, acts like a dog.",
            funFact: "they're not actually hypoallergenic. they just look like they should be",
            rarity: .rare,
            icon: "globe.americas"
        ),
        BreedCatalogEntry(
            id: "Tabby",
            displayName: "Tabby",
            description: "the classic. the og. striped, spotted, or swirled. every cat aspires to this energy.",
            funFact: "not technically a breed but a coat pattern. we don't care, they earned their spot",
            rarity: .common,
            icon: "cat"
        ),
        BreedCatalogEntry(
            id: "Tiger Tabby",
            displayName: "Tiger Tabby",
            description: "tabby but make it fierce. bold stripes. walks like they're on a runway.",
            funFact: "the 'M' marking on their forehead supposedly stands for 'majestic'. or 'menace'.",
            rarity: .common,
            icon: "cat.fill"
        ),
        BreedCatalogEntry(
            id: "Turkish Angora",
            displayName: "Turkish Angora",
            description: "graceful, athletic, and definitely smarter than you. silky white coat optional.",
            funFact: "turkish angoras often have odd eyes — one blue, one amber. built-in accessory",
            rarity: .rare,
            icon: "wand.and.stars"
        ),
    ]

    static let count = allBreeds.count

    static func entry(for breedName: String) -> BreedCatalogEntry? {
        allBreeds.first { $0.id == breedName }
    }

    static func contains(_ breedName: String) -> Bool {
        allBreeds.contains { $0.id == breedName }
    }
}

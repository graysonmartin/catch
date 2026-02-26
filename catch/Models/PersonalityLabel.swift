import Foundation

enum PersonalityLabel: String, CaseIterable, Identifiable {

    // Standard
    case silly
    case playful
    case cozy
    case talkative
    case friendly
    case shy
    case lazy
    case chaotic

    // Weird / funny
    case haunted
    case suspiciouslyPolite = "suspiciously polite"
    case holdsGrudges = "holds grudges"
    case oneBrainCell = "one brain cell"
    case menace
    case screamsForNoReason = "screams for no reason"
    case wouldCommitCrimes = "would commit crimes"
    case soggy
    case builtDifferent = "built different"
    case freeloading
    case plottingSomething = "plotting something"
    case emotionallyUnavailable = "emotionally unavailable"
    case large

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    static let standard: [PersonalityLabel] = [
        .silly, .playful, .cozy, .talkative, .friendly, .shy, .lazy, .chaotic
    ]

    static let weird: [PersonalityLabel] = [
        .haunted, .suspiciouslyPolite, .holdsGrudges, .oneBrainCell,
        .menace, .screamsForNoReason, .wouldCommitCrimes, .soggy,
        .builtDifferent, .freeloading, .plottingSomething,
        .emotionallyUnavailable, .large
    ]
}

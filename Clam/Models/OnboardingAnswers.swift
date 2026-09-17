import Foundation

/// What the user told us during onboarding. Drives the personalized "reveal" numbers.
struct OnboardingAnswers: Codable, Equatable {
    var hoursPerDay: Double = 4.5
    var triggers: Set<Trigger> = []

    enum Trigger: String, Codable, CaseIterable, Identifiable {
        case bored, inBed, waiting, procrastinating, anxious, justChecking

        var id: String { rawValue }

        var label: String {
            switch self {
            case .bored: return "I'm bored"
            case .inBed: return "In bed"
            case .waiting: return "Waiting in line"
            case .procrastinating: return "Avoiding work"
            case .anxious: return "Feeling anxious"
            case .justChecking: return "\"Just checking\""
            }
        }

        var symbol: String {
            switch self {
            case .bored: return "face.dashed"
            case .inBed: return "bed.double.fill"
            case .waiting: return "figure.stand.line.dotted.figure.stand"
            case .procrastinating: return "laptopcomputer.slash"
            case .anxious: return "waveform.path.ecg"
            case .justChecking: return "eye.fill"
            }
        }
    }

    // MARK: - Reveal math

    /// Full days per year spent on the phone at the stated rate.
    var daysPerYear: Int {
        Int((hoursPerDay * 365 / 24).rounded())
    }

    /// Assumed reduction once someone uses a blocker consistently. Conservative; sourced
    /// estimates for app-blocker users range 30–50%.
    static let assumedReduction = 0.4

    /// Days per year the user gets back at the assumed reduction.
    var daysBackPerYear: Int {
        Int((Double(daysPerYear) * Self.assumedReduction).rounded())
    }

    /// Hours per week saved, for the paywall copy.
    var hoursBackPerWeek: Int {
        Int((hoursPerDay * 7 * Self.assumedReduction).rounded())
    }
}

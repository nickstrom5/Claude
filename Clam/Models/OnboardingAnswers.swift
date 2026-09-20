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

    /// Assumed reduction once someone locks apps consistently. Source: Opal reports its members
    /// cut screen time by 1h23m/day, about 30% of the 4h37m global mobile average (DataReportal
    /// 2026). We use a third. Replace with Clam's own data once we have it.
    static let assumedReduction = 1.0 / 3.0

    /// Days per year the user gets back at the assumed reduction.
    var daysBackPerYear: Int {
        Int((Double(daysPerYear) * Self.assumedReduction).rounded())
    }

    /// Hours per week saved, for the paywall copy.
    var hoursBackPerWeek: Int {
        Int((hoursPerDay * 7 * Self.assumedReduction).rounded())
    }
}

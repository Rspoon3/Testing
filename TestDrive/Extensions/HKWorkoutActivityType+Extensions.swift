import HealthKit
import SFSymbols

extension HKWorkoutActivityType {
    /// Human-readable name for the workout type.
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .dance: return "Dance"
        case .cooldown: return "Cooldown"
        case .coreTraining: return "Core Training"
        case .pilates: return "Pilates"
        case .crossTraining: return "Cross Training"
        case .mixedCardio: return "Mixed Cardio"
        default: return "Workout"
        }
    }

    /// SF Symbol representing the workout type.
    var symbol: SFSymbol {
        switch self {
        case .running: return .figureRun
        case .walking: return .figureWalk
        case .cycling: return .bicycle
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .dumbbellFill
        case .highIntensityIntervalTraining: return .flameFill
        case .yoga: return .figureYoga
        case .swimming: return .figurePoolSwim
        case .hiking: return .figureHiking
        case .elliptical: return .figureElliptical
        case .rowing: return .figureRower
        case .stairClimbing: return .figureStairStepper
        case .dance: return .figureSocialdance
        case .coreTraining: return .figureCoreTraining
        case .pilates: return .figurePilates
        case .crossTraining: return .figureCrossTraining
        case .mixedCardio: return .figureMixedCardio
        default: return .figureRun
        }
    }
}

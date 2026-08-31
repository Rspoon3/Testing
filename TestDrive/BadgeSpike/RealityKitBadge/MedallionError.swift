//
//  MedallionError.swift
//  TestDrive
//

import Foundation

/// Failures while building the 3D medallion.
enum MedallionError: Error, LocalizedError {
    /// `ImageRenderer` could not rasterize the badge face.
    case artworkRenderFailed

    var errorDescription: String? {
        switch self {
        case .artworkRenderFailed:
            "Could not rasterize the badge artwork into a texture."
        }
    }
}

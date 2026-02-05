import SwiftUI

struct MatrixTextRenderer: TextRenderer {
  var glowColor: Color

  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    context.drawLayer { glow in
      glow.blendMode = .plusLighter
      glow.addFilter(.blur(radius: 10))
      glow.addFilter(.shadow(color: glowColor.opacity(1.0), radius: 14, x: 0, y: 0))
      glow.addFilter(.shadow(color: glowColor.opacity(0.85), radius: 28, x: 0, y: 0))
      for line in layout {
        glow.draw(line)
      }
    }

    context.addFilter(.shadow(color: glowColor.opacity(1.0), radius: 4, x: 0, y: 0))
    for line in layout {
      context.draw(line)
    }
  }
}

import SwiftUI

struct MatrixTextRenderer: TextRenderer {
  var glowColor: Color

  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    context.addFilter(.shadow(color: glowColor.opacity(0.9), radius: 6, x: 0, y: 0))
    context.addFilter(.shadow(color: glowColor.opacity(0.5), radius: 12, x: 0, y: 0))
    for line in layout {
      context.draw(line)
    }
  }
}

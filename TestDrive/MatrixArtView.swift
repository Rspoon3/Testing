import SwiftUI

struct MatrixArtView: View {
  let drops: [MatrixWordDrop]
  let timeSeconds: Double
  let isAnimating: Bool

  private let columns = 10
  private let gutter: CGFloat = 6

  var body: some View {
    TimelineView(.animation) { timeline in
      render(at: isAnimating ? timeline.date.timeIntervalSinceReferenceDate : timeSeconds)
        .textRenderer(MatrixTextRenderer(glowColor: .green))
    }
  }

  @ViewBuilder
  private func render(at time: Double) -> some View {
    Canvas { context, size in
      let columnWidth = (size.width - CGFloat(columns - 1) * gutter) / CGFloat(columns)
      let green = Color(red: 0.55, green: 1.0, blue: 0.65)

      for drop in drops {
        let x = CGFloat(drop.column) * (columnWidth + gutter) + columnWidth * 0.5 + drop.xOffset
        let lineHeight = drop.fontSize * 1.15
        let chars = Array(drop.word)
        let stackHeight = CGFloat(chars.count) * lineHeight
        let y = positionY(time: time, drop: drop, height: size.height, stackHeight: stackHeight)

        for (index, char) in chars.enumerated() {
          let text = Text(String(char))
            .font(.system(size: drop.fontSize, weight: .medium, design: .monospaced))
            .foregroundStyle(green.opacity(drop.opacity))
          let charY = y + CGFloat(index) * lineHeight
          let point = CGPoint(x: x, y: charY)

          context.drawLayer { glow in
            glow.blendMode = .plusLighter
            glow.addFilter(.blur(radius: 8))
            glow.addFilter(.shadow(color: green.opacity(1.0), radius: 18, x: 0, y: 0))
            glow.addFilter(.shadow(color: green.opacity(0.8), radius: 28, x: 0, y: 0))
            glow.draw(text, at: point, anchor: .center)
          }

          context.draw(text, at: point, anchor: .center)
        }
      }
    }
    .background(Color.black)
  }

  private func positionY(time: Double, drop: MatrixWordDrop, height: CGFloat, stackHeight: CGFloat) -> CGFloat {
    let travel = height + stackHeight + 120
    let raw = (CGFloat(time) * drop.speed + drop.phase).truncatingRemainder(dividingBy: travel)
    return raw - stackHeight - 60
  }
}

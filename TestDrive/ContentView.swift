//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct SankeyNode: Identifiable {
    let id: UUID = UUID()
    let name: String
    let value: CGFloat
}

struct SankeyLink {
    let from: SankeyNode
    let to: SankeyNode
    let value: CGFloat
}

struct SankeyChartView: View {
    let sources: [SankeyNode]
    let targets: [SankeyNode]
    let links: [SankeyLink]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let spacing: CGFloat = 20
                let sourceYPositions = calculateYPositions(for: sources, in: size.height, spacing: spacing)
                let targetYPositions = calculateYPositions(for: targets, in: size.height, spacing: spacing)

                for link in links {
                    if let sourceIndex = sources.firstIndex(where: { $0.id == link.from.id }),
                       let targetIndex = targets.firstIndex(where: { $0.id == link.to.id }) {
                        
                        let startX: CGFloat = 100
                        let endX: CGFloat = size.width - 100
                        
                        let startY = sourceYPositions[sourceIndex]
                        let endY = targetYPositions[targetIndex]
                        
                        var path = Path()
                        path.move(to: CGPoint(x: startX, y: startY))
                        path.addCurve(to: CGPoint(x: endX, y: endY),
                                      control1: CGPoint(x: startX + 100, y: startY),
                                      control2: CGPoint(x: endX - 100, y: endY))
                        
                        let gradient = Gradient(colors: [.blue.opacity(0.5), .green.opacity(0.5)])
                        context.stroke(path, with: .linearGradient(gradient,
                                                                   startPoint: CGPoint(x: startX, y: startY),
                                                                   endPoint: CGPoint(x: endX, y: endY)),
                                       style: StrokeStyle(lineWidth: link.value, lineCap: .round))
                    }
                }
            }
        }
    }

    private func calculateYPositions(for nodes: [SankeyNode], in totalHeight: CGFloat, spacing: CGFloat) -> [CGFloat] {
        var positions: [CGFloat] = []
        var currentY: CGFloat = spacing
        for node in nodes {
            positions.append(currentY + node.value / 2)
            currentY += node.value + spacing
        }
        return positions
    }
}

struct ContentView: View {
    var body: some View {
        let sources = [
            SankeyNode(name: "A", value: 40),
            SankeyNode(name: "B", value: 30),
            SankeyNode(name: "C", value: 20),
        ]

        let targets = [
            SankeyNode(name: "X", value: 50),
            SankeyNode(name: "Y", value: 40),
        ]

        let links = [
            SankeyLink(from: sources[0], to: targets[0], value: 25),
            SankeyLink(from: sources[0], to: targets[1], value: 15),
            SankeyLink(from: sources[1], to: targets[0], value: 20),
            SankeyLink(from: sources[1], to: targets[1], value: 10),
            SankeyLink(from: sources[2], to: targets[1], value: 20)
        ]

        return SankeyChartView(sources: sources, targets: targets, links: links)
            .frame(height: 300)
            .padding()
    }
}

#Preview {
    ContentView()
}

//
//  PointsEarnedView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/27/26.
//

import Charts
import SwiftUI
import UIKit

/// A card summarizing points earned over a selectable time range (week, month, or year).
struct PointsEarnedView: View {
    // MARK: - Variables

    @State private var viewModel = PointsEarnedViewModel()
    @Environment(\.displayScale) private var displayScale

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            content(maxWidth: 600, chartHeight: 220)

            Button("Save", action: saveToPhotos)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Private Views

    private func content(maxWidth: CGFloat, chartHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Points earned")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.pointsEarnedNavy)

            card(chartHeight: chartHeight)
        }
        .frame(maxWidth: maxWidth)
        .padding()
        .background(.background)
    }

    private func card(chartHeight: CGFloat) -> some View {
        VStack(spacing: 24) {
            rangePicker
            periodHeader
            chart(height: chartHeight)
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(PointsEarnedRange.allCases) { range in
                rangePill(range)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func rangePill(_ range: PointsEarnedRange) -> some View {
        let isSelected = viewModel.selectedRange == range

        return Button {
            viewModel.selectedRange = range
        } label: {
            Text(range.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.pointsEarnedNavy : Color.clear)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(.quaternary, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
    }

    private var periodHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button {} label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text(viewModel.currentPeriod.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.pointsEarnedNavy)

                Spacer()

                Button {} label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text("\(viewModel.currentPeriod.receiptCount) receipts")
                Text("•")
                Image(.pointsDefault)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                Text(viewModel.currentPeriod.totalPoints.formatted())
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func chart(height: CGFloat) -> some View {
        Chart(viewModel.currentPeriod.dataPoints) { dataPoint in
            BarMark(
                x: .value("X", dataPoint.x),
                y: .value("Points", dataPoint.points),
                width: .fixed(barWidth)
            )
            .foregroundStyle(Color.pointsEarnedGold)
            .cornerRadius(2)
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: viewModel.currentPeriod.axisTickPositions) { value in
                if let position = value.as(Int.self), let label = viewModel.currentPeriod.axisLabels[position] {
                    AxisValueLabel {
                        Text(label)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                    .foregroundStyle(.quaternary)
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: height)
    }

    // MARK: - Private Helpers

    private var barWidth: CGFloat {
        switch viewModel.selectedRange {
        case .week: 28
        case .month: 8
        case .year: 20
        }
    }

    private func saveToPhotos() {
        let exportContent = content(maxWidth: 1600, chartHeight: 1000)
            .frame(width: 1600)

        let renderer = ImageRenderer(content: exportContent)
        renderer.scale = displayScale

        guard let image = renderer.uiImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

#Preview {
    PointsEarnedView()
}

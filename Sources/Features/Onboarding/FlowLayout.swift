import SwiftUI

struct FlowLayout: SwiftUI.Layout {
  var spacing: CGFloat = 10
  var lineSpacing: CGFloat = 10

  func sizeThatFits(
    proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) -> CGSize {
    let width = proposal.width ?? .infinity
    let rows = arrangeRows(subviews: subviews, maxWidth: width)
    let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
    let usedWidth = rows.map(\.width).max() ?? 0
    return CGSize(width: width.isFinite ? width : usedWidth, height: height)
  }

  func placeSubviews(
    in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
  ) {
    let rows = arrangeRows(subviews: subviews, maxWidth: bounds.width)
    var y = bounds.minY
    for row in rows {
      var x = bounds.minX
      for item in row.items {
        item.subview.place(
          at: CGPoint(x: x, y: y), anchor: .topLeading,
          proposal: ProposedViewSize(item.size))
        x += item.size.width + spacing
      }
      y += row.height + lineSpacing
    }
  }

  private struct RowItem {
    let subview: LayoutSubview
    let size: CGSize
  }

  private struct Row {
    let items: [RowItem]
    let width: CGFloat
    let height: CGFloat
  }

  private func arrangeRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
    var rows: [Row] = []
    var currentItems: [RowItem] = []
    var currentWidth: CGFloat = 0
    var currentHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      let candidateWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width
      if !currentItems.isEmpty && maxWidth.isFinite && candidateWidth > maxWidth {
        rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
        currentItems = []
        currentWidth = 0
        currentHeight = 0
      }
      currentWidth = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width
      currentHeight = max(currentHeight, size.height)
      currentItems.append(RowItem(subview: subview, size: size))
    }
    if !currentItems.isEmpty {
      rows.append(Row(items: currentItems, width: currentWidth, height: currentHeight))
    }
    return rows
  }
}

import AppKit

public final class StatusItemRenderer {
    
    /// 绘制超窄极简双层微胶囊（宽度仅 28pt，等同于一个标准系统图标宽度）
    public static func renderDualCylinder(remaining5h: Double, remainingWeekly: Double, isLocked: Bool) -> NSImage {
        let width: CGFloat = 28
        let height: CGFloat = 22
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        let font = NSFont.systemFont(ofSize: 7.0, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        
        // 1. 上层：5H 剩余胶囊 (y: 11.5, width: 26, h: 8.5)
        let rect1 = NSRect(x: 1, y: 11.5, width: 26, height: 8.5)
        let bgPath1 = NSBezierPath(roundedRect: rect1, xRadius: 4.25, yRadius: 4.25)
        NSColor.quaternaryLabelColor.setFill()
        bgPath1.fill()
        
        // 5H 填充进度
        let fill1Width = max(3.0, (rect1.width * CGFloat(min(100.0, max(0.0, remaining5h))) / 100.0))
        let fill1Rect = NSRect(x: 1, y: 11.5, width: fill1Width, height: 8.5)
        let fill1Path = NSBezierPath(roundedRect: fill1Rect, xRadius: 4.25, yRadius: 4.25)
        
        let color1: NSColor
        if isLocked {
            color1 = NSColor.systemRed
        } else if remaining5h < 20 {
            color1 = NSColor.systemOrange
        } else {
            color1 = NSColor.systemGreen
        }
        color1.withAlphaComponent(0.9).setFill()
        fill1Path.fill()
        
        // 5H 极简数字
        let text1 = "\(Int(remaining5h))" as NSString
        let textSize1 = text1.size(withAttributes: attrs)
        let textPoint1 = NSPoint(x: rect1.midX - textSize1.width / 2, y: rect1.midY - textSize1.height / 2 - 0.5)
        text1.draw(at: textPoint1, withAttributes: attrs)
        
        // 2. 下层：周额度剩余胶囊 (y: 1.5, width: 26, h: 8.5)
        let rect2 = NSRect(x: 1, y: 1.5, width: 26, height: 8.5)
        let bgPath2 = NSBezierPath(roundedRect: rect2, xRadius: 4.25, yRadius: 4.25)
        NSColor.quaternaryLabelColor.setFill()
        bgPath2.fill()
        
        // 周填充进度
        let fill2Width = max(3.0, (rect2.width * CGFloat(min(100.0, max(0.0, remainingWeekly))) / 100.0))
        let fill2Rect = NSRect(x: 1, y: 1.5, width: fill2Width, height: 8.5)
        let fill2Path = NSBezierPath(roundedRect: fill2Rect, xRadius: 4.25, yRadius: 4.25)
        NSColor.systemBlue.withAlphaComponent(0.9).setFill()
        fill2Path.fill()
        
        // 周极简数字
        let text2 = "\(Int(remainingWeekly))" as NSString
        let textSize2 = text2.size(withAttributes: attrs)
        let textPoint2 = NSPoint(x: rect2.midX - textSize2.width / 2, y: rect2.midY - textSize2.height / 2 - 0.5)
        text2.draw(at: textPoint2, withAttributes: attrs)
        
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}

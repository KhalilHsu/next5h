import AppKit

public final class StatusItemRenderer {
    
    /// 绘制低调黑白微胶囊（黑色剩余额度进度填充 + 白色高可读性字体 + 极简半透明背景框架）
    public static func renderDualCylinder(remaining5h: Double, remainingWeekly: Double, isLocked: Bool) -> NSImage {
        let width: CGFloat = 28
        let height: CGFloat = 22
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: 7.2, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white.withAlphaComponent(0.85)
        ]
        
        func drawCapsule(rect: NSRect, percent: Double) {
            let path = NSBezierPath(roundedRect: rect, xRadius: 4.25, yRadius: 4.25)
            
            // 1. 框架与背景（半透明底槽）
            NSColor.quaternaryLabelColor.setFill()
            path.fill()
            
            // 2. 剩余额度颜色：黑色进度填充
            let clampedPercent = min(100.0, max(0.0, percent))
            let fillWidth = max(2.0, (rect.width * CGFloat(clampedPercent) / 100.0))
            
            if fillWidth > 0 && !isLocked {
                let fillRect = NSRect(x: rect.minX, y: rect.minY, width: fillWidth, height: rect.height)
                let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 4.25, yRadius: 4.25)
                
                NSGraphicsContext.saveGraphicsState()
                path.addClip()
                NSColor.black.withAlphaComponent(0.92).setFill()
                fillPath.fill()
                NSGraphicsContext.restoreGraphicsState()
            }
            
            // 3. 微细轮廓边框
            NSColor.separatorColor.withAlphaComponent(0.20).setStroke()
            path.lineWidth = 0.5
            path.stroke()
            
            // 4. 剩余额度字体：白色
            let text = (isLocked ? "--" : "\(Int(clampedPercent))") as NSString
            let textSize = text.size(withAttributes: attrs)
            let textPoint = NSPoint(
                x: round(rect.midX - textSize.width / 2),
                y: round(rect.midY - textSize.height / 2 - 0.5)
            )
            text.draw(at: textPoint, withAttributes: attrs)
        }
        
        // 1. 上层：5H 剩余额度微胶囊 (y: 11.5)
        let rect1 = NSRect(x: 1, y: 11.5, width: 26, height: 8.5)
        drawCapsule(rect: rect1, percent: remaining5h)
        
        // 2. 下层：周额度剩余微胶囊 (y: 1.5)
        let rect2 = NSRect(x: 1, y: 1.5, width: 26, height: 8.5)
        drawCapsule(rect: rect2, percent: remainingWeekly)
        
        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}



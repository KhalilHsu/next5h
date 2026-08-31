import AppKit

public final class StatusItemRenderer {
    
    /// 绘制低调黑白灰极简双层微胶囊（宽度仅 28pt，适配 macOS 浅色/深色模式，兼顾低调美感与高可读性）
    public static func renderDualCylinder(remaining5h: Double, remainingWeekly: Double, isLocked: Bool) -> NSImage {
        let width: CGFloat = 28
        let height: CGFloat = 22
        
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { bounds in
            let font = NSFont.monospacedDigitSystemFont(ofSize: 7.2, weight: .heavy)
            let labelColor = NSColor.labelColor
            
            func drawCapsule(rect: NSRect, percent: Double, fillAlpha: CGFloat) {
                let path = NSBezierPath(roundedRect: rect, xRadius: 4.25, yRadius: 4.25)
                
                // 1. 底层微胶囊轨道槽位 (低调半透明底色)
                labelColor.withAlphaComponent(0.12).setFill()
                path.fill()
                
                // 2. 进度条填充 (低调灰度中性填充)
                let clampedPercent = min(100.0, max(0.0, percent))
                let fillWidth = max(0.0, rect.width * CGFloat(clampedPercent) / 100.0)
                
                if fillWidth > 0 && !isLocked {
                    NSGraphicsContext.saveGraphicsState()
                    path.addClip()
                    let fillRect = NSRect(x: rect.minX, y: rect.minY, width: fillWidth, height: rect.height)
                    labelColor.withAlphaComponent(fillAlpha).setFill()
                    NSBezierPath(rect: fillRect).fill()
                    NSGraphicsContext.restoreGraphicsState()
                }
                
                // 3. 极细微质感边框 (强化轮廓与精致度)
                labelColor.withAlphaComponent(0.20).setStroke()
                path.lineWidth = 0.5
                path.stroke()
                
                // 4. 高清晰居中数字 (等宽粗体，不受背景色干扰)
                let textString = isLocked ? "--" : "\(Int(clampedPercent))" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: labelColor.withAlphaComponent(isLocked ? 0.45 : 0.95)
                ]
                let textSize = textString.size(withAttributes: attrs)
                let textPoint = NSPoint(
                    x: round(rect.midX - textSize.width / 2),
                    y: round(rect.midY - textSize.height / 2 - 0.5)
                )
                textString.draw(at: textPoint, withAttributes: attrs)
            }
            
            // 1. 上层：5H 剩余胶囊 (Primary 主指标，透明度 0.38)
            let rect1 = NSRect(x: 1, y: 11.5, width: 26, height: 8.5)
            drawCapsule(rect: rect1, percent: remaining5h, fillAlpha: 0.38)
            
            // 2. 下层：周额度剩余胶囊 (Secondary 次级指标，透明度 0.22)
            let rect2 = NSRect(x: 1, y: 1.5, width: 26, height: 8.5)
            drawCapsule(rect: rect2, percent: remainingWeekly, fillAlpha: 0.22)
            
            return true
        }
        
        image.isTemplate = false
        return image
    }
}


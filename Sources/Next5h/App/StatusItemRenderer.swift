import AppKit

public final class StatusItemRenderer {
    
    /// 绘制遵循 Apple HIG 规范的原生 Template 双层微胶囊（Alpha 进度填充 + 混合模式文字镂空 + 动态深浅色自适应）
    public static func renderDualCylinder(remaining5h: Double, remainingWeekly: Double, isLocked: Bool) -> NSImage {
        let width: CGFloat = 28
        let height: CGFloat = 22
        
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { bounds in
            let font = NSFont.monospacedDigitSystemFont(ofSize: 7.2, weight: .heavy)
            
            func drawCapsule(rect: NSRect, percent: Double) {
                let path = NSBezierPath(roundedRect: rect, xRadius: 4.25, yRadius: 4.25)
                
                // 1. 半透明微胶囊底槽轨道 (Track: Alpha 0.22，深色下呈现磨砂微白，浅色下呈现淡灰)
                NSColor.black.withAlphaComponent(0.22).setFill()
                path.fill()
                
                // 2. 剩余额度进度填充 (Fill: Alpha 1.0，深色下呈现高亮纯白，浅色下呈现沉稳纯黑)
                let clampedPercent = min(100.0, max(0.0, percent))
                let fillWidth = max(0.0, (rect.width * CGFloat(clampedPercent) / 100.0))
                let fillRect = NSRect(x: rect.minX, y: rect.minY, width: fillWidth, height: rect.height)
                
                if fillWidth > 0 && !isLocked {
                    NSGraphicsContext.saveGraphicsState()
                    path.addClip()
                    NSColor.black.withAlphaComponent(1.0).setFill()
                    fillRect.fill()
                    NSGraphicsContext.restoreGraphicsState()
                }
                
                // 3. 微细轮廓边框 (强化胶囊精致边缘)
                NSColor.black.withAlphaComponent(0.28).setStroke()
                path.lineWidth = 0.5
                path.stroke()
                
                // 4. 文字排版与高对比度渲染
                let text = (isLocked ? "--" : "\(Int(clampedPercent))") as NSString
                let textSize = text.size(withAttributes: [.font: font])
                let textPoint = NSPoint(
                    x: round(rect.midX - textSize.width / 2),
                    y: round(rect.midY - textSize.height / 2 - 0.5)
                )
                
                guard let cgContext = NSGraphicsContext.current?.cgContext else { return }
                
                // 4a. 填充区内：使用 .clear 混合模式镂空 (Knockout)，文字透出背景底色
                if fillWidth > 0 && !isLocked {
                    cgContext.saveGState()
                    let clipPath = NSBezierPath(roundedRect: rect, xRadius: 4.25, yRadius: 4.25)
                    clipPath.addClip()
                    let fillClip = NSBezierPath(rect: fillRect)
                    fillClip.addClip()
                    
                    cgContext.setBlendMode(.clear)
                    text.draw(at: textPoint, withAttributes: [.font: font])
                    cgContext.restoreGState()
                }
                
                // 4b. 未填充区 (底槽) 内：使用实心黑色 (Template 模式下即为实心前景色) 绘制
                if fillWidth < rect.width || isLocked {
                    cgContext.saveGState()
                    let clipPath = NSBezierPath(roundedRect: rect, xRadius: 4.25, yRadius: 4.25)
                    clipPath.addClip()
                    let unfillX = isLocked ? rect.minX : fillRect.maxX
                    let unfillWidth = isLocked ? rect.width : (rect.maxX - fillRect.maxX)
                    let unfillClip = NSBezierPath(rect: NSRect(x: unfillX, y: rect.minY, width: unfillWidth, height: rect.height))
                    unfillClip.addClip()
                    
                    cgContext.setBlendMode(.normal)
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: NSColor.black.withAlphaComponent(0.95)
                    ]
                    text.draw(at: textPoint, withAttributes: attrs)
                    cgContext.restoreGState()
                }
            }
            
            // 1. 上层：5H 剩余额度微胶囊 (y: 11.5)
            let rect1 = NSRect(x: 1, y: 11.5, width: 26, height: 8.5)
            drawCapsule(rect: rect1, percent: remaining5h)
            
            // 2. 下层：周额度剩余微胶囊 (y: 1.5)
            let rect2 = NSRect(x: 1, y: 1.5, width: 26, height: 8.5)
            drawCapsule(rect: rect2, percent: remainingWeekly)
            
            return true
        }
        
        image.isTemplate = true
        return image
    }
}



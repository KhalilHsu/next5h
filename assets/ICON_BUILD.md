# App icon packaging

The original user-supplied artwork is preserved in `icons/next5h_5h_ring_1024.png`. The production `AppIcon.png` includes transparent Dock margins and is packaged into all ICNS sizes by `bash scripts/build_icon.sh`.

Padding correction used the built-in imagegen tool, then PNG dimension normalization for packaging. Prompt: preserve the entire blue/gold 5H artwork, typography and proportions; remove background outside the rounded-square silhouette to true alpha transparency; center the tile at approximately 82% of the square canvas, with equal transparent margins; no redesign or added elements.

Measured final 1024px PNG bounds at alpha > 10%: x=84–939, y=94–930. The extracted 1024px ICNS representation has the same bounds. System Calendar and Settings icons measured about 80% occupancy for comparison. Dock visual size also depends on magnification and hover.

## 简体中文

用户提供的原图保留在 `icons/next5h_5h_ring_1024.png`。生产图标 `AppIcon.png` 已补透明留白，运行 `bash scripts/build_icon.sh` 生成全部 ICNS 尺寸。

使用内置 imagegen 修正留白，再归一化 PNG 尺寸用于打包。提示词约束：保留蓝金色 5H 设计、字体与比例；圆角图标外区域为真实透明；居中占画布约 82%；不重新设计或添加元素。

最终 1024px PNG 与 ICNS 解包图的可见区域一致：x=84–939、y=94–930（alpha > 10%）。日历与系统设置用于对比的占比约 80%；Dock 放大和 hover 也会影响实际显示大小。

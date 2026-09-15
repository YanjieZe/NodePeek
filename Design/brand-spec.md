# NodePeek design

Your remote machines, at a glance.

## Direction

Compact native macOS utility, inspired by the information hierarchy of Activity Monitor and Finder. Preserve dense GPU rows and native drag ordering. Use system controls, a resizable material sidebar, a unified toolbar and semantic colors.

## Tokens

- Typography: SF system; monospaced digits for measurements.
- Title 20 semibold; brand 15 semibold; data 12 medium; metadata 11; table headers 10.
- Accent: system accent for controls and charts; icon blue #0F61E3.
- Surfaces: system text background and sidebar material; automatic light/dark appearance.
- Status: semantic green for connected, orange for unavailable/paused; always accompany with text.
- Spacing: 4, 8, 12, 16, 20; compact GPU row 30; sidebar row 64.
- Radius: 6 for sidebar selection, 7 for data surfaces.
- Sidebar: 210–320 points, initial 230. Window minimum: 960 × 580.

## Mark

A blue eye-shaped orbit around a central node, on a pale rounded macOS icon plate. The menu bar uses a simplified monochrome template of the same mark. Generate all sizes with Design/GenerateIcon.swift; do not stretch or recolor the application icon.

## References

- https://developer.apple.com/design/human-interface-guidelines/sidebars
- https://developer.apple.com/design/human-interface-guidelines/toolbars
- https://github.com/Wholiver/swiftui-design-skill

The skill's mobile-sized typography, touch targets and decorative brand prescriptions are adapted to the user's explicit compact macOS requirement. Native AppKit interaction and semantic system colors take priority.

import AppKit
import SwiftUI

public class QuickAddPanel: NSPanel {
    public init(store: TaskStore) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 100),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = QuickAddView(
            onSubmit: { [weak self] task in
                store.addTask(task)
                self?.close()
            },
            onDismiss: { [weak self] in
                self?.close()
            }
        )

        contentView = NSHostingView(rootView: view)
    }

    func showCentered() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        let y = screenFrame.midY + screenFrame.height / 4
        setFrameOrigin(NSPoint(x: x, y: y))
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func toggle() {
        if isVisible {
            close()
        } else {
            showCentered()
        }
    }

    override public var canBecomeKey: Bool { true }
}

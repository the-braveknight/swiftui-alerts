//
//  ActionSheet.swift
//  alert-app
//
//  Created by Zaid Rahhawi on 3/16/21.
//

import SwiftUI

#if os(iOS)
public struct ActionSheet {
    private let title: String
    private let message: String?
    private var actions: [Action]
    
    public typealias Action = Alert.Action
    
    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
        self.actions = [Action(title: "Dismiss", style: .default)]
    }
    
    public func actions(@ArrayBuilder content: () -> [Action]) -> Self {
        var alert = self
        alert.actions = content()
        return alert
    }
    
    func makeUIAlertController() -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        actions.forEach { action in
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler?()
            }
            
            alertAction.isEnabled = !action.isDisabled
            
            func handleStateChange(notification: Notification) {
                if let observedAction = notification.object as? Action, action == observedAction {
                    alertAction.isEnabled = !observedAction.isDisabled
                }
            }
            
            NotificationCenter.default.addObserver(forName: Action.stateDidChangeNotification, object: nil, queue: .main, using: handleStateChange)
            
            alert.addAction(alertAction)
        }
        
        return alert
    }
}

public struct ActionSheetModifier : ViewModifier {
    @Binding var isPresented: Bool
    let actionSheet: ActionSheet
    
    public init(isPresented: Binding<Bool>, content: () -> ActionSheet) {
        self._isPresented = isPresented
        self.actionSheet = content()
    }
    
    public func body(content: Content) -> some View {
        content.onChange(of: isPresented) { isPresented in
            if isPresented {
                present()
            }
        }
    }
    
    private func present() {
        let uiAlertController = actionSheet.makeUIAlertController()
        UIApplication.shared.windows.first?.rootViewController?.present(uiAlertController, animated: true) {
            isPresented = false
        }
    }
}

#endif

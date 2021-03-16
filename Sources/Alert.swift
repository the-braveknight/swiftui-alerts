//
//  File.swift
//  
//
//  Created by Zaid Rahhawi on 3/15/21.
//

import SwiftUI

public struct Alert {
    private let title: String
    private let message: String?
    fileprivate var actions: [Action]
    private var textFields: [TextField] = []
    
    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
        
        #if os(iOS)
        self.actions = [Action(title: "Dismiss", style: .default)]
        #elseif os(macOS)
        self.actions = [Action(title: "Dismiss", style: .informational)]
        #endif
    }
    
    public struct Action : Equatable {
        let title: String
        #if os(iOS)
        let style: UIAlertAction.Style
        #elseif os(macOS)
        let style: NSAlert.Style
        #endif
        let handler: (() -> Void)?
        
        private(set) var isDisabled: Bool = false
        
        static let stateDidChangeNotification = Notification.Name("actionStateDidChange")
        
        #if os(iOS)
        public init(title: String, style: UIAlertAction.Style, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
        #endif
        
        #if os(macOS)
        public init(title: String, style: NSAlert.Style, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
        #endif
        
        public func disabled(_ isDisabled: Bool) -> Self {
            var action = self
            action.isDisabled = isDisabled
            NotificationCenter.default.post(Notification(name: Action.stateDidChangeNotification, object: action))
            return action
        }
        
        public static func ==(lhs: Action, rhs: Action) -> Bool {
            lhs.title == rhs.title && lhs.style == rhs.style
        }
    }
    
    public struct TextField {
        fileprivate let title: String
        fileprivate let isSecureTextEntry: Bool
        @Binding fileprivate var text: String
        
        public init(title: String, isSecureTextEntry: Bool = false, text: Binding<String>) {
            self.title = title
            self.isSecureTextEntry = isSecureTextEntry
            self._text = text
        }
    }
    
    public func textFields(@ArrayBuilder content: () -> [TextField]) -> Self {
        var alert = self
        alert.textFields = content()
        return alert
    }
    
    public func actions(@ArrayBuilder content: () -> [Action]) -> Self {
        var alert = self
        alert.actions = content()
        return alert
    }
    
    #if os(iOS)
    func makeUIAlertController(isPresented: Binding<Bool>) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        textFields.forEach { textField in
            func handleTextChange(notification: Notification) {
                guard let uiTextField = notification.object as? UITextField else {
                    return
                }
                
                guard let text = uiTextField.text else {
                    return
                }
                
                textField.text = text
            }
            
            alert.addTextField { uiTextField in
                uiTextField.text = textField.text
                uiTextField.placeholder = textField.title
                uiTextField.isSecureTextEntry = textField.isSecureTextEntry
                
                NotificationCenter.default.addObserver(forName:  UITextField.textDidChangeNotification, object: uiTextField, queue: .main, using: handleTextChange)
            }
        }
        
        actions.forEach { action in
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler?()
                isPresented.wrappedValue = false
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
    #elseif os(macOS)
    func makeNSAlert() -> NSAlert {
        let alert = NSAlert()
        
        alert.messageText = title
        if let message = message {
            alert.informativeText = message
        }
        
        actions.forEach { action in
            let button = alert.addButton(withTitle: action.title)
            button.isEnabled = !action.isDisabled
            
            NotificationCenter.default.addObserver(forName: Action.stateDidChangeNotification, object: nil, queue: .main) { notification in
                //
                if let observedAction = notification.object as? Action, action == observedAction {
                    button.isEnabled = !observedAction.isDisabled
                }
            }
        }
        
        let nsTextFields: [NSTextField] = textFields.map { textField in
            let nsTextField = textField.isSecureTextEntry ? NSSecureTextField() : NSTextField()
            
            func handleTextChange(notification: Notification) {
                guard let nsTextField = notification.object as? NSTextField else {
                    return
                }
                
                textField.text = nsTextField.stringValue
            }
            
            nsTextField.stringValue = textField.text
            nsTextField.placeholderString = textField.title
            NotificationCenter.default.addObserver(forName:  NSTextField.textDidChangeNotification  , object: nsTextField, queue: .main, using: handleTextChange)
            
            return nsTextField
        }
        
        if !nsTextFields.isEmpty {
            let stackView = NSStackView(views: nsTextFields)
            stackView.frame = CGRect(x: 0, y: 0, width: 230, height: CGFloat(nsTextFields.count) * 20 + CGFloat(nsTextFields.count - 1) * stackView.spacing)
            stackView.translatesAutoresizingMaskIntoConstraints = true
            stackView.orientation = .vertical
            alert.accessoryView = stackView
        }
        
        return alert
    }
    #endif
}

public struct AlertModifier : ViewModifier {
    @Binding var isPresented: Bool
    let alert: Alert
    
    public init(isPresented: Binding<Bool>, content: () -> Alert) {
        self._isPresented = isPresented
        self.alert = content()
    }
    
    public func body(content: Content) -> some View {
        content.onChange(of: isPresented) { isPresented in
            if isPresented {
                present()
            }
        }
    }
    
    private func present() {
        #if os(iOS)
        let uiAlertController = alert.makeUIAlertController(isPresented: $isPresented)
        UIApplication.shared.windows.first?.rootViewController?.present(uiAlertController, animated: true)
        #elseif os(macOS)
        let result = alert.makeNSAlert().runModal()
        let index = result.rawValue - 1000 // According to documentation
        alert.actions[index].handler?()
        isPresented = false
        #endif
    }
}

public typealias Action = Alert.Action
public typealias TextField = Alert.TextField

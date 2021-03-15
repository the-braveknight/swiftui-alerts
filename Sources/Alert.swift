//
//  File.swift
//  
//
//  Created by Zaid Rahhawi on 3/15/21.
//

import SwiftUI

public struct Alert {
    public let title: String
    public let message: String?
    
    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    struct Action {
        let title: String
        #if canImport(UIKit)
        let style: UIAlertAction.Style
        #elseif canImport(AppKit)
        let style: NSAlert.Style
        #endif
        let handler: (() -> Void)?
    }
    
    struct TextField {
        let title: String
        let isSecureTextEntry: Bool
        @Binding var text: String
    }
    
    var actions: [Action] = []
    var textFields: [TextField] = []
    
    public func addTextField(title: String, isSecureTextEntry: Bool = false, text: Binding<String>) -> Self {
        var alert = self
        alert.textFields.append(TextField(title: title, isSecureTextEntry: isSecureTextEntry, text: text))
        return alert
    }
}

public struct AlertModifier : ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> Alert
    
    public func body(content: Content) -> some View {
        content.onChange(of: isPresented) { isPresented in
            if isPresented {
                present()
            }
        }
    }
    
    private func present() {
        let alert = content()
        #if canImport(UIKit)
        let uiAlertController = alert.makeAlertController()
        UIApplication.shared.windows.first?.rootViewController?.present(uiAlertController, animated: true) {
            isPresented = false
        }
        #elseif canImport(AppKit)
        let result = alert.makeAlert().runModal()
        let index = result.rawValue - 1000 // According to documentation
        alert.actions[index].handler?()
        isPresented = false
        #endif
    }
}

public extension View {
    func alert(isPresented: Binding<Bool>, content: @escaping () -> Alert) -> some View {
        modifier(AlertModifier(isPresented: isPresented, content: content))
    }
}

#if canImport(UIKit)
public extension Alert {
    func addAction(title: String, style: UIAlertAction.Style, handler: (() -> Void)? = nil) -> Self {
        var alert = self
        alert.actions.append(Action(title: title, style: style, handler: handler))
        return alert
    }
    
    func makeAlertController() -> UIAlertController {
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
                uiTextField.placeholder = textField.title
                uiTextField.isSecureTextEntry = textField.isSecureTextEntry
                NotificationCenter.default.addObserver(forName:  UITextField.textDidChangeNotification, object: uiTextField, queue: .main, using: handleTextChange)
            }
        }
        
        actions.forEach { action in
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler?()
            }
            
            alert.addAction(alertAction)
        }
        
        return alert
    }
}
#endif

#if canImport(AppKit)
public extension Alert {
    func addAction(title: String, style: NSAlert.Style, handler: (() -> Void)? = nil) -> Self {
        var alert = self
        alert.actions.append(Action(title: title, style: style, handler: handler))
        return alert
    }
    
    func makeAlert() -> NSAlert {
        let alert = NSAlert()
        
        alert.messageText = title
        if let message = message {
            alert.informativeText = message
        }
        
        actions.forEach { action in
            alert.addButton(withTitle: action.title)
        }
        
        let textFields: [NSTextField] = self.textFields.map { textField in
            let nsTextField = textField.isSecureTextEntry ? NSSecureTextField() : NSTextField()
            
            func handleTextChange(notification: Notification) {
                guard let nsTextField = notification.object as? NSTextField else {
                    return
                }
                
                textField.text = nsTextField.stringValue
            }
            
            nsTextField.placeholderString = textField.title
            NotificationCenter.default.addObserver(forName:  NSTextField.textDidChangeNotification  , object: nsTextField, queue: .main, using: handleTextChange)
            
            return nsTextField
        }
        
        if !textFields.isEmpty {
            let stackView = NSStackView(views: textFields)
            stackView.frame = CGRect(x: 0, y: 0, width: 300, height: CGFloat(textFields.count) * 20 + CGFloat(textFields.count - 1) * stackView.spacing)
            stackView.translatesAutoresizingMaskIntoConstraints = true
            stackView.orientation = .vertical
            alert.accessoryView = stackView
        }
        
        return alert
    }
}
#endif

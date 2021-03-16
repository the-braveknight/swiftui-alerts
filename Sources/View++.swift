//
//  View++.swift
//  alert-app
//
//  Created by Zaid Rahhawi on 3/16/21.
//

import SwiftUI

public extension View {
    func alert(isPresented: Binding<Bool>, content: @escaping () -> Alert) -> some View {
        modifier(AlertModifier(isPresented: isPresented, content: content))
    }
    
    #if os(iOS)
    func actionSheet(isPresented: Binding<Bool>, content: @escaping () -> ActionSheet) -> some View {
        modifier(ActionSheetModifier(isPresented: isPresented, content: content))
    }
    #endif
}

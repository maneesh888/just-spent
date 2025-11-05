// MainContent.swift
import SwiftUI

struct MainContent: View {
    let items: [String]
    
    var body: some View {
        List(items, id: \.self) { item in
            Text(item)
                .padding()
        }
        .listStyle(InsetGroupedListStyle())
    }
}

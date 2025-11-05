// Header.swift
import SwiftUI

struct Header: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                // Add header button action here
            }) {
                Image(systemName: "plus")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)
        .cornerRadius(10)
    }
}

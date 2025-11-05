// Footer.swift
import SwiftUI

struct Footer: View {
    let footerText: String
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                // Add footer button action here
            }) {
                Text(footerText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

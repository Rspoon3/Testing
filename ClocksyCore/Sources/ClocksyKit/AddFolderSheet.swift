import SwiftUI

struct AddFolderSheet: View {
    @Binding var isPresented: Bool
    @Binding var folderName: String
    @Binding var selectedColor: Color
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#FFF5E6"),
                        Color(hex: "#FFE8D6")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Folder Name")
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#8B7355"))
                        
                        TextField("e.g. Home, Work, Mental Health", text: $folderName)
                            .font(.custom("Avenir Next", size: 18))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.8))
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Folder Color")
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#8B7355"))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ThemeColors.allColors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color(hex: "#5C4033") : Color.clear, lineWidth: 3)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 60))
                            .foregroundColor(selectedColor)
                        
                        Text(folderName.isEmpty ? "Preview" : folderName)
                            .font(.custom("Avenir Next", size: 20))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#5C4033"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.5))
                    )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                        folderName = ""
                    }
                    .foregroundColor(Color(hex: "#8B7355"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#D4A373"))
                    .disabled(folderName.isEmpty)
                }
            }
        }
    }
}
import SwiftUI
import AVFoundation
import UIKit
import Combine
import PhotosUI


extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3: // RGB (12-bit) e.g., "FFF"
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit) e.g., "FFFFFF"
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit) e.g., "FFFFFFFF"
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to black if hex format is unrecognized
        }

        self.init(
            .sRGB, // Color space
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
// MARK: - Main App
struct FoodLensApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Content View
struct ContentView: View {
    @StateObject private var viewModel = FoodViewModel()
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    @State private var isAnalyzing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "F9F9F9"), Color(hex: "F0F0F0")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView(title: "Dotmini Foodx Callories")
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            if let image = viewModel.capturedImage {
                                FoodImageView(image: image, isAnalyzing: $isAnalyzing) {
                                    withAnimation {
                                        viewModel.capturedImage = nil
                                        viewModel.foodAnalysis = nil
                                    }
                                }
                            } else {
                                ImagePickerOptionsView(
                                    onCameraSelected: {
                                        imageSource = .camera
                                        showImagePicker = true
                                    },
                                    onGallerySelected: {
                                        imageSource = .photoLibrary
                                        showImagePicker = true
                                    }
                                )
                            }
                            
                            if let analysis = viewModel.foodAnalysis {
                                FoodAnalysisView(analysis: analysis)
                            } else if isAnalyzing {
                                AnalyzingView()
                            } else if viewModel.capturedImage != nil {
                                AnalyzeButtonView {
                                    isAnalyzing = true
                                    Task {
                                        await viewModel.analyzeFood()
                                        isAnalyzing = false
                                    }
                                }
                            } else {
                                InstructionsView()
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: imageSource, selectedImage: { image in
                    viewModel.setImage(image)
                })
            }
            .navigationBarHidden(true)
            .onChange(of: showImagePicker) { newValue in
                if !newValue {
                    imageSource = .camera
                }
            }
        }
    }
}

// Header View
struct HeaderView: View {
    var title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "333333"))
            
            Spacer()
            
            Image(systemName: "gearshape.fill")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "007AFF"))
                .padding(8)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color.white.opacity(0.8))
    }
}

// Image Picker Options View
struct ImagePickerOptionsView: View {
    var onCameraSelected: () -> Void
    var onGallerySelected: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Image Source")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "333333"))
                .padding(.top)
            
            HStack(spacing: 30) {
                VStack {
                    Button(action: onCameraSelected) {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "007AFF"), Color(hex: "5856D6")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color(hex: "5856D6").opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    Text("Camera")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "333333"))
                        .padding(.top, 8)
                }
                
                VStack {
                    Button(action: onGallerySelected) {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "FF9500"), Color(hex: "FF3B30")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color(hex: "FF9500").opacity(0.5), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    Text("Gallery")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "333333"))
                        .padding(.top, 8)
                }
            }
            .padding(.vertical, 20)
            
            Text("Take a photo or select one from your gallery to analyze its nutritional content")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color(hex: "666666"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Food Image View
struct FoodImageView: View {
    var image: UIImage
    @Binding var isAnalyzing: Bool
    var onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .cornerRadius(15)
                    .clipped()
                
                if !isAnalyzing {
                    Button(action: onReset) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .padding(10)
                }
            }
            
            if !isAnalyzing {
                Text("Your food image")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "666666"))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Analyze Button View
struct AnalyzeButtonView: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                Text("Analyze Food")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "34C759"), Color(hex: "30B350")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(15)
            .shadow(color: Color(hex: "34C759").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Analyzing View
struct AnalyzingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "007AFF"))
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Analyzing your food...")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "333333"))
            
            Text("Using AI to identify ingredients and nutrition facts")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color(hex: "666666"))
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Food Analysis View
struct FoodAnalysisView: View {
    var analysis: FoodAnalysis
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(analysis.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "333333"))
                    
                    Spacer()
                    
                    Label("\(analysis.calories) kcal", systemImage: "flame.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "FF9500"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "FF9500").opacity(0.15))
                        .cornerRadius(12)
                }
                
                Text(analysis.description)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Color(hex: "666666"))
                    .padding(.vertical, 8)
            }
            .padding()
            
            HStack(spacing: 0) {
                ForEach(["Nutrition", "Vitamins", "Details"], id: \.self) { tab in
                    let index = ["Nutrition", "Vitamins", "Details"].firstIndex(of: tab) ?? 0
                    
                    Button(action: {
                        withAnimation {
                            selectedTab = index
                        }
                    }) {
                        Text(tab)
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular, design: .rounded))
                            .foregroundColor(selectedTab == index ? Color(hex: "007AFF") : Color(hex: "999999"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .background(Color(hex: "F5F5F5"))
            
            GeometryReader { geometry in
                let width = geometry.size.width / 3
                
                Rectangle()
                    .fill(Color(hex: "007AFF"))
                    .frame(width: width, height: 3)
                    .offset(x: CGFloat(selectedTab) * width)
                    .animation(.spring(), value: selectedTab)
            }
            .frame(height: 3)
            
            TabView(selection: $selectedTab) {
                NutritionTabView(macros: analysis.macros)
                    .tag(0)
                
                VitaminsTabView(vitamins: analysis.vitamins)
                    .tag(1)
                
                DetailsTabView(ingredients: analysis.ingredients, allergies: analysis.allergies)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Nutrition Tab
struct NutritionTabView: View {
    var macros: [MacroNutrient]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(macros) { macro in
                MacroNutrientRow(macro: macro)
            }
            
            Spacer()
        }
        .padding()
    }
}

// Vitamins Tab
struct VitaminsTabView: View {
    var vitamins: [Vitamin]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(vitamins) { vitamin in
                    VitaminRow(vitamin: vitamin)
                }
            }
            .padding()
        }
    }
}

// Details Tab
struct DetailsTabView: View {
    var ingredients: [String]
    var allergies: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "333333"))
                    
                    ForEach(ingredients, id: \.self) { ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(Color(hex: "999999"))
                                .padding(.top, 6)
                            
                            Text(ingredient)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(Color(hex: "666666"))
                            
                            Spacer()
                        }
                    }
                }
                
                Divider()
                
                if !allergies.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Allergy Info")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "333333"))
                        
                        ForEach(allergies, id: \.self) { allergy in
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "FF3B30"))
                                
                                Text(allergy)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(Color(hex: "666666"))
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// Macro Nutrient Row
struct MacroNutrientRow: View {
    var macro: MacroNutrient
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(macro.name, systemImage: macro.icon)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "333333"))
                
                Spacer()
                
                Text("\(macro.amount) \(macro.unit)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "333333"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "EEEEEE"))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color(hex: macro.color))
                        .frame(width: min(CGFloat(macro.percentage) / 100 * geometry.size.width, geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Daily Value")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "999999"))
                
                Spacer()
                
                Text("\(macro.percentage)%")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: macro.color))
            }
        }
    }
}

// Vitamin Row
struct VitaminRow: View {
    var vitamin: Vitamin
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vitamin.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(vitamin.benefit)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "666666"))
                    .lineLimit(2)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color(hex: "EEEEEE"), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: CGFloat(vitamin.percentage) / 100)
                    .stroke(Color(hex: vitamin.color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(vitamin.percentage)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: vitamin.color))
            }
        }
    }
}

// Instructions View
struct InstructionsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "007AFF"))
                .padding(.bottom, 10)
            
            Text("Discover What You're Eating")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "333333"))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                InstructionRow(
                    icon: "camera.fill",
                    color: "FF9500",
                    title: "Take a photo",
                    description: "Snap a clear photo of your food"
                )
                
                InstructionRow(
                    icon: "wand.and.stars",
                    color: "5856D6",
                    title: "AI Analysis",
                    description: "Our AI identifies your food"
                )
                
                InstructionRow(
                    icon: "heart.fill",
                    color: "FF2D55",
                    title: "Get Nutrition Facts",
                    description: "See calories, vitamins, and more"
                )
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct InstructionRow: View {
    var icon: String
    var color: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: color).opacity(0.15))
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: color))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "333333"))
                
                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "666666"))
            }
            
            Spacer()
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var selectedImage: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selectedImage: selectedImage)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var selectedImage: (UIImage) -> Void
        
        init(selectedImage: @escaping (UIImage) -> Void) {
            self.selectedImage = selectedImage
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                selectedImage(image)
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct GeminiRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig?

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String?
        let inlineData: InlineData?

        init(text: String) {
            self.text = text
            self.inlineData = nil
        }

        init(inlineData: InlineData) {
            self.text = nil
            self.inlineData = inlineData
        }
    }

    struct InlineData: Codable {
        let mimeType: String
        let data: String // Base64 encoded image
    }

    struct GenerationConfig: Codable {
        let responseMimeType: String
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]?
    let error: GeminiError? // สำหรับรับ error message จาก Google API โดยตรง

    struct Candidate: Codable {
        let content: Content?
        let finishReason: String?
        let safetyRatings: [SafetyRating]?
    }

    struct Content: Codable {
        let parts: [Part]?
    }

    struct Part: Codable {
        let text: String? // JSON ของ FoodAnalysis จะอยู่ในนี้ (ถ้า prompt ถูกต้อง)
    }

    struct SafetyRating: Codable {
        let category: String
        let probability: String
    }
    
    struct GeminiError: Codable {
        let code: Int?
        let message: String?
        let status: String?
    }
}

struct FoodAnalysis: Codable, Identifiable {
    let id: UUID // Use UUID for a unique, Codable identifier

    let name: String
    let description: String
    let calories: Int
    let macros: [MacroNutrient] // Ensure MacroNutrient is Codable & Identifiable
    let vitamins: [Vitamin]   // Ensure Vitamin is Codable & Identifiable
    let ingredients: [String]
    let allergies: [String]

    // Define CodingKeys if your JSON keys are different from your property names
    // OR if you want to exclude a property (like 'id') from direct JSON mapping.
    enum CodingKeys: String, CodingKey {
        // 'id' is NOT listed here because we assume it's not in the API's JSON for FoodAnalysis itself.
        // We will initialize 'id' manually in the custom decoder.
        case name, description, calories, macros, vitamins, ingredients, allergies
    }

    // Custom Initializer for Decodable conformance
    // This allows 'id' to be initialized even if it's not in the JSON payload.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode all properties that ARE expected from the JSON
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        calories = try container.decode(Int.self, forKey: .calories)
        macros = try container.decode([MacroNutrient].self, forKey: .macros)
        vitamins = try container.decode([Vitamin].self, forKey: .vitamins)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        allergies = try container.decode([String].self, forKey: .allergies)
        
        // Manually initialize the 'id' property with a new UUID.
        // This makes the struct Identifiable without requiring 'id' to be in the JSON.
        self.id = UUID()
    }

    // Optional: Add a memberwise initializer if you also create FoodAnalysis objects manually in your code.
    // This is separate from the Codable init(from:) used for JSON decoding.
    init(id: UUID = UUID(), name: String, description: String, calories: Int, macros: [MacroNutrient], vitamins: [Vitamin], ingredients: [String], allergies: [String]) {
        self.id = id
        self.name = name
        self.description = description
        self.calories = calories
        self.macros = macros
        self.vitamins = vitamins
        self.ingredients = ingredients
        self.allergies = allergies
    }
}

// Make sure MacroNutrient and Vitamin are also Codable and Identifiable
// (Your previous definitions for these were likely fine, just ensure they remain so)
struct MacroNutrient: Codable, Identifiable {
    let id = UUID() // Or: let id: String // if your API provides a unique string ID
    let name: String
    let amount: Int
    let unit: String
    let percentage: Int
    let icon: String  // This will be a string (e.g., SF Symbol name)
    let color: String // This will be a string (e.g., hex color code)

    // If 'id' is not "id" in JSON or you want to exclude the default UUID during encoding
    private enum CodingKeys: String, CodingKey {
        // Exclude 'id' if it's only for local Identifiable conformance and not in API JSON
        case name, amount, unit, percentage, icon, color
    }
    
    // If your API *does* provide an ID for MacroNutrient, adjust CodingKeys accordingly
    // and change `let id = UUID()` to `let id: ExpectedIDType`.
}

struct Vitamin: Codable, Identifiable {
    let id = UUID() // Or: let id: String
    let name: String
    let percentage: Int
    let benefit: String
    let color: String // String for hex color code

    private enum CodingKeys: String, CodingKey {
        case name, percentage, benefit, color
    }
}

// MARK: - FoodViewModel
class FoodViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var foodAnalysis: FoodAnalysis?
    @Published var errorMessage: String?
    @Published var isAnalyzing: Bool = false

    // --- 🚫 สำคัญมาก: ใส่ API Key ใหม่ที่คุณสร้างขึ้นมา และไม่เคยเปิดเผยที่ไหน 🚫 ---
    private let geminiAPIKey = "AIzaSyBDtilDoS-VEtRzC8ascLHs9Af1aafpafs" // <--- ใส่ KEY ใหม่ของคุณที่นี่!!!

    // --- ✨ เลือกใช้ Vision Model ที่เหมาะสม ✨ ---
    private let visionModel = "gemini-2.0-flash" // หรือ "gemini-1.5-flash", "gemini-1.5-pro" (ตรวจสอบรุ่นล่าสุด)

    // Computed property สำหรับ API URL ที่ถูกต้อง
    private var apiURL: URL? {
        // ประกอบ URL ให้ถูกต้อง โดยใส่ API Key เข้าไปใน query parameter
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(visionModel):generateContent?key=\(geminiAPIKey)")
    }

    func setImage(_ image: UIImage?) { // อนุญาตให้ set nil ได้ เพื่อ reset
        self.capturedImage = image
        self.foodAnalysis = nil
        self.errorMessage = nil
        self.isAnalyzing = false // Reset สถานะเมื่อมีการตั้งค่ารูปใหม่
    }

    func analyzeFood() async {
        guard let image = capturedImage else {
            await MainActor.run { self.errorMessage = "ยังไม่ได้เลือกรูปภาพ" }
            return
        }
        guard let validApiURL = apiURL else {
          
            await MainActor.run { self.errorMessage = "API URL ไม่ถูกต้อง (อาจเกิดจาก API Key มีปัญหา)" }
            return
        }

        await MainActor.run {
            self.isAnalyzing = true
            self.errorMessage = nil
            self.foodAnalysis = nil
        }

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            await MainActor.run {
                self.errorMessage = "ไม่สามารถแปลงรูปภาพเป็นข้อมูลได้"
                self.isAnalyzing = false
            }
            return
        }
        let base64Image = imageData.base64EncodedString()

        
        let promptText = """
        Analyze the food in the provided image. Identify the food and provide its nutritional information.
        Return the output ONLY as a single, valid JSON object that strictly follows this structure:
        {
          "name": "string (food name)",
          "description": "string (brief description of the food)",
          "calories": integer (total kilocalories),
          "macros": [
            {"name": "Protein", "amount": integer, "unit": "g", "percentage": integer (daily value %), "icon": "fish.fill", "color": "FF6347"},
            {"name": "Carbohydrates", "amount": integer, "unit": "g", "percentage": integer (daily value %), "icon": "leaf.fill", "color": "FFD700"},
            {"name": "Fat", "amount": integer, "unit": "g", "percentage": integer (daily value %), "icon": "drop.fill", "color": "4682B4"}
          ],
          "vitamins": [
            {"name": "Vitamin A", "percentage": integer (daily value %), "benefit": "string (brief benefit)", "color": "FFA500"},
            {"name": "Vitamin C", "percentage": integer (daily value %), "benefit": "string (brief benefit)", "color": "32CD32"}
          ],
          "ingredients": ["string (list of common ingredients)"],
          "allergies": ["string (list of common allergens if any, e.g., 'Peanuts', 'Dairy')"]
        }
        Do not include any explanatory text, markdown formatting, or anything else before or after the JSON object itself.
        For "icon" and "color" fields, provide generic string placeholders if actual SF Symbol names or specific hex colors are not applicable, or use the examples if suitable.
        If the food cannot be clearly identified or nutritional details are unavailable, provide best estimates or indicate unknown values appropriately within the JSON structure (e.g., for numeric fields use 0 or -1, for string fields use "Unknown" or "N/A").
        """

      
        let requestPayload = GeminiRequest(
            contents: [
                .init(parts: [
                    .init(text: promptText), // ส่วนของ Prompt
                    .init(inlineData: .init(mimeType: "image/jpeg", data: base64Image)) // ส่วนของรูปภาพ
                ])
            ],
            generationConfig: .init(responseMimeType: "application/json") // ขอให้ AI ตอบกลับเป็น JSON
        )

        var request = URLRequest(url: validApiURL) // ใช้ validApiURL ที่มีการใส่ key ถูกต้องแล้ว
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(requestPayload)
            request.httpBody = jsonData

            // Debug: พิมพ์ JSON request body เพื่อตรวจสอบ
            // if let jsonString = String(data: jsonData, encoding: .utf8) {
            //      print("➡️ Gemini Request Body: \(jsonString)")
            // }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "การตอบกลับจาก Server ไม่ใช่ HTTP response ที่ถูกต้อง"])
            }

            // Debug: พิมพ์ Raw Response จาก Server ทุกครั้งเพื่อการวิเคราะห์
            if let rawResponseString = String(data: data, encoding: .utf8) {
                 print("⬅️ Raw Server Response [\(httpResponse.statusCode)]: \(rawResponseString)")
            }

            if httpResponse.statusCode != 200 {
                var serverErrorMessage = "การตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง (สถานะ: \(httpResponse.statusCode))"
                // พยายาม decode error message จาก Google API โดยตรง
                do {
                    let errorResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    if let apiError = errorResponse.error {
                        serverErrorMessage = "API Error \(apiError.code ?? httpResponse.statusCode): \(apiError.message ?? "Unknown error from API.")"
                    } else if let candidateErrorPart = errorResponse.candidates?.first?.content?.parts?.first?.text, !candidateErrorPart.isEmpty {
                         serverErrorMessage = "API Response issue: \(candidateErrorPart)"
                    } else if let rawString = String(data: data, encoding: .utf8), !rawString.isEmpty {
                        serverErrorMessage += " Details: \(rawString)"
                    }
                } catch {
                     // ไม่สามารถ decode error response ของ Google ได้, ใช้ข้อความทั่วไปพร้อม raw data ถ้ามี
                    if let dataString = String(data: data, encoding: .utf8), !dataString.isEmpty {
                        serverErrorMessage += " Raw Details: \(dataString)"
                    }
                }
                // ใช้ httpResponse.statusCode จริงๆ ใน code ของ NSError
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverErrorMessage])
            }

            // Decode Gemini API Response หลัก
            let geminiApiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            // ดึงส่วนที่เป็น JSON text ที่ AI สร้างขึ้น (ซึ่งควรจะตรงกับ FoodAnalysis struct)
            guard let candidate = geminiApiResponse.candidates?.first else {
                throw NSError(domain: "APIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "ไม่พบ 'candidates' ในการตอบกลับของโมเดล."])
            }

            if candidate.finishReason != "STOP" && candidate.finishReason != nil {
                 var reasonMessage = "โมเดลหยุดทำงานด้วยเหตุผล: \(candidate.finishReason!)"
                 if let safetyIssues = candidate.safetyRatings?.filter({ $0.probability != "NEGLIGIBLE" && $0.probability != "LOW" }), !safetyIssues.isEmpty {
                     reasonMessage += ". Safety issues: " + safetyIssues.map { "\($0.category): \($0.probability)" }.joined(separator: ", ")
                 }
                 throw NSError(domain: "APIError", code: 1, userInfo: [NSLocalizedDescriptionKey: reasonMessage])
            }

            guard let contentPart = candidate.content?.parts?.first,
                  let jsonTextFromModel = contentPart.text else {
                throw NSError(domain: "APIError", code: 1, userInfo: [NSLocalizedDescriptionKey: "ไม่สามารถดึงข้อมูล JSON text จาก 'parts' ในการตอบกลับของโมเดลได้."])
            }
            
            // Debug: พิมพ์ JSON string ที่ได้จาก Model เพื่อตรวจสอบก่อน decode FoodAnalysis
            // print("ℹ️ JSON String from Model for FoodAnalysis: \(jsonTextFromModel)")

            guard let foodAnalysisData = jsonTextFromModel.data(using: .utf8) else {
                throw NSError(domain: "DecodingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "ไม่สามารถแปลงข้อความ JSON ที่ได้จากโมเดลเป็น Data ได้: \(jsonTextFromModel)"])
            }
            
            let decoder = JSONDecoder()
            let analysisResult = try decoder.decode(FoodAnalysis.self, from: foodAnalysisData)

            await MainActor.run {
                self.foodAnalysis = analysisResult
                self.errorMessage = nil // เคลียร์ error ถ้าสำเร็จ
            }

        } catch let decodingError as DecodingError {
            var errorMsg = "เกิดข้อผิดพลาดในการถอดรหัสข้อมูล (DecodingError): "
            // (รายละเอียดของ decoding error ต่างๆ สามารถคงไว้เหมือนเดิมเพื่อช่วย debug)
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMsg += "ไม่พบ Key '\(key.stringValue)' - \(context.debugDescription) Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let value, let context):
                errorMsg += "ไม่พบ Value สำหรับ Type '\(value)' - \(context.debugDescription) Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMsg += "Type ไม่ตรงกันสำหรับ Type '\(type)' - \(context.debugDescription) Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMsg += "ข้อมูลเสียหาย - \(context.debugDescription) Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            @unknown default:
                errorMsg += "Unknown decoding error."
            }
            print("🔴 \(errorMsg)")
            await MainActor.run {
                self.errorMessage = "ไม่สามารถแปลผลข้อมูลที่ได้รับ. กรุณาตรวจสอบ Console สำหรับรายละเอียด."
            }
        }
        catch { // Error อื่นๆ รวมถึง APIError ที่ throw ไว้ข้างบน
            print("🔴 Error during food analysis: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            self.isAnalyzing = false // สิ้นสุดการวิเคราะห์เสมอ
        }
    }
}

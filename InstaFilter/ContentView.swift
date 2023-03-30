//
//  ContentView.swift
//  InstaFilter
//
//  Created by Danjuma Nasiru on 13/02/2023.
//

import CoreImage
import CoreImage.CIFilterBuiltins
// to access for biometrics like fingerprint/faceID, import LocalAuthentication. Also make sure to create another key in target project and select "Privacy - Face ID Usage Description" then set the string description that you'll also use as the reason context.evaluatePolicy localizedReason parameter.
import LocalAuthentication
import SwiftUI


struct ContentView: View {
    
    @State private var image : Image?
    @State private var inputImage : UIImage?
    @State private var processedImage: UIImage?
    
    @State private var filterIntensity : Double = 0.0
    @State private var filterRadius = 500.0
    @State private var filterScale = 50.0
    
    @State private var currentFilter : CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    @State private var showingImagePicker = false
    
    @State private var unlocked = true //should be false if i intend to use biometrics verification
    
    @State private var showingFilterSheet = false
    
    var imageAvailable : Bool{
        image != nil
    }
    
    
    var body: some View {
        
        if unlocked{
            NavigationView{
                VStack{
                    
                    Spacer()
                    
                    ZStack{
                        Rectangle()
                            .fill(.secondary)
                        Text(!imageAvailable ? "Tap to select a picture" : "")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        image?
                            .resizable()
                            .frame(height: 300)
                            .scaledToFit()
                        
                    }
                    .frame(height: 300)
                    .onTapGesture {
                        showingImagePicker = true
                    }
                    
                    Spacer()
                    VStack{
                        HStack{
                            VStack{
                                Text("Intensity")
                                Slider(value: $filterIntensity)
                                    .onChange(of: filterIntensity, perform: {_ in applyProcessing()})
                                Text("\(filterIntensity , specifier: "%.1f")")
                            }
                            
                            
                        }
                        .padding(.vertical)
                        
                        HStack{
                            VStack(spacing: 5){
                                Text("scale")
                                Slider(value: $filterScale, in: 0...100, step: 10)
                                    .onChange(of: filterScale, perform: {_ in applyProcessing()})
                                Text(filterScale.formatted())
                            }
                            
                            VStack(spacing: 5){
                                Text("Radius")
                                Slider(value: $filterRadius, in: 0...1000, step: 50)
                                    .onChange(of: filterRadius, perform: {_ in applyProcessing()})
                                Text(filterRadius.formatted())
                            }
                        }
                        .padding(.vertical)
                        
                        
                    }
                    
                    HStack {
                        Button("Change Filter") {
                            showingFilterSheet = true
                        }
                        .padding(10)
                        .background(imageAvailable ? CustomColor.alatRed : Color.gray)
                        .foregroundColor(CustomColor.light_white_dark_black)
                        .cornerRadius(10)
                        .disabled(!imageAvailable)
                        
                        Spacer()
                        
                        Button("Save", action: save)
                            .padding(10)
                            .background(imageAvailable ? CustomColor.alatRed : Color.gray)
                            .foregroundColor(CustomColor.light_white_dark_black)
                            .cornerRadius(10)
                            .disabled(!imageAvailable)
                    }
                }
                .padding([.horizontal, .bottom])
                .navigationTitle("Instafilter")
                .onChange(of: inputImage){_ in loadImage()}
                .sheet(isPresented: $showingImagePicker){
                    ImagePicker(image: $inputImage)
                }
                .confirmationDialog("Select Filter", isPresented: $showingFilterSheet){
                    HStack{
                        Button("Crystallize") { setFilter(CIFilter.crystallize())
                        }
                        Button("Edges") {
                            setFilter(CIFilter.edges())
                        }
                    }
                    HStack{
                        Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur())
                        }
                        Button("Pixellate") { setFilter(CIFilter.pixellate())
                        }
                    }
                    HStack{
                        Button("Sepia Tone") { setFilter(CIFilter.sepiaTone())
                        }
                        Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask())
                        }
                    }
                    HStack{
                        Button("Vignette") {
                            setFilter(CIFilter.vignette())
                        }
                        Button("Twirl Distortion"){
                            setFilter(CIFilter.twirlDistortion())
                        }
                    }
                    HStack{
                        Button("Mask to Alpha"){
                            setFilter(.maskToAlpha())
                        }
                        Button("Zoom Blur"){
                            setFilter(.zoomBlur())
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        
                    }
                    
                
            }
        }
    }else{
        Button("Unlock"){
            authenticate()
        }
    }
    
}

func loadImage() {
    guard let inputImage = inputImage else { return }
    
    let beginImage = CIImage(image: inputImage)
    currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
    applyProcessing()
}

func save (){
    guard let processedImage = processedImage else {
        return
    }
    let imageSaver = ImageSaver()
    
    imageSaver.successHandler = {
        print("Success!")
    }
    
    imageSaver.errorHandler = {
        print("Oops: \($0.localizedDescription)")
    }
    
    imageSaver.writeToPhotoAlbum(image: processedImage)
}

func applyProcessing() {
    let inputKeys = currentFilter.inputKeys
    
    if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
    if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
    if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }
    
    guard let outputImage = currentFilter.outputImage else { return }
    
    if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
        let uiImage = UIImage(cgImage: cgimg)
        image = Image(uiImage: uiImage)
        processedImage = uiImage
    }
}

func setFilter (_ filter: CIFilter){
    currentFilter = filter
    loadImage()
}

func authenticate(){
    let context = LAContext()
    var error : NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
        //this string is used with touchID. The one we set in project options to get permission is used with faceID
        let reason = "We need to confirm its you"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason, reply: {success, authenticationError in
            if success{
                unlocked = true
            }else{
                print("error")
            }
        })
    }
    else{
        print("Can't handle biometrics")
    }
}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

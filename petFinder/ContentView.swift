import SwiftUI
import MapKit
import PhotosUI

protocol MapSelectable {
    var mapSelectionIdentifier: String { get }
}

struct PetReport: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    let imageData: Data?
    let description: String
    
}

extension PetReport: MapSelectable {
    var mapSelectionIdentifier: String {
        id.uuidString
    }
}

struct ContentView: View {
    // Exemple de données fictives
        @State private var petReports = [
            PetReport(
                title: "Chien trouvé – Max 🐶",
                coordinate: CLLocationCoordinate2D(latitude: 45.4215, longitude: -75.6972),
                imageName: "chien_max",
                imageData: nil,
                description: "Berger allemand mâle, collier rouge, trouvé près du parc Major's Hill. Contact: 613-555-1234"
            ),
            PetReport(
                title: "Chat trouvé – Noir 🐱",
                coordinate: CLLocationCoordinate2D(latitude: 45.4290, longitude: -75.6890),
                imageName: "chat_noir",
                imageData: nil,
                description: "Chat noir avec tache blanche, puce électronique détectée. Actuellement chez un vétérinaire."
            ),
            PetReport(
                title: "Cochon d'Inde trouvé 🐹",
                coordinate: CLLocationCoordinate2D(latitude: 45.4050, longitude: -75.6890),
                imageName: "cochon_inde",
                imageData: nil,
                description: "Cochon d'Inde caramel répondant à 'Caramel', trouvé près du marché By. Cage temporaire."
            ),
            PetReport(
                title: "Perroquet trouvé 🦜",
                coordinate: CLLocationCoordinate2D(latitude: 45.4480, longitude: -75.6890),
                imageName: "perroquet",
                imageData: nil,
                description: "Ara bleu parlant trouvé à Gatineau, aile soignée. Récompense pour preuve de propriété."
            )
        ]

    @State private var selectedPetReport: PetReport?
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Nouveaux States pour l'ajout
    @State private var isSelectingLocation = false
    @State private var newPetLocation: CLLocationCoordinate2D?
    @State private var newPetTitle = ""
    @State private var newPetDescription = ""
    
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(petReports) { report in
                        Annotation(report.title, coordinate: report.coordinate) {
                            PetAnnotationView(report: report, selectedPetReport: $selectedPetReport)
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onTapGesture { location in
                    guard isSelectingLocation else { return }
                    
                    Task {
                        if let coordinate =  proxy.convert(location, from: .local) {
                            newPetLocation = coordinate
                            isSelectingLocation = false
                        }
                    }
                }
            }

            // Bouton Ajouter Animal
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isSelectingLocation.toggle()
                    }) {
                        Image(systemName: isSelectingLocation ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(isSelectingLocation ? .red : .blue)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSelectingLocation ? Color.red : Color.blue, lineWidth: 3)
                            )
                            .shadow(radius: 4)
                            .animation(.easeInOut, value: isSelectingLocation)
                    }
                }
                .padding()
            }
        }

        // Sheet : Ajouter Titre & Description
        .sheet(isPresented: Binding<Bool>(
            get: { newPetLocation != nil },
            set: { if !$0 { newPetLocation = nil } }
        )) {
            if let location = newPetLocation {
                VStack {
                    Text("Ajouter un animal")
                        .font(.headline)
                        .padding(.top)

                    TextField("Titre", text: $newPetTitle)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    TextField("Description", text: $newPetDescription)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    PhotosPicker(
                        selection: $selectedPickerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Ajouter une image", systemImage: "photo")
                            .frame(width: 200)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .onChange(of: selectedPickerItem) {
                        Task {
                            if let data = try? await selectedPickerItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }

                    Button("Enregistrer") {
                        let newReport = PetReport(
                            title: newPetTitle,
                            coordinate: location,
                            imageName: newPetTitle,
                            imageData: selectedImageData,
                            description: newPetDescription
                        )
                        petReports.append(newReport)
                        newPetTitle = ""
                        newPetDescription = ""
                        newPetLocation = nil
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                }
                .padding(.vertical)
                .presentationDetents([.height(300)]) // Taille fixe de 300 points
                .presentationDragIndicator(.visible) // Montre l'indicateur de drag
            }
        }
        

        // Sheet pour visualiser les détails
        .sheet(item: $selectedPetReport) { report in
            VStack {
            Spacer()
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: { selectedPetReport = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                
                ScrollView {
                    VStack(spacing: 15) {
                        
                        if let data = report.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)
                        } else{
                            Image(report.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(10)

                        }
                        
                        Text(report.title)
                            .font(.title2.bold())
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Description :")
                                .fontWeight(.bold)
                                .font(.headline)
                            Text(report.description)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                
                Button(action: {
                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: report.coordinate))
                    mapItem.name = report.title
                    mapItem.openInMaps()
                }) {
                    Label("Ouvrir dans Plans", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 5)
            )
            .padding(.horizontal, 10)
        }
        .presentationBackground(.clear)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct PetAnnotationView: View {
    let report: PetReport
    @Binding var selectedPetReport: PetReport?

    var body: some View {
        Group {
            if let data = report.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else if UIImage(named: report.imageName) != nil {
                Image(report.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "pawprint.circle.fill")
                    .font(.title)
                    .foregroundColor(.red)
            }

        }
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(radius: 3)
        .onTapGesture {
            selectedPetReport = report
        }
    }
}

#Preview {
    ContentView()
}

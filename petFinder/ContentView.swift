import SwiftUI
import MapKit

protocol MapSelectable {
    var mapSelectionIdentifier: String { get }
}

struct PetReport: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let imageName: String
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
                description: "Berger allemand mâle, collier rouge, trouvé près du parc Major's Hill. Contact: 613-555-1234"
            ),
            PetReport(
                title: "Chat trouvé – Noir 🐱",
                coordinate: CLLocationCoordinate2D(latitude: 45.4290, longitude: -75.6890),
                imageName: "chat_noir",
                description: "Chat noir avec tache blanche, puce électronique détectée. Actuellement chez un vétérinaire."
            ),
            PetReport(
                title: "Cochon d'Inde trouvé 🐹",
                coordinate: CLLocationCoordinate2D(latitude: 45.4000, longitude: -75.6830),
                imageName: "cochon_inde",
                description: "Cochon d'Inde caramel répondant à 'Caramel', trouvé près du marché By. Cage temporaire."
            ),
            PetReport(
                title: "Perroquet trouvé 🦜",
                coordinate: CLLocationCoordinate2D(latitude: 45.4485, longitude: -75.7000),
                imageName: "perroquet",
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

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(petReports) { report in
                        Annotation(report.title, coordinate: report.coordinate) {
                            Image(report.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 3)
                                .onTapGesture {
                                    selectedPetReport = report // Ceci déclenchera le sheet
                                }
                        }
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .gesture(
                    DragGesture(minimumDistance: 0).onEnded { value in
                        guard isSelectingLocation else { return }
                        
                        // Obtenir la position du tap
                        let location = value.location
                        
                        // Convertir en coordonnées géographiques
                        if let coordinate = proxy.convert(location, from: .local) {
                            newPetLocation = coordinate
                            isSelectingLocation = false
                        }
                    }
                )
                
            }

            // Bouton Ajouter Animal
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isSelectingLocation = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .padding()
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
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

                    Button("Enregistrer") {
                        let newReport = PetReport(
                            title: newPetTitle,
                            coordinate: location,
                            imageName: "dog",
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
        

        // Sheet pour visualiser les détails (version améliorée)
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
                        Image(report.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(10)
                        
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

#Preview {
    ContentView()
}

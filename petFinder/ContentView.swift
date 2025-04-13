import SwiftUI
import MapKit
import CoreLocation

struct PetReport: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    let description: String
}

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.4215, longitude: -75.6972),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    
    @State private var selectedReport: PetReport?
    
    @State private var showingAddSheet = false
    @State private var newPetLocation: CLLocationCoordinate2D?
    @State private var newPetTitle = ""
    @State private var newPetDescription = ""
    
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
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(petReports) { report in
                    Annotation(report.title, coordinate: report.coordinate) {
                        Button(action: { selectedReport = report }) {
                            VStack {
                                Image(report.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 3)
                                
                                Text(report.title)
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                // Gestion du clic sur la carte
                
                // Position utilisateur
                if let userLocation = locationManager.lastLocation {
                    Annotation("Ma position", coordinate: userLocation.coordinate) {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                }
            }
            
            .onTapGesture { location in
                if showingAddSheet {
                    // Convertir le CGPoint en coordonnées géographiques
                    let coordinate = convertPointToCoordinate(location)
                    newPetLocation = coordinate
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
                                   
            // Bouton pour centrer la carte sur la position de l'utilisateur
            VStack {
                Spacer()
                HStack {
                    // Bouton d'ajout (nouveau)
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    // Bouton de localisation (existant)
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing)
                }
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
        }
            
        // sheet pour vesuailise les details d'un animal perdu/trouve
        .sheet(item: $selectedReport) { report in
            VStack {
                Spacer() // Pousse tout le contenu vers le bas
                
                VStack(spacing: 20) {
                    // Header avec bouton de fermeture
                    HStack {
                        Spacer()
                        Button(action: { selectedReport = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Contenu scrollable
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
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.7) // Limite la hauteur max
                    
                    // Bouton toujours visible en bas
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
        
    
    // Fonction pour centrer sur la position utilisateur
    private func centerOnUserLocation() {
        if let userLocation = locationManager.lastLocation {
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
            }
        } else {
            locationManager.requestAuthorization()
        }
    }
    
    // Fonction de conversion
    private func convertPointToCoordinate(_ point: CGPoint) -> CLLocationCoordinate2D {
        // Vous aurez besoin d'une référence à votre MKMapView
        // Voici une approche utilisant MapProxy (iOS 17+)
        let coordinate = CLLocationCoordinate2D(
            latitude: 0, // Valeur temporaire
            longitude: 0 // Valeur temporaire
        )
        // Implémentez la conversion réelle ici
        return coordinate
    }
}

#Preview {
    ContentView()
}

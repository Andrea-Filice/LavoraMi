//
//  StationsDB.swift
//  LavoraMi
//
//  Created by Andrea Filice on 08/01/26.
//

import Foundation
import MapKit

struct StationsDB {
    //MARK: METRO STATIONS:
    
    static let stationsM1: [MetroStation] = [
        .init(name: "Sesto 1° Maggio FS", coordinate: .init(latitude: 45.54156, longitude: 9.23835), branch: "Main"),
        .init(name: "Sesto Rondò", coordinate: .init(latitude: 45.5342, longitude: 9.23128), branch: "Main"),
        .init(name: "Sesto Marelli", coordinate: .init(latitude: 45.52356, longitude: 9.22796), branch: "Main"),
        .init(name: "Villa S. Giovanni", coordinate: .init(latitude: 45.51745, longitude: 9.22613), branch: "Main"),
        .init(name: "Precotto", coordinate: .init(latitude: 45.51215, longitude: 9.22449), branch: "Main"),
        .init(name: "Gorla", coordinate: .init(latitude: 45.50662, longitude: 9.22287), branch: "Main"),
        .init(name: "Turro", coordinate: .init(latitude: 45.50091, longitude: 9.22114), branch: "Main"),
        .init(name: "Rovereto", coordinate: .init(latitude: 45.49578, longitude: 9.21957), branch: "Main"),
        .init(name: "Pasteur", coordinate: .init(latitude: 45.49091, longitude: 9.21816), branch: "Main"),
        .init(name: "Loreto", coordinate: .init(latitude: 45.48584, longitude: 9.21638), branch: "Main"),
        .init(name: "Lima", coordinate: .init(latitude: 45.48027, longitude: 9.21085), branch: "Main"),
        .init(name: "Porta Venezia", coordinate: .init(latitude: 45.47471, longitude: 9.20568), branch: "Main"),
        .init(name: "Palestro", coordinate: .init(latitude: 45.47142, longitude: 9.20194), branch: "Main"),
        .init(name: "San Babila", coordinate: .init(latitude: 45.46642, longitude: 9.19757), branch: "Main"),
        .init(name: "Duomo", coordinate: .init(latitude: 45.46443, longitude: 9.18927), branch: "Main"),
        .init(name: "Cordusio", coordinate: .init(latitude: 45.46539, longitude: 9.18635), branch: "Main"),
        .init(name: "Cairoli", coordinate: .init(latitude: 45.4682, longitude: 9.18225), branch: "Main"),
        .init(name: "Cadorna FN", coordinate: .init(latitude: 45.4682, longitude: 9.17588), branch: "Main"),
        .init(name: "Conciliazione", coordinate: .init(latitude: 45.46749, longitude: 9.1663), branch: "Main"),
        .init(name: "Pagano", coordinate: .init(latitude: 45.46828, longitude: 9.16077), branch: "Main"),
        
        .init(name: "Buonarroti", coordinate: .init(latitude: 45.47054, longitude: 9.1552), branch: "Rho"),
        .init(name: "Amendola", coordinate: .init(latitude: 45.47356, longitude: 9.15132), branch: "Rho"),
        .init(name: "Lotto", coordinate: .init(latitude: 45.47909, longitude: 9.14454), branch: "Rho"),
        .init(name: "QT8", coordinate: .init(latitude: 45.48625, longitude: 9.13743), branch: "Rho"),
        .init(name: "Lampugnano", coordinate: .init(latitude: 45.4894, longitude: 9.12731), branch: "Rho"),
        .init(name: "Uruguay", coordinate: .init(latitude: 45.49344, longitude: 9.12045), branch: "Rho"),
        .init(name: "Bonola", coordinate: .init(latitude: 45.49703, longitude: 9.11009), branch: "Rho"),
        .init(name: "San Leonardo", coordinate: .init(latitude: 45.50116, longitude: 9.10149), branch: "Rho"),
        .init(name: "Molino Dorino", coordinate: .init(latitude: 45.50516, longitude: 9.09323), branch: "Rho"),
        .init(name: "Pero", coordinate: .init(latitude: 45.50869, longitude: 9.08581), branch: "Rho"),
        .init(name: "Rho Fiera", coordinate: .init(latitude: 45.51797, longitude: 9.08564), branch: "Rho"),
        
        .init(name: "Wagner", coordinate: .init(latitude: 45.46784, longitude: 9.15529), branch: "Bisceglie"),
        .init(name: "De Angeli", coordinate: .init(latitude: 45.46656, longitude: 9.14987), branch: "Bisceglie"),
        .init(name: "Gambara", coordinate: .init(latitude: 45.46499, longitude: 9.14295), branch: "Bisceglie"),
        .init(name: "Bande Nere", coordinate: .init(latitude: 45.46133, longitude: 9.13695), branch: "Bisceglie"),
        .init(name: "Primaticcio", coordinate: .init(latitude: 45.45952, longitude: 9.12961), branch: "Bisceglie"),
        .init(name: "Inganni", coordinate: .init(latitude: 45.45756, longitude: 9.12225), branch: "Bisceglie"),
        .init(name: "Bisceglie", coordinate: .init(latitude: 45.45531, longitude: 9.11335), branch: "Bisceglie")
    ]

    static let stationsM2: [MetroStation] = [
        .init(name: "Assago Forum", coordinate: .init(latitude: 45.40183, longitude: 9.14562), branch: "Assago"),
        .init(name: "Assago Milanofiori Nord", coordinate: .init(latitude: 45.40945, longitude: 9.15004), branch: "Assago"),

        .init(name: "P.Za Abbiategrasso", coordinate: .init(latitude: 45.42984, longitude: 9.17838), branch: "Abbiategrasso"),

        .init(name: "Famagosta", coordinate: .init(latitude: 45.43719, longitude: 9.16795), branch: "Main"),
        .init(name: "Romolo", coordinate: .init(latitude: 45.44373, longitude: 9.16767), branch: "Main"),
        .init(name: "Porta Genova FS", coordinate: .init(latitude: 45.45273, longitude: 9.16972), branch: "Main"),
        .init(name: "S. Agostino", coordinate: .init(latitude: 45.45834, longitude: 9.16977), branch: "Main"),
        .init(name: "S. Ambrogio", coordinate: .init(latitude: 45.46185, longitude: 9.17325), branch: "Main"),
        .init(name: "Cadorna FN", coordinate: .init(latitude: 45.4682, longitude: 9.17588), branch: "Main"),
        .init(name: "Lanza", coordinate: .init(latitude: 45.47196, longitude: 9.18273), branch: "Main"),
        .init(name: "Moscova", coordinate: .init(latitude: 45.4775, longitude: 9.18471), branch: "Main"),
        .init(name: "Garibaldi FS", coordinate: .init(latitude: 45.48351, longitude: 9.18671), branch: "Main"),
        .init(name: "Gioia", coordinate: .init(latitude: 45.48462, longitude: 9.19523), branch: "Main"),
        .init(name: "Centrale FS", coordinate: .init(latitude: 45.48469, longitude: 9.20274), branch: "Main"),
        .init(name: "Caiazzo", coordinate: .init(latitude: 45.48525, longitude: 9.2091), branch: "Main"),
        .init(name: "Loreto", coordinate: .init(latitude: 45.48584, longitude: 9.21638), branch: "Main"),
        .init(name: "Piola", coordinate: .init(latitude: 45.48081, longitude: 9.22509), branch: "Main"),
        .init(name: "Lambrate FS", coordinate: .init(latitude: 45.48423, longitude: 9.235), branch: "Main"),
        .init(name: "Udine", coordinate: .init(latitude: 45.49145, longitude: 9.23688), branch: "Main"),
        .init(name: "Cimiano", coordinate: .init(latitude: 45.50004, longitude: 9.24142), branch: "Main"),
        .init(name: "Crescenzago", coordinate: .init(latitude: 45.50521, longitude: 9.24822), branch: "Main"),
        .init(name: "Cascina Gobba", coordinate: .init(latitude: 45.51114, longitude: 9.26052), branch: "Main"),

        .init(name: "Cologno Sud", coordinate: .init(latitude: 45.52021, longitude: 9.27492), branch: "Cologno"),
        .init(name: "Cologno Centro", coordinate: .init(latitude: 45.52747, longitude: 9.28296), branch: "Cologno"),
        .init(name: "Cologno Nord", coordinate: .init(latitude: 45.53426, longitude: 9.29111), branch: "Cologno"),

        .init(name: "Vimodrone", coordinate: .init(latitude: 45.51574, longitude: 9.28564), branch: "Gessate"),
        .init(name: "Cascina Burrona", coordinate: .init(latitude: 45.51736, longitude: 9.29783), branch: "Gessate"),
        .init(name: "Cernusco Sul Naviglio", coordinate: .init(latitude: 45.52097, longitude: 9.33083), branch: "Gessate"),
        .init(name: "Villa Fiorita", coordinate: .init(latitude: 45.5205, longitude: 9.34609), branch: "Gessate"),
        .init(name: "Cassina De Pecchi", coordinate: .init(latitude: 45.52163, longitude: 9.36213), branch: "Gessate"),
        .init(name: "Bussero", coordinate: .init(latitude: 45.52541, longitude: 9.3758), branch: "Gessate"),
        .init(name: "Villa Pompea", coordinate: .init(latitude: 45.52778, longitude: 9.38505), branch: "Gessate"),
        .init(name: "Gorgonzola", coordinate: .init(latitude: 45.53649, longitude: 9.4036), branch: "Gessate"),
        .init(name: "Cascina Antonietta", coordinate: .init(latitude: 45.5421, longitude: 9.42364), branch: "Gessate"),
        .init(name: "Gessate", coordinate: .init(latitude: 45.54524, longitude: 9.43656), branch: "Gessate")
    ]
    
    static let stationsM3: [MetroStation] = [
        .init(name: "San Donato", coordinate: .init(latitude: 45.42897, longitude: 9.25653), branch: "Main"),
        .init(name: "Rogoredo FS", coordinate: .init(latitude: 45.43366, longitude: 9.23849), branch: "Main"),
        .init(name: "Porto Di Mare", coordinate: .init(latitude: 45.43717, longitude: 9.23041), branch: "Main"),
        .init(name: "Corvetto", coordinate: .init(latitude: 45.4403, longitude: 9.22385), branch: "Main"),
        .init(name: "Brenta", coordinate: .init(latitude: 45.44301, longitude: 9.21801), branch: "Main"),
        .init(name: "Lodi TIBB", coordinate: .init(latitude: 45.44698, longitude: 9.20975), branch: "Main"),
        .init(name: "Porta Romana", coordinate: .init(latitude: 45.45152, longitude: 9.203), branch: "Main"),
        .init(name: "Crocetta", coordinate: .init(latitude: 45.45597, longitude: 9.19569), branch: "Main"),
        .init(name: "Missori", coordinate: .init(latitude: 45.46057, longitude: 9.18818), branch: "Main"),
        .init(name: "Duomo", coordinate: .init(latitude: 45.46443, longitude: 9.18927), branch: "Main"),
        .init(name: "Montenapoleone", coordinate: .init(latitude: 45.47027, longitude: 9.19249), branch: "Main"),
        .init(name: "Turati", coordinate: .init(latitude: 45.47455, longitude: 9.19481), branch: "Main"),
        .init(name: "Repubblica", coordinate: .init(latitude: 45.48038, longitude: 9.19878), branch: "Main"),
        .init(name: "Centrale FS", coordinate: .init(latitude: 45.48469, longitude: 9.20274), branch: "Main"),
        .init(name: "Sondrio", coordinate: .init(latitude: 45.4896, longitude: 9.20109), branch: "Main"),
        .init(name: "Zara", coordinate: .init(latitude: 45.49225, longitude: 9.19246), branch: "Main"),
        .init(name: "Maciachini", coordinate: .init(latitude: 45.49788, longitude: 9.18478), branch: "Main"),
        .init(name: "Dergano", coordinate: .init(latitude: 45.50564, longitude: 9.17978), branch: "Main"),
        .init(name: "Affori Centro", coordinate: .init(latitude: 45.51358, longitude: 9.17417), branch: "Main"),
        .init(name: "Affori FN", coordinate: .init(latitude: 45.52087, longitude: 9.16901), branch: "Main"),
        .init(name: "Comasina", coordinate: .init(latitude: 45.52835, longitude: 9.16387), branch: "Main")
    ]

    static let stationsM4: [MetroStation] = [
        .init(name: "Linate Aereoporto", coordinate: .init(latitude: 45.46284, longitude: 9.27791), branch: "Main"),
        .init(name: "Repetti", coordinate: .init(latitude: 45.46201, longitude: 9.2404), branch: "Main"),
        .init(name: "Stazione Forlanini", coordinate: .init(latitude: 45.46465, longitude: 9.2363), branch: "Main"),
        .init(name: "Argonne", coordinate: .init(latitude: 45.46815, longitude: 9.23119), branch: "Main"),
        .init(name: "Susa", coordinate: .init(latitude: 45.4682, longitude: 9.22499), branch: "Main"),
        .init(name: "Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Tricolore", coordinate: .init(latitude: 45.46793, longitude: 9.20868), branch: "Main"),
        .init(name: "San Babila", coordinate: .init(latitude: 45.46642, longitude: 9.19757), branch: "Main"),
        .init(name: "Sforza-Policlinico", coordinate: .init(latitude: 45.45874, longitude: 9.19433), branch: "Main"),
        .init(name: "Santa Sofia", coordinate: .init(latitude: 45.45633, longitude: 9.18863), branch: "Main"),
        .init(name: "Vetra", coordinate: .init(latitude: 45.4571, longitude: 9.18262), branch: "Main"),
        .init(name: "De Amicis", coordinate: .init(latitude: 45.45909, longitude: 9.17721), branch: "Main"),
        .init(name: "S. Ambrogio", coordinate: .init(latitude: 45.46182, longitude: 9.17321), branch: "Main"),
        .init(name: "Coni Zugna", coordinate: .init(latitude: 45.45909, longitude: 9.1649), branch: "Main"),
        .init(name: "California", coordinate: .init(latitude: 45.45755, longitude: 9.16005), branch: "Main"),
        .init(name: "Bolivar", coordinate: .init(latitude: 45.45538, longitude: 9.15316), branch: "Main"),
        .init(name: "Tolstoj", coordinate: .init(latitude: 45.45359, longitude: 9.14801), branch: "Main"),
        .init(name: "Frattini", coordinate: .init(latitude: 45.45182, longitude: 9.14245), branch: "Main"),
        .init(name: "Gelsomini", coordinate: .init(latitude: 45.4496, longitude: 9.13542), branch: "Main"),
        .init(name: "Segneri", coordinate: .init(latitude: 45.44695, longitude: 9.13086), branch: "Main"),
        .init(name: "San Cristoforo", coordinate: .init(latitude: 45.44256, longitude: 9.13008), branch: "Main")
    ]
    
    static let stationsM5: [MetroStation] = [
        .init(name: "Bignami", coordinate: .init(latitude: 45.52653, longitude: 9.21227), branch: "Main"),
        .init(name: "Ponale", coordinate: .init(latitude: 45.52186, longitude: 9.20939), branch: "Main"),
        .init(name: "Bicocca", coordinate: .init(latitude: 45.51429, longitude: 9.20549), branch: "Main"),
        .init(name: "Ca'Granda", coordinate: .init(latitude: 45.50733, longitude: 9.20121), branch: "Main"),
        .init(name: "Istria", coordinate: .init(latitude: 45.50163, longitude: 9.19792), branch: "Main"),
        .init(name: "Marche", coordinate: .init(latitude: 45.49639, longitude: 9.19499), branch: "Main"),
        .init(name: "Zara", coordinate: .init(latitude: 45.49225, longitude: 9.19246), branch: "Main"),
        .init(name: "Isola", coordinate: .init(latitude: 45.48759, longitude: 9.19131), branch: "Main"),
        .init(name: "Garibaldi FS", coordinate: .init(latitude: 45.48351, longitude: 9.18671), branch: "Main"),
        .init(name: "Monumentale", coordinate: .init(latitude: 45.48532, longitude: 9.18098), branch: "Main"),
        .init(name: "Cenisio", coordinate: .init(latitude: 45.48799, longitude: 9.17207), branch: "Main"),
        .init(name: "Gerusalemme", coordinate: .init(latitude: 45.48469, longitude: 9.16696), branch: "Main"),
        .init(name: "Domodossola FN", coordinate: .init(latitude: 45.48135, longitude: 9.1621), branch: "Main"),
        .init(name: "Tre Torri", coordinate: .init(latitude: 45.47807, longitude: 9.15664), branch: "Main"),
        .init(name: "Portello", coordinate: .init(latitude: 45.4814, longitude: 9.15045), branch: "Main"),
        .init(name: "Lotto", coordinate: .init(latitude: 45.47909, longitude: 9.14454), branch: "Main"),
        .init(name: "Segesta", coordinate: .init(latitude: 45.47909, longitude: 9.13734), branch: "Main"),
        .init(name: "S. Siro Ippodromo", coordinate: .init(latitude: 45.47909, longitude: 9.12858), branch: "Main"),
        .init(name: "S. Siro Stadio", coordinate: .init(latitude: 45.47909, longitude: 9.11857), branch: "Main")
    ]
    
    //MARK: SUBURBAN LINES STATIONS
    
    static let stationsS1: [MetroStation] = [
        .init(name: "Saronno", coordinate: .init(latitude: 45.62534, longitude: 9.03075), branch: "Main"),
        .init(name: "Saronno Sud", coordinate: .init(latitude: 45.61235, longitude: 9.04557), branch: "Main"),
        .init(name: "Caronno Pertusella", coordinate: .init(latitude: 45.5981, longitude: 9.05794), branch: "Main"),
        .init(name: "Cesate", coordinate: .init(latitude: 45.5908, longitude: 9.06631), branch: "Main"),
        .init(name: "Garbagnate Milanese", coordinate: .init(latitude: 45.58014, longitude: 9.08042), branch: "Main"),
        .init(name: "Garbagnate Parco Delle Groane", coordinate: .init(latitude: 45.57108, longitude: 9.09097), branch: "Main"),
        .init(name: "Bollate Nord", coordinate: .init(latitude: 45.55262, longitude: 9.11209), branch: "Main"),
        .init(name: "Bollate Centro", coordinate: .init(latitude: 45.54289, longitude: 9.12283), branch: "Main"),
        .init(name: "Novate Milanese", coordinate: .init(latitude: 45.533, longitude: 9.13238), branch: "Main"),
        .init(name: "Milano Quarto Oggiaro", coordinate: .init(latitude: 45.51918, longitude: 9.14562), branch: "Main"),
        .init(name: "Milano Bovisa", coordinate: .init(latitude: 45.50257, longitude: 9.15925), branch: "Main"),
        .init(name: "Milano Lancetti", coordinate: .init(latitude: 45.4949, longitude: 9.17637), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Repubblica", coordinate: .init(latitude: 45.48034, longitude: 9.19888), branch: "Main"),
        .init(name: "Milano Pta Venezia", coordinate: .init(latitude: 45.47633, longitude: 9.20709), branch: "Main"),
        .init(name: "Milano Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Milano Pta Vittoria", coordinate: .init(latitude: 45.45989, longitude: 9.22355), branch: "Main"),
        .init(name: "Milano Rogoredo", coordinate: .init(latitude: 45.43386, longitude: 9.23911), branch: "Main"),
        .init(name: "S. Donato Milanese", coordinate: .init(latitude: 45.41879, longitude: 9.25291), branch: "Main"),
        .init(name: "Borgolombardo", coordinate: .init(latitude: 45.4045, longitude: 9.27046), branch: "Main"),
        .init(name: "S. Giuliano Milanese", coordinate: .init(latitude: 45.39134, longitude: 9.28652), branch: "Main"),
        .init(name: "Melegnano", coordinate: .init(latitude: 45.35647, longitude: 9.31936), branch: "Main"),
        .init(name: "S. Zenone Al Lambro", coordinate: .init(latitude: 45.33783, longitude: 9.36165), branch: "Main"),
        .init(name: "Tavazzano", coordinate: .init(latitude: 45.32641, longitude: 9.40282), branch: "Main"),
        .init(name: "Lodi", coordinate: .init(latitude: 45.3092, longitude: 9.49776), branch: "Main"),
    ]
    
    static let stationsS2: [MetroStation] = [
        .init(name: "Mariano Comense", coordinate: .init(latitude: 45.69358, longitude: 9.18141), branch: "Main"),
        .init(name: "Cabiate", coordinate: .init(latitude: 45.67592, longitude: 9.16843), branch: "Main"),
        .init(name: "Meda", coordinate: .init(latitude: 45.66242, longitude: 9.15886), branch: "Main"),
        .init(name: "Seveso", coordinate: .init(latitude: 45.6483, longitude: 9.14018), branch: "Main"),
        .init(name: "Cesano Maderno", coordinate: .init(latitude: 45.63073, longitude: 9.14209), branch: "Main"),
        .init(name: "Boviso Masciago", coordinate: .init(latitude: 45.61199, longitude: 9.14128), branch: "Main"),
        .init(name: "Varedo", coordinate: .init(latitude: 45.59555, longitude: 9.15341), branch: "Main"),
        .init(name: "Palazzolo Milanese", coordinate: .init(latitude: 45.58107, longitude: 9.15667), branch: "Main"),
        .init(name: "Paderno Dugnano", coordinate: .init(latitude: 45.56499, longitude: 9.16132), branch: "Main"),
        .init(name: "Cormano Cusano Milanino", coordinate: .init(latitude: 45.54571, longitude: 9.17409), branch: "Main"),
        .init(name: "Milano Bruzzano Parco Nord", coordinate: .init(latitude: 45.53374, longitude: 9.1728), branch: "Main"),
        .init(name: "Milano Affori", coordinate: .init(latitude: 45.52131, longitude: 9.16743), branch: "Main"),
        .init(name: "Milano Bovisa", coordinate: .init(latitude: 45.50257, longitude: 9.15925), branch: "Main"),
        .init(name: "Milano Lancetti", coordinate: .init(latitude: 45.4949, longitude: 9.17637), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Repubblica", coordinate: .init(latitude: 45.48034, longitude: 9.19888), branch: "Main"),
        .init(name: "Milano Pta Venezia", coordinate: .init(latitude: 45.47633, longitude: 9.20709), branch: "Main"),
        .init(name: "Milano Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Milano Pta Vittoria", coordinate: .init(latitude: 45.45989, longitude: 9.22355), branch: "Main"),
        .init(name: "Milano Rogoredo", coordinate: .init(latitude: 45.43386, longitude: 9.23911), branch: "Main")
    ]
    
    static let stationsS3: [MetroStation] = [
        .init(name: "Milano Cadorna", coordinate: .init(latitude: 45.46843, longitude: 9.17553), branch: "Main"),
        .init(name: "Milano Domodossola", coordinate: .init(latitude: 45.48089, longitude: 9.16224), branch: "Main"),
        .init(name: "Milano Bovisa", coordinate: .init(latitude: 45.50257, longitude: 9.15925), branch: "Main"),
        .init(name: "Milano Quarto Oggiaro", coordinate: .init(latitude: 45.51918, longitude: 9.14562), branch: "Main"),
        .init(name: "Novate Milanese", coordinate: .init(latitude: 45.533, longitude: 9.13238), branch: "Main"),
        .init(name: "Bollate Centro", coordinate: .init(latitude: 45.54289, longitude: 9.12283), branch: "Main"),
        .init(name: "Bollate Nord", coordinate: .init(latitude: 45.55262, longitude: 9.11209), branch: "Main"),
        .init(name: "Garbagnate Parco Delle Groane", coordinate: .init(latitude: 45.57108, longitude: 9.09097), branch: "Main"),
        .init(name: "Garbagnate Milanese", coordinate: .init(latitude: 45.58014, longitude: 9.08042), branch: "Main"),
        .init(name: "Cesate", coordinate: .init(latitude: 45.5908, longitude: 9.06631), branch: "Main"),
        .init(name: "Caronno Pertusella", coordinate: .init(latitude: 45.5981, longitude: 9.05794), branch: "Main"),
        .init(name: "Saronno Sud", coordinate: .init(latitude: 45.61235, longitude: 9.04557), branch: "Main"),
        .init(name: "Saronno", coordinate: .init(latitude: 45.62534, longitude: 9.03075), branch: "Main")
    ]
    
    static let stationsS4: [MetroStation] = [
        .init(name: "Camnago - Lentate", coordinate: .init(latitude: 45.66837, longitude: 9.13328), branch: "Main"),
        .init(name: "Seveso", coordinate: .init(latitude: 45.6483, longitude: 9.14018), branch: "Main"),
        .init(name: "Cesano Maderno", coordinate: .init(latitude: 45.63073, longitude: 9.14209), branch: "Main"),
        .init(name: "Boviso Masciago", coordinate: .init(latitude: 45.61199, longitude: 9.14128), branch: "Main"),
        .init(name: "Varedo", coordinate: .init(latitude: 45.59555, longitude: 9.15341), branch: "Main"),
        .init(name: "Palazzolo Milanese", coordinate: .init(latitude: 45.58107, longitude: 9.15667), branch: "Main"),
        .init(name: "Paderno Dugnano", coordinate: .init(latitude: 45.56499, longitude: 9.16132), branch: "Main"),
        .init(name: "Cormano Cusano Milanino", coordinate: .init(latitude: 45.54571, longitude: 9.17409), branch: "Main"),
        .init(name: "Milano Bruzzano Parco Nord", coordinate: .init(latitude: 45.53374, longitude: 9.1728), branch: "Main"),
        .init(name: "Milano Affori", coordinate: .init(latitude: 45.52131, longitude: 9.16743), branch: "Main"),
        .init(name: "Milano Bovisa", coordinate: .init(latitude: 45.50257, longitude: 9.15925), branch: "Main"),
        .init(name: "Milano Domodossola", coordinate: .init(latitude: 45.48089, longitude: 9.16224), branch: "Main"),
        .init(name: "Milano Cadorna", coordinate: .init(latitude: 45.46843, longitude: 9.17553), branch: "Main")
    ]
    
    static let stationsS5: [MetroStation] = [
        .init(name: "Varese", coordinate: .init(latitude: 45.81625, longitude: 8.83295), branch: "Main"),
        .init(name: "Gazzada Schianno Morazzone", coordinate: .init(latitude: 45.77868, longitude: 8.82473), branch: "Main"),
        .init(name: "Castronno", coordinate: .init(latitude: 45.74525, longitude: 8.81051), branch: "Main"),
        .init(name: "Albizzate - Solbiate Arno", coordinate: .init(latitude: 45.7233, longitude: 8.80628), branch: "Main"),
        .init(name: "Cavaria", coordinate: .init(latitude: 45.69814, longitude: 8.80371), branch: "Main"),
        .init(name: "Gallarate", coordinate: .init(latitude: 45.65974, longitude: 8.79853), branch: "Main"),
        .init(name: "Busto Arsizio", coordinate: .init(latitude: 45.61593, longitude: 8.86589), branch: "Main"),
        .init(name: "Legnano", coordinate: .init(latitude: 45.5937, longitude: 8.91087), branch: "Main"),
        .init(name: "Canegrate", coordinate: .init(latitude: 45.56934, longitude: 8.92673), branch: "Main"),
        .init(name: "Parabiago", coordinate: .init(latitude: 45.55261, longitude: 8.94651), branch: "Main"),
        .init(name: "Vanzago - Pogliano", coordinate: .init(latitude: 45.52536, longitude: 8.99573), branch: "Main"),
        .init(name: "Rho", coordinate: .init(latitude: 45.52411, longitude: 9.04355), branch: "Main"),
        .init(name: "Rho FieraMilano", coordinate: .init(latitude: 45.52113, longitude: 9.0885), branch: "Main"),
        .init(name: "Milano Certosa", coordinate: .init(latitude: 45.50683, longitude: 9.13593), branch: "Main"),
        .init(name: "Milano Villapizzone", coordinate: .init(latitude: 45.50202, longitude: 9.15092), branch: "Main"),
        .init(name: "Milano Lancetti", coordinate: .init(latitude: 45.4949, longitude: 9.17637), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Repubblica", coordinate: .init(latitude: 45.48034, longitude: 9.19888), branch: "Main"),
        .init(name: "Milano Pta Venezia", coordinate: .init(latitude: 45.47633, longitude: 9.20709), branch: "Main"),
        .init(name: "Milano Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Milano Pta Vittoria", coordinate: .init(latitude: 45.45989, longitude: 9.22355), branch: "Main"),
        .init(name: "Milano Forlanini", coordinate: .init(latitude: 45.46438, longitude: 9.23691), branch: "Main"),
        .init(name: "Segrate", coordinate: .init(latitude: 45.48075, longitude: 9.29859), branch: "Main"),
        .init(name: "Pioltello Limito", coordinate: .init(latitude: 45.48611, longitude: 9.32949), branch: "Main"),
        .init(name: "Vigate", coordinate: .init(latitude: 45.49441, longitude: 9.37649), branch: "Main"),
        .init(name: "Melzo", coordinate: .init(latitude: 45.50208, longitude: 9.4192), branch: "Main"),
        .init(name: "Pozzuolo Martesana", coordinate: .init(latitude: 45.50852, longitude: 9.45631), branch: "Main"),
        .init(name: "Trecella", coordinate: .init(latitude: 45.51283, longitude: 9.48068), branch: "Main"),
        .init(name: "Cassano d'Adda", coordinate: .init(latitude: 45.51446, longitude: 9.51278), branch: "Main"),
        .init(name: "Treviglio", coordinate: .init(latitude: 45.51531, longitude: 9.58864), branch: "Main")
    ]
    
    static let stationsS6: [MetroStation] = [
        .init(name: "Novara", coordinate: .init(latitude: 45.45111, longitude: 8.62451), branch: "Main"),
        .init(name: "Trecate", coordinate: .init(latitude: 45.42866, longitude: 8.73938), branch: "Main"),
        .init(name: "Magenta", coordinate: .init(latitude: 45.4681, longitude: 8.88073), branch: "Main"),
        .init(name: "Corbetta - S. Stefano", coordinate: .init(latitude: 45.48122, longitude: 8.91811), branch: "Main"),
        .init(name: "Vittuone - Arluno", coordinate: .init(latitude: 45.49093, longitude: 8.94733), branch: "Main"),
        .init(name: "Pregana Milanese", coordinate: .init(latitude: 45.51011, longitude: 9.00279), branch: "Main"),
        .init(name: "Rho", coordinate: .init(latitude: 45.52411, longitude: 9.04355), branch: "Main"),
        .init(name: "Rho FieraMilano", coordinate: .init(latitude: 45.52113, longitude: 9.0885), branch: "Main"),
        .init(name: "Milano Certosa", coordinate: .init(latitude: 45.50683, longitude: 9.13593), branch: "Main"),
        .init(name: "Milano Villapizzone", coordinate: .init(latitude: 45.50202, longitude: 9.15092), branch: "Main"),
        .init(name: "Milano Lancetti", coordinate: .init(latitude: 45.4949, longitude: 9.17637), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Repubblica", coordinate: .init(latitude: 45.48034, longitude: 9.19888), branch: "Main"),
        .init(name: "Milano Pta Venezia", coordinate: .init(latitude: 45.47633, longitude: 9.20709), branch: "Main"),
        .init(name: "Milano Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Milano Pta Vittoria", coordinate: .init(latitude: 45.45989, longitude: 9.22355), branch: "Main"),
        .init(name: "Milano Forlanini", coordinate: .init(latitude: 45.46438, longitude: 9.23691), branch: "Main"),
        .init(name: "Segrate", coordinate: .init(latitude: 45.48075, longitude: 9.29859), branch: "Main"),
        .init(name: "Pioltello Limito", coordinate: .init(latitude: 45.48611, longitude: 9.32949), branch: "Main"),
        .init(name: "Vigate", coordinate: .init(latitude: 45.49441, longitude: 9.37649), branch: "Main"),
        .init(name: "Melzo", coordinate: .init(latitude: 45.50208, longitude: 9.4192), branch: "Main"),
        .init(name: "Pozzuolo Martesana", coordinate: .init(latitude: 45.50852, longitude: 9.45631), branch: "Main"),
        .init(name: "Trecella", coordinate: .init(latitude: 45.51283, longitude: 9.48068), branch: "Main"),
        .init(name: "Cassano d'Adda", coordinate: .init(latitude: 45.51446, longitude: 9.51278), branch: "Main"),
        .init(name: "Treviglio", coordinate: .init(latitude: 45.51531, longitude: 9.58864), branch: "Main")
    ]
    
    static let stationsS7: [MetroStation] = [
        .init(name: "Lecco", coordinate: .init(latitude: 45.85637, longitude: 9.3934), branch: "Main"),
        .init(name: "Valmadrera", coordinate: .init(latitude: 45.84641, longitude: 9.36801), branch: "Main"),
        .init(name: "Civate", coordinate: .init(latitude: 45.83133, longitude: 9.35275), branch: "Main"),
        .init(name: "Sala Al Barro - Galbiate", coordinate: .init(latitude: 45.82118, longitude: 9.35937), branch: "Main"),
        .init(name: "Oggiono", coordinate: .init(latitude: 45.78891, longitude: 9.33758), branch: "Main"),
        .init(name: "Molteno", coordinate: .init(latitude: 45.78085, longitude: 9.30171), branch: "Main"),
        .init(name: "Costa Masnaga", coordinate: .init(latitude: 45.76347, longitude: 9.2849), branch: "Main"),
        .init(name: "Cassano Nibionno Bulciago", coordinate: .init(latitude: 45.74621, longitude: 9.27996), branch: "Main"),
        .init(name: "Renate - Veduggio", coordinate: .init(latitude: 45.7284, longitude: 9.27997), branch: "Main"),
        .init(name: "Besana", coordinate: .init(latitude: 45.70274, longitude: 9.28303), branch: "Main"),
        .init(name: "Villa Raverio", coordinate: .init(latitude: 45.69038, longitude: 9.26172), branch: "Main"),
        .init(name: "Carate Calo'", coordinate: .init(latitude: 45.67642, longitude: 9.25213), branch: "Main"),
        .init(name: "Triuggio - Ponte Albiate", coordinate: .init(latitude: 45.65892, longitude: 9.26682), branch: "Main"),
        .init(name: "Macherio - Canonica", coordinate: .init(latitude: 45.64556, longitude: 9.2869), branch: "Main"),
        .init(name: "Biassono - Lesmo Parco", coordinate: .init(latitude: 45.63221, longitude: 9.29829), branch: "Main"),
        .init(name: "Buttafava", coordinate: .init(latitude: 45.62142, longitude: 9.3013), branch: "Main"),
        .init(name: "Villasanta", coordinate: .init(latitude: 45.60336, longitude: 9.30516), branch: "Main"),
        .init(name: "Monza Sobborghi", coordinate: .init(latitude: 45.5819, longitude: 9.28449), branch: "Main"),
        .init(name: "Monza", coordinate: .init(latitude: 45.57797, longitude: 9.27289), branch: "Main"),
        .init(name: "Sesto S. Giovanni", coordinate: .init(latitude: 45.54126, longitude: 9.23903), branch: "Main"),
        .init(name: "Milano Greco Pirelli", coordinate: .init(latitude: 45.51288, longitude: 9.21416), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main")
    ]
    
    static let stationsS8: [MetroStation] = [
        .init(name: "Lecco", coordinate: .init(latitude: 45.85637, longitude: 9.3934), branch: "Main"),
        .init(name: "Lecco Maggianico", coordinate: .init(latitude: 45.83102, longitude: 9.41205), branch: "Main"),
        .init(name: "Calolziocorte Olginate", coordinate: .init(latitude: 45.80175, longitude: 9.42714), branch: "Main"),
        .init(name: "Airuno", coordinate: .init(latitude: 45.75549, longitude: 9.42232), branch: "Main"),
        .init(name: "Olgiate-Calco-Brivio", coordinate: .init(latitude: 45.72919, longitude: 9.40366), branch: "Main"),
        .init(name: "Cernusco-Merate", coordinate: .init(latitude: 45.69503, longitude: 9.39692), branch: "Main"),
        .init(name: "Osnago", coordinate: .init(latitude: 45.67873, longitude: 9.38711), branch: "Main"),
        .init(name: "Carnate Usmate", coordinate: .init(latitude: 45.65318, longitude: 9.37493), branch: "Main"),
        .init(name: "Arcore", coordinate: .init(latitude: 45.62377, longitude: 9.32292), branch: "Main"),
        .init(name: "Monza", coordinate: .init(latitude: 45.57797, longitude: 9.27289), branch: "Main"),
        .init(name: "Sesto S. Giovanni", coordinate: .init(latitude: 45.54126, longitude: 9.23903), branch: "Main"),
        .init(name: "Milano Greco Pirelli", coordinate: .init(latitude: 45.51288, longitude: 9.21416), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main")
    ]
    
    static let stationsS9: [MetroStation] = [
        .init(name: "Saronno", coordinate: .init(latitude: 45.62534, longitude: 9.03075), branch: "Main"),
        .init(name: "Saronno Sud", coordinate: .init(latitude: 45.61235, longitude: 9.04557), branch: "Main"),
        .init(name: "Ceriano Laghetto - Solaro", coordinate: .init(latitude: 45.6249, longitude: 9.07936), branch: "Main"),
        .init(name: "Ceriano Laghetto Groane", coordinate: .init(latitude: 45.62718, longitude: 9.1002), branch: "Main"),
        .init(name: "Cesano Maderno Laghetto Groane", coordinate: .init(latitude: 45.63033, longitude: 9.12652), branch: "Main"),
        .init(name: "Cesano Maderno", coordinate: .init(latitude: 45.63073, longitude: 9.14209), branch: "Main"),
        .init(name: "Seveso Baruccana", coordinate: .init(latitude: 45.63807, longitude: 9.16292), branch: "Main"),
        .init(name: "Seregno", coordinate: .init(latitude: 45.64609, longitude: 9.20302), branch: "Main"),
        .init(name: "Desio", coordinate: .init(latitude: 45.62011, longitude: 9.21829), branch: "Main"),
        .init(name: "Lissone - Muggiò", coordinate: .init(latitude: 45.60618, longitude: 9.23526), branch: "Main"),
        .init(name: "Monza", coordinate: .init(latitude: 45.57797, longitude: 9.27289), branch: "Main"),
        .init(name: "Sesto S. Giovanni", coordinate: .init(latitude: 45.54126, longitude: 9.23903), branch: "Main"),
        .init(name: "Milano Greco Pirelli", coordinate: .init(latitude: 45.51288, longitude: 9.21416), branch: "Main"),
        .init(name: "Milano Lambrate", coordinate: .init(latitude: 45.48475, longitude: 9.23678), branch: "Main"),
        .init(name: "Milano Forlanini", coordinate: .init(latitude: 45.46438, longitude: 9.23691), branch: "Main"),
        .init(name: "Milano Scalo Romana", coordinate: .init(latitude: 45.44585, longitude: 9.21303), branch: "Main"),
        .init(name: "Milano Tibaldi - Bocconi", coordinate: .init(latitude: 45.44394, longitude: 9.18506), branch: "Main"),
        .init(name: "Milano Romolo", coordinate: .init(latitude: 45.44335, longitude: 9.1675), branch: "Main"),
        .init(name: "Milano S. Cristoforo", coordinate: .init(latitude: 45.44256, longitude: 9.13008), branch: "Main"),
        .init(name: "Corsico", coordinate: .init(latitude: 45.43605, longitude: 9.10899), branch: "Main"),
        .init(name: "Cesano Boscone", coordinate: .init(latitude: 45.43044, longitude: 9.09158), branch: "Main"),
        .init(name: "Trezzano sul Naviglio", coordinate: .init(latitude: 45.42025, longitude: 9.0669), branch: "Main"),
        .init(name: "Gaggiano", coordinate: .init(latitude: 45.40874, longitude: 9.03118), branch: "Main"),
        .init(name: "Albairate - Vermezzo", coordinate: .init(latitude: 45.40435, longitude: 8.95822), branch: "Main"),
    ]
    
    static let stationsS11: [MetroStation] = [
        .init(name: "Como S. Giovanni", coordinate: .init(latitude: 45.80901, longitude: 9.07279), branch: "Main"),
        .init(name: "Como Camerlata", coordinate: .init(latitude: 45.78457, longitude: 9.0794), branch: "Main"),
        .init(name: "Cucciago", coordinate: .init(latitude: 45.74081, longitude: 9.08206), branch: "Main"),
        .init(name: "Cantù - Cermenate", coordinate: .init(latitude: 45.71623, longitude: 9.09948), branch: "Main"),
        .init(name: "Carimate", coordinate: .init(latitude: 45.69718, longitude: 9.10737), branch: "Main"),
        .init(name: "Camnago - Lentate", coordinate: .init(latitude: 45.66837, longitude: 9.13328), branch: "Main"),
        .init(name: "Seregno", coordinate: .init(latitude: 45.64609, longitude: 9.20302), branch: "Main"),
        .init(name: "Desio", coordinate: .init(latitude: 45.62011, longitude: 9.21829), branch: "Main"),
        .init(name: "Lissone - Muggiò", coordinate: .init(latitude: 45.60618, longitude: 9.23526), branch: "Main"),
        .init(name: "Monza", coordinate: .init(latitude: 45.57797, longitude: 9.27289), branch: "Main"),
        .init(name: "Sesto S. Giovanni", coordinate: .init(latitude: 45.54126, longitude: 9.23903), branch: "Main"),
        .init(name: "Milano Greco Pirelli", coordinate: .init(latitude: 45.51288, longitude: 9.21416), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Villapizzone", coordinate: .init(latitude: 45.50202, longitude: 9.15092), branch: "Main"),
        .init(name: "Milano Certosa", coordinate: .init(latitude: 45.50683, longitude: 9.13593), branch: "Main"),
        .init(name: "Rho FieraMilano", coordinate: .init(latitude: 45.52113, longitude: 9.0885), branch: "Main"),
        .init(name: "Rho", coordinate: .init(latitude: 45.52411, longitude: 9.04355), branch: "Main")
    ]
    
    static let stationsS12: [MetroStation] = [
        .init(name: "Cormano Cusano Milanino", coordinate: .init(latitude: 45.54571, longitude: 9.17409), branch: "Main"),
        .init(name: "Milano Bovisa", coordinate: .init(latitude: 45.50257, longitude: 9.15925), branch: "Main"),
        .init(name: "Milano Lancetti", coordinate: .init(latitude: 45.4949, longitude: 9.17637), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Repubblica", coordinate: .init(latitude: 45.48034, longitude: 9.19888), branch: "Main"),
        .init(name: "Milano Pta Venezia", coordinate: .init(latitude: 45.47633, longitude: 9.20709), branch: "Main"),
        .init(name: "Milano Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Milano Pta Vittoria", coordinate: .init(latitude: 45.45989, longitude: 9.22355), branch: "Main"),
        .init(name: "Milano Rogoredo", coordinate: .init(latitude: 45.43386, longitude: 9.23911), branch: "Main"),
        .init(name: "S. Donato Milanese", coordinate: .init(latitude: 45.41879, longitude: 9.25291), branch: "Main"),
        .init(name: "Borgolombardo", coordinate: .init(latitude: 45.4045, longitude: 9.27046), branch: "Main"),
        .init(name: "S. Giuliano Milanese", coordinate: .init(latitude: 45.39134, longitude: 9.28652), branch: "Main"),
        .init(name: "Melegnano", coordinate: .init(latitude: 45.35647, longitude: 9.31936), branch: "Main")
    ]
    
    static let stationsS13: [MetroStation] = [
        .init(name: "Pavia", coordinate: .init(latitude: 45.18878, longitude: 9.14488), branch: "Main"),
        .init(name: "Certosa di Pavia", coordinate: .init(latitude: 45.25656, longitude: 9.1542), branch: "Main"),
        .init(name: "Villamaggiore", coordinate: .init(latitude: 45.32047, longitude: 9.19051), branch: "Main"),
        .init(name: "Pieve Emanuele", coordinate: .init(latitude: 45.33966, longitude: 9.20351), branch: "Main"),
        .init(name: "Locate Triulzi", coordinate: .init(latitude: 45.35974, longitude: 9.22152), branch: "Main"),
        .init(name: "Milano Rogoredo", coordinate: .init(latitude: 45.43386, longitude: 9.23911), branch: "Main"),
        .init(name: "Milano Pta Vittoria", coordinate: .init(latitude: 45.45989, longitude: 9.22355), branch: "Main"),
        .init(name: "Milano Dateo", coordinate: .init(latitude: 45.46799, longitude: 9.21845), branch: "Main"),
        .init(name: "Milano Pta Venezia", coordinate: .init(latitude: 45.47633, longitude: 9.20709), branch: "Main"),
        .init(name: "Milano Repubblica", coordinate: .init(latitude: 45.48034, longitude: 9.19888), branch: "Main"),
        .init(name: "Milano Pta Garibaldi", coordinate: .init(latitude: 45.48449, longitude: 9.18737), branch: "Main"),
        .init(name: "Milano Lancetti", coordinate: .init(latitude: 45.4949, longitude: 9.17637), branch: "Main"),
        .init(name: "Milano Bovisa", coordinate: .init(latitude: 45.50257, longitude: 9.15925), branch: "Main")
    ]
    
    static let stationsS19: [MetroStation] = [
        .init(name: "Milano Rogoredo", coordinate: .init(latitude: 45.43386, longitude: 9.23911), branch: "Main"),
        .init(name: "Milano Scalo Romana", coordinate: .init(latitude: 45.44585, longitude: 9.21303), branch: "Main"),
        .init(name: "Milano Tibaldi - Bocconi", coordinate: .init(latitude: 45.44394, longitude: 9.18506), branch: "Main"),
        .init(name: "Milano Romolo", coordinate: .init(latitude: 45.44335, longitude: 9.1675), branch: "Main"),
        .init(name: "Milano S. Cristoforo", coordinate: .init(latitude: 45.44256, longitude: 9.13008), branch: "Main"),
        .init(name: "Corsico", coordinate: .init(latitude: 45.43605, longitude: 9.10899), branch: "Main"),
        .init(name: "Cesano Boscone", coordinate: .init(latitude: 45.43044, longitude: 9.09158), branch: "Main"),
        .init(name: "Trezzano sul Naviglio", coordinate: .init(latitude: 45.42025, longitude: 9.0669), branch: "Main"),
        .init(name: "Gaggiano", coordinate: .init(latitude: 45.40874, longitude: 9.03118), branch: "Main"),
        .init(name: "Albairate - Vermezzo", coordinate: .init(latitude: 45.40435, longitude: 8.95822), branch: "Main")
    ]
    
    static let stationsS31: [MetroStation] = [
        .init(name: "Brecia", coordinate: .init(latitude: 45.53252, longitude: 10.21297), branch: "Main"),
        .init(name: "Brecia Borgo S. Giovanni", coordinate: .init(latitude: 45.54333, longitude: 10.19076), branch: "Main"),
        .init(name: "Brecia Violino", coordinate: .init(latitude: 45.54511, longitude: 10.16873), branch: "Main"),
        .init(name: "Castegnato", coordinate: .init(latitude: 45.56608, longitude: 10.11827), branch: "Main"),
        .init(name: "Paderno Franciacorta", coordinate: .init(latitude: 45.58691, longitude: 10.08725), branch: "Main"),
        .init(name: "Passirano", coordinate: .init(latitude: 45.59021, longitude: 10.06359), branch: "Main"),
        .init(name: "Bornato - Calino", coordinate: .init(latitude: 45.59035, longitude: 10.03298), branch: "Main"),
        .init(name: "Borgonato - Adro", coordinate: .init(latitude: 45.62225, longitude: 10.02005), branch: "Main"),
        .init(name: "Provaglio Timoline", coordinate: .init(latitude: 45.63504, longitude: 10.03538), branch: "Main"),
        .init(name: "Iseo", coordinate: .init(latitude: 45.65657, longitude: 10.05003), branch: "Main")
    ]
}

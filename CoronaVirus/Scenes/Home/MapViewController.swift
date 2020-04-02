import UIKit
import MapKit
import CSV
import PromiseKit

class MapViewController: UIViewController {
  
  let mapView = MKMapView()
 
  
  private func readCSV(fileName: String) -> (headerRow: [String]?, dataRows: [[String]]){
    let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv")!
    let stream = InputStream(url: fileURL)!
    let reader = try! CSVReader(stream: stream, hasHeaderRow: true)
    
    let headerRow = reader.headerRow
    var dataRows = [[String]]()
    while let dataRow = reader.next() {
      dataRows.append(dataRow)
    }
    return (headerRow, dataRows)
  }
  
  private func parse() -> Promise<Region> {
    return Promise { seal in
      let (headers, confirmedRows) = readCSV(fileName: "time_series_19-covid-Confirmed")
      let (_, recoveredRows)  = readCSV(fileName: "time_series_19-covid-Recovered")
      let (_, deathRows)  = readCSV(fileName: "time_series_19-covid-Deaths")
      let dateValues = headers!.dropFirst(4)
      
      for index in confirmedRows.indices {
        let confirmedSeries = confirmedRows[index]
        let recoveredSeries = recoveredRows[index]
        let deathSeries = deathRows[index]
        
        for index in dateValues.indices {
          let dateFormatter = DateFormatter()
          dateFormatter.locale = .posix
          dateFormatter.dateFormat = "M/d/yy"
          let date = dateFormatter.date(from: dateValues[index])!
          
          let confirmedCases = Int(confirmedSeries[index]) ?? 0
          let recoveredCases = Int(recoveredSeries[index]) ?? 0
          let deathCases = Int(deathSeries[index]) ?? 0

          let stats = Statistic(confirmed: confirmedCases,
                                recovered: recoveredCases,
                                death: deathCases)
          var series = [Date: Statistic]()
          series[date] = stats
          
          let latitude = Double(confirmedSeries[2]) ?? 0
          let longitude = Double(confirmedSeries[3]) ?? 0
          let coordinate = Coordinate(latitude: latitude, longitude: longitude)
          let province = confirmedSeries
          
          let report = Report(lastUpdate: date, statistic: stats)
          
          let timeSeries = TimeSeries(series: series)
          let region = Region(province: "", country: "", coordinate: coordinate, report: report, timeSeries: timeSeries)
          seal.reject(NSError())
        }
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(mapView)
    mapView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    mapView.delegate = self
  }
}

extension MapViewController: MKMapViewDelegate {
  
}

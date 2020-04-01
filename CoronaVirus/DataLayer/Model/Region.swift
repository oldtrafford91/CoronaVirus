import Foundation

public struct Region {
  public let province: String?
  public let country: String
  public let coordinate: Coordinate
  
  public let report: Report
  public let timeSeries: TimeSeries
}

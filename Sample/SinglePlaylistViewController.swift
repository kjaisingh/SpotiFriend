//
//  SinglePlaylistViewController.swift
//
//  Created by Karan Jaisingh on 21/5/20.
//

import UIKit
import Spartan
import SVProgressHUD
import Charts

class SinglePlaylistViewController: UIViewController {
    
    @IBOutlet weak var playlistLabel: UILabel!
    @IBOutlet weak var trackLengthLabel: UILabel!
    @IBOutlet weak var explicityScoreLabel: UILabel!
    @IBOutlet weak var trackPopularityLabel: UILabel!
    @IBOutlet weak var pieChart: PieChartView!
    var timer: Timer!
    
    var trackList: [Track] = []
    var duration: [Int] = []
    var popularity: [Int] = []
    var explicit: [Bool] = []
    var artists: [String] = []
    
    var avgDuration: Double = 0
    var avgDurationSecs: Int = 0
    var avgDurationMins: Int = 0
    var avgPopularity: Double = 0
    var avgExplicit: Double = 0
    var artistCounts: [String: Int] = [:]
    var graphData: [(artist: String, count: Double)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        ViewController().spartanSetup()
        pieChart.noDataText = ""
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.lightGray.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        playlistLabel.text = globalVariables.selectedPlaylistName
        playlistLabel.sizeToFit()
        playlistLabel.center.x = self.view.center.x
        
        var complete: Int = 0
        while(complete < globalVariables.selectedPlaylistSize) {
            var limit: Int = 0
            if(complete < globalVariables.selectedPlaylistSize - 100) {
                limit = 100
            } else {
                limit = globalVariables.selectedPlaylistSize - complete
            }
            _ = Spartan.getPlaylistTracks(userId: globalVariables.selectedPlaylistUserID, playlistId: globalVariables.selectedPlaylistID, limit: limit, offset: complete, market: .us, success: { (pagingObject) in
                let tracks = pagingObject.items
                for i in 0...(tracks!.count - 1) {
                    let currentTrack = tracks?[i].track
                    self.trackList.append(currentTrack!)
                    self.duration.append((currentTrack?.durationMs)!)
                    self.popularity.append((currentTrack?.popularity)!)
                    self.explicit.append((currentTrack?.explicit)!)
                    for artist in currentTrack!.artists {
                        self.artists.append(artist.name)
                    }
                }
            }, failure: { (error) in
                print(error)
            })
            complete = complete + limit
        }
        self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.loop), userInfo: nil, repeats: true)
    }
    
    // function to calculate data to display
    func analyzeData() {
        // find averages for duration, popularity and explicit
        avgDuration = (Double(duration.reduce(0, +) / (duration.count)))
        let avgDurationInSeconds: Double = avgDuration / 1000
        avgDurationMins = Int(floor((avgDurationInSeconds / 60)))
        avgDurationSecs = Int(avgDurationInSeconds) - (avgDurationMins * 60)
        avgPopularity = Double(popularity.reduce(0, +)) / Double(popularity.count)
        avgPopularity = Double(round(100 * avgPopularity) / 100)
        let numExplicit = explicit.filter{$0}.count
        avgExplicit = Double(numExplicit) / Double(explicit.count)
        avgExplicit = Double(round(10000 * avgExplicit) / 100)
        
        // find artist track counts and store top values in graphdata
        for artist in artists {
            artistCounts[artist] = (artistCounts[artist] ?? 0) + 1
        }
        let artistCountsDec = artistCounts.sorted(by: {$0.value > $1.value})
        if(artistCountsDec.count > 10) {
            var sum: Double = 0
            for i in 0...9 {
                let pair = artistCountsDec[i]
                var percentage: Double = (Double(pair.value) / Double(trackList.count)) * 100
                percentage = Double(round(10 * percentage) / 10)
                graphData.append((pair.key, percentage))
                sum += percentage
            }
            let othersPercentage = Double(round(10 * (100 - sum)) / 10)
            graphData.append(("Others", othersPercentage))
        } else {
            for pair in artistCountsDec {
                graphData.append((pair.key, Double(pair.value)))
            }
        }
        
        // call function to display calculated data
        displayData()
    }
    
    // function to format and present data displayed
    func displayData() {
        // formatting and displaying basic playlist data
        if(avgDurationSecs >= 10) {
            trackLengthLabel.text = "Average Track Length: \(avgDurationMins):\(avgDurationSecs) mins"
        } else {
            trackLengthLabel.text = "Average Track Length: \(avgDurationMins):0\(avgDurationSecs) mins"
        }
        trackPopularityLabel.text = "Average Track Popularity: \(avgPopularity)/100"
        explicityScoreLabel.text = "Playlist Explicity Score: \(avgExplicit)%"
        trackLengthLabel.sizeToFit()
        trackPopularityLabel.sizeToFit()
        explicityScoreLabel.sizeToFit()
        
        // initializing entries for piechart
        var dataEntry: [PieChartDataEntry] = []
        for element in graphData {
            let label = element.artist
            let value = element.count
            dataEntry.append(PieChartDataEntry(value: value, label: label))
        }
        
        // initializing data system for piechart
        var chartDataset: PieChartDataSet = PieChartDataSet(entries: dataEntry, label: "")
        chartDataset.xValuePosition = .outsideSlice
        let chartData = PieChartData(dataSet: chartDataset)
        
        // formatting labels for piechart
        if(graphData.count > 10) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 1
            formatter.multiplier = 1.0
            formatter.percentSymbol = "%"
            chartData.setValueFormatter(DefaultValueFormatter(formatter: formatter))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.decimalSeparator = "."
            chartData.setValueFormatter(DefaultValueFormatter(formatter: formatter))
        }
        
        // customizing components of piecharts
        chartDataset.colors = ChartColorTemplates.vordiplom()
        chartDataset.valueFont = UIFont.systemFont(ofSize: 10.0)
        pieChart.entryLabelFont = UIFont.systemFont(ofSize: 10.0)
        pieChart.data = chartData
        pieChart.legend.enabled = false
        pieChart.extraRightOffset = 25
        pieChart.extraLeftOffset = 25
        pieChart.sizeToFit()
        pieChart.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: ChartEasingOption.easeInCirc)

        SVProgressHUD.dismiss()
    }
    
    // looped function that executes method in conditional when asynchronous method is complete
    @objc func loop() {
        if (self.duration.count >= globalVariables.selectedPlaylistSize) {
            timer.invalidate()
            analyzeData()
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

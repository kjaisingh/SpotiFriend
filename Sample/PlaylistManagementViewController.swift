//
//  PlaylistManagementViewController.swift
//
//  Created by Karan Jaisingh on 22/5/20.
//

import UIKit
import Spartan
import SpotifyLogin
import SVProgressHUD

class PlaylistManagementViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var playlistNames: [String] = []
    var playlistIDs: [String] = []
    var playlistUserIDs: [String] = []
    var playlistImages: [SpartanImage] = []
    var playlistSizes: [Int] = []
    
    var selected: Int = 0
    var requestType: String = "bpm"
    // state options: bpm, popularity or energy
    
    var trackList: [Track] = []
    var duration: [Double] = []
    var bpm: [Double] = []
    var energy: [Double] = []
    var popularity: [Double] = []

    @IBOutlet weak var tableView: UITableView!
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        ViewController().spartanSetup()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.lightGray.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        _ = Spartan.getMyPlaylists(limit: 20, offset: 0, success: { (pagingObject) in
            let playlists = pagingObject.items
            let username = SpotifyLogin.shared.username
            for i in 0...(playlists!.count - 1) {
                var uri: String = (playlists?[i].owner.uri!)!
                uri = uri.replacingOccurrences(of: "spotify:user:", with: "")
                if(username == uri) {
                    self.playlistUserIDs.append(uri)
                    self.playlistNames.append((playlists?[i].name)!)
                    self.playlistImages.append((playlists?[i].images[0])!)
                    self.playlistSizes.append((playlists?[i].tracksObject.total)!)
                    
                    var uri2: String = (playlists?[i].uri)!
                    uri2 = uri2.replacingOccurrences(of: "spotify:playlist:", with: "")
                    self.playlistIDs.append(uri2)
                }
            }
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }, failure: { (error) in
            print(error)
            SVProgressHUD.dismiss()
        })
    }
     
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistNames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let cellText = self.playlistNames[indexPath.row]
        cell.textLabel?.text = cellText
        
        let cellURL = playlistImages[indexPath.row].url
        let url = URL(string: cellURL!)
        cell.imageView?.kf.indicatorType = .activity
        cell.imageView?.kf.setImage(with: url, completionHandler: {
            (image, error, cacheType, imageUrl) in
            cell.imageView?.image = self.squareImage(image: image!, size: 70.0)
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        })
        
        if (indexPath.row == selected) {
            cell.backgroundColor = UIColor.lightGray
        } else {
            cell.backgroundColor = .clear
        }
        
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = cellText
        cell.imageView?.layer.cornerRadius = 10
        cell.imageView?.clipsToBounds = true
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected = indexPath.row
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func squareImage(image: UIImage, size: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size, height: size))
        image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // actions to clear data and begin sorting operation
    @IBAction func sortByBPM(_ sender: Any) {
        requestType = "bpm"
        clearDataArrays()
        getPlaylistTracks()
    }
    @IBAction func sortByPopularity(_ sender: Any) {
        requestType = "popularity"
        clearDataArrays()
        getPlaylistTracks()
    }
    @IBAction func sortByEnergy(_ sender: Any) {
        requestType = "energy"
        clearDataArrays()
        getPlaylistTracks()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // function to get tracks in selected playlist
    func getPlaylistTracks() {
        var complete: Int = 0
        var limit: Int = 0
        SVProgressHUD.show()
        while(complete < playlistSizes[selected]) {
            if(complete < playlistSizes[selected] - 100) {
                limit = 100
            } else {
                limit = playlistSizes[selected] - complete
            }
            _ = Spartan.getPlaylistTracks(userId: playlistUserIDs[selected], playlistId: playlistIDs[selected], limit: limit, offset: complete, market: .us, success: { (pagingObject) in
                let tracks = pagingObject.items
                for i in 0...(tracks!.count - 1) {
                    let currentTrack = tracks?[i].track
                    self.trackList.append(currentTrack!)
                    self.duration.append(Double((currentTrack?.durationMs)!))
                    self.popularity.append(Double((currentTrack?.popularity)!))
                }
            }, failure: { (error) in
                print(error)
            })
            complete = complete + limit
        }
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.loopGetTracks), userInfo: nil, repeats: true)
    }
    
    // function to get audio data for tracks in given playlist
    func getPlaylistTrackData() {
        var complete: Int = 0
        var limit: Int = 0
        var trackIDs: [String] = []
        for track in trackList {
            let uri = track.uri
            trackIDs.append(uri!.replacingOccurrences(of: "spotify:track:", with: ""))
        }
        while(complete < trackList.count) {
            if(complete < trackList.count - 100) {
                limit = 100
            } else {
                limit = trackList.count - complete
            }
            let rangeMax = complete + limit
            let subset = Array(trackIDs[complete..<rangeMax])
            _ = Spartan.getAudioFeatures(trackIds: subset, success: { (audioFeaturesObject) in
                for feature in audioFeaturesObject {
                    self.bpm.append(feature.tempo ?? 100.00)
                    self.energy.append(feature.energy ?? 0.5)
                }
            }, failure: { (error) in
                print(error)
            })
            complete = complete + limit
        }
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.loopGetTracksData), userInfo: nil, repeats: true)
    }
    
    // function to reorder tracks in given playlist using audio data
    func reorderTracksBy(filter: String) {
        var unorderedData: [Double] = []
        if(filter == "bpm") {
            unorderedData = bpm
        } else if (filter == "popularity") {
            unorderedData = popularity
        } else {
            unorderedData = energy
        }
        let total: Int = unorderedData.count
                
        let dispatchGroup = DispatchGroup()
        let dispatchQueue = DispatchQueue(label: "asynchronous-queue")
        let dispatchSemaphore = DispatchSemaphore(value: 0)
        
        // creating an asynchronous protocol to ensure that reorder operations are completed in turn
        dispatchQueue.async {
            for position in 0...(total - 1) {
                dispatchGroup.enter()
                
                var index: Int
                let minValue = unorderedData.min()!
                let maxValue = unorderedData.max()!
                if(filter == "bpm") {
                    index = unorderedData.index(of: minValue)!
                } else {
                    index = unorderedData.index(of: maxValue)!
                }
                let start = index + position
                                
                _ = Spartan.reorderPlaylistsTracks(userId: self.playlistUserIDs[self.selected], playlistId: self.playlistIDs[self.selected], rangeStart: start, insertBefore: position, success: { (snapshot) in
                    unorderedData.remove(at: index)
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                }, failure: { (error) in
                    print(error)
                    dispatchSemaphore.signal()
                    dispatchGroup.leave()
                })
                dispatchSemaphore.wait()
            }
        }
        dispatchGroup.notify(queue: dispatchQueue) {
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                print ("The playlist has been reordered.")
            }
        }
    }
    
    // looped functions that execute methods in conditional when given asynchronous method is complete
    @objc func loopGetTracks() {
        if (trackList.count >= playlistSizes[selected]) {
            timer.invalidate()
            getPlaylistTrackData()
        }
    }
    @objc func loopGetTracksData() {
        if (trackList.count >= playlistSizes[selected]) {
            timer.invalidate()
            reorderTracksBy(filter: requestType)
        }
    }
    
    // function to clear data arrays in preparation for new sorting operation
    func clearDataArrays() {
        trackList = []
        bpm = []
        popularity = []
        energy = []
    }
    
}

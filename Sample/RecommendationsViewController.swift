//
//  RecommendationsViewController.swift
//
//  Created by Karan Jaisingh on 21/5/20.
//

import UIKit
import Spartan
import SpotifyLogin
import SVProgressHUD

class RecommendationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var timer: Timer!
    var complete: Bool = false
    
    var artistIDs: [String] = []
    var relatedArtistIDs: [String] = []
    
    var trackIDs: [String] = []
    var trackNames: [String] = []
    var trackImages: [SpartanImage] = []
    var trackURLs: [String] = []
    
    var displayedIDs: [String] = []
    var displayedNames: [String] = []
    var displayedImages: [SpartanImage] = []
    var displayedURLs: [String] = []

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
        
        _ = Spartan.getMyTopArtists(limit: 10, offset: 0, timeRange: .shortTerm, success: { (pagingObject) in
            let recentArtists = pagingObject.items
            for artist in recentArtists! {
                var uri: String = artist.uri
                uri = uri.replacingOccurrences(of: "spotify:artist:", with: "")
                self.artistIDs.append(uri)
            }
            self.findRelatedArtists()
        }, failure: { (error) in
            print(error)
        })
    }
    
    // function to find related artists to user's recent top artists
    func findRelatedArtists() {
        var i: Int = 0
        for id in artistIDs {
            _ = Spartan.getArtistsRelatedArtists(artistId: id, success: { (artists) in
                for artist in artists {
                    var uri: String = artist.uri
                    uri = uri.replacingOccurrences(of: "spotify:artist:", with: "")
                    if(self.artistIDs.contains(uri) == false && self.relatedArtistIDs.contains(uri) == false) {
                        self.relatedArtistIDs.append(uri)
                    }
                }
                i = i + 1
                if(i == (self.artistIDs.count - 1)) {
                    self.complete = true
                }
            }, failure: { (error) in
                print(error)
            })
        }
        self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.loop), userInfo: nil, repeats: true)
    }
    
    // function to find related tracks using related artists
    func findRelatedTracks() {
        let randomIDs = relatedArtistIDs[randomPick: 25]
        for id in randomIDs {
             _ = Spartan.getArtistsTopTracks(artistId: id, country: .us, success: { (tracks) in
                let randomTracks = tracks[randomPick: 2]
                for track in randomTracks {
                    let uri: String = track.uri
                    self.displayedIDs.append(uri.replacingOccurrences(of: "spotify:track:", with: ""))
                    self.displayedNames.append(track.name)
                    self.displayedURLs.append(Array(track.externalUrls)[0].value)
                    self.displayedImages.append(track.album.images[0])
                }
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
            }, failure: { (error) in
                print(error)
                SVProgressHUD.dismiss()
            })
        }
    }
    
    // looping function that executes when asychronous request is complete
    @objc func loop() {
        if (complete) {
            timer.invalidate()
            findRelatedTracks()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedIDs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let cellText = "\(indexPath.row + 1). " + self.displayedNames[indexPath.row]
        cell.textLabel?.text = cellText
        
        let cellURL = displayedImages[indexPath.row].url
        let url = URL(string: cellURL!)
        cell.imageView?.kf.indicatorType = .activity
        cell.imageView?.kf.setImage(with: url, completionHandler: {
            (image, error, cacheType, imageUrl) in
            cell.imageView?.image = self.squareImage(image: image!, size: 50.0)
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        })
        
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = cellText
        cell.backgroundColor = .clear
        cell.imageView?.layer.cornerRadius = 10
        cell.imageView?.clipsToBounds = true
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIApplication.shared.openURL(NSURL(string: displayedURLs[indexPath.row])! as URL)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func squareImage(image: UIImage, size: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size, height: size))
        image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    // action to generate new recommended playlist
    @IBAction func generatePressed(_ sender: Any) {
        displayedIDs = []
        displayedNames = []
        displayedImages = []
        displayedURLs = []
        findRelatedTracks()
    }
    
    // action to save current recommended playlist to spotify account
    @IBAction func savePressed(_ sender: Any) {
        let username = SpotifyLogin.shared.username
        _ = Spartan.createPlaylist(userId: username!, name: "SpotiFriend \(randomString(length: 5))", isPublic: true, isCollaborative: false, success: { (playlist) in
            var playlistID: String = playlist.uri
            playlistID = playlistID.replacingOccurrences(of: "spotify:playlist:", with: "")
            var trackURIs: [String] = []
            for i in 0...(self.displayedIDs.count - 1) {
                trackURIs.append("spotify:track:\(self.displayedIDs[i])")
            }
            _ = Spartan.addTracksToPlaylist(userId: username!, playlistId: playlistID, trackUris: trackURIs, success: { (snapshot) in
                print("Successfully created playlist!")
            }, failure: { (error) in
                print(error)
            })
        }, failure: { (error) in
            print(error)
        })
    }
    
    // function to generate random n digit code using alaphanumeric characters
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

// extension to allow for picking n random elements in arrray
extension Array {
    subscript (randomPick n: Int) -> [Element] {
        var copy = self
        for i in stride(from: count - 1, to: count - n - 1, by: -1) {
            copy.swapAt(i, Int(arc4random_uniform(UInt32(i + 1))))
        }
        return Array(copy.suffix(n))
    }
}

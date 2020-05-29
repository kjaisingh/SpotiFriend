//
//  PlaylistAnalysisViewController.swift
//
//  Created by Karan Jaisingh on 20/5/20.
//

import UIKit
import Spartan
import SVProgressHUD

class PlaylistAnalysisViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var playlistNames: [String] = []
    var playlistIDs: [String] = []
    var playlistUserIDs: [String] = []
    var playlistImages: [SpartanImage] = []
    var playlistSizes: [Int] = []
    var selected: Int = 0

    @IBOutlet weak var tableView: UITableView!
    
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
            for i in 0...(playlists!.count - 1) {
                self.playlistNames.append((playlists?[i].name)!)
                self.playlistImages.append((playlists?[i].images[0])!)
                self.playlistSizes.append((playlists?[i].tracksObject.total)!)
                
                var uri: String = (playlists?[i].owner.uri!)!
                uri = uri.replacingOccurrences(of: "spotify:user:", with: "")
                self.playlistUserIDs.append(uri)
                
                var uri2: String = (playlists?[i].uri)!
                uri2 = uri2.replacingOccurrences(of: "spotify:playlist:", with: "")
                self.playlistIDs.append(uri2)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // initalizing global variables if analysis request made
    @IBAction func getAnalysisPressed(_ sender: Any) {
        globalVariables.selectedPlaylistID = playlistIDs[selected]
        globalVariables.selectedPlaylistName = playlistNames[selected]
        globalVariables.selectedPlaylistUserID = playlistUserIDs[selected]
        globalVariables.selectedPlaylistSize = playlistSizes[selected]
    }
    
}

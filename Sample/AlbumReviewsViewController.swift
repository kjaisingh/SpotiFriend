//
//  AlbumReviewsViewController.swift
//
//  Created by Karan Jaisingh on 22/5/20.
//

import UIKit
import CoreData
import Spartan
import Cosmos

class AlbumReviewsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var albumNames: [String] = []
    var albumArtists: [String] = []
    var albumImageURLs: [String] = []
    var albumURLs: [String] = []
    var albumReviews: [Double] = []

    @IBOutlet weak var tableView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController().spartanSetup()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.lightGray.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        if #available(iOS 10.0, *) {
            retrieveData()
        } else {
            print("Please update your iOS device to Version 10.0+ to proceed.")
        }
    }
    
    // retrieve data from core data storage and place in pre-initialized arrays
    @available(iOS 10.0, *)
    func retrieveData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Review")
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result as! [NSManagedObject] {
                albumNames.append(data.value(forKeyPath: "albumName") as! String)
                albumArtists.append(data.value(forKeyPath: "albumArtist") as! String)
                albumImageURLs.append(data.value(forKeyPath: "albumImageURL") as! String)
                albumURLs.append(data.value(forKeyPath: "albumURL") as! String)
                albumReviews.append(data.value(forKeyPath: "albumReview") as! Double)
                tableView.reloadData()
            }
        } catch {
            print("Data could not be fetched.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumNames.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIApplication.shared.openURL(NSURL(string: albumURLs[indexPath.row])! as URL)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.numberOfLines = 0;
        let cellText = "\(self.albumNames[indexPath.row])\n\(self.albumArtists[indexPath.row])"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 14.0)
        cell.textLabel?.text = cellText
        
        var reviewDisplay = cell.viewWithTag(1) as! CosmosView
        reviewDisplay.rating = self.albumReviews[indexPath.row]
        
        let cellURL = albumImageURLs[indexPath.row]
        let url = URL(string: cellURL)
        cell.imageView?.kf.indicatorType = .activity
        cell.imageView?.kf.setImage(with: url, completionHandler: {
            (image, error, cacheType, imageUrl) in
            cell.imageView?.image = self.squareImage(image: image!, size: 70.0)
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
    
    func squareImage(image: UIImage, size: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size, height: size))
        image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

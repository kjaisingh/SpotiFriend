//
//  TopArtistsViewController.swift
//
//  Created by Karan Jaisingh on 20/5/20.
//

import UIKit
import Spartan
import Kingfisher
import SVProgressHUD

class TopArtistsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // instance variables declaration
    var longTermArtists: [String] = []
    var longTermImages: [SpartanImage] = []
    var longTermURLs: [String] = []
    var shortTermArtists: [String] = []
    var shortTermImages: [SpartanImage] = []
    var shortTermURLs: [String] = []
    
    // state options: 0 indicates all time, 1 indicates recent
    var state: Int = 0
    
    // user interface components
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var allTimeButton: UIButton!
    @IBOutlet weak var recentlyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show()
        ViewController().spartanSetup()
        
        allTimeButton.setTitleColor(.white, for: .normal)
        allTimeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        recentlyButton.setTitleColor(.darkGray, for: .normal)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.lightGray.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none

        // retrieve and organize data for user's all time top artists
        _ = Spartan.getMyTopArtists(limit: 10, offset: 0, timeRange: .longTerm, success: { (pagingObject) in
            let longTerm = pagingObject.items
            for i in 0...(longTerm!.count - 1) {
                self.longTermArtists.append((longTerm?[i].name)!)
                self.longTermImages.append((longTerm?[i].images?[0])!)
                self.longTermURLs.append(Array(longTerm![i].externalUrls)[0].value)
            }
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }, failure: { (error) in
            print(error)
            SVProgressHUD.dismiss()
        })
        
        // retrieve and organize data for user's recent top artists
        _ = Spartan.getMyTopArtists(limit: 10, offset: 0, timeRange: .shortTerm, success: { (pagingObject) in
            let shortTerm = pagingObject.items
            for i in 0...(shortTerm!.count - 1) {
                self.shortTermArtists.append((shortTerm?[i].name)!)
                self.shortTermImages.append((shortTerm?[i].images?[0])!)
                self.shortTermURLs.append(Array(shortTerm![i].externalUrls)[0].value)
            }
            self.tableView.reloadData()
        }, failure: { (error) in
            print(error)
        })
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(state == 0) {
            return longTermArtists.count
        }
        return shortTermArtists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.backgroundColor = .clear
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        var cellText: String?
        var imageURL: URL?
        
        if(state == 0) {
            cellText = "\(indexPath.row + 1). " + self.longTermArtists[indexPath.row]
            let cellURL = longTermImages[indexPath.row].url
            imageURL = URL(string: cellURL!)
        } else {
            cellText = "\(indexPath.row + 1). " + self.shortTermArtists[indexPath.row]
            let cellURL = shortTermImages[indexPath.row].url
            imageURL = URL(string: cellURL!)
        }
        
        cell.imageView?.kf.indicatorType = .activity
        cell.imageView?.kf.setImage(with: imageURL, completionHandler: {
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(state == 0) {
            UIApplication.shared.openURL(NSURL(string: longTermURLs[indexPath.row])! as URL)
        } else {
            UIApplication.shared.openURL(NSURL(string: shortTermURLs[indexPath.row])! as URL)
        }
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
    
    // function to switch tableview content when all time button pressed
    @IBAction func allTimePressed(_ sender: Any) {
        state = 0
        allTimeButton.setTitleColor(.white, for: .normal)
        allTimeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        recentlyButton.setTitleColor(.darkGray, for: .normal)
        recentlyButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        tableView.reloadData()
    }
    
    // function to switch tableview content when recent button pressed
    @IBAction func recentlyPressed(_ sender: Any) {
        state = 1
        allTimeButton.setTitleColor(.darkGray, for: .normal)
        allTimeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        recentlyButton.setTitleColor(.white, for: .normal)
        recentlyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        tableView.reloadData()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

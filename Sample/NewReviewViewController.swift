//
//  NewReviewViewController.swift
//
//  Created by Karan Jaisingh on 23/5/20.
//

import UIKit
import CoreData
import Spartan
import Cosmos

class NewReviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var albumsNames: [String] = []
    var albumsArtist: [String] = []
    var albumsImages: [SpartanImage] = []
    var albumsURLs: [String] = []
    
    var selectedAlbumName: String? = nil
    var selectedAlbumArtist: String? = nil
    var selectedAlbumImage: SpartanImage? = nil
    var selectedAlbumURL: String? = nil
    
    var selected: Int = 0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cosmosView: CosmosView!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var selectedImageField: UIImageView!
    @IBOutlet weak var selectedNameField: UILabel!
    @IBOutlet weak var selectedArtistField: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController().spartanSetup()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.lightGray.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        searchBar.backgroundColor = UIColor.clear
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .black

        cosmosView.isHidden = true
        saveButton.isHidden = true
        
        selectedNameField.numberOfLines = 0
        selectedArtistField.numberOfLines = 0
        
        cosmosView.didTouchCosmos = didTouchCosmos
        cosmosView.didFinishTouchingCosmos = didFinishTouchingCosmos
    }
    
    // search for albums on spotify when text in search bar changes
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        selected = 0
        albumsNames = []
        albumsArtist = []
        albumsImages = []
        albumsURLs = []
        if(searchText.count > 2) {
            _ = Spartan.search(query: searchText, type: .album, success: { (pagingObject: PagingObject<SimplifiedAlbum>) in
                let albums = pagingObject.items
                for album in albums! {
                    self.albumsNames.append(album.name)
                    self.albumsArtist.append(album.artists[0].name)
                    self.albumsImages.append(album.images[0])
                    self.albumsURLs.append(Array(album.externalUrls)[0].value)
                }
                self.tableView.reloadData()
            }, failure: { (error) in
                print(error)
            })
        } else if (searchText.count == 0) {
            self.tableView.reloadData()
        }
    }
    
    // reset values in search bar when cancel pressed
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        albumsNames = []
        albumsArtist = []
        albumsImages = []
        albumsURLs = []
        selected = 0
        cosmosView.isHidden = true
        saveButton.isHidden = true
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumsNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let cellText = self.albumsNames[indexPath.row]
        cell.textLabel?.text = cellText
        
        let cellURL = albumsImages[indexPath.row].url
        let url = URL(string: cellURL!)
        cell.imageView?.kf.indicatorType = .activity
        cell.imageView?.kf.setImage(with: url, completionHandler: {
            (image, error, cacheType, imageUrl) in
            cell.imageView?.image = self.squareImage(image: image!, size: 60.0)
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
        cosmosView.isHidden = false
        saveButton.isHidden = false
        cosmosView.rating = 0
        
        selected = indexPath.row
        
        selectedAlbumName = albumsNames[indexPath.row]
        selectedAlbumArtist = albumsArtist[indexPath.row]
        selectedAlbumImage = albumsImages[indexPath.row]
        selectedAlbumURL = albumsURLs[indexPath.row]
        
        selectedNameField.text = selectedAlbumName
        selectedArtistField.text = selectedAlbumArtist
        
        let imageURL = selectedAlbumImage?.url
        let url = URL(string: imageURL!)
        selectedImageField.kf.setImage(with: url, completionHandler: {
            (image, error, cacheType, imageUrl) in
            self.selectedImageField.image = self.squareImage(image: image!, size: 50.0)
        })
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    // change cosmos rating when touched
    func didTouchCosmos(_ rating: Double) {
        cosmosView.rating = rating
    }
    
    // change cosmos rating when finished touching
    func didFinishTouchingCosmos(_ rating: Double) {
        cosmosView.rating = rating
    }
    
    func squareImage(image: UIImage, size: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: size, height: size))
        image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // action to save rating to core data storage
    @available(iOS 10.0, *)
    @IBAction func savePressed(_ sender: Any) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let reviewEntity = NSEntityDescription.entity(forEntityName: "Review", in: managedContext)
        
        let review = NSManagedObject(entity: reviewEntity!, insertInto: managedContext)
        review.setValue(selectedAlbumArtist, forKeyPath: "albumArtist")
        review.setValue(selectedAlbumName, forKeyPath: "albumName")
        review.setValue(selectedAlbumImage?.url, forKeyPath: "albumImageURL")
        review.setValue(selectedAlbumURL, forKeyPath: "albumURL")
        review.setValue(cosmosView.rating, forKeyPath: "albumReview")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save.")
        }
                
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

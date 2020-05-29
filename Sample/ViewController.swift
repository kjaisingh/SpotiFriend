//
//  ViewController.swift
//
//  Created by Karan Jaisingh on 21/5/20.
//

import UIKit
import CoreData
import SpotifyLogin
import Spartan

class ViewController: UIViewController {
    
    @IBOutlet weak var loggedInStackView: UIStackView!
    @IBOutlet weak var topTracksButton: UIButton!
    @IBOutlet weak var topArtistsButton: UIButton!
    @IBOutlet weak var playlistAnalysisButton: UIButton!
    @IBOutlet weak var recommendationsButton: UIButton!
    @IBOutlet weak var albumReviewsButton: UIButton!
    @IBOutlet weak var playlistManagementButton: UIButton!
  
    // retrieve authorization token for spotify
    func spartanSetup() {
        Spartan.loggingEnabled = true
        SpotifyLogin.shared.getAccessToken { (accessToken, error) in
            Spartan.authorizationToken = accessToken
            if error != nil {
                print(error)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spartanSetup()
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.view.bounds
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.lightGray.cgColor]
        self.view.layer.insertSublayer(gradientLayer, at: 0)
        createRoundedButtons()
        
        // resetAllRecords(in: "Review")
        // uncommenting line above resets all records in core data database
        
        playlistManagementButton.titleLabel?.textAlignment = NSTextAlignment.center
        
        // automatically login if user has used the app previously
        SpotifyLogin.shared.getAccessToken { [weak self] (token, error) in
            self?.loggedInStackView.alpha = (error == nil) ? 1.0 : 0.0
            if error != nil, token == nil {
                self?.showLoginFlow()
            }
        }
    }

    func showLoginFlow() {
        self.performSegue(withIdentifier: "home_to_login", sender: self)
    }

    // log user out
    @IBAction func didTapLogOut(_ sender: Any) {
        SpotifyLogin.shared.logout()
        self.loggedInStackView.alpha = 0.0
        self.showLoginFlow()
    }
    
    // function to reset all records in core data database
    func resetAllRecords(in entity : String) {
        if #available(iOS 10.0, *) {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            do {
                try context.execute(deleteRequest)
                try context.save()
            } catch {
                print ("There was an error deleting all records in the entity.")
            }
        } else {
            print("Please update your iOS device to Version 10.0+ to proceed.")
        }
    }
    
    // setting UI components for buttons on screen
    func createRoundedButtons() {
        topTracksButton.layer.cornerRadius = 10
        topTracksButton.clipsToBounds = true
        topArtistsButton.layer.cornerRadius = 10
        topArtistsButton.clipsToBounds = true
        playlistAnalysisButton.layer.cornerRadius = 10
        playlistAnalysisButton.clipsToBounds = true
        recommendationsButton.layer.cornerRadius = 10
        recommendationsButton.clipsToBounds = true
        albumReviewsButton.layer.cornerRadius = 10
        albumReviewsButton.clipsToBounds = true
        playlistManagementButton.layer.cornerRadius = 10
        playlistManagementButton.clipsToBounds = true
    }
    
}

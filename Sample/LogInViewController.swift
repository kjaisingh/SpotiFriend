//
//  LoginViewController.swift
//
//  Created by Karan Jaisingh on 21/5/20.
//

import UIKit
import SpotifyLogin

class LogInViewController: UIViewController {

    var loginButton: UIButton?
    
    // initialization of spotify login button
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = SpotifyLoginButton(viewController: self,
                                        scopes: [.streaming,
                                                 .userReadEmail,
                                                 .userReadPrivate,
                                                 .playlistReadPrivate,
                                                 .playlistReadCollaborative,
                                                 .playlistModifyPublic,
                                                 .playlistReadPrivate,
                                                 .userLibraryRead,
                                                 .userLibraryModify,
                                                 .userReadTop,
                                                 .userReadCurrentlyPlaying,
                                                 .userFollowRead,
                                                 .userFollowModify
                                                ])
        self.view.addSubview(button)
        self.loginButton = button
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(loginSuccessful),
                                               name: .SpotifyLoginSuccessful,
                                               object: nil)
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        loginButton?.frame = CGRect(x: 100, y: 570, width: 250, height: 50)
        loginButton?.center.x = self.view.center.x
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func loginSuccessful() {
        self.navigationController?.popViewController(animated: true)
    }
    
}

//
//  AppDelegate.swift
//  Browser
//
//  Created by Amer Hukić on 10. 9. 2021..
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.makeKeyAndVisible()
    window?.rootViewController = BrowserContainerViewController()
    return true
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    guard let scheme = url.scheme?.lowercased(),
          ["http", "https", "safari"].contains(scheme) else { return false }

    let destination: URL?
    if scheme == "safari" {
      if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
         let value = components.queryItems?.first(where: { $0.name == "url" })?.value,
         let parsed = URL(string: value),
         let parsedScheme = parsed.scheme?.lowercased(),
         ["http", "https"].contains(parsedScheme) {
        destination = parsed
      } else {
        destination = nil
      }
    } else {
      destination = url
    }

    guard let destination,
          let destinationScheme = destination.scheme?.lowercased(),
          ["http", "https"].contains(destinationScheme) else { return false }

    if let browser = window?.rootViewController as? BrowserContainerViewController {
      browser.openIncomingURL(destination)
      return true
    }
    return false
  }
}


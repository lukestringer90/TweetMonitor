//
//  ViewController.swift
//  Stakeout
//
//  Created by Luke Stringer on 30/03/2018.
//  Copyright © 2018 Luke Stringer. All rights reserved.
//

import UIKit
import TwitterKit
import Swifter
import CoreLocation
import SafariServices

class TimelineViewController: TWTRTimelineViewController {
	
	var locationManager: BackgroundLocationManager!
	
	var list: List? {
		get {
			return selectedListStore.list
		}
	}
	
	// TODO: Make array of Keywords
	var keywords: [String] {
		get {
			return keywordStore.all().map { $0.text }
		}
	}
	let keywordStore = KeywordStore.shared
	let selectedListStore = SelectedListStore.shared
	
	var listSelectionNavController: UINavigationController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		keywordStore.observer = self
		selectedListStore.observer = self
		
		guard let session = Twitter.sharedInstance().sessionStore.session() else {
			login()
			return
		}
		
		Swifter.setup(from: session)
		start()
		
		TWTRTweetView.appearance().showActionButtons = false
	}
}


// MARK: - Storage Observance
extension TimelineViewController: KeywordStoreObserver {
	func store(_ store: KeywordStore, updated keywords: [Keyword]) {
		start()
	}
}

extension TimelineViewController: ListStoreObserver {
	func store(_ store: SelectedListStore, updated list: List?) {
		start()
	}
}

// MARK: - Setup
fileprivate extension TimelineViewController {
	func login() {
		Twitter.sharedInstance().logIn(completion: { (session, error) in
			guard let session = session else {
				let alert = UIAlertController(title: "Login Error", message: error?.localizedDescription, preferredStyle: .alert)
				let action = UIAlertAction(title: "Try Again", style: .default, handler: { _ in
					self.login()
				})
				alert.addAction(action)
				self.present(alert, animated: true, completion: nil)
				return
			}
			
			Swifter.setup(from: session)
			self.start()
		})
	}
	
	func start() {
		guard let selectedList = list else {
			showListSelection()
			return
		}
		
		
		locationManager = BackgroundLocationManager(callback: locationUpdated)
		setupTimeline(with: selectedList)
	}
	
	func setupTimeline(with list: List) {
		
		guard let (slug, screenName) = list.listTag.slugAndOwnerScreenName() else {
			fatalError("Bad List or User Tag")
		}
		
		dataSource = FilteredListTimelineDataSource(listSlug: slug,
													listOwnerScreenName: screenName,
													matching: keywords,
													apiClient: TWTRAPIClient())
		
		tweetViewDelegate = self
		title = slug
	}
	
}

// MARK: - Segues
extension TimelineViewController {
	func showListSelection() {
		guard let listSelection = storyboard?.instantiateViewController(withIdentifier: "ListSelection") else {
			fatalError("Cannot instantiate list selection view controller")
		}
		listSelectionNavController = UINavigationController(rootViewController: listSelection)
		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(listSelectionDone))
		listSelection.navigationItem.leftBarButtonItem = doneButton
		present(listSelectionNavController, animated: true, completion: nil)
	}
	
	@IBAction func unwind(_:UIStoryboardSegue) { }
	
	@objc func listSelectionDone() {
		if selectedListStore.list != nil {
			dismiss(animated: true, completion: nil)
			start()
		}
	}
}

// MARK: - Location updates
fileprivate extension TimelineViewController {
	func locationUpdated(with locations: [CLLocation]) {
		
		guard let selectedList = list else {
			showListSelection()
			return
		}
		
		let matcher = TweetKeywordMatcher(store: TweetStore.shared)
		
		matcher.requestTweets(in: selectedList.listTag, withTextContainingAnyOf: keywords) { possibleMatching, error in
			guard let matching = possibleMatching else {
				print(error ?? "No matching or error")
				return
			}
			
			if matching.count > 0 {
				print("\(matching.count) new tweets Matching: \(self.keywords)")
				print("\(matching.map { $0.text })")
				NotificationSender.sendNotification(title: "New Matching Tweets", subtitle: matching.first!.text)
				self.refresh()
			}
		}
	}
}

// MARK: - Tweet View Delegate
extension TimelineViewController: TWTRTweetViewDelegate {
	func tweetView(_ tweetView: TWTRTweetView, didTap url: URL) {
		let config = SFSafariViewController.Configuration()
		config.barCollapsingEnabled = true
		let vc = SFSafariViewController(url: url, configuration: config)
		vc.dismissButtonStyle = .done
		present(vc, animated: true, completion: nil)
	}
}

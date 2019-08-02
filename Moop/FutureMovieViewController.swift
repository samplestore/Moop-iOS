//
//  FutureMovieViewController.swift
//  Moop
//
//  Created by Chang Woo Son on 23/05/2019.
//  Copyright © 2019 kor45cw. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices

class FutureMovieViewController: UIViewController {

    private let searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            refreshControl.addTarget(self, action: #selector(requestData), for: .valueChanged)
            collectionView.refreshControl = refreshControl
            collectionView.register(MovieCell.self)
        }
    }
    private var datas: [MovieInfo] = [] {
        didSet {
            let theaters = UserDefaults.standard.object([TheaterType].self, forKey: .theater) ?? TheaterType.allCases
            let ages = UserDefaults.standard.object([AgeType].self, forKey: .age) ?? AgeType.allCases
            self.filteredMovies = datas
                                    .filter { $0.contain(types: theaters) }
                                    .filter { $0.contain(ages: ages) }
        }
    }

    private var filteredMovies: [MovieInfo] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    private var searchedMovies: [MovieInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        self.registerForPreviewing(with: self, sourceView: self.collectionView)
        self.datas = MovieInfoManager.shared.futureDatas
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case "toDetails":
            guard let destination = segue.destination as? MovieDetailViewController,
                let indexPathItem = sender as? Int else { return }
            if isFiltering() {
                destination.item = searchedMovies[indexPathItem]
            } else {
                destination.item = filteredMovies[indexPathItem]
            }
        case "toFilter":
            guard let destinationNavi = segue.destination as? UINavigationController,
                let destination = destinationNavi.viewControllers.first as? FilterViewController else { return }
            destination.delegate = self
        default:
            break
        }
    }
    
    @objc private func requestData() {
        MovieInfoManager.shared.requestFutureData { [weak self] in
            guard let self = self else { return }
            self.datas = MovieInfoManager.shared.futureDatas
            self.refreshControl.endRefreshing()
        }
    }
    
    var canScrollToTop: Bool = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canScrollToTop = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        canScrollToTop = false
    }
}

extension FutureMovieViewController: FilterChangeDelegate {
    func filterItemChanged() {
        let theaters = UserDefaults.standard.object([TheaterType].self, forKey: .theater) ?? TheaterType.allCases
        let ages = UserDefaults.standard.object([AgeType].self, forKey: .age) ?? AgeType.allCases
        self.filteredMovies = datas
                                .filter { $0.contain(types: theaters) }
                                .filter { $0.contain(ages: ages) }
    }
}

extension FutureMovieViewController: ScrollToTopDelegate {
    func scrollToTop() {
        if collectionView != nil && !filteredMovies.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
            }
        }
    }
}

extension FutureMovieViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        searchedMovies = filteredMovies.filter({ $0.title.contains(searchController.searchBar.text ?? "" ) })
        collectionView.reloadData()
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}

extension FutureMovieViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering() {
            return searchedMovies.count
        }
        return filteredMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MovieCell = collectionView.dequeueReusableCell(for: indexPath)
        if isFiltering() {
            cell.set(searchedMovies[indexPath.item])
        } else {
            cell.set(filteredMovies[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toDetails", sender: indexPath.item)
    }
}

extension FutureMovieViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = (collectionView.bounds.width - 36) / 3
        return CGSize(width: cellWidth, height: cellWidth / 600.0 * 855)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
//    @available(iOS 13.0, *)
//    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
//            let share = UIAction(__title: "Share", image: UIImage(named: "share"), identifier: nil) { [weak self] _ in
//                guard let self = self else { return }
//                let shareText = self.isFiltering() ? self.searchedMovies[indexPath.item].shareText : self.filteredMovies[indexPath.item].shareText
//                self.share(text: shareText)
//            }
//            let cgv = UIAction(__title: "CGV", image: nil, identifier: nil) { [weak self] _ in
//                guard let self = self else { return }
//                let item = self.isFiltering() ? self.searchedMovies[indexPath.item] : self.filteredMovies[indexPath.item]
//                self.rating(type: .cgv, id: item.cgv?.id ?? "")
//            }
//            
//            let lotte = UIAction(__title: "LOTTE", image: nil, identifier: nil) { [weak self] _ in
//                guard let self = self else { return }
//                let item = self.isFiltering() ? self.searchedMovies[indexPath.item] : self.filteredMovies[indexPath.item]
//                self.rating(type: .lotte, id: item.lotte?.id ?? "")
//            }
//            
//            let megabox = UIAction(__title: "MEGABOX", image: nil, identifier: nil) { [weak self] _ in
//                guard let self = self else { return }
//                let item = self.isFiltering() ? self.searchedMovies[indexPath.item] : self.filteredMovies[indexPath.item]
//                self.rating(type: .megabox, id: item.megabox?.id ?? "")
//            }
//            
//            // Create and return a UIMenu with the share action
//            return UIMenu(__title: "", image: nil, identifier: nil, children: [share, cgv, lotte, megabox])
//        }
//    }
}

extension FutureMovieViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        guard let destination = storyboard?.instantiateViewController(withIdentifier: "detail") as? MovieDetailViewController else { return nil }
        destination.item = isFiltering() ? searchedMovies[indexPath.item] : filteredMovies[indexPath.item]
        destination.delegate = self
        return destination
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}

extension FutureMovieViewController: MovieDetailPickAndPopDelegate {
    func share(text: String) {
        let viewController = UIActivityViewController(activityItems: [text], applicationActivities: [])
        present(viewController, animated: true, completion: nil)
    }
    
    func rating(type: TheaterType, id: String) {
        let webURL: URL?
        switch type {
        case .cgv:
            webURL = URL(string: "http://m.cgv.co.kr/WebApp/MovieV4/movieDetail.aspx?MovieIdx=\(id)")
        case .lotte:
            webURL = URL(string: "http://www.lottecinema.co.kr/LCMW/Contents/Movie/Movie-Detail-View.aspx?movie=\(id)")
        case .megabox:
            webURL = URL(string: "http://m.megabox.co.kr/?menuId=movie-detail&movieCode=\(id)")
        }
        
        guard let url = webURL else { return }
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}

//
//  Movie.swift
//  MovieSong
//
//  Created by Jim Campagno on 8/20/16.
//  Copyright © 2016 Gamesmith, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol MovieImageDelegate {
    
    func imageUpdate(withMovie movie: Movie)
    
}

final class Movie {
    
    // TODO: Instruction #1, create instance properties
    
    var title:String = ""
    var year:String = ""
    var imdbID:String = ""
    var posterURLString:String? = nil

    // TODO: Instruction #4, create more instance properties
    
    var attemptedToDownloadImage = false
    var movieImageDelegate: MovieImageDelegate?
    var shouldKickOffImageDownload: Bool { return shouldKickOffTheDownload() }
    var image: UIImage? { return retrieveImage() }
    var imageState = MovieImageState() {
        didSet {
            movieImageDelegate?.imageUpdate(withMovie: self)
        }
    }
    var hasFullInfo:Bool = false
    var rated:String = "NoRating"
    var released:String = "No Release Date"
    var director:String = "No Director"
    var imdbRating:String = "N/A"
    var tomatoMeter:String = "N/A"
    var plot:String = "No Plot"
    var ratingPercent = "No Ratings"
    
    
    // TODO: Instruction #2, create Initializer
    
    init(movieJSON:[String : String]) {
        title = movieJSON["Title"] ?? "No Title"
        year = movieJSON["Year"] ?? "No Year"
        imdbID = movieJSON["imdbID"] ?? "No imdbID"
        if let moviePosterURL = movieJSON["Poster"] {
            posterURLString = moviePosterURL
        }
    }
    
    func updateFilmInfo(jsonResponse:[String : AnyObject]) {
        rated = (jsonResponse["Rated"] as! String)
        released = (jsonResponse["Released"] as! String)
        director = (jsonResponse["Director"] as! String)
        imdbRating = jsonResponse["imdbRating"] as! String
        tomatoMeter = (jsonResponse["tomatoMeter"] as! String)
        plot = (jsonResponse["Plot"] as! String)
    }
    
    
    // TODO: Instruction #4, create the updateFilmInfo(_:) method
    
}


// MARK: Image Methods
extension Movie {
    
    fileprivate func retrieveImage() -> UIImage? {
        switch imageState {
        case .loading(let image):
            if shouldKickOffImageDownload { downloadImage() }
            return image
        case .downloaded(let image): return image
        case .NoImage(let image): return image
        case .nothing:
            if shouldKickOffImageDownload {  downloadImage() }
            return nil
        }
    }
    
    func noImage() {
        imageState.noImage()
    }
    
    func loadingImage() {
        imageState.loadingImage()
    }
    
    func nothingImage() {
        imageState.nothingImage()
    }
    
}

// MARK: Download Image Methods
extension Movie {
    
    func downloadImage()  {
        nothingImage()
        loadingImage()
        guard !attemptedToDownloadImage else { return }
        attemptedToDownloadImage = true
        guard let posterURLString = posterURLString, let posterURL = URL(string: posterURLString) else { noImage(); return }
        downloadImage(withURL: posterURL)
    }
    
    func downloadImage(withURL URL: Foundation.URL) {
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
        
        defaultSession.dataTask(with: URL, completionHandler: { data, response, error in
            DispatchQueue.main.async(execute: {
                if error != nil || data == nil { self.noImage() }
                if data != nil {
                    let image = UIImage(data: data!)
                    if image == nil {
                       self.noImage()
                    } else {
                        self.imageState = .downloaded(image!)
                    }
                }
            })
            }) .resume()
    }
    
    fileprivate func shouldKickOffTheDownload() -> Bool {
        switch (imageState, attemptedToDownloadImage) {
        case (.loading(_), false): return true
        case (.nothing, false): return true
        default: return false
        }
    }
    
}


// MARK: Update Info
extension Movie {
    
    func updateInfo(handler: @escaping (Bool) -> Void) throws {
        
        let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
        /*
        guard let urlString = imdbID.stringByAddingPercentEncodingWithAllowedCharacters(CharacterSet.URLQueryAllowedCharacterSet())
            else { throw MovieError.badSearchString("Unable to encode \(title) to use within our search.") }
 */
        guard let urlString = imdbID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            else { throw MovieError.badSearchString("Unable to encode \(title) to use within our search.") }
        print("urlString = \(urlString)")
        /*guard let searchURL = URL(string: "http://www.omdbapi.com/?apikey=375048c5&s=\(urlString)&y=&plot=full&r=json")
         guard let searchURL = URL(string: "http://www.omdbapi.com/?apikey=375048c5&i=\(urlString)&plot=full&r=json&tomatoes=true")
         else { throw MovieError.badSearchURL("Unable to create URL with the search term: \(title)") }
         */
        
        guard let searchURL = URL(string: "http://www.omdbapi.com/?apikey=375048c5&i=\(urlString)&plot=full&r=json&tomatoes=true")
            else { throw MovieError.badSearchURL("Unable to create URL with the search term: \(title)") }
        
        /*
         defaultSession.dataTask(with: searchURL, completionHandler: { [unowned self] data, response, error in
         DispatchQueue.main.async(execute: {
         if error != nil { handler(nil, MovieError.noData(error!.localizedDescription)) }
         if data == nil { handler(nil, MovieError.noData("Data has come back nil.")) }
 */
        print("searchURL = \(searchURL)")
        defaultSession.dataTask(with: searchURL, completionHandler: { [unowned self] data,
            response, error in
            DispatchQueue.main.async(execute: {
                if error != nil { handler(false) }
                if data == nil { handler(false) }
                
                print(String(describing: data!))
                
                /*
                 guard let jsonResponse = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String: AnyObject], let search = jsonResponse["Search"]
                 else { handler(nil, MovieError.badJSONconversion("Unable to convert data to JSON")); return }
 */
                guard let jsonResponse = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String:AnyObject]
                    else { handler(false); return }
                
                print("jsonResponse = \(jsonResponse)")
                
                //let actualSearch: [String : String] = jsonResponse as! [String : String]
                
                
                //let jsonResponse2: JSONResponseDictionary = search as! JSONResponseDictionary

                //print("jsonResponse = \(jsonResponse)")
                self.updateFilmInfo(jsonResponse: jsonResponse )
            
                self.hasFullInfo = true

                handler(true)
            })
            }).resume()
    }

}


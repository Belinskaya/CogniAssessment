//
//  ExplorerPinAnnotationView.swift
//  CogniIncCashbackExplorer
//
//  Created by Ekaterina Belinskaya on 04/09/2018.
//  Copyright © 2018 Ameba. All rights reserved.
//

import UIKit
import MapKit

class ExplorerPinAnnotationView: MKAnnotationView {
    var cashBack: Float
    init(with annotation: MKAnnotation) {
        cashBack = 0
        super.init(annotation: annotation, reuseIdentifier: nil)
        
        guard let venueAnnotation = annotation as? Venue else { return }
        
        canShowCallout = true
        cashBack = venueAnnotation.cashback
        
        image = #imageLiteral(resourceName: "pin")
        
        let label = UILabel(frame: CGRect(x: 5, y: 5, width: 10, height: 20))
        label.text = "\(cashBack)%"
        label.textAlignment = .center
        label.textColor = .white
        label.font = label.font.withSize(12)
        label.sizeToFit()
        if let imageSize = image?.size {
            label.center = CGPoint(x: imageSize.width/2, y: imageSize.height/2 - 7)
        }
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        cashBack = 0
        super.init(coder: aDecoder)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if let hitView = hitView {
            superview?.bringSubview(toFront: hitView)
        }
        return hitView
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var isInside = bounds.contains(point)
        if !isInside {
            for view in subviews {
                isInside = view.frame.contains(point)
                if isInside { break }
            }
        }
        return isInside
    }
    
}

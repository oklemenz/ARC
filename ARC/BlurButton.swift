//
//  BlurButton.swift
//  ARC
//
//  Created by Klemenz, Oliver on 14.12.17.
//  Copyright © 2017 Klemenz, Oliver. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
public class BlurButton : UIButton {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {        
        layer.cornerRadius = bounds.size.width / 2
        clipsToBounds = true
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blurView.frame = bounds
        blurView.isUserInteractionEnabled = false
        blurView.layer.cornerRadius = bounds.size.width / 2
        blurView.clipsToBounds = true
        
        let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .extraLight))
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
        vibrancyEffectView.frame = bounds
        vibrancyEffectView.isUserInteractionEnabled = false
        vibrancyEffectView.layer.cornerRadius = bounds.size.width / 2
        vibrancyEffectView.clipsToBounds = true
        
        if let imageView = imageView {
            vibrancyEffectView.contentView.addSubview(imageView)
            blurView.contentView.addSubview(vibrancyEffectView)
        }
        
        insertSubview(blurView, at: 0)
        
        setImage(image(for: .highlighted), for: [.selected, .highlighted])
        setBackgroundImage(backgroundImage(for: .highlighted), for: [.selected, .highlighted])
    }
}

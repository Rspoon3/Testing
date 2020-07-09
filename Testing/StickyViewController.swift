//
//  StickyViewController.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/8/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

class StickyViewController: UIViewController
{
    lazy var dynamicAnimator: UIDynamicAnimator =
        {
            let dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
            dynamicAnimator.setValue(true, forKey: "debugEnabled")
            return dynamicAnimator
        }()
    
    lazy var collision: UICollisionBehavior =
        {
            let collision = UICollisionBehavior(items: [self.orangeView])
            collision.translatesReferenceBoundsIntoBoundary = true
            return collision
        }()
    
    lazy var fieldBehaviors: [UIFieldBehavior] =
        {
            var fieldBehaviors = [UIFieldBehavior]()
            for _ in 0 ..< 4
            {
                let field = UIFieldBehavior.springField()
                field.addItem(self.orangeView)
                fieldBehaviors.append(field)
            }
            return fieldBehaviors
        }()
    
    lazy var itemBehavior: UIDynamicItemBehavior =
        {
            let itemBehavior = UIDynamicItemBehavior(items: [self.orangeView])
            // Adjust these values to change the "stickiness" of the view
            itemBehavior.density = 0.01
            itemBehavior.resistance = 10
            itemBehavior.friction = 0.0
            itemBehavior.allowsRotation = false
            return itemBehavior
        }()
    
    lazy var orangeView: UIView =
        {
            let widthHeight: CGFloat = 40.0
            let orangeView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: widthHeight, height: widthHeight))
            orangeView.backgroundColor = UIColor.orange
            self.view.addSubview(orangeView)
            return orangeView
        }()
    
    lazy var panGesture: UIPanGestureRecognizer =
        {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(sender:)))
            return panGesture
        }()
    
    lazy var attachment: UIAttachmentBehavior =
        {
            let attachment = UIAttachmentBehavior(item: self.orangeView, attachedToAnchor: .zero)
            return attachment
        }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        dynamicAnimator.addBehavior(collision)
        dynamicAnimator.addBehavior(itemBehavior)
        for field in fieldBehaviors
        {
            dynamicAnimator.addBehavior(field)
        }
        
        orangeView.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        orangeView.center = view.center
        dynamicAnimator.updateItem(usingCurrentState: orangeView)
        
        for (index, field) in fieldBehaviors.enumerated()        {
            
            if index == 0{
                field.position = CGPoint(x: view.bounds.midX / 2, y:  view.bounds.height / 4)
            } else if index == 1{
                field.position = CGPoint(x: view.bounds.width * 0.75, y:  view.bounds.height / 4)
            }else if index == 2{
                field.position = CGPoint(x: view.bounds.midX / 2, y:  view.bounds.height * 0.75)
            }else{ field.position = CGPoint(x: view.bounds.width * 0.75, y:  view.bounds.height * 0.75)
            }
            
            
            field.region = UIRegion(size: CGSize(width: view.bounds.width / 2, height: view.bounds.height * 0.5))
        }
    }
    
    @objc func handlePan(sender: UIPanGestureRecognizer)
    {
        let location = sender.location(in: view)
        let velocity = sender.velocity(in: view)
        switch sender.state
        {
        case .began:
            attachment.anchorPoint = location
            dynamicAnimator.addBehavior(attachment)
        case .changed:
            attachment.anchorPoint = location
        case .cancelled, .ended, .failed, .possible:
            itemBehavior.addLinearVelocity(velocity, for: self.orangeView)
            dynamicAnimator.removeBehavior(attachment)
        @unknown default:
            fatalError("Not supported")
        }
    }
}


struct StickyViewController_Previews: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview{
            StickyViewController()
        }
    }
}

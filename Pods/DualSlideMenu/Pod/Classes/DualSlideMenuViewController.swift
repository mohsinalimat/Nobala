//
//  DualSlideMenuViewController.swift
//  Pods
//
//  Created by Vincent Le on 3/24/16.
//  Main container class that accepts the sub view controllers on initialization
//  The main functions should be public to allow developers to use in specific cases

import UIKit

public enum State {
    case left
    case right
    case main
}

@objc
public protocol DualSlideMenuViewControllerDelegate {
    @objc optional func onSwipe()
    @objc optional func didChangeView()
}
open class DualSlideMenuViewController: UIViewController {
    
    //Create variables that will be used
    open var mainView: UIViewController!
    open var navigation: UINavigationController!
    open var currentState: State = .main
    open var mainStoryboard: UIStoryboard!
    open var rightMenu: UIViewController!
    open var leftMenu: UIViewController!
    open var leftSideOffset: CGFloat = 150 // this variable will determine the offset of the main view when a menu view is in view
    open var rightSideOffset: CGFloat = 150 // this variable will determine the offset when the right menu is in view
    open var delegate: DualSlideMenuViewControllerDelegate?
    
    fileprivate var amountOfMenus: Int!
    fileprivate var menuType: State?
    
    public convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController) {
        self.init()
        mainView = mainViewController
        leftMenu = leftMenuViewController
        
        addSwipeGestures(mainView)
        view.insertSubview(mainView.view, at: 0) // adds main view at the bottom
        view.insertSubview(leftMenu.view, belowSubview: mainView.view)
        amountOfMenus = 1;
        menuType = .left
        
    }
    
    public convenience init (mainViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        mainView = mainViewController
        rightMenu = rightMenuViewController
        
        addSwipeGestures(mainView)
        view.insertSubview(mainView.view, at: 0) // adds main view at the bottom
        view.insertSubview(rightMenu.view, belowSubview: mainView.view)
        amountOfMenus = 1;
        menuType = .right
    }
    
    /**
     Main initialization method that is recommended for use
     
     The view controllers that are passed in can be navigation controllers if the developers decide to add navigation
     
     - parameter mainViewController
     - parameter leftMenuViewController
     - parameter rightMenuViewController
     */
    public convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        mainView = mainViewController
        leftMenu = leftMenuViewController
        rightMenu = rightMenuViewController
        
        addSwipeGestures(mainView)
        view.insertSubview(mainView.view, at: 0) // adds main view at the bottom
        view.insertSubview(rightMenu.view, belowSubview: mainView.view) // stacks subview in order
        view.insertSubview(leftMenu.view, belowSubview: rightMenu.view) // the two subviews are added in this order, but makes no real noticeable difference
        amountOfMenus = 2;
        menuType = .main // There are two menus in this controller
    }
    
    /**
     Method called on initialization that adds left and right swipe recognizers
     
     - parameter mainView: the view that will contain the gestures, which is the main view because only the main
     view will recognize the swipe gestures
     */
    fileprivate func addSwipeGestures(_ mainView: UIViewController) {
        // creates two swipe gesture recognizers for the two side menus
            let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(DualSlideMenuViewController.handleSwipes(_:)))
            let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(DualSlideMenuViewController.handleSwipes(_:)))
        // assigns correct direction for the two recognizers even though the names are confusing
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        // adds the recognizers to the main view not the side views
        mainView.view.addGestureRecognizer(leftSwipe)
        mainView.view.addGestureRecognizer(rightSwipe)
    }
    
    /**
     Now allows developers to add swipe gesture in the side views
     
     - parameter viewController: the view controller that a recognizer will be added to
     - parameter direction:      the direction of type UISwipeGestureRecognizierDirection
     */
    open func addSwipeGestureInSide(_ viewController: UIViewController, direction: UISwipeGestureRecognizerDirection) {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(DualSlideMenuViewController.handleSwipes(_:)))
        swipe.direction = direction
        viewController.view.addGestureRecognizer(swipe)
    }
    /**
     called when the user makes a swipe
     
     - parameter sender: the sender
     */
    func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        // determines swipe direction from input and acts accordingly
        if (sender.direction == .left) {
            toggle("left")
        }
        else if (sender.direction == .right){
            toggle("right")
        }
        delegate?.onSwipe!()
    }
    
    /**
     Main toggle function that controls navigation of side menu
     
     - parameter swipeDirection: the direction of the swipe
     ex. "left" or "right" where swiping from left to right is a "right" swipe
     */
    open func toggle(_ swipeDirection: String) {
        // acts depending on the current state of the app
        switch currentState{
        case .main :
            //Swipe left to open right panel
            if (swipeDirection == "left") {
                if menuType == .right || amountOfMenus == 2 { moveToView(true, type: .right) }
                if amountOfMenus == 2 { swapPanels(.right) }
            }
                //Swipe right to open left panel
            else if (swipeDirection == "right") {
                if menuType == .left || amountOfMenus == 2 { moveToView(true, type: .left) }
                if amountOfMenus == 2 { swapPanels(.left) }
            }
            break
        case .left :
            //Swipe left to close left panel
            if (swipeDirection == "left") {
                moveToView(false, type: .left)
            } else {
                collapseAll()
            }
            break
        case .right :
            //Swipe right to close right panel
            if (swipeDirection == "right") {
                moveToView(false, type: .right)
            } else {
                collapseAll()
            }
            break
        }
    }
    
    /**
     This is an escape method that will animate to the main view no matter what view the app is currently in
     
     This method will not animate the transition, so the main view will appear in view instantly
     Up to developers to decide which to use for their use case
     
     - parameter completion handler because animations are run asynchronously
     */
    open func toMain(_ completion: ((Bool) -> Void)! = nil) {
        // the animation has a duration of 0, so nothing is actually be animated
        // everthing is instantaneous
        UIView.animate(withDuration: 0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.mainView.view.frame.origin.x = 0
            }, completion: completion)
        currentState = .main
    }
    
    
    /**
     Similar to toMain, except instantly animates to left menu
     */
    open func toLeft() {
        if (amountOfMenus == 2 || menuType == .left) {
            //Calculate the amount of distance the main view needs to move
            let displacement = mainView.view.frame.width - leftSideOffset
            animateInstantly(displacement)
            currentState = .left
        }
    }
    
    /**
     Similar to toMain, except instantly animates to right menu
     */
    open func toRight() {
        if (amountOfMenus == 2 || menuType == .right) {
            //Calculate the amount of distance the main view needs to move
            let displacement = rightSideOffset - mainView.view.frame.width
            animateInstantly(displacement)
            currentState = .right
        }
    }
    
    /**
     Will move to main view from either left or right menu.
     Pretty straight forward, this is a cleaner implementation of toMain and does include animations
     Up to developers to decide to fit their use case
     */
    open func collapseAll() {
        // conditional all ends in main view, just determines which animation to do so
        if currentState == .left {
            moveToView(false, type: .left)
        } else if currentState == .right {
            moveToView(false, type: .right)
        }
    }
    /**
     Swap side panels positions
     example places right panel behind left panel
     
     - parameter type: the panel that will be on top
     */
    fileprivate func swapPanels(_ type: State) {
        if (type == .right){
            leftMenu.view.removeFromSuperview()
            view.insertSubview(leftMenu.view, belowSubview: rightMenu.view)
        }
        else if (type == .left) {
            rightMenu.view.removeFromSuperview()
            view.insertSubview(rightMenu.view, belowSubview: leftMenu.view)
        }
    }
    
    /**
     Navigate to left or right panel
     
     - parameter open: to show the side view or to show the main view, true to show side view
     - parameter type: the type of view that is currently being displayed
     */
    fileprivate func moveToView(_ open: Bool, type: State){
        if (open) {
            var displacement: CGFloat = 0
            //Calculate the amount of distance the main view needs to move
            if (type == .left) {
                displacement = mainView.view.frame.width - leftSideOffset
            }
            else if (type == .right) {
                displacement = rightSideOffset - mainView.view.frame.width
            }
            moveMainViewBy(displacement) { _ in
                self.currentState = type
                self.delegate?.didChangeView!()
            }
        }
        else {
            //Move back to main view
            moveMainViewBy(0) { _ in
                self.currentState = .main
                self.delegate?.didChangeView!()
            }
            
        }
        
    }
    /**
     Controls the animation of sliding a view on or off where the main view
     is the view that is being moved in order to show the side views
     
     - parameter xDisplacement: The slide value and direction
     - parameter completion:   The completion handler for asynchronous calls
     */
    fileprivate func moveMainViewBy(_ xDisplacement: CGFloat, completion: ((Bool) -> Void)! = nil) {
        //Animate with a spring damping coefficient of 0.8
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.mainView.view.frame.origin.x = xDisplacement
            }, completion: completion)
    }
    
    fileprivate func animateInstantly(_ displacement: CGFloat) {
        UIView.animate(withDuration: 0, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.mainView.view.frame.origin.x = displacement
            }, completion: nil)
    }
}

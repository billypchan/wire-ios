//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

extension ConversationViewController {
    @objc
    func addParticipants(_ participants: Set<ZMUser>) {
        var newConversation: ZMConversation? = nil
        
        ZMUserSession.shared()?.enqueueChanges({
            newConversation = self.conversation.addParticipantsOrCreateConversation(participants)
        }, completionHandler: { [weak self] in
            if let newConversation = newConversation {
                self?.zClientViewController?.select(conversation: newConversation, focusOnView: true, animated: true)
            }
        })
    }
    
    @objc
    func createContentViewController() {
        contentViewController = ConversationContentViewController(conversation: conversation,
                                                                  message: visibleMessage,
                                                                  mediaPlaybackManager: zClientViewController?.mediaPlaybackManager,
                                                                  session: session)
        contentViewController.delegate = self
        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentViewController.bottomMargin = 16
        inputBarController.mentionsView = contentViewController.mentionsSearchResultsViewController
        contentViewController.mentionsSearchResultsViewController.delegate = inputBarController
    }
    
    @objc
    func createMediaBarViewController() {
        mediaBarViewController = MediaBarViewController(mediaPlaybackManager: ZClientViewController.shared?.mediaPlaybackManager)
        mediaBarViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapMediaBar(_:))))
    }

    @objc
    func didTapMediaBar(_ tapGestureRecognizer: UITapGestureRecognizer?) {
        if let mediaPlayingMessage = AppDelegate.shared.mediaPlaybackManager?.activeMediaPlayer?.sourceMessage,
            conversation == mediaPlayingMessage.conversation {
            contentViewController.scroll(to: mediaPlayingMessage, completion: nil)
        }
    }
    
    @objc
    func createInputBarController() {
        inputBarController = ConversationInputBarViewController(conversation: conversation)
        inputBarController.delegate = self
        inputBarController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Create an invisible input accessory view that will allow us to take advantage of built in keyboard
        // dragging and sizing of the scrollview
        invisibleInputAccessoryView = InvisibleInputAccessoryView()
        invisibleInputAccessoryView.delegate = self
        invisibleInputAccessoryView.isUserInteractionEnabled = false // make it not block touch events
        invisibleInputAccessoryView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        if !AutomationHelper.sharedHelper.disableInteractiveKeyboardDismissal {
            inputBarController.inputBar.invisibleInputAccessoryView = invisibleInputAccessoryView
        }
    }
}


extension ConversationViewController: InvisibleInputAccessoryViewDelegate {
    
    // WARNING: DO NOT TOUCH THIS UNLESS YOU KNOW WHAT YOU ARE DOING
    func invisibleInputAccessoryView(_ view: InvisibleInputAccessoryView, superviewFrameChanged frame: CGRect?) {
        // Adjust the input bar distance from bottom based on the invisibleAccessoryView
        var distanceFromBottom: CGFloat = 0
        
        // On iOS 8, the frame goes to zero when the accessory view is hidden
        if frame?.equalTo(.zero) == false {
            
            let convertedFrame = view.convert(view.superview?.frame ?? CGRect.zero, from: view.superview?.superview)
            
            // We have to use intrinsicContentSize here because the frame may not have actually been updated yet
            let newViewHeight = view.intrinsicContentSize.height
            
            distanceFromBottom = view.frame.size.height - convertedFrame.origin.y - newViewHeight
            distanceFromBottom = max(0, distanceFromBottom)
        }
        
        let closure: () -> () = {
            self.inputBarBottomMargin?.constant = -distanceFromBottom
            
            view.layoutIfNeeded()
        }
        
        if isAppearing {
            UIView.performWithoutAnimation(closure)
        } else {
            closure()
        }
        
    }
}
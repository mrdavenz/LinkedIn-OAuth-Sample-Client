//
//  LinkedInLoginDialog.h
//  PBProto
//
//  Created by Dave van Dugteren on 9/09/12.
//  Copyright (c) 2012 Alive. All rights reserved.
//

#import "LinkedInDialog.h"

@protocol LinkedInLoginDialogDelegate;

/**
 * Do not use this interface directly, instead, use authorize in Facebook.h
 *
 * Linkedin Login Dialog interface for start the linkedin webView login dialog.
 * It start pop-ups prompting for credentials and permissions.
 */

@interface LinkedInLoginDialog : LinkedInDialog {
  id<LinkedInLoginDialogDelegate> _loginDelegate;
}

- (id)initWithParams :(NSString*) params
             delegate:(id <LinkedInLoginDialogDelegate>) delegate;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@protocol LinkedInLoginDialogDelegate <NSObject>

- (void)liDialogLogin:(NSString*)token expirationDate:(NSDate*)expirationDate;

- (void)liDialogNotLogin:(BOOL)cancelled;

@end


//
//  ALMLinkedIn.h
//  PBProto
//
//  Created by Dave van Dugteren on 6/09/12.
//  www.alivemobile.com.au
//

#import <Foundation/Foundation.h>
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OATokenManager.h"  
#import "OAuthLoginView.h"
#import "LinkedInLoginDialog.h"

@protocol LinkedInSessionDelegate <NSObject>
/*
 * Called when the user successfully logged in.
 */
@optional
- (void) liDidLogin;

/*
 * Called when the user dismissed the dialog without logging in.
 */
- (void) liDidNotLogin:(BOOL)cancelled;

/**
 * Called after the access token was extended. If your application has any
 * references to the previous access token (for example, if your application
 * stores the previous access token in persistent storage), your application
 * should overwrite the old access token with the new one in this method.
 * See extendAccessToken for more details.
 */
- (void) liDidExtendToken: (NSString*)accessToken
                expiresAt: (NSDate*)expiresAt;

/**
 * Called when the user logged out.
 */
- (void) liDidLogout;

/**
 * Called when the current session has expired. This might happen when:
 *  - the access token expired
 *  - the app has been disabled
 *  - the user revoked the app's permissions
 *  - the user changed his or her password
 */

- (void) liSessionInvalidated;

@end

@interface LinkedIn : NSObject<LinkedInLoginDialogDelegate>{
  NSArray*  _permissions;
  NSDate*   _expirationDate;
  
  NSMutableSet* _requests;
  
  NSURL *requestURL;
}

@property(nonatomic, assign) id<LinkedInSessionDelegate> sessionDelegate;

@property (nonatomic, strong) OAConsumer *consumer;
@property (nonatomic, strong) OAToken *accessToken;
@property (nonatomic, copy) NSDate* expirationDate;
//@property (nonatomic, retain) OAuthLoginView *oAuthLoginView;
@property (nonatomic, retain) LinkedInLoginDialog *loginDialog;

- (id)initWithDelegate:(id<LinkedInSessionDelegate>)delegate;

//- (void)logout:(id<LinkedInSessionDelegate>)delegate;

- (BOOL)isSessionValid;

- (void)authorize:(NSString *)permissions;

- (void)requestWithGraphPath: (NSString *) graphPath
                   andParams: (NSArray *) params
               andHttpMethod: (NSString *) httpMethod
                 andDelegate: (id <NSObject>) delegate;


@end

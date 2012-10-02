//
//  LinkedInDialog.h
//  Peoplebank App
//
//  Created by Dave van Dugteren on 9/09/12.
//  Copyright (c) 2012 Alive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import "JSONKit.h"
#import "OAConsumer.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OATokenManager.h"

@protocol LinkedInDialogDelegate;

@interface LinkedInDialog : UIView<UIWebViewDelegate, UIScrollViewDelegate>{
  
  __unsafe_unretained id<LinkedInDialogDelegate> _delegate;
  //  NSString *_params; //Permissions //TODO: change var name
  
  NSString * _serverURL;
  NSURL* _loadingURL;
  UIWebView* _webView;
  UIActivityIndicatorView* _spinner;
  UIButton* _closeButton;
  UIInterfaceOrientation _orientation;
  BOOL _showingKeyboard;
  BOOL _isViewInvisible;
  
  UIView* _modalBackgroundView;
  
  IBOutlet UIActivityIndicatorView *activityIndicator;
  IBOutlet UITextField *addressBar;
  
  // Theses ivars could be made into a provider class
  // Then you could pass in different providers for Twitter, LinkedIn, etc
  NSString *apikey;
  NSString *secretkey;
  NSString *requestTokenURLString;
  NSURL *requestTokenURL;
  NSString *accessTokenURLString;
  NSURL *accessTokenURL;
  NSString *userLoginURLString;
  NSURL *userLoginURL;
  NSString *linkedInCallbackURL;
}

@property(nonatomic, retain) OAToken *requestToken;
@property(nonatomic, retain) OAToken *accessToken;
@property(nonatomic, retain) NSDictionary *profile;
@property(nonatomic, retain) OAConsumer *consumer;
- (void)initLinkedInApi;
- (void)requestTokenFromProvider;
- (void)allowUserToLogin;
- (void)accessTokenFromProvider;
//
@property(nonatomic,assign) id<LinkedInDialogDelegate> delegate;
@property(nonatomic, retain) NSString* params;

- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle;

- (void)show;

/**
 * Displays the first page of the dialog.
 *
 * Do not ever call this directly.  It is intended to be overriden by subclasses.
 */
- (void)load;

/**
 * Displays a URL in the dialog.
 */
- (void)loadURL:(NSString*)url
            get:(NSDictionary*)getParams;

/**
 * Hides the view and notifies delegates of success or cancellation.
 */
- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated;

/**
 * Hides the view and notifies delegates of an error.
 */
- (void)dismissWithError:(NSError*)error animated:(BOOL)animated;

/**
 * Subclasses may override to perform actions just prior to showing the dialog.
 */
- (void)dialogWillAppear;

/**
 * Subclasses may override to perform actions just after the dialog is hidden.
 */
- (void)dialogWillDisappear;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidSucceed:(NSURL *)url;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidCancel:(NSURL *)url;

@end

@protocol LinkedInDialogDelegate <NSObject>

@optional

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(LinkedInDialog *)dialog;

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url;

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url;

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogDidNotComplete:(LinkedInDialog *)dialog;

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(LinkedInDialog*)dialog didFailWithError:(NSError *)error;

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser,
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(LinkedInDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;

@end
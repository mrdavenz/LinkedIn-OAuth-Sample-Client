//
//  LinkedInLoginDialog.m
//  Peoplebank App
//
//  Created by Dave van Dugteren on 9/09/12.
//  Copyright (c) 2012 Alive. All rights reserved.
//

#import "LinkedInLoginDialog.h"

@implementation LinkedInLoginDialog

- (id)initWithParams :(NSString*) params
             delegate:(id <LinkedInLoginDialogDelegate>) delegate{
  
  self = [super init];
  self.params = params;
  _loginDelegate = delegate;
  
  [self initLinkedInApi];
  
  return self;
}

- (void) dialogDidSucceed:(NSURL*)url {
  NSString *q = [url absoluteString];
  NSString *token = [self getStringFromUrl:q needle:@"access_token="];
  NSString *expTime = [self getStringFromUrl:q needle:@"expires_in="];
  NSDate *expirationDate =nil;
  
  if (expTime != nil) {
    int expVal = [expTime intValue];
    if (expVal == 0) {
      expirationDate = [NSDate distantFuture];
    } else {
      expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
    }
  }
  
  if ((token == (NSString *) [NSNull null]) || (token.length == 0)) {
    [self dialogDidCancel:url];
    [self dismissWithSuccess:NO animated:YES];
  } else {
    if ([_loginDelegate respondsToSelector:@selector(fbDialogLogin:expirationDate:)]) {
//      [_loginDelegate fbDialogLogin:token expirationDate:expirationDate];
    }
    [self dismissWithSuccess:YES animated:YES];
  }
}

/**
 * Override FBDialog : to call with the login dialog get canceled
 */
- (void)dialogDidCancel:(NSURL *)url {
  [self dismissWithSuccess: NO
                  animated: YES];
  
  if ([_loginDelegate respondsToSelector:@selector(fbDialogNotLogin:)]) {
//    [_loginDelegate fbDialogNotLogin:YES];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  if (!(([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -999) ||
        ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
    [super webView:webView didFailLoadWithError:error];
    if ([_loginDelegate respondsToSelector:@selector(fbDialogNotLogin:)]) {
//      [_loginDelegate fbDialogNotLogin:NO];
    }
  }
}

@end

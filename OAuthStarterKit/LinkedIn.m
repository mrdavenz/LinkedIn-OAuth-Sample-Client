//
//  ALMLinkedIn.m
//  PBProto
//
//  Created by Dave van Dugteren on 6/09/12.
//  Copyright (c) 2012 Alive. All rights reserved.
//

#import "LinkedIn.h"

static NSString* kProviderBaseURL = @"http://api.linkedin.com/";
static NSString* kRedirectURL = @"hdlinked://linkedin/oauth";

static NSString* kAPIKey = kLinkedInApiKey;
static NSString* kAPISecretKey = kLinkedInApiSecret;

@interface LinkedIn ()

// private properties
@property(nonatomic, retain) NSArray* permissions;

@end

@implementation LinkedIn

@synthesize permissions = _permissions,
          expirationDate = _expirationDate;

- (void)requestWithGraphPath: (NSString *) graphPath
                   andParams: (NSArray *) params
               andHttpMethod: (NSString *) httpMethod
                 andDelegate: (id <NSObject>) delegate{
  
  NSString *stringGraphPath = @"v1/";
  NSString *fullURL = [kProviderBaseURL stringByAppendingString: [stringGraphPath stringByAppendingString: graphPath]];

  requestURL = [NSURL URLWithString: fullURL];

  if ([self isSessionValid]) {
    [self apiCall];
  }
  else{
    NSString *paramsString = [[NSMutableString alloc] init];
    
    for (NSString *param in params)
      paramsString = [paramsString stringByAppendingFormat: @" %@", param];
    
    NSRange range = NSMakeRange(0, 1);
    
    [paramsString stringByReplacingCharactersInRange: range
                                          withString: @""]; //Remove leading space.
    
    NSLog(@"Requesting Linkedin Permissions: %@", paramsString);
    
    [self authorize: paramsString]; //@"r_fullprofile r_contactinfo r_emailaddress"
  }
}

- (void)authorize:(NSString *)permissions{
  NSLog(@"authorize: %@", permissions);
  
  self.loginDialog = [[LinkedInLoginDialog alloc] initWithParams: permissions
                                                        delegate: self];

  // register to be told when the login is finished
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(loginViewDidFinish:)
                                               name: @"loginViewDidFinish"
                                             object: self.loginDialog];
  
  [self.loginDialog show];
  //[self presentModalViewController:self. oAuthLoginView animated:YES];
}

-(void) loginViewDidFinish:(NSNotification*)notification
{
  self.accessToken = self.loginDialog.accessToken;
  
  [self saveAccessTokenDetails];
  
	[[NSNotificationCenter defaultCenter] removeObserver:self];

  [self apiCall];
}

- (void) saveAccessTokenDetails{
  NSMutableDictionary *accessTokenParamsDict = [NSMutableDictionary dictionary];
  if (self.accessToken.key)       [accessTokenParamsDict setObject: self.accessToken.key forKey: @"key"];
  if (self.accessToken.secret)    [accessTokenParamsDict setObject: self.accessToken.secret forKey: @"secret"];
  if (self.accessToken.session)   [accessTokenParamsDict setObject: self.accessToken.session forKey: @"session"];
  if (self.accessToken.verifier)  [accessTokenParamsDict setObject: self.accessToken.verifier forKey: @"verifier"];
  if (self.accessToken.duration)  [accessTokenParamsDict setObject: self.accessToken.duration forKey: @"duration"];
  if (self.accessToken.attributes)[accessTokenParamsDict setObject: self.accessToken.attributes forKey: @"attributes"];
  
  [accessTokenParamsDict setObject: [NSDate date]
                            forKey: @"date"];  // date created
  
  [accessTokenParamsDict setObject: [NSNumber numberWithBool: self.accessToken.forRenewal]
                            forKey: @"forRenewal"];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  if ([defaults objectForKey: @"kAccessToken"])
    [defaults removeObjectForKey: @"kAccessToken"];
  
  NSMutableDictionary *consumerDict = [[NSMutableDictionary alloc] init];
  if (self.loginDialog.consumer.key) [consumerDict setObject: self.loginDialog.consumer.key
                                                  forKey: @"key"];
  
  if (self.loginDialog.consumer.secret) [consumerDict setObject: self.loginDialog.consumer.secret
                                                  forKey: @"secret"];
  
  if (self.loginDialog.consumer.realm) [consumerDict setObject: self.loginDialog.consumer.realm
                                                  forKey: @"realm"];
  
  [defaults setObject: accessTokenParamsDict
               forKey: @"kAccessToken"];
  
  [defaults setObject: consumerDict
               forKey: @"kConsumer"];
}

- (void) apiCall{
  //If cached AccessToken, no need to use the loginDialog recieved settings, get it locally.
  if (self.consumer != nil) {
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL: requestURL
                                    consumer: self.consumer
                                       token: self.accessToken
                                    callback: nil
                           signatureProvider: nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest: request
                         delegate: self.sessionDelegate
                didFinishSelector: @selector(profileApiCallResult:didFinish:)
                  didFailSelector: @selector(profileApiCallResult:didFail:)];
  }
  else{
    OAMutableURLRequest *request =
    [[OAMutableURLRequest alloc] initWithURL: requestURL
                                    consumer: self.loginDialog.consumer
                                       token: self.loginDialog.accessToken
                                    callback: nil
                           signatureProvider: nil];
    
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    [fetcher fetchDataWithRequest: request
                         delegate: self.sessionDelegate
                didFinishSelector: @selector(profileApiCallResult:didFinish:)
                  didFailSelector: @selector(profileApiCallResult:didFail:)];
  }
}

- (id)initWithDelegate:(id<LinkedInSessionDelegate>)delegate{
  self = [super init];
  if (self) {
    _requests = [[NSMutableSet alloc] init];
    self.sessionDelegate = delegate;
  }
  
  return self;
}

/*
  If the access token cannot be verified, show the dialogue box.
 */
- (BOOL)isSessionValid
{
//  return (self.accessToken != nil && self.expirationDate != nil
//          && NSOrderedDescending == [self.expirationDate compare:[NSDate date]]);

  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSMutableDictionary *dictForToken = [userDefaults objectForKey: @"kAccessToken"];
  NSMutableDictionary *dictForConsumer = [userDefaults objectForKey: @"kConsumer"];
  
  if (self.accessToken == nil) {
    if (dictForToken) {
      
      NSNumber *isRenewable = [dictForToken objectForKey:@"forRenewal"];

      self.accessToken = [[OAToken alloc] initWithKey: [dictForToken objectForKey:@"key"]
                                               secret: [dictForToken objectForKey:@"secret"]
                                              session: [dictForToken objectForKey:@"session"]
                                             verifier: [dictForToken objectForKey:@"verifier"]
                                             duration: [dictForToken objectForKey:@"duration"]
                                           attributes: [dictForToken objectForKey:@"attributes"]
                                              created: [dictForToken objectForKey:@"date"]
                                            renewable: isRenewable.boolValue];

      self.consumer = [[OAConsumer alloc] initWithKey: [dictForConsumer objectForKey: @"key"]
                                               secret: [dictForConsumer objectForKey: @"secret"]
                                                realm: [dictForConsumer objectForKey: @"realm"]];
    }
  }
  
  //TODO: Add check for access token being invalid for some reason...
  return (self.accessToken != nil);
}

#pragma mark -
#pragma mark LinkedInLoginDialogDelegate

- (void)liDialogLogin:(NSString*)token expirationDate:(NSDate*)expirationDate{
  NSLog(@"liDialogLogin");
}

- (void)liDialogNotLogin:(BOOL)cancelled{
  NSLog(@"liDialogNotLogin");
}

@end

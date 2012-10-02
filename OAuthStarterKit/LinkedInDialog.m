/*
* 
* LinkedInDialog.m
* PBProto
*
* Created by Dave van Dugteren on 9/09/12.
* Code based off the FBConnect API
* 
* Copyright (c) 2012 Alive. All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0

* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#import "LinkedInDialog.h"
#import "JSON.h"

#define API_KEY_LENGTH 12
#define SECRET_KEY_LENGTH 16

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static CGFloat kBorderGray[4] = {0.3, 0.3, 0.3, 0.8};
static CGFloat kBorderBlack[4] = {0.3, 0.3, 0.3, 1};

static CGFloat kTransitionDuration = 0.3;

static CGFloat kPadding = 0;
static CGFloat kBorderWidth = 20;

///////////////////////////////////////////////////////////////////////////////////////////////////

static BOOL LIIsDeviceIPad() {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  }
#endif
  return NO;
}

@implementation LinkedInDialog

@synthesize delegate = _delegate,
            params   = _params;

- (void)addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect radius:(float)radius {
  CGContextBeginPath(context);
  CGContextSaveGState(context);
  
  if (radius == 0) {
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextAddRect(context, rect);
  } else {
    rect = CGRectOffset(CGRectInset(rect, 0.5, 0.5), 0.5, 0.5);
    CGContextTranslateCTM(context, CGRectGetMinX(rect)-0.5, CGRectGetMinY(rect)-0.5);
    CGContextScaleCTM(context, radius, radius);
    float fw = CGRectGetWidth(rect) / radius;
    float fh = CGRectGetHeight(rect) / radius;
    
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
  }
  
  CGContextClosePath(context);
  CGContextRestoreGState(context);
}


- (void)drawRect:(CGRect)rect fill:(const CGFloat*)fillColors radius:(CGFloat)radius {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  
  if (fillColors) {
    CGContextSaveGState(context);
    CGContextSetFillColor(context, fillColors);
    if (radius) {
      [self addRoundedRectToPath:context rect:rect radius:radius];
      CGContextFillPath(context);
    } else {
      CGContextFillRect(context, rect);
    }
    CGContextRestoreGState(context);
  }
  
  CGColorSpaceRelease(space);
}

- (void)strokeLines:(CGRect)rect stroke:(const CGFloat*)strokeColor {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  
  CGContextSaveGState(context);
  CGContextSetStrokeColorSpace(context, space);
  CGContextSetStrokeColor(context, strokeColor);
  CGContextSetLineWidth(context, 1.0);
  
  {
    CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y-0.5},
      {rect.origin.x+rect.size.width, rect.origin.y-0.5}};
    CGContextStrokeLineSegments(context, points, 2);
  }
  {
    CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y+rect.size.height-0.5},
      {rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height-0.5}};
    CGContextStrokeLineSegments(context, points, 2);
  }
  {
    CGPoint points[] = {{rect.origin.x+rect.size.width-0.5, rect.origin.y},
      {rect.origin.x+rect.size.width-0.5, rect.origin.y+rect.size.height}};
    CGContextStrokeLineSegments(context, points, 2);
  }
  {
    CGPoint points[] = {{rect.origin.x+0.5, rect.origin.y},
      {rect.origin.x+0.5, rect.origin.y+rect.size.height}};
    CGContextStrokeLineSegments(context, points, 2);
  }
  
  CGContextRestoreGState(context);
  
  CGColorSpaceRelease(space);
}


- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation {
  if (orientation == _orientation) {
    return NO;
  } else {
    return orientation == UIInterfaceOrientationPortrait
    || orientation == UIInterfaceOrientationPortraitUpsideDown
    || orientation == UIInterfaceOrientationLandscapeLeft
    || orientation == UIInterfaceOrientationLandscapeRight;
  }
}

- (CGAffineTransform)transformForOrientation {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (orientation == UIInterfaceOrientationLandscapeLeft) {
    return CGAffineTransformMakeRotation(M_PI*1.5);
  } else if (orientation == UIInterfaceOrientationLandscapeRight) {
    return CGAffineTransformMakeRotation(M_PI/2);
  } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
    return CGAffineTransformMakeRotation(-M_PI);
  } else {
    return CGAffineTransformIdentity;
  }
}

- (void)sizeToFitOrientation:(BOOL)transform {
  if (transform) {
    self.transform = CGAffineTransformIdentity;
  }
  
  CGRect frame = [UIScreen mainScreen].applicationFrame;
  CGPoint center = CGPointMake(
                               frame.origin.x + ceil(frame.size.width/2),
                               frame.origin.y + ceil(frame.size.height/2));
  
  CGFloat scale_factor = 1.0f;
  if (LIIsDeviceIPad()) {
    // On the iPad the dialog's dimensions should only be 60% of the screen's
    scale_factor = 0.6f;
  }
  
  CGFloat width = floor(scale_factor * frame.size.width) - kPadding * 2;
  CGFloat height = floor(scale_factor * frame.size.height) - kPadding * 2;
  
  _orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(_orientation)) {
    self.frame = CGRectMake(kPadding, kPadding, height, width);
  } else {
    self.frame = CGRectMake(kPadding, kPadding, width, height);
  }
  self.center = center;
  
  if (transform) {
    self.transform = [self transformForOrientation];
  }
}

- (void)updateWebOrientation {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    [_webView stringByEvaluatingJavaScriptFromString:
     @"document.body.setAttribute('orientation', 90);"];
  } else {
    [_webView stringByEvaluatingJavaScriptFromString:
     @"document.body.removeAttribute('orientation');"];
  }
}

- (void)bounce1AnimationStopped {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:kTransitionDuration/2];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
  self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
  [UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:kTransitionDuration/2];
  self.transform = [self transformForOrientation];
  [UIView commitAnimations];
}


- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
  if (params) {
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in params.keyEnumerator) {
      NSString* value = [params objectForKey:key];
      NSString* escaped_value = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                    NULL, /* allocator */
                                                                                    (__bridge CFStringRef)value,
                                                                                    NULL, /* charactersToLeaveUnescaped */
                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                    kCFStringEncodingUTF8);
      
      [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    
    NSString* query = [pairs componentsJoinedByString:@"&"];
    NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
    return [NSURL URLWithString:url];
  } else {
    return [NSURL URLWithString:baseURL];
  }
}

- (void)addObservers {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(deviceOrientationDidChange:)
                                               name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification"
                                             object:nil];
}

- (void)removeObservers {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"UIKeyboardWillShowNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)postDismissCleanup {
  [self removeObservers];
  [self removeFromSuperview];
  [_modalBackgroundView removeFromSuperview];
}

- (void)dismiss:(BOOL)animated {
  [self dialogWillDisappear];
  
  // If the dialog has been closed, then we need to cancel the order to open it.
  // This happens in the case of a frictionless request, see webViewDidFinishLoad for details
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(showWebView)
                                             object:nil];
  
  _loadingURL = nil;
  
  if (animated) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
    self.alpha = 0;
    [UIView commitAnimations];
  } else {
    [self postDismissCleanup];
  }
}

- (void)cancel {
  [self dialogDidCancel:nil];
}

- (id)init {
  if ((self = [super initWithFrame:CGRectZero])) {
    _delegate = nil;
    _loadingURL = nil;
    _showingKeyboard = NO;
    
    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentMode = UIViewContentModeRedraw;
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(kPadding, kPadding, 480, 480)];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_webView];
    
    UIImage* closeImage = [UIImage imageNamed:@"FBDialog.bundle/images/close.png"];
    
    UIColor* color = [UIColor colorWithRed:167.0/255 green:184.0/255 blue:216.0/255 alpha:1];
    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setImage:closeImage forState:UIControlStateNormal];
    [_closeButton setTitleColor:color forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_closeButton addTarget:self action:@selector(cancel)
           forControlEvents:UIControlEventTouchUpInside];
    
    // To be compatible with OS 2.x
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_2_2
    _closeButton.font = [UIFont boldSystemFontOfSize:12];
#else
    _closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
#endif
    
    _closeButton.showsTouchWhenHighlighted = YES;
    _closeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin
    | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:_closeButton];
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                UIActivityIndicatorViewStyleWhiteLarge];
    if ([_spinner respondsToSelector:@selector(setColor:)]) {
      [_spinner setColor:[UIColor grayColor]];
    } else {
      [_spinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    }
    _spinner.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
    | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:_spinner];
    _modalBackgroundView = [[UIView alloc] init];
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  [self drawRect:rect fill:kBorderGray radius:0];
  
  CGRect webRect = CGRectMake(
                              ceil(rect.origin.x + kBorderWidth), ceil(rect.origin.y + kBorderWidth)+1,
                              rect.size.width - kBorderWidth*2, _webView.frame.size.height+1);
  
  [self strokeLines:webRect stroke:kBorderBlack];
}

- (void)showWebView {
  UIWindow* window = [UIApplication sharedApplication].keyWindow;
  if (!window) {
    window = [[UIApplication sharedApplication].windows objectAtIndex:0];
  }
  _modalBackgroundView.frame = window.frame;
  [_modalBackgroundView addSubview:self];
  [window addSubview:_modalBackgroundView];
  
  self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:kTransitionDuration/1.5];
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
  self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
  [UIView commitAnimations];
  
  [self dialogWillAppear];
  [self addObservers];
}

// Show a spinner during the loading time for the dialog. This is designed to show
// on top of the webview but before the contents have loaded.
- (void)showSpinner {
  [_spinner sizeToFit];
  [_spinner startAnimating];
  _spinner.center = _webView.center;
}

- (void)hideSpinner {
  [_spinner stopAnimating];
  _spinner.hidden = YES;
}

- (void)deviceOrientationDidChange:(void*)object {
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (!_showingKeyboard && [self shouldRotateToOrientation:orientation]) {
    [self updateWebOrientation];
    
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    [self sizeToFitOrientation:YES];
    [UIView commitAnimations];
  }
}

- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle {
  NSString * str = nil;
  NSRange start = [url rangeOfString:needle];
  if (start.location != NSNotFound) {
    // confirm that the parameter is not a partial name match
    unichar c = '?';
    if (start.location != 0) {
      c = [url characterAtIndex:start.location - 1];
    }
    if (c == '?' || c == '&' || c == '#') {
      NSRange end = [[url substringFromIndex:start.location+start.length] rangeOfString:@"&"];
      NSUInteger offset = start.location+start.length;
      str = end.location == NSNotFound ?
      [url substringFromIndex:offset] :
      [url substringWithRange:NSMakeRange(offset, end.location)];
      str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
  }
  return str;
}

- (id)initWithURL: (NSString *) serverURL
           params: (NSString *) params
  isViewInvisible: (BOOL)isViewInvisible
         delegate: (id <LinkedInDialogDelegate>) delegate {
  
  self = [self init];
  _serverURL = serverURL;
  _params = params;
  _delegate = delegate;
  _isViewInvisible = isViewInvisible;
  
  return self;
}

- (void)load {
  [self loadURL: _serverURL
            get: _params];
}

- (void)loadURL:(NSString*)url get:(NSDictionary*)getParams
{
  _loadingURL = [self generateURL:url params:getParams];
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_loadingURL];
  
  [_webView loadRequest:request];
}


- (void)show {
  //  [self load];
  [self sizeToFitOrientation: YES];
  
  //CGFloat innerWidth = self.frame.size.width - (kBorderWidth+1)*2;
  CGFloat innerWidth = self.frame.size.width - (kBorderWidth * 2);
  [_closeButton sizeToFit];
  
  _closeButton.frame = CGRectMake(2, 2, 29, 29);
  
  [self addSubview: _closeButton];
  
  _webView.frame = CGRectMake(
                              kBorderWidth,
                              kBorderWidth,
                              innerWidth,
                              self.frame.size.height - (kBorderWidth * 2));
  
  [_webView setContentStretch: _webView.frame];
  
  
  if ([apikey length] < API_KEY_LENGTH || [secretkey length] < SECRET_KEY_LENGTH)
  {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @"OAuth Starter Kit"
                          message: @"You must add your apikey and secretkey.  See the project file readme.txt"
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    
    // Notify parent and close this view
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"loginViewDidFinish"
     object:self];
    
    [self.delegate dialog: self didFailWithError: nil];
  }
  
  if (!_isViewInvisible) {
    [self showSpinner];
    [self showWebView];
  }
  
  [self requestTokenFromProvider];
}


- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated {
  if (success) {
    if ([_delegate respondsToSelector:@selector(dialogDidComplete:)]) {
      [_delegate dialogDidComplete:self];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(dialogDidNotComplete:)]) {
      [_delegate dialogDidNotComplete:self];
    }
  }
  
  [self dismiss:animated];
}

- (void)dismissWithError:(NSError*)error animated:(BOOL)animated {
  if ([_delegate respondsToSelector:@selector(dialog:didFailWithError:)]) {
    [_delegate dialog:self didFailWithError:error];
  }
  
  [self dismiss:animated];
}

- (void)dialogWillAppear {
}

- (void)dialogWillDisappear {
}

- (void)dialogDidSucceed:(NSURL *)url {
  
  if ([_delegate respondsToSelector:@selector(dialogCompleteWithUrl:)]) {
    [_delegate dialogCompleteWithUrl:url];
  }
  [self dismissWithSuccess:YES animated:YES];
}

- (void)dialogDidCancel:(NSURL *)url {
  if ([_delegate respondsToSelector:@selector(dialogDidNotCompleteWithUrl:)]) {
    [_delegate dialogDidNotCompleteWithUrl:url];
  }
  [self dismissWithSuccess:NO animated:YES];
}

// New methods

//
// OAuth step 1a:
//
// The first step in the the OAuth process to make a request for a "request token".
// Yes it's confusing that the work request is mentioned twice like that, but it is whats happening.
//
- (void)requestTokenFromProvider
{
  OAMutableURLRequest *request =  [[OAMutableURLRequest alloc] initWithURL: requestTokenURL
                                                                  consumer: self.consumer
                                                                     token: nil
                                                                  callback: linkedInCallbackURL
                                                         signatureProvider: nil] ;
  
  [request setHTTPMethod:@"POST"];
  
  OARequestParameter * scopeParameter=[OARequestParameter requestParameter:@"scope" value:@"r_fullprofile r_contactinfo r_emailaddress"];
  
  [request setParameters:[NSArray arrayWithObject:scopeParameter]];
  
  OADataFetcher *fetcher = [[OADataFetcher alloc] init];
  
  [fetcher fetchDataWithRequest:request
                       delegate:self
              didFinishSelector:@selector(requestTokenResult:didFinish:)
                didFailSelector:@selector(requestTokenResult:didFail:)];
}

- (void)requestTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
  if (ticket.didSucceed == NO)
    return;
  
  NSLog(@"Step 2: requestTokenResult");
  
  NSString *responseBody = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
  
  NSLog(@"responseBody: %@", responseBody);
  
  self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];

  [self allowUserToLogin];
}

- (void)requestTokenResult:(OAServiceTicket *)ticket didFail:(NSData *)error
{
  NSLog(@"%@",[error description]);
}

//
// OAuth step 2:
//
// Show the user a browser displaying the LinkedIn login page.
// They type username/password and this is how they permit us to access their data
// We use a UIWebView for this.
//
// Sending the token information is required, but in this one case OAuth requires us
// to send URL query parameters instead of putting the token in the HTTP Authorization
// header as we do in all other cases.
//
- (void)allowUserToLogin
{
  NSString *userLoginURLWithToken = [NSString stringWithFormat:@"%@?oauth_token=%@",
                                     userLoginURLString, self.requestToken.key];
  
  userLoginURL = [NSURL URLWithString:userLoginURLWithToken];
  
  NSLog(@"Firing off URL: %@", userLoginURL.absoluteString);
  
  NSURLRequest *request = [NSMutableURLRequest requestWithURL: userLoginURL];
  
  NSError *error;
//  
//  [_webView setAutoresizesSubviews: YES];
//  [_webView setClearsContextBeforeDrawing: YES];
//  [_webView setOpaque: YES];
//  [_webView setScalesPageToFit: YES];
//  [_webView setContentMode: UIViewContentModeScaleToFill];
  
  NSString *string = [NSString stringWithContentsOfURL: userLoginURL
                                              encoding: NSStringEncodingConversionAllowLossy
                                                 error: &error];
  
  [_webView loadHTMLString: string
                   baseURL:userLoginURL];
  //[_webView loadRequest:request];
}


//
// OAuth step 3:
//
// This method is called when our webView browser loads a URL, this happens 3 times:
//
//      a) Our own [webView loadRequest] message sends the user to the LinkedIn login page.
//
//      b) The user types in their username/password and presses 'OK', this will submit
//         their credentials to LinkedIn
//
//      c) LinkedIn responds to the submit request by redirecting the browser to our callback URL
//         If the user approves they also add two parameters to the callback URL: oauth_token and oauth_verifier.
//         If the user does not allow access the parameter user_refused is returned.
//
//      Example URLs for these three load events:
//          a) https://www.linkedin.com/uas/oauth/authorize?oauth_token=<token value>
//
//          b) https://www.linkedin.com/uas/oauth/authorize/submit   OR
//             https://www.linkedin.com/uas/oauth/authenticate?oauth_token=<token value>&trk=uas-continue
//
//          c) hdlinked://linkedin/oauth?oauth_token=<token value>&oauth_verifier=63600     OR
//             hdlinked://linkedin/oauth?user_refused
//
//
//  We only need to handle case (c) to extract the oauth_verifier value
//
//- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
//{
//	NSURL *url = request.URL;
//	NSString *urlString = url.absoluteString;
//  
//  addressBar.text = urlString;
//  [activityIndicator startAnimating];
//  
//  BOOL requestForCallbackURL = ([urlString rangeOfString:linkedInCallbackURL].location != NSNotFound);
//  if ( requestForCallbackURL )
//  {
//    BOOL userAllowedAccess = ([urlString rangeOfString:@"user_refused"].location == NSNotFound);
//    if ( userAllowedAccess )
//    {
//      [self.requestToken setVerifierWithUrl:url];
//      [self accessTokenFromProvider];
//    }
//    else
//    {
//      // User refused to allow our app access
//      // Notify parent and close this view
//      [[NSNotificationCenter defaultCenter]
//       postNotificationName:@"loginViewDidFinish"
//       object:self
//       userInfo:nil];
//      
//      //      [self dismissModalViewControllerAnimated:YES];
//    }
//  }
//  else
//  {
//    // Case (a) or (b), so ignore it
//  }
//	return YES;
//}

//
// OAuth step 4:
//
- (void)accessTokenFromProvider
{
  NSLog(@"accessTokenFromProvider");
  
  OAMutableURLRequest *request =
  [[OAMutableURLRequest alloc] initWithURL:accessTokenURL
                                   consumer:self.consumer
                                      token:self.requestToken
                                   callback:nil
                          signatureProvider:nil];
  
  [request setHTTPMethod:@"POST"];
  
  OADataFetcher *fetcher = [[OADataFetcher alloc] init];
  
  OARequestParameter * scopeParameter=[OARequestParameter requestParameter:@"scope" value:@"r_fullprofile r_contactinfo r_emailaddress"];
  
  [request setParameters:[NSArray arrayWithObject:scopeParameter]];
  
  [fetcher fetchDataWithRequest:request
                       delegate:self
              didFinishSelector:@selector(accessTokenResult:didFinish:)
                didFailSelector:@selector(accessTokenResult:didFail:)];
}

- (void)accessTokenResult:(OAServiceTicket *)ticket didFinish:(NSData *)data
{
  NSString *responseBody = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];

  BOOL problem = ([responseBody rangeOfString:@"oauth_problem"].location != NSNotFound);

  if ( problem )
  {
    NSLog(@"Request access token failed.");
    NSLog(@"%@",responseBody);
  }
  else
  {
    self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
  }
  // Notify parent and close this view
  [[NSNotificationCenter defaultCenter]
   postNotificationName:@"loginViewDidFinish"
   object:self];
}

//
//  This api consumer data could move to a provider object
//  to allow easy switching between LinkedIn, Twitter, etc.
//
- (void)initLinkedInApi
{
  apikey = kLinkedInApiKey;
  secretkey = kLinkedInApiSecret;
  
  self.consumer = [[OAConsumer alloc] initWithKey: apikey
                                           secret: secretkey
                                            realm: @"http://api.linkedin.com/"];
  
  requestTokenURLString = @"https://api.linkedin.com/uas/oauth/requestToken";
  accessTokenURLString  = @"https://api.linkedin.com/uas/oauth/accessToken";
  userLoginURLString    = @"https://www.linkedin.com/uas/oauth/authorize";
  linkedInCallbackURL   = @"hdlinked://linkedin/oauth";
  
  requestTokenURL = [NSURL URLWithString:requestTokenURLString];
  accessTokenURL  = [NSURL URLWithString:accessTokenURLString];
  userLoginURL    = [NSURL URLWithString:userLoginURLString];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
  
  NSLog(@"Step 3::webView");
  
  NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
  
  addressBar.text = urlString;
  [activityIndicator startAnimating];
  
  BOOL requestForCallbackURL = ([urlString rangeOfString:linkedInCallbackURL].location != NSNotFound);
  if ( requestForCallbackURL )
  {
    NSLog(@"url contains callback: hdlinked");
    
    BOOL userAllowedAccess = ([urlString rangeOfString:@"user_refused"].location == NSNotFound);
    if ( userAllowedAccess )
    {
      [self.requestToken setVerifierWithUrl:url];
      [self accessTokenFromProvider];
    }
    else
    {
      // User refused to allow our app access
      // Notify parent and close this view
      [[NSNotificationCenter defaultCenter]
       postNotificationName:@"loginViewDidFinish"
       object:self
       userInfo:nil];
    }
    //return NO;

  }
  else
  {
    // Case (a) or (b), so ignore it
    
     }
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  
  NSLog(@"webViewDidFinishLoad");
  
  if (_isViewInvisible) {
    // if our cache asks us to hide the view, then we do, but
    // in case of a stale cache, we will display the view in a moment
    // note that showing the view now would cause a visible white
    // flash in the common case where the cache is up to date
    [self performSelector:@selector(showWebView) withObject:nil afterDelay:.05];
  } else {
    [self hideSpinner];
  }
  [self updateWebOrientation];
  
  [self zoomToFit];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  // 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
  // -999 == "Operation could not be completed", note -999 occurs when the user clicks away before
  // the page has completely loaded, if we find cases where we want this to result in dialog failure
  // (usually this just means quick-user), then we should add something more robust here to account
  // for differences in application needs
  NSLog(@"didFailLoadWithError: %@", error.debugDescription);
  if (!(([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -999) ||
        ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102))) {
    [self dismissWithError:error animated:YES];
  }
}

#pragma mark -
#pragma mark UIKeyboardNotifications

- (void)keyboardWillShow:(NSNotification*)notification {
  
  _showingKeyboard = YES;
  
  if (LIIsDeviceIPad()) {
    // On the iPad the screen is large enough that we don't need to
    // resize the dialog to accomodate the keyboard popping up
    return;
  }
  
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    _webView.frame = CGRectInset(_webView.frame,
                                 -(kPadding + kBorderWidth),
                                 -(kPadding + kBorderWidth));
  }
  
  [_webView.scrollView scrollRectToVisible: CGRectMake(0, _webView.frame.size.height, 280, 1) animated:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification {
  _showingKeyboard = NO;
  
  if (LIIsDeviceIPad()){
    return;
  }
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if (UIInterfaceOrientationIsLandscape(orientation)) {
    _webView.frame = CGRectInset(_webView.frame,
                                 kPadding + kBorderWidth,
                                 kPadding + kBorderWidth);
  }
}


-(void)zoomToFit
{
  //[self runJS];

  [self resize];
  
  //<meta name="viewport" content="width=device-width; minimum-scale=1.0; maximum-scale=1.0; user-scalable=no">
}

- (void)resize{
  CGSize contentSize = _webView.scrollView.contentSize;
  CGSize viewSize = self.bounds.size;
  
  float rw = 280 / contentSize.width;
  
  _webView.scrollView.minimumZoomScale = rw;
  //_webView.scrollView.maximumZoomScale = rw;
  _webView.scrollView.zoomScale = rw;
  
  [_webView setScalesPageToFit: YES];
  
  _webView.scrollView.delegate = self;
}

- (void) runJS{
  NSLog(@"load js");
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"resizeweb" ofType:@"js"];
  NSError *error = nil;
  NSString *jsCode = [NSString stringWithContentsOfFile: path
                                               encoding: NSUTF8StringEncoding
                                                  error: &error];
  if (error) {
    NSLog(@"error: %@", error.debugDescription);
  }
  [_webView stringByEvaluatingJavaScriptFromString:jsCode];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
  NSLog(@"scrollViewDidZoom");
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
  return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view{
  [self resize];
}

@end

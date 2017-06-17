#define prefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(),@"se.nosskirneh.properlockgestures.plist"]

static BOOL homescreenEnabled;
static BOOL LSandNCEnabled;
static BOOL notificationsEnabled;
static BOOL passcodeEnabled;

static void reloadPrefs() {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefPath]];
    homescreenEnabled = [[defaults objectForKey:@"Homescreen"] boolValue];
    LSandNCEnabled = [[defaults objectForKey:@"Lockscreen"] boolValue];
    notificationsEnabled = [[defaults objectForKey:@"Notifications"] boolValue];
    passcodeEnabled = [[defaults objectForKey:@"Passcode"] boolValue];
}

void updateSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo) {
    reloadPrefs();
}

%ctor {
    reloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &updateSettings, CFStringRef(@"se.nosskirneh.properlockgestures/preferencesChanged"), NULL, 0);
}



@interface SpringBoard : NSObject
- (void)_simulateLockButtonPress;
@end


static void handleTouches(NSSet *touches) {
    NSUInteger numTaps = [[touches anyObject] tapCount];
    if (numTaps == 2) {
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

// LS/NC Normal
@interface SBPagedScrollView : UIScrollView
@end

%hook SBPagedScrollView

- (void)_layoutPages {
    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGesture];
    [tapGesture release];

    %orig;
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized) {
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS Clock & Date
@interface SBLockScreenDateViewController : UIViewController
@end

%hook SBLockScreenDateViewController

- (void)viewDidLoad {
    %orig;

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized) {
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS notifications
@interface NCNotificationPriorityListViewController : UIViewController
@end

%hook NCNotificationPriorityListViewController

- (void)viewDidLoad {
    %orig;

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (notificationsEnabled && sender.state == UIGestureRecognizerStateRecognized) {
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS media controls
@interface SBDashBoardMediaControlsView : UIView
@end

%hook SBDashBoardMediaControlsView

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (LSandNCEnabled) {
        handleTouches(touches);
    }
}

%end

// LS Artwork
// Add directly to artworkView doesn't work. Instead, create a new view and add that to artwork
@interface SBDashBoardMediaArtworkViewController : UIViewController
- (void)addGestureView;
@end

@interface MPUNowPlayingArtworkView : UIView
@end

static MPUNowPlayingArtworkView *LSArtworkView;
static UIView *gestureView;
static SBDashBoardMediaArtworkViewController *artworkViewController;

%hook MPUNowPlayingArtworkView

- (id)initWithFrame:(CGRect)frame {
    // We only want the first that gets initalized (LS)
    return LSArtworkView ? %orig : LSArtworkView = %orig;
}

- (void)setFrame:(CGRect)frame {
    %orig;

    if (self == LSArtworkView && !gestureView) {
        // If this would've gone directly to artworkViewController's viewDidLoad, 
        // LSArtworkView's frame is 0, 0, 0, 0 by that time.
        [artworkViewController addGestureView];
    }
}

%end

%hook SBDashBoardMediaArtworkViewController

- (id)init {
    return artworkViewController = %orig;
}

%new
- (void)addGestureView {
    gestureView = [[UIView alloc] initWithFrame:LSArtworkView.frame];
    [gestureView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.01]];

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [gestureView addGestureRecognizer:tapGesture];
    [tapGesture release];

    [self.view addSubview:gestureView];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized) {
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}

%end

// LS Passcode screen
%hook SBUIPasscodeLockViewWithKeypad

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (passcodeEnabled) {
        handleTouches(touches);
    }
}

%end

%hook SBEmptyButtonView

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (passcodeEnabled) {
        handleTouches(touches);
    }
}

%end

@interface SBDashBoardChargingViewController : UIViewController
@end

// LS Charging view
%hook SBDashBoardChargingViewController

- (void)loadView {
    %orig;

    UIView *gestureView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [gestureView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.01]];

    // Add double tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [gestureView addGestureRecognizer:tapGesture];
    [tapGesture release];

    [self.view addSubview:gestureView];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized) {
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
    }
}
%end

// Home screen
%hook SBIconListView

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (homescreenEnabled) {
        handleTouches(touches);
    }
}

%end

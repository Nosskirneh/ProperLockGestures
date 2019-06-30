#define prefPath [NSString stringWithFormat:@"%@/Library/Preferences/%@", NSHomeDirectory(), @"se.nosskirneh.properlockgestures.plist"]

static BOOL homescreenEnabled;
static BOOL LSandNCEnabled;
static BOOL notificationsEnabled;
static BOOL passcodeEnabled;

static void reloadPrefs() {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefPath]];
    homescreenEnabled = defaults[@"Homescreen"] ? [defaults[@"Homescreen"] boolValue] : YES;
    LSandNCEnabled = defaults[@"Lockscreen"] ? [defaults[@"Lockscreen"] boolValue] : YES;
    notificationsEnabled = defaults[@"Notifications"] ? [defaults[@"Notifications"] boolValue] : YES;
    passcodeEnabled = defaults[@"Passcode"] ? [defaults[@"Passcode"] boolValue] : YES;
}

void updateSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo) {
    reloadPrefs();
}


@interface SpringBoard : NSObject
- (void)_simulateLockButtonPress;
@end


static void handleTouches(NSSet *touches) {
    NSUInteger numTaps = [[touches anyObject] tapCount];
    if (numTaps == 2)
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}

static void addGesture(id self, UIView *target) {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [target addGestureRecognizer:tapGesture];
}

// LS/NC Normal
@interface SBPagedScrollView : UIScrollView
@end

%hook SBPagedScrollView

%group iOS10LS
- (void)_layoutPages {
    addGesture(self, self);

    %orig;
}
%end

%group iOS11LS
- (void)layoutPages {
    addGesture(self, self);

    %orig;
}
%end

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}

%end

// LS Clock & Date
@interface SBLockScreenDateViewController : UIViewController
@end

%hook SBLockScreenDateViewController

- (void)viewDidLoad {
    %orig;

    addGesture(self, self.view);
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}

%end

// LS notifications
@interface NCNotificationPriorityListViewController : UIViewController
@end

%hook NCNotificationPriorityListViewController

- (void)viewDidLoad {
    %orig;

    addGesture(self, self.view);
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (notificationsEnabled && sender.state == UIGestureRecognizerStateRecognized)
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}

%end

// LS media controls
@interface SBDashBoardMediaControlsView : UIView
@end

%hook SBDashBoardMediaControlsView

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (LSandNCEnabled)
        handleTouches(touches);
}

%end


%group iOS10
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

    addGesture(self, gestureView);
    [self.view addSubview:gestureView];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}

%end
%end

// LS Passcode screen
%hook SBUIPasscodeLockViewWithKeypad

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (passcodeEnabled)
        handleTouches(touches);
}

%end

%hook SBEmptyButtonView

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (passcodeEnabled)
        handleTouches(touches);
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

    addGesture(self, gestureView);
    [self.view addSubview:gestureView];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}
%end

// Home screen
%hook SBIconListView

%new
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (homescreenEnabled)
        handleTouches(touches);
}

%end



%ctor {
    reloadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &updateSettings, CFStringRef(@"se.nosskirneh.properlockgestures/preferencesChanged"), NULL, 0);

    %init;

    if ([%c(SBPagedScrollView) instancesRespondToSelector:@selector(_layoutPages)])
        %init(iOS10LS);
    else if ([%c(SBPagedScrollView) instancesRespondToSelector:@selector(layoutPages)])
        %init(iOS11LS);

    if (%c(SBDashBoardMediaArtworkViewController))
        %init(iOS10);
}

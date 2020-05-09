#import "SettingsKeys.h"
#import <notify.h>

static BOOL homescreenEnabled;
static BOOL LSandNCEnabled;
static BOOL notificationsEnabled;
static BOOL passcodeEnabled;

static void loadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];

    NSNumber *current = prefs[kHomescreen];
    homescreenEnabled = current ? [current boolValue] : YES;

    current = prefs[kLockscreen];
    LSandNCEnabled = current ? [current boolValue] : YES;

    current = prefs[kNotifications];
    notificationsEnabled = current ? [current boolValue] : YES;

    current = prefs[kPasscode];
    passcodeEnabled = current ? [current boolValue] : YES;
}


@interface SpringBoard : NSObject
- (void)_simulateLockButtonPress;
@end

static void simulatePress() {
    [((SpringBoard *)[%c(SpringBoard) sharedApplication]) _simulateLockButtonPress];
}

static void handleTouches(NSSet *touches) {
    NSUInteger numTaps = [[touches anyObject] tapCount];
    if (numTaps == 2)
        simulatePress();
}

static void addGesture(id self, UIView *target) {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [target addGestureRecognizer:tapGesture];
}

// LS/NC Normal
%hook PagedScrollView

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        simulatePress();
}

%end

%group iOS10LS
    %hook PagedScrollView
    - (void)_layoutPages {
        UIScrollView *_self = (UIScrollView *)self;
        addGesture(_self, _self);

        %orig;
    }
    %end
%end

%group iOS11LS
    %hook PagedScrollView
    - (void)layoutPages {
        UIScrollView *_self = (UIScrollView *)self;
        addGesture(_self, _self);

        %orig;
    }
    %end
%end


// LS Clock & Date
%hook LockScreenDateViewController

- (void)viewDidLoad {
    %orig;

    UIViewController *_self = (UIViewController *)self;
    addGesture(_self, _self.view);
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        simulatePress();
}

%end

// LS notifications
@interface NCNotificationPriorityListViewController : UIViewController
@end

%group oldNC
    %hook NCNotificationPriorityListViewController

    - (void)viewDidLoad {
        %orig;

        addGesture(self, self.view);
    }

    %new
    - (void)handleTapGesture:(UITapGestureRecognizer *)sender {
        if (notificationsEnabled && sender.state == UIGestureRecognizerStateRecognized)
            simulatePress();
    }

    %end
%end

// LS media controls
%hook MediaControlsView

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

        // If this would've gone directly to artworkViewController's viewDidLoad,
        // LSArtworkView's frame is 0, 0, 0, 0 by that time.
        if (self == LSArtworkView && !gestureView)
            [artworkViewController addGestureView];
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
            simulatePress();
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

// LS Charging view
%hook ChargingViewController

- (void)loadView {
    %orig;

    UIView *gestureView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [gestureView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.01]];

    addGesture(self, gestureView);
    [((UIViewController *)self).view addSubview:gestureView];
}

%new
- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (LSandNCEnabled && sender.state == UIGestureRecognizerStateRecognized)
        simulatePress();
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
    loadPreferences();

    int _;
    notify_register_dispatch(kSettingsChanged,
        &_,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0l),
        ^(int _) {
            loadPreferences();
        }
    );

    Class pagedScrollViewClass = %c(SBFPagedScrollView);
    if (!pagedScrollViewClass)
        pagedScrollViewClass = %c(SBPagedScrollView);

    Class dateViewControllerClass = %c(SBFLockScreenDateViewController);
    if (!dateViewControllerClass)
        dateViewControllerClass = %c(SBLockScreenDateViewController);

    Class mediaControlsViewClass = %c(CSMediaControlsView);
    if (!mediaControlsViewClass)
        mediaControlsViewClass = %c(SBDashBoardMediaControlsView);

    Class chargingViewControllerClass = %c(CSChargingViewController);
    if (!chargingViewControllerClass)
        chargingViewControllerClass = %c(SBDashBoardChargingViewController);
    %init(PagedScrollView = pagedScrollViewClass,
          LockScreenDateViewController = dateViewControllerClass,
          MediaControlsView = mediaControlsViewClass,
          ChargingViewController = chargingViewControllerClass);

    if ([pagedScrollViewClass instancesRespondToSelector:@selector(_layoutPages)])
        %init(iOS10LS, PagedScrollView = pagedScrollViewClass);
    else if ([pagedScrollViewClass instancesRespondToSelector:@selector(layoutPages)])
        %init(iOS11LS, PagedScrollView = pagedScrollViewClass); // iOS 12 and 13 too

    // Old stuff, not used on iOS 11 and later
    if (%c(SBDashBoardMediaArtworkViewController))
        %init(iOS10);

    if (%c(NCNotificationPriorityListViewController))
        %init(oldNC);
}

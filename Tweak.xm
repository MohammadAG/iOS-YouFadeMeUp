#import <UIKit/UIKit.h>
#import <substrate.h>

@interface SBIconModel
-(id)expectedIconForDisplayIdentifier:(NSString*)displayIdentifier;
@end

@interface SBIconViewMap : NSObject

@property (nonatomic,retain,readonly) SBIconModel *iconModel;

-(id)iconViewForIcon:(id)icon;

@end

@interface SBAppSwitcherIconController {
    SBIconViewMap *_iconViewMap;
}
@end

@interface SBAppSwitcherController
@property(readonly, nonatomic) SBAppSwitcherIconController *iconController;
@end

@interface SBUIController
+ (id)sharedInstance;
- (id)_appSwitcherController;
@end

@interface SBAppSwitcherPageView : UIView
@property (nonatomic,retain) UIView* view;
@end

@interface SBDisplayItem
@property (nonatomic,readonly) NSString * displayIdentifier;
@end

@interface SBAppSwitcherSnapshotView : NSObject
@property (nonatomic,copy,readonly) SBDisplayItem * displayItem;
@end

@interface SBAppSwitcherItemScrollView : UIScrollView
@property(retain, nonatomic) SBAppSwitcherPageView *item;
@end

static SBIconViewMap * getSwitcherIconMap() {
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    if (!uiController)
        return nil;
    SBAppSwitcherController *appSwitcherController = [uiController _appSwitcherController];
    if (!appSwitcherController)
        return nil;
    SBAppSwitcherIconController *iconController = appSwitcherController.iconController;
    if (!iconController)
        return nil;
    return MSHookIvar<SBIconViewMap *>(iconController, "_iconViewMap");
}

%hook SBAppSwitcherPageViewController

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    %orig;
    
    [scrollView retain];
    SBAppSwitcherItemScrollView *itemScrollView = (SBAppSwitcherItemScrollView*) scrollView;
    if (!itemScrollView || ![itemScrollView respondsToSelector:@selector(item)]) {
        [scrollView release];
        return;
    }
    CGPoint contentOffset = itemScrollView.contentOffset;
    // Scrolling horizontally
    if (contentOffset.y == 0 && contentOffset.x > 0) {
        [scrollView release];
        return;
    }
    
    SBAppSwitcherPageView *pageView = itemScrollView.item;
    [scrollView release];
    if (!pageView) {
        return;
    }
    [pageView retain];
    
    SBAppSwitcherSnapshotView *snapshotView = (SBAppSwitcherSnapshotView*) pageView.view;
    [pageView release];
    if (!snapshotView)
        return;
    
    [snapshotView retain];
    
    SBIconViewMap *viewMap = getSwitcherIconMap();
    if (!viewMap) {
        [snapshotView release];
        return;
    }
    
    [viewMap retain];
    
    // type is SBIcon, but we don't need to know that
    id icon = [viewMap.iconModel expectedIconForDisplayIdentifier:snapshotView.displayItem.displayIdentifier];
    [snapshotView release];
    if (!icon)
        return;
    
    [icon retain];
    UIView *iconView = [viewMap iconViewForIcon:icon];
    [icon release];
    
    [viewMap release];
    if (!iconView)
        return;
    [iconView retain];
    
    float percent = 1;
    if (contentOffset.y > 0) { // Dismissing upwards
        percent = 1 - (contentOffset.y / ([[UIScreen mainScreen] bounds].size.height - iconView.frame.origin.y) * 2);
    } else { // Downwards
        percent = 1 - (ABS(contentOffset.y) / 50.0);
    }
    iconView.alpha = percent;
    [iconView release];
}

%end
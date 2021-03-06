#import "NRESettings.h"
#import <Cephei/HBPreferences.h>

@implementation NRESettings {
    HBPreferences *_preferences;
    NSDictionary<NSString *, id> *_cachedPrefs;
}

#pragma mark - Init

+ (instancetype)sharedSettings {
    static NRESettings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _cachedPrefs = [NSDictionary dictionary];

        _preferences = [HBPreferences preferencesForIdentifier:@"com.shade.noire"];

        [_preferences registerBool:&_enabled default:NO forKey:NREPreferencesEnabledKey];

        [_preferences registerBool:&_forceTouch default:NO forKey:NREPreferences3DTouchKey];
        [_preferences registerBool:&_controlCenter default:NO forKey:NREPreferencesControlCenterKey];
        [_preferences registerBool:&_dock default:NO forKey:NREPreferencesDockKey];
        [_preferences registerBool:&_folders default:NO forKey:NREPreferencesFoldersKey];
        [_preferences registerBool:&_notifications default:NO forKey:NREPreferencesNotificationsKey];
        [_preferences registerBool:&_widgets default:NO forKey:NREPreferencesWidgetsKey];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesWereUpdated) name:HBPreferencesDidChangeNotification object:nil];
        [self preferencesWereUpdated];
    }

    return self;
}

#pragma mark - Callbacks

- (void)preferencesWereUpdated {
    // Observers
    NSDictionary<NSString *, id> *settingsDictionary = _preferences.dictionaryRepresentation;
    for (NSString *key in settingsDictionary.allKeys) {
        if ([settingsDictionary[key] isEqual:_cachedPrefs[key]]) {
            continue;
        }

        [self notifyObserversOfSettingsChange:key];
    }

    _cachedPrefs = settingsDictionary;
}

#pragma mark - Observers

- (void)addObserver:(id<NRESettingsObserver>)observer {
    if ([_observers containsObject:observer]) {
        return;
    }

    [_observers addObject:observer];
}

- (void)removeObserver:(id<NRESettingsObserver>)observer {
    if (![_observers containsObject:observer]) {
        return;
    }

    [_observers removeObject:observer];
}

- (void)notifyObserversOfSettingsChange:(NSString *)keyPath {
    for (id<NRESettingsObserver> observer in self.observers) {
        [observer settings:self changedValueForKeyPath:keyPath];
    }
}

@end
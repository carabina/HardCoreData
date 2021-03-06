//
//  HCDCoreDataStack.m
//  Pods
//
//  Created by Sergii Kryvoblotskyi on 5/12/15.
//
//

#import "HCDCoreDataStack.h"

@interface HCDCoreDataStack ()

/* Represents the local url where the store is placed */
@property (nonatomic, strong) NSURL *storeURL;

@end

@implementation HCDCoreDataStack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize mainManagedObjectContext = _mainManagedObjectContext;

+ (instancetype)binaryStackWithName:(NSString *)modelName
{
    return [self stackWithModelName:modelName storeType:NSBinaryStoreType];
}

+ (instancetype)inMemoryStackWithName:(NSString *)modelName
{
    return [self stackWithModelName:modelName storeType:NSInMemoryStoreType];
}

+ (instancetype)sqliteStackWithName:(NSString *)modelName
{
    return [self stackWithModelName:modelName storeType:NSSQLiteStoreType];
}

+ (instancetype)stackWithModelName:(NSString *)modelName storeType:(NSString *)storeType
{
    return [[self alloc] initWithModelName:modelName storeType:storeType];
}

- (instancetype)initWithModelName:(NSString *)modelName storeType:(NSString *)storeType
{
    self = [super init];
    if (self) {
        _modelName = modelName;
        _storeType = storeType;
    }
    return self;
}

#pragma mark - HCDCoreDataStack Protocol

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        
        /* Create PSC */
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        
        /* Add store to it */
        NSError *error = nil;
        if (![_persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:self.storeURL options:options error:&error]) {
            NSLog(@"CD Error: %s\n%@\n%@", __PRETTY_FUNCTION__, [self class], error);
        }
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        
        /* Current model */
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSURL *modelURL = [bundle URLForResource:self.modelName withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSManagedObjectContext *)mainManagedObjectContext
{
    if (!_mainManagedObjectContext) {
        
        /* Create background context with attached psc */
        NSManagedObjectContext *storageBackgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        storageBackgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        
        /* Create main queue context as main */
        _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainManagedObjectContext.parentContext = storageBackgroundContext;
    }
    return _mainManagedObjectContext;
}

#pragma mark - Private Accessors

- (NSURL *)storeURL
{
    if (!_storeURL) {
        _storeURL = [self _defaultStoreURL];
    }
    return _storeURL;
}

#pragma mark - Private

- (NSURL *)_defaultStoreURL
{
    NSFileManager *fileManager = [NSFileManager new];
#if TARGET_OS_IPHONE
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:self.modelName];
#else
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleName = [[bundle infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    NSURL *applicationSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *appFolderURL = [applicationSupportURL URLByAppendingPathComponent:bundleName];
    
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:appFolderURL.path isDirectory:&isDirectory]) {
        NSError *error = nil;
        if (![fileManager createDirectoryAtURL:appFolderURL withIntermediateDirectories:NO attributes:nil error:&error]) {
            NSLog(@"Cannot create folder to place the store - %@", error);
        }
    }
    return appFolderURL;
#endif
}

@end

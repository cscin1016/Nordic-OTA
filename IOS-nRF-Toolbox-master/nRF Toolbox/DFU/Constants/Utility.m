

#import "Utility.h"

@implementation Utility

NSString * const dfuServiceUUIDString = @"00001530-1212-EFDE-1523-785FEABCD123";
NSString * const dfuControlPointCharacteristicUUIDString = @"00001531-1212-EFDE-1523-785FEABCD123";
NSString * const dfuPacketCharacteristicUUIDString = @"00001532-1212-EFDE-1523-785FEABCD123";
NSString * const dfuVersionCharacteritsicUUIDString = @"00001534-1212-EFDE-1523-785FEABCD123";

NSString * const ANCSServiceUUIDString = @"7905F431-B5CE-4E99-A40F-4B1E122D00D0";
NSString * const TimerServiceUUIDString = @"1805";

int  PACKETS_NOTIFICATION_INTERVAL = 10;
int const PACKET_SIZE = 20;

NSString* const FIRMWARE_TYPE_SOFTDEVICE = @"softdevice";
NSString* const FIRMWARE_TYPE_BOOTLOADER = @"bootloader";
NSString* const FIRMWARE_TYPE_APPLICATION = @"application";
NSString* const FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER = @"softdevice and bootloader";


//文件类型
+ (NSArray *) getFirmwareTypes
{
    static NSArray *events;
    if (events == nil) {
        events = @[FIRMWARE_TYPE_SOFTDEVICE, FIRMWARE_TYPE_BOOTLOADER, FIRMWARE_TYPE_APPLICATION, FIRMWARE_TYPE_BOTH_SOFTDEVICE_BOOTLOADER];
    }
    return events;
}

+ (NSString *) stringFileExtension:(enumFileExtension)fileExtension
{
    switch (fileExtension) {
        case HEX:
            return @"hex";
        case BIN:
            return @"bin";
            
        default:
            return nil;
    }
}

+ (void)showAlert:(NSString *)message
{
 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DFU" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
 [alert show];
}

+(void)showBackgroundNotification:(NSString *)message
{
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    notification.alertAction = @"Show";
    notification.alertBody = message;
    notification.hasAction = NO;
    notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    notification.timeZone = [NSTimeZone  defaultTimeZone];
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] setScheduledLocalNotifications:[NSArray arrayWithObject:notification]];
}

+ (BOOL)isApplicationStateInactiveORBackground {
    UIApplicationState applicationState = [[UIApplication sharedApplication] applicationState];
    if (applicationState == UIApplicationStateInactive || applicationState == UIApplicationStateBackground) {
        return YES;
    }
    else {
        return NO;
    }
}

+(NSArray *)getFilesFromAppDirectory:(NSString *)directoryName
{
    NSString *firmwaresDirectoryPath = [self getAppDirectoryPath:directoryName];
    
    
    NSMutableArray *AllFilesNames = [[NSMutableArray alloc]init];
    NSError *error;
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:firmwaresDirectoryPath error:&error];
    if (error) {
        NSLog(@"error in opening directory path: %@",firmwaresDirectoryPath);
        return nil;
    }
    else {
        //        NSLog(@"number of files in directory %lu",(unsigned long)fileNames.count);
        for (NSString *fileName in fileNames) {
            //            NSLog(@"Found file in directory: %@",fileName);
            [AllFilesNames addObject:fileName];
        }
        return [AllFilesNames copy];
    }
    
    
    //    return [self getAllFilesFromDirectory:firmwaresDirectoryPath];
}


+(NSString *)getAppDirectoryPath:(NSString *)directoryName
{
    NSString *appPath = [[NSBundle mainBundle] resourcePath];
    NSString *firmwaresDirectoryPath = [appPath stringByAppendingPathComponent:directoryName];
    return firmwaresDirectoryPath;
}
@end

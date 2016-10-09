

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ScannedPeripheral : NSObject

@property (strong, nonatomic) CBPeripheral* peripheral;
@property (assign, nonatomic) int RSSI;
@property (nonatomic) BOOL isConnected;

+ (ScannedPeripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI isPeripheralConnected:(BOOL)isConnected;

- (NSString*) name;

@end

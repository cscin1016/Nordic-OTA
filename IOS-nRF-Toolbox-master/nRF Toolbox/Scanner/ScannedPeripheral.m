

#import "ScannedPeripheral.h"

@implementation ScannedPeripheral
@synthesize peripheral;
@synthesize RSSI;
@synthesize isConnected;

+ (ScannedPeripheral*) initWithPeripheral:(CBPeripheral*)peripheral rssi:(int)RSSI isPeripheralConnected:(BOOL)isConnected
{
    ScannedPeripheral* value = [ScannedPeripheral alloc];
    value.peripheral = peripheral;
    value.RSSI = RSSI;
    value.isConnected = isConnected;
    return value;
}

-(NSString*) name
{
    NSString* name = [peripheral name];
    if (name == nil)
    {
        return @"No name";
    }
    return name;
}

-(BOOL)isEqual:(id)object
{
    ScannedPeripheral* other = (ScannedPeripheral*) object;
    return peripheral == other.peripheral;
}

@end

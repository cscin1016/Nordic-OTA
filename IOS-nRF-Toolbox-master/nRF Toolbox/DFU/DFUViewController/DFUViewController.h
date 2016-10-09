

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ScannerDelegate.h"
#import "DFUOperations.h"


@interface DFUViewController : UIViewController <ScannerDelegate, DFUOperationsDelegate,CBCentralManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *deviceName;

@property (strong, nonatomic)NSString *selectedFileType;


@end

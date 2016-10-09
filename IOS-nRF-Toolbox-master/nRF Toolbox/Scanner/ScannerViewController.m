

#import "ScannerViewController.h"
#import "ScannedPeripheral.h"
#import "Utility.h"

@interface ScannerViewController ()

/*!
 * List of the peripherals shown on the table view. Peripheral are added to this list when it's discovered.
 * Only peripherals with bridgeServiceUUID in the advertisement packets are being displayed.
 */
@property (strong, nonatomic) NSMutableArray *peripherals;
/*!
 * The timer is used to periodically reload table
 */
@property (strong, nonatomic) NSTimer *timer;

- (void)timerFireMethod:(NSTimer *)timer;

@end

@implementation ScannerViewController
@synthesize bluetoothManager;
@synthesize devicesTable;
@synthesize filterUUID;
@synthesize peripherals;
@synthesize timer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    peripherals = [NSMutableArray arrayWithCapacity:8];
    devicesTable.delegate = self;
    devicesTable.dataSource = self;
    
    // We want the scanner to scan with dupliate keys (to refresh RRSI every second) so it has to be done using non-main queue
    dispatch_queue_t centralQueue = dispatch_queue_create("no.nordicsemi.ios.nrftoolbox", DISPATCH_QUEUE_SERIAL);
    bluetoothManager = [[CBCentralManager alloc]initWithDelegate:self queue:centralQueue];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self scanForPeripherals:NO];
}

- (IBAction)didCancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)getConnectedPeripherals {
    NSLog(@"getConnectedPeripherals");
    if (filterUUID != nil) {
        NSLog(@"Retrieving Connected Peripherals ...");
        NSArray *connectedPeripherals = [bluetoothManager retrieveConnectedPeripheralsWithServices:@[filterUUID]];
        NSLog(@"Connected Peripherals with filter: %lu",(unsigned long)connectedPeripherals.count);
        for (CBPeripheral *connectedPeripheral in connectedPeripherals) {
            NSLog(@"Connected Peripheral: %@",connectedPeripheral.name);
            [self addConnectedPeripheral:connectedPeripheral];
        }
    }
    else {
        CBUUID *dfuServiceUUID = [CBUUID UUIDWithString:dfuServiceUUIDString];
        CBUUID *ancsServiceUUID = [CBUUID UUIDWithString:ANCSServiceUUIDString];
        NSArray *connectedPeripherals = [bluetoothManager retrieveConnectedPeripheralsWithServices:@[dfuServiceUUID, ancsServiceUUID]];
        NSLog(@"Connected Peripherals without filter: %lu",(unsigned long)connectedPeripherals.count);
        for (CBPeripheral *connectedPeripheral in connectedPeripherals) {
            NSLog(@"Connected Peripheral: %@",connectedPeripheral.name);
            [self addConnectedPeripheral:connectedPeripheral];
        }
    }
}

- (void) addConnectedPeripheral:(CBPeripheral *)peripheral
{
    ScannedPeripheral* sensor = [ScannedPeripheral initWithPeripheral:peripheral rssi:0 isPeripheralConnected:YES];
    [peripherals addObject:sensor];
}

#pragma mark Central Manager delegate methods

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        //TODO Retrieve already connected/paired devices
        [self getConnectedPeripherals];
        [self scanForPeripherals:YES];
    }
}

/*!
 * @brief Starts scanning for peripherals with rscServiceUUID
 * @param enable If YES, this method will enable scanning for bridge devices, if NO it will stop scanning
 * @return 0 if success, -1 if Bluetooth Manager is not in CBCentralManagerStatePoweredOn state.
 */
- (int) scanForPeripherals:(BOOL)enable
{
    if (bluetoothManager.state != CBCentralManagerStatePoweredOn)
    {
        return -1;
    }
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (enable)
        {
            NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
            if (filterUUID != nil)
            {
                [bluetoothManager scanForPeripheralsWithServices:@[ filterUUID ] options:options];
            }
            else
            {
                [bluetoothManager scanForPeripheralsWithServices:nil options:options];
            }
            
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
        }
        else
        {
            [timer invalidate];
            timer = nil;
            
            [bluetoothManager stopScan];
        }
    });
    return 0;
}

/*!
 * @brief This method is called periodically by the timer. It refreshes the devices list. Updates from Central Manager comes to fast and it's hard to select a device if refreshed from there.
 * @param timer the timer that has called the method
 */
- (void)timerFireMethod:(NSTimer *)timer
{
    [devicesTable reloadData];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Scanner uses other queue to send events. We must edit UI in the main queue
    //NSLog(@"scanned peripheral : %@",peripheral.name);
    dispatch_async(dispatch_get_main_queue(), ^{
        // Add the sensor to the list and reload deta set
        ScannedPeripheral* sensor = [ScannedPeripheral initWithPeripheral:peripheral rssi:RSSI.intValue isPeripheralConnected:NO];
        if (![peripherals containsObject:sensor])
        {
            [peripherals addObject:sensor];
        }
        else
        {
            sensor = [peripherals objectAtIndex:[peripherals indexOfObject:sensor]];
            sensor.RSSI = RSSI.intValue;
        }
    });
}

#pragma mark Table View delegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [bluetoothManager stopScan];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Call delegate method
    [self.delegate centralManager:bluetoothManager didPeripheralSelected:[[peripherals objectAtIndex:indexPath.row] peripheral]];
}

#pragma mark Table View Data Source delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return peripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // Update sensor name
    ScannedPeripheral *peripheral = [peripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = [peripheral name];
    if (peripheral.isConnected) {
        cell.imageView.image = [UIImage imageNamed:@"Connected"];
    }
    else {
        cell.imageView.image = [self getRSSIImage:peripheral.RSSI];
    }
    return cell;
}

-(UIImage *) getRSSIImage:(int)rssi {
    // Update RSSI indicator
    UIImage* image;
    if (rssi < -90) {
        image = [UIImage imageNamed: @"Signal_0"];
    }
    else if (rssi < -70)
    {
        image = [UIImage imageNamed: @"Signal_1"];
    }
    else if (rssi < -50)
    {
        image = [UIImage imageNamed: @"Signal_2"];
    }
    else
    {
        image = [UIImage imageNamed: @"Signal_3"];
    }
    return image;
}

@end

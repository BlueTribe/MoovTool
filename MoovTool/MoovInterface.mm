#import "MoovInterface.h"
#import "AppDelegate.h"
#import <Cocoa/Cocoa.h>

#define MOOV_ADV_SERVICE_UUID @"2B0A857D-3982-4152-B46F-5E7423578524"
#define MOOV_MEM_SERVICE_UUID @"f000cd50-0451-4000-b000-000000000000"

#define MOOV_ADDR_CHAR_UUID @"f000cd61-0451-4000-b000-000000000000"
#define MOOV_MEM_READ_CHAR_UUID @"f000cd62-0451-4000-b000-000000000000"


enum e_moov_memory_op_state
{
    _moov_memory_op_unknown,
    _moov_memory_op_read_header,
    _moov_memory_op_read_payload,
    _moov_memory_op_finished,
};

constexpr int32_t k_assumed_memory_data_type = 0;

struct moov_flash_memory_header
{
    // is the recoding initialized by me?
    int32_t signature;
    
    // max recording size
    int32_t max_size;
    
    // sampling period in millisecond
    int16_t period_setting;
    
    // data type
    int16_t type;
};

@implementation MoovInterface
{
    e_moov_memory_op_state _moov_memory_op_state;
    uint32_t               _moov_memory_address_offset;
    moov_flash_memory_header _header;
    NSMutableData          *_readData;
}

@synthesize readValue = _readData;

-(id)init
{
    self = [super init];
    
    cbManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    self.peripherals = [[NSMutableArray alloc] init];
    
    _moov_memory_op_state = _moov_memory_op_unknown;
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////
// Device Functions
-(void)connect: (NSInteger)ndx
{
    self.moov = self.peripherals[ndx];
    
    if(self.moov)
    {
        [cbManager connectPeripheral:self.moov options:nil];
    }
}

-(void)record
{
    // Todo
}

-(void)read
{
    if(self.moov)
    {
        assert (_moov_memory_op_state == _moov_memory_op_unknown);
        _moov_memory_op_state = _moov_memory_op_read_header;
        [self readHeader];
    }
}

// Device Functions
////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////
// Moov operations
-(void)readHeader
{
    uint32_t address = 0;
    [self.moov writeValue:[NSData dataWithBytes:&address length:sizeof(address)] forCharacteristic:addrChar type:CBCharacteristicWriteWithResponse];
}

-(void)readNextBodyBlock
{
    [self.moov writeValue:[NSData dataWithBytes:&_moov_memory_address_offset length:sizeof(_moov_memory_address_offset)] forCharacteristic:addrChar type:CBCharacteristicWriteWithResponse];
}

////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////
// Central Manager Delegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            [cbManager scanForPeripheralsWithServices: @[[CBUUID UUIDWithString: MOOV_ADV_SERVICE_UUID]]
                                              options: @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
        break;
            
        default:
            NSLog(@"Central State: %ld", central.state);
        break;
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@", peripheral);
    [central stopScan];
    [self.peripherals addObject:peripheral];
    
    // tell the app delegate something changed
    [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected %@", peripheral);
    peripheral.delegate = self;
    [peripheral discoverServices: @[[CBUUID UUIDWithString: MOOV_MEM_SERVICE_UUID]]];
    // tell the app delegate something changed
    [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect %@ Error %@", peripheral, error);
}

// Central Manager Delegate
////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////
// Peripheral Manager Delegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    CBService * service;
    
    for (service in peripheral.services)
    {
        NSLog(@"Discovered Service: %@", service.UUID);
        
        if([service.UUID isEqualTo: [CBUUID UUIDWithString:MOOV_MEM_SERVICE_UUID]])
        {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:MOOV_ADDR_CHAR_UUID],
                                                  [CBUUID UUIDWithString:MOOV_MEM_READ_CHAR_UUID]]
                                     forService: service];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    CBCharacteristic * characteristic;
    
    for(characteristic in service.characteristics)
    {
        NSLog(@"Discovered Characteristic: %@", characteristic.UUID);
        if([characteristic.UUID isEqualTo:[CBUUID UUIDWithString:MOOV_MEM_READ_CHAR_UUID]])
        {
            readChar = characteristic;
            // tell the app delegate something changed
            [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
        }
        else if([characteristic.UUID isEqualTo:[CBUUID UUIDWithString:MOOV_ADDR_CHAR_UUID]])
        {
            addrChar = characteristic;
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Read Value %@", characteristic.value);
    
    if (characteristic.value.length == 0 || error)
    {
        NSLog(@"error %zd %@", characteristic.value.length, error);
    }
    else if ([characteristic isEqualTo:readChar])
    {
        NSAssert(characteristic.value.length == 504, @"assuming the block size is always 504 bytes");
        
        switch (_moov_memory_op_state)
        {
            case _moov_memory_op_read_header:
                // cast to C struct
                [characteristic.value getBytes:&_header length:sizeof(_header)];
                NSAssert(_header.type == k_assumed_memory_data_type, @"We only support type 0 for now");
                
                // next step:
                _moov_memory_op_state = _moov_memory_op_read_payload;
                _moov_memory_address_offset = static_cast<uint32_t>(characteristic.value.length);
                
                // init NSData to store all data from moov
                _readData = [NSMutableData data];
                
                // start to read payload data:
                [self readNextBodyBlock];
                break;
            case _moov_memory_op_read_payload:
                // append new data:
                [_readData appendData:characteristic.value];

                // move address pointer
                _moov_memory_address_offset += characteristic.value.length;
                
                if (_moov_memory_address_offset < _header.max_size)
                {
                    [self readNextBodyBlock];
                }
                else
                {
                    _moov_memory_op_state = _moov_memory_op_finished;
                    NSLog(@"Done.");
                }
                
                break;
            default:
                NSAssert(false, @"unreachable");
        }
    }
    
    // tell the app delegate something changed
    [((AppDelegate*)[NSApplication sharedApplication].delegate) update];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"error %@", error);
    }
    else if ([characteristic isEqualTo:addrChar])
    {
        switch (_moov_memory_op_state)
        {
            case _moov_memory_op_read_header:
            case _moov_memory_op_read_payload:
                [self.moov readValueForCharacteristic:readChar];
                break;
            default:
                NSAssert(false, @"unreachable");
        }
    }
    else
    {
        NSLog(@"#@^@#$^$!#($#%%");
    }
}

// Peripheral Manager Delegate
////////////////////////////////////////////////////////////////////////////////////////////

@end

////////////////////////////////////////////////////////////////////////////////
//    Copyright (c) Open Connectivity Foundation (OCF), AllJoyn Open Source
//    Project (AJOSP) Contributors and others.
//
//    SPDX-License-Identifier: Apache-2.0
//
//    All rights reserved. This program and the accompanying materials are
//    made available under the terms of the Apache License, Version 2.0
//    which accompanies this distribution, and is available at
//    http://www.apache.org/licenses/LICENSE-2.0
//
//    Copyright (c) Open Connectivity Foundation and Contributors to AllSeen
//    Alliance. All rights reserved.
//
//    Permission to use, copy, modify, and/or distribute this software for
//    any purpose with or without fee is hereby granted, provided that the
//    above copyright notice and this permission notice appear in all
//    copies.
//
//    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
//    WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//    AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
//    DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
//    PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
//    TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
//    PERFORMANCE OF THIS SOFTWARE.
////////////////////////////////////////////////////////////////////////////////

#import "BusAttachmentTests.h"
#import "AJNBusAttachment.h"
#import "AJNInterfaceDescription.h"
#import "AJNAboutDataListener.h"
#import "AJNAboutObject.h"
#import "AJNAboutData.h"
#import "AJNAboutProxy.h"
#import "AJNAboutIcon.h"
#import "AJNAboutIconObject.h"
#import "AJNAboutIconProxy.h"
#import "AJNAboutObjectDescription.h"
#import "BasicObject.h"
#import "AJNMessageArgument.h"
#import "AJNMessage.h"
#import "AJNInit.h"


static NSString * const kBusAttachmentTestsAdvertisedName = @"org.alljoyn.bus.objc.tests.AReallyNiftyNameThatNoOneWillUse";
static NSString * const kBusAttachmentTestsInterfaceName = @"org.alljoyn.bus.objc.tests.NNNNNNEEEEEEEERRRRRRRRRRDDDDDDDSSSSSSSS";
static NSString * const kBusAttachmentTestsInterfaceMethod = @"behaveInSociallyAwkwardWay";
static NSString * const kBusAttachmentTestsInterfaceXML = @"<interface name=\"org.alljoyn.bus.objc.tests.NNNNNNEEEEEEEERRRRRRRRRRDDDDDDDSSSSSSSS\">\
                                                                <signal name=\"FigdetingNervously\">\
                                                                    <arg name=\"levelOfAwkwardness\" type=\"s\"/>\
                                                                </signal>\
                                                                <property name=\"nerdiness\" type=\"s\" access=\"read\"/>\
                                                            </interface>";

static NSString * const kBusObjectTestsObjectPath = @"/basic_object";
const NSTimeInterval kBusAttachmentTestsWaitTimeBeforeFailure = 10.0;
const NSInteger kBusAttachmentTestsServicePort = 999;
BOOL receiveAnnounce = NO;
static NSMutableDictionary *gDefaultAboutData;
// MAX_ICON_SIZE_IN_BYTES = ALLJOYN_MAX_ARRAY_LEN
static const size_t MAX_ICON_SIZE_IN_BYTES = 131072;
static const uint8_t ICON_BYTE = 0x11;

@interface BusAttachmentTests() <AJNBusListener, AJNSessionListener, AJNSessionPortListener, AJNJoinSessionDelegate, AJNPingPeerDelegate, AJNAboutDataListener, AJNAboutListener>

@property (nonatomic, strong) AJNBusAttachment *bus;
@property (nonatomic) BOOL listenerDidRegisterWithBusCompleted;
@property (nonatomic) BOOL listenerDidUnregisterWithBusCompleted;
@property (nonatomic) BOOL didFindAdvertisedNameCompleted;
@property (nonatomic) BOOL didLoseAdvertisedNameCompleted;
@property (nonatomic) BOOL nameOwnerChangedCompleted;
@property (nonatomic) BOOL busWillStopCompleted;
@property (nonatomic) BOOL busDidDisconnectCompleted;
@property (nonatomic) BOOL sessionWasLost;
@property (nonatomic) BOOL didAddMemberNamed;
@property (nonatomic) BOOL didRemoveMemberNamed;
@property (nonatomic) BOOL shouldAcceptSessionJoinerNamed;
@property (nonatomic) BOOL didJoinInSession;
@property (nonatomic) AJNSessionId testSessionId;
@property (nonatomic) BOOL isTestClient;
@property (nonatomic) BOOL clientConnectionCompleted;
@property (nonatomic) BOOL isAsyncTestClientBlock;
@property (nonatomic) BOOL isAsyncTestClientDelegate;
@property (nonatomic) BOOL isPingAsyncComplete;
@property (nonatomic) BOOL didReceiveAnnounce;
@property (nonatomic) BOOL setInvalidData;
@property (nonatomic) BOOL setInvalidLanguage;
@property (nonatomic) NSString *busNameToConnect;
@property (nonatomic) AJNSessionPort sessionPortToConnect;
@property (nonatomic) BOOL testBadAnnounceData;
@property (nonatomic) BOOL testMissingAboutDataField;
@property (nonatomic) BOOL testMissingAnnounceDataField;
@property (nonatomic) BOOL testUnsupportedLanguage;
@property (nonatomic) BOOL testNonDefaultUTFLanguage;
@property (nonatomic) AJNMessageArgument *testAboutObjectDescriptionArg;
@property (nonatomic) AJNMessageArgument *testAboutDataArg;
@property (nonatomic) BOOL testAboutObjectDescription;


- (BOOL)waitForBusToStop:(NSTimeInterval)timeoutSeconds;
- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSeconds onFlag:(BOOL*)flag;

@end

@implementation BusAttachmentTests

@synthesize bus = _bus;
@synthesize listenerDidRegisterWithBusCompleted = _listenerDidRegisterWithBusCompleted;
@synthesize listenerDidUnregisterWithBusCompleted = _listenerDidUnregisterWithBusCompleted;
@synthesize didFindAdvertisedNameCompleted = _didFindAdvertisedNameCompleted;
@synthesize didLoseAdvertisedNameCompleted = _didLoseAdvertisedNameCompleted;
@synthesize nameOwnerChangedCompleted = _nameOwnerChangedCompleted;
@synthesize busWillStopCompleted = _busWillStopCompleted;
@synthesize busDidDisconnectCompleted = _busDidDisconnectCompleted;
@synthesize sessionWasLost = _sessionWasLost;
@synthesize didAddMemberNamed = _didAddMemberNamed;
@synthesize didRemoveMemberNamed = _didRemoveMemberNamed;
@synthesize shouldAcceptSessionJoinerNamed = _shouldAcceptSessionJoinerNamed;
@synthesize didJoinInSession = _didJoinInSession;
@synthesize testSessionId = _testSessionId;
@synthesize isTestClient = _isTestClient;
@synthesize isAsyncTestClientBlock = _isAsyncTestClientBlock;
@synthesize isAsyncTestClientDelegate = _isAsyncTestClientDelegate;
@synthesize clientConnectionCompleted = _clientConnectionCompleted;
@synthesize isPingAsyncComplete = _isPingAsyncComplete;
@synthesize didReceiveAnnounce = _didReceiveAnnounce;
@synthesize setInvalidData = _setInvalidData;
@synthesize setInvalidLanguage = _setInvalidLanguage;
@synthesize busNameToConnect = _busNameToConnect;
@synthesize sessionPortToConnect = _sessionPortToConnect;
@synthesize testBadAnnounceData = _testBadAnnounceData;
@synthesize testMissingAboutDataField = _testMissingAboutDataField;
@synthesize testMissingAnnounceDataField = _testMissingAnnounceDataField;
@synthesize testUnsupportedLanguage = _testUnsupportedLanguage;
@synthesize testNonDefaultUTFLanguage = _testNonDefaultUTFLanguage;
@synthesize testAboutObjectDescriptionArg = _testAboutObjectDescriptionArg;
@synthesize testAboutDataArg = _testAboutDataArg;
@synthesize testAboutObjectDescription = _testAboutObjectDescription;

- (void)setUp
{
    [super setUp];

    [AJNInit alljoynInit];
    [AJNInit alljoynRouterInit];

    [self setUpWithBusAttachement: [[AJNBusAttachment alloc] initWithApplicationName:@"testApp" allowRemoteMessages:YES]];
}

- (void)tearDown
{
    self.listenerDidRegisterWithBusCompleted = NO;
    self.listenerDidUnregisterWithBusCompleted = NO;
    self.didFindAdvertisedNameCompleted = NO;
    self.didLoseAdvertisedNameCompleted = NO;
    self.nameOwnerChangedCompleted = NO;
    self.busWillStopCompleted = NO;
    self.busDidDisconnectCompleted = NO;

    self.sessionWasLost = NO;
    self.didAddMemberNamed = NO;
    self.didRemoveMemberNamed = NO;
    self.shouldAcceptSessionJoinerNamed = NO;
    self.didJoinInSession = NO;
    self.isTestClient = NO;
    self.isAsyncTestClientBlock = NO;
    self.isAsyncTestClientDelegate = NO;
    self.clientConnectionCompleted = NO;
    self.isPingAsyncComplete = NO;
    self.setInvalidData = NO;
    self.setInvalidLanguage = NO;
    self.didReceiveAnnounce = NO;
    receiveAnnounce = NO;
    self.busNameToConnect = nil;
    self.sessionPortToConnect = 0;
    self.testBadAnnounceData = NO;
    self.testMissingAboutDataField = NO;
    self.testMissingAnnounceDataField = NO;
    self.testUnsupportedLanguage = NO;
    self.testNonDefaultUTFLanguage = NO;
    self.testAboutObjectDescription = NO;

    self.bus = nil;

    [AJNInit alljoynRouterShutdown];
    [AJNInit alljoynShutdown];

    [super tearDown];
}

- (void)setUpWithBusAttachement:(AJNBusAttachment *)busAttachment
{
    self.bus = busAttachment;
    self.listenerDidRegisterWithBusCompleted = NO;
    self.listenerDidUnregisterWithBusCompleted = NO;
    self.didFindAdvertisedNameCompleted = NO;
    self.didLoseAdvertisedNameCompleted = NO;
    self.nameOwnerChangedCompleted = NO;
    self.busWillStopCompleted = NO;
    self.busDidDisconnectCompleted = NO;

    self.sessionWasLost = NO;
    self.didAddMemberNamed = NO;
    self.didRemoveMemberNamed = NO;
    self.shouldAcceptSessionJoinerNamed = NO;
    self.didJoinInSession = NO;
    self.isTestClient = NO;
    self.isAsyncTestClientBlock = NO;
    self.isAsyncTestClientDelegate = NO;
    self.clientConnectionCompleted = NO;
    self.isPingAsyncComplete = NO;
    self.setInvalidData = NO;
    self.setInvalidLanguage = NO;
    receiveAnnounce = NO;
    self.busNameToConnect = nil;
    self.sessionPortToConnect = 0;
    self.testBadAnnounceData = NO;
    self.testMissingAboutDataField = NO;
    self.testMissingAnnounceDataField = NO;
    self.testUnsupportedLanguage = NO;
    self.testNonDefaultUTFLanguage = NO;
    self.testAboutObjectDescription = NO;
}

- (void)testShouldHaveValidHandleAfterIntialization
{
    XCTAssertTrue(self.bus.handle != NULL, @"The bus attachment should always have a valid handle after initialization.");
}

- (void)testShouldCreateInterface
{
    AJNInterfaceDescription *iface = [self.bus createInterfaceWithName:kBusAttachmentTestsInterfaceName enableSecurity:NO];
    XCTAssertNotNil(iface, @"Bus failed to create interface.");

    [iface activate];

    iface = [self.bus interfaceWithName:kBusAttachmentTestsInterfaceName];
    XCTAssertNotNil(iface, @"Bus failed to retrieve interface that had already been created.");

    NSArray *interfaces = self.bus.interfaces;
    BOOL didFindInterface = NO;
    for (AJNInterfaceDescription *interfaceDescription in interfaces) {
        if ([interfaceDescription.name compare:kBusAttachmentTestsInterfaceName] == NSOrderedSame) {
            didFindInterface = YES;
            break;
        }
    }
    XCTAssertTrue(didFindInterface,@"Bus did not return interface that was activated.");
}

- (void)testShouldCreateInterfaceFromXml
{
    QStatus status = [self.bus createInterfacesFromXml:kBusAttachmentTestsInterfaceXML];
    XCTAssertTrue(status == ER_OK, @"Bus failed to create interface from XML.");

    AJNInterfaceDescription *iface = [self.bus interfaceWithName:kBusAttachmentTestsInterfaceName];
    XCTAssertNotNil(iface, @"Bus failed to retrieve interface that had already been created from XML.");
}

- (void)testShouldDeleteInterface
{
    AJNInterfaceDescription *iface = [self.bus createInterfaceWithName:kBusAttachmentTestsInterfaceName enableSecurity:NO];
    XCTAssertNotNil(iface, @"Bus failed to create interface.");
    QStatus status = [iface addMethodWithName:kBusAttachmentTestsInterfaceMethod inputSignature:@"s" outputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"behavior"]];
    XCTAssertTrue(status == ER_OK, @"Interface description failed to add method to interface.");

    status = [self.bus deleteInterface:iface];
    XCTAssertTrue(status == ER_OK, @"Bus failed to delete interface.");

    iface = [self.bus interfaceWithName:kBusAttachmentTestsInterfaceName];
    XCTAssertNil(iface, @"Bus retrieved interface that had already been deleted.");
}

- (void)testShouldNotDeleteInterface
{
    AJNInterfaceDescription *iface = [self.bus createInterfaceWithName:kBusAttachmentTestsInterfaceName enableSecurity:NO];
    XCTAssertNotNil(iface, @"Bus failed to create interface.");
    QStatus status = [iface addMethodWithName:kBusAttachmentTestsInterfaceMethod inputSignature:@"s" outputSignature:@"s" argumentNames:[NSArray arrayWithObject:@"behavior"]];
    XCTAssertTrue(status == ER_OK, @"Interface description failed to add method to interface.");
    [iface activate];

    status = [self.bus deleteInterface:iface];
    XCTAssertTrue(status != ER_OK, @"Bus deleted interface after it was activated.");

    iface = [self.bus interfaceWithName:kBusAttachmentTestsInterfaceName];
    XCTAssertNotNil(iface, @"Bus failed to retrieve interface that had been unsuccessfully deleted.");
}

- (void)testShouldReportConnectionStatusCorrectly
{
    XCTAssertFalse(self.bus.isStarted, @"Bus attachment indicates that it is started before successful call to start.");
    XCTAssertFalse(self.bus.isStopping, @"Bus attachment indicates that it is stopping before successful call to stop.");
    XCTAssertFalse(self.bus.isConnected, @"Bus attachment indicates that it is connected before successful call to connect.");

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    XCTAssertTrue(self.bus.isStarted, @"Bus attachment indicates that it is not started after successful call to start.");
    XCTAssertFalse(self.bus.isStopping, @"Bus attachment indicates that it is stopping before successful call to stop.");
    XCTAssertFalse(self.bus.isConnected, @"Bus attachment indicates that it is connected before successful call to connect.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    XCTAssertTrue(self.bus.isConnected, @"Bus attachment indicates that it is not connected after successful call to connect.");
    XCTAssertTrue(self.bus.isStarted, @"Bus attachment indicates that it is not started after successful call to start.");
    XCTAssertFalse(self.bus.isStopping, @"Bus attachment indicates that it is stopping before successful call to stop.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");
    XCTAssertFalse(self.bus.isConnected, @"Bus attachment indicates that it is connected after successful call to disconnect.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");
    XCTAssertTrue(self.bus.isStopping, @"Bus attachment indicates that it is not stopping after successful call to stop.");
    XCTAssertFalse(self.bus.isConnected, @"Bus attachment indicates that it is connected after successful call to disconnect.");
}

- (void)testShouldHaveUniqueNameAndIdentifier
{
    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    XCTAssertTrue(self.bus.uniqueName != nil && self.bus.uniqueName.length > 0, @"Bus should be assigned a unique name after starting and connecting.");

    XCTAssertTrue(self.bus.uniqueIdentifier != nil && self.bus.uniqueIdentifier.length > 0, @"Bus should be assigned a unique identifier after starting and connecting.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");
    XCTAssertFalse(self.bus.isConnected, @"Bus attachment indicates that it is connected after successful call to disconnect.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");
    XCTAssertTrue(self.bus.isStopping, @"Bus attachment indicates that it is not stopping after successful call to stop.");
    XCTAssertFalse(self.bus.isConnected, @"Bus attachment indicates that it is connected after successful call to disconnect.");

}

- (void)testShouldRegisterBusListener
{
    [self.bus registerBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidRegisterWithBusCompleted], @"The bus listener should have been notified that a listener was registered.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldNotifyBusListenerWhenStopping
{
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busWillStopCompleted], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldNotifyBusListenerWhenDisconnecting
{
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busWillStopCompleted], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldNotifyBusListenerWhenAdvertisedNameFound
{
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [self.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Find advertised name failed.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didFindAdvertisedNameCompleted], @"The bus listener should have been notified that the advertised name was found.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busWillStopCompleted], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldNotifyBusListenerWhenAdvertisedNameLost
{
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [self.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Find advertised name failed.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didFindAdvertisedNameCompleted], @"The bus listener should have been notified that the advertised name was found.");

    status = [self.bus cancelAdvertisedName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didLoseAdvertisedNameCompleted], @"The bus listener should have been notified that the advertised name was lost.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busWillStopCompleted], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldNotifyBusListenerWhenNameOwnerChanges
{
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_nameOwnerChangedCompleted], @"The bus listener should have been notified that the name we requested has a new owner now (us).");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busWillStopCompleted], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldIndicateThatNameHasOwner
{
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_nameOwnerChangedCompleted], @"The bus listener should have been notified that the name we requested has a new owner now (us).");

    BOOL hasOwner = [self.bus doesWellKnownNameHaveOwner:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(hasOwner, @"The doesWellKnownNameHaveOwner message should have returned true after we took ownership of the name.");

    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busWillStopCompleted], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");
}

- (void)testShouldAllowSessionToBeJoinedByAClient
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;

    [self.bus registerBusListener:self];
    [client.bus registerBusListener:client];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    status = [client.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Client disconnect from bus via null transport failed.");
    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [client.bus stop];
    XCTAssertTrue(status == ER_OK, @"Client bus failed to stop.");
    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The client bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

- (void)testShouldNotifyClientWhenLinkIsBroken
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;

    [self.bus registerBusListener:self];
    [client.bus registerBusListener:client];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    uint32_t timeout = 40;
    status = [client.bus setLinkTimeout:&timeout forSession:client.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Failed to set the link timeout on the client's bus attachment. Error was %@", [AJNStatus descriptionForStatusCode:status]);
    timeout = 40;
    status = [self.bus setLinkTimeout:&timeout forSession:self.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Failed to set the link timeout on the service's bus attachment. Error was %@", [AJNStatus descriptionForStatusCode:status]);

    status = [client.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Client disconnect from bus via null transport failed.");
    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [client.bus stop];
    XCTAssertTrue(status == ER_OK, @"Client bus failed to stop.");
    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The client bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

- (void)testShouldAllowSessionToBeAsynchronouslyJoinedByAClientUsingBlock
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isAsyncTestClientBlock = YES;

    [self.bus registerBusListener:self];
    [client.bus registerBusListener:client];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    status = [client.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Client disconnect from bus via null transport failed.");
    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [client.bus stop];
    XCTAssertTrue(status == ER_OK, @"Client bus failed to stop.");
    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The client bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

- (void)testShouldAllowSessionToBeAsynchronouslyJoinedByAClientUsingDelegate
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isAsyncTestClientDelegate = YES;

    [self.bus registerBusListener:self];
    [client.bus registerBusListener:client];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");
    status = [client.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Client disconnect from bus via null transport failed.");
    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [client.bus stop];
    XCTAssertTrue(status == ER_OK, @"Client bus failed to stop.");
    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The client bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}


- (void)testShouldAllowPeerToBeAsynchronouslyPingedByAClientUsingDelegate
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isAsyncTestClientDelegate = YES;

    [self.bus registerBusListener:self];
    [client.bus registerBusListener:client];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    XCTAssertTrue(ER_OK == [self.bus pingPeerAsync:kBusAttachmentTestsAdvertisedName withTimeout:5 completionDelegate:self context:nil], @"PingPeerAsync Failed");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_isPingAsyncComplete], @"The service could not be pinged");

    status = [client.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Client disconnect from bus via null transport failed.");
    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [client.bus stop];
    XCTAssertTrue(status == ER_OK, @"Client bus failed to stop.");
    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The client bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

- (void)testShouldAllowPeerToBeAsynchronouslyPingedByAClientUsingBlock
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isAsyncTestClientBlock = YES;

    [self.bus registerBusListener:self];
    [client.bus registerBusListener:client];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    XCTAssertTrue(ER_OK == [self.bus pingPeerAsync:kBusAttachmentTestsAdvertisedName withTimeout:5
                                  completionBlock:^(QStatus status, void *context) {
                                      NSLog(@"Ping Peer Async callback");
                                      XCTAssertTrue(status == ER_OK, @"Ping Peer Async failed");
                                      self.isPingAsyncComplete = YES;
                                  }context:nil], @"PingPeerAsync Failed");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_isPingAsyncComplete], @"The service could not be pinged");

    status = [client.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Client disconnect from bus via null transport failed.");
    status = [self.bus disconnect];
    XCTAssertTrue(status == ER_OK, @"Disconnect from bus via null transport failed.");

    status = [client.bus stop];
    XCTAssertTrue(status == ER_OK, @"Client bus failed to stop.");
    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The client bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_busDidDisconnectCompleted], @"The bus listener should have been notified that the bus was disconnected.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

- (void)testShouldAllowServiceToLeaveSelfJoin
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUpWithBusAttachement:self.bus];
    client.isTestClient = YES;
    [client.bus registerBusListener:client];
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:NO proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    status = [self.bus setHostedSessionListener:self toSession:self.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Binding of a Service sessionlistener failed");

    status = [client.bus setJoinedSessionListener:client toSession:client.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Binding of a Client sessionlistener failed");

    status = [self.bus setHostedSessionListener:nil toSession:self.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Removal of the Service sessionlistener failed");

    status = [client.bus setJoinedSessionListener:nil toSession:client.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Removal of the Client sessionlistener failed");

    status = [self.bus leaveHostedSession:self.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Service failed to leave self joined session");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

- (void)testShouldAllowClientToLeaveSelfJoin
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    [client setUpWithBusAttachement:self.bus];
    client.isTestClient = YES;
    [client.bus registerBusListener:client];
    [self.bus registerBusListener:self];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");

    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:NO proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    status = [self.bus requestWellKnownName:kBusAttachmentTestsAdvertisedName withFlags:kAJNBusNameFlagDoNotQueue|kAJNBusNameFlagReplaceExisting];
    XCTAssertTrue(status == ER_OK, @"Request for well known name failed.");

    status = [self.bus advertiseName:kBusAttachmentTestsAdvertisedName withTransportMask:kAJNTransportMaskAny];
    XCTAssertTrue(status == ER_OK, @"Advertise name failed.");

    status = [client.bus findAdvertisedName:kBusAttachmentTestsAdvertisedName];
    XCTAssertTrue(status == ER_OK, @"Client attempt to find advertised name %@ failed.", kBusAttachmentTestsAdvertisedName);

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_shouldAcceptSessionJoinerNamed], @"The service did not report that it was queried for acceptance of the client joiner.");
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_didJoinInSession], @"The service did not receive a notification that the client joined the session.");
    XCTAssertTrue(client.clientConnectionCompleted, @"The client did not report that it connected.");
    XCTAssertTrue(client.testSessionId == self.testSessionId, @"The client session id does not match the service session id.");

    status = [self.bus setHostedSessionListener:self toSession:self.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Binding of a Service sessionlistener failed");

    status = [client.bus setJoinedSessionListener:client toSession:client.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Binding of a Client sessionlistener failed");

    status = [client.bus leaveJoinedSession:client.testSessionId];
    XCTAssertTrue(status == ER_OK, @"Client failed to leave self joined session");

    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_sessionWasLost], @"The Service was not informed that the session was lost.");

    status = [self.bus stop];
    XCTAssertTrue(status == ER_OK, @"Bus failed to stop.");

    XCTAssertTrue([client waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");
    XCTAssertTrue([self waitForBusToStop:kBusAttachmentTestsWaitTimeBeforeFailure], @"The bus listener should have been notified that the bus is stopping.");

    [client.bus unregisterBusListener:client];
    [self.bus unregisterBusListener:self];
    XCTAssertTrue([self waitForCompletion:kBusAttachmentTestsWaitTimeBeforeFailure onFlag:&_listenerDidUnregisterWithBusCompleted], @"The bus listener should have been notified that a listener was unregistered.");

    [client tearDown];
}

//TODO: - (void)testShouldNotifyAJNSessionListenerInCaseOfSessionLost

- (void)testShouldReceiveAnnounceSignalAndPrintIt
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");

    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testShouldReceiveAboutIcon
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    // Service sets the About Icon
    AJNAboutIcon *aboutIcon = [[AJNAboutIcon alloc] init];
    status = [aboutIcon setUrlWithMimeType:@"image/png" url:@"http://www.example.com"];
    XCTAssertTrue(status == ER_OK, @"Could not set Url for the About Icon");
    uint8_t aboutIconContent[] = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00,
        0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x0A,
        0x00, 0x00, 0x00, 0x0A, 0x08, 0x02, 0x00, 0x00, 0x00, 0x02,
        0x50, 0x58, 0xEA, 0x00, 0x00, 0x00, 0x04, 0x67, 0x41, 0x4D,
        0x41, 0x00, 0x00, 0xAF, 0xC8, 0x37, 0x05, 0x8A, 0xE9, 0x00,
        0x00, 0x00, 0x19, 0x74, 0x45, 0x58, 0x74, 0x53, 0x6F, 0x66,
        0x74, 0x77, 0x61, 0x72, 0x65, 0x00, 0x41, 0x64, 0x6F, 0x62,
        0x65, 0x20, 0x49, 0x6D, 0x61, 0x67, 0x65, 0x52, 0x65, 0x61,
        0x64, 0x79, 0x71, 0xC9, 0x65, 0x3C, 0x00, 0x00, 0x00, 0x18,
        0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x62, 0xFC, 0x3F, 0x95,
        0x9F, 0x01, 0x37, 0x60, 0x62, 0xC0, 0x0B, 0x46, 0xAA, 0x34,
        0x40, 0x80, 0x01, 0x00, 0x06, 0x7C, 0x01, 0xB7, 0xED, 0x4B,
        0x53, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
        0xAE, 0x42, 0x60, 0x82 };

    [aboutIcon setContentWithMimeType:@"image/png" data:aboutIconContent size:(sizeof(aboutIconContent) / sizeof(aboutIconContent[0])) ownsFlag:false];

    // Set AboutIconObject
    AJNAboutIconObject __unused *aboutIconObject = [[AJNAboutIconObject alloc] initWithBusAttachment:self.bus aboutIcon:aboutIcon]; //__unused applied because this object don't used directly, and due to this warning appears.

    //Client gets the About Icon
    AJNAboutIconProxy *aboutIconProxy = [[AJNAboutIconProxy alloc] initWithBusAttachment:client.bus busName:client.busNameToConnect sessionId:client.testSessionId];
    AJNAboutIcon *clientAboutIcon = [[AJNAboutIcon alloc] init];
    [aboutIconProxy getIcon:clientAboutIcon];

    // Check Url
    XCTAssertTrue([[clientAboutIcon getUrl] isEqualToString:[aboutIcon getUrl]], @"About Icon Url does not match");

    // Check content size
    XCTAssertTrue([clientAboutIcon getContentSize] == [aboutIcon getContentSize], @"About Icon content size does not match");

    // Check About Icon content
    uint8_t *clientAboutIconContent = [clientAboutIcon getContent];

    for (size_t i=0 ;i < [clientAboutIcon getContentSize] ; i++) {
        XCTAssertTrue((clientAboutIconContent[i] == aboutIconContent[i]), @"Mistmatch in About Icon content");
        if (clientAboutIconContent[i] != aboutIconContent[i]) {
            break;
        }

    }
    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testShouldHandleLargeAboutIcon
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    // Service sets the About Icon
    AJNAboutIcon *aboutIcon = [[AJNAboutIcon alloc] init];
    status = [aboutIcon setUrlWithMimeType:@"image/png" url:@"http://www.example.com"];
    XCTAssertTrue(status == ER_OK, @"Could not set Url for the About Icon");

    uint8_t aboutIconContent[MAX_ICON_SIZE_IN_BYTES];
    for (size_t iconByte = 0; iconByte < MAX_ICON_SIZE_IN_BYTES; iconByte++) {
        aboutIconContent[iconByte] = ICON_BYTE;
    }

    status = [aboutIcon setContentWithMimeType:@"image/png" data:aboutIconContent size:(sizeof(aboutIconContent) / sizeof(aboutIconContent[0])) ownsFlag:false];

    // Set AboutIconObject
    AJNAboutIconObject __unused *aboutIconObject = [[AJNAboutIconObject alloc] initWithBusAttachment:self.bus aboutIcon:aboutIcon]; //__unused applied because this object don't used directly, and due to this warning appears.

    //Client gets the About Icon
    AJNAboutIconProxy *aboutIconProxy = [[AJNAboutIconProxy alloc] initWithBusAttachment:client.bus busName:client.busNameToConnect sessionId:client.testSessionId];
    AJNAboutIcon *clientAboutIcon = [[AJNAboutIcon alloc] init];
    [aboutIconProxy getIcon:clientAboutIcon];

    // Check Url
    XCTAssertTrue([[clientAboutIcon getUrl] isEqualToString:[aboutIcon getUrl]], @"About Icon Url does not match");

    // Check content size
    XCTAssertTrue([clientAboutIcon getContentSize] == [aboutIcon getContentSize], @"About Icon content size does not match");

    // Check About Icon content
    uint8_t *clientAboutIconContent = [clientAboutIcon getContent];

    for (size_t i=0 ;i < [clientAboutIcon getContentSize] ; i++) {
        XCTAssertTrue((clientAboutIconContent[i] == aboutIconContent[i]), @"Mistmatch in About Icon content");
        if (clientAboutIconContent[i] != aboutIconContent[i]) {
            break;
        }

    }
    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testShouldFailLargeAboutIcon
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    // Service sets the About Icon
    AJNAboutIcon *aboutIcon = [[AJNAboutIcon alloc] init];
    status = [aboutIcon setUrlWithMimeType:@"image/png" url:@"http://www.example.com"];
    XCTAssertTrue(status == ER_OK, @"Could not set Url for the About Icon");

    uint8_t aboutIconContent[MAX_ICON_SIZE_IN_BYTES + 2];
    for (size_t iconByte = 0; iconByte < MAX_ICON_SIZE_IN_BYTES; iconByte++) {
        aboutIconContent[iconByte] = ICON_BYTE;
    }

    status = [aboutIcon setContentWithMimeType:@"image/png" data:aboutIconContent size:(sizeof(aboutIconContent) / sizeof(aboutIconContent[0])) ownsFlag:false];

    // Set AboutIconObject
    AJNAboutIconObject __unused *aboutIconObject = [[AJNAboutIconObject alloc] initWithBusAttachment:self.bus aboutIcon:aboutIcon]; //__unused applied because this object don't used directly, and due to this warning appears.

    //Client gets the About Icon
    AJNAboutIconProxy *aboutIconProxy = [[AJNAboutIconProxy alloc] initWithBusAttachment:client.bus busName:client.busNameToConnect sessionId:client.testSessionId];
    AJNAboutIcon *clientAboutIcon = [[AJNAboutIcon alloc] init];
    [aboutIconProxy getIcon:clientAboutIcon];

    // Check Url
    XCTAssertTrue([[clientAboutIcon getUrl] isEqualToString:[aboutIcon getUrl]], @"About Icon Url does not match");

    // Check content size
    XCTAssertTrue([clientAboutIcon getContentSize] == [aboutIcon getContentSize], @"About Icon content size does not match");

    // Check About Icon content
    uint8_t *clientAboutIconContent = [clientAboutIcon getContent];

    for (size_t i=0 ;i < [clientAboutIcon getContentSize] ; i++) {
        XCTAssertTrue((clientAboutIconContent[i] == aboutIconContent[i]), @"Mistmatch in About Icon content");
        if (clientAboutIconContent[i] != aboutIconContent[i]) {
            break;
        }

    }
    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testShouldHandleInconsistentAnnounceData
{
    self.testBadAnnounceData = YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_ABOUT_INVALID_ABOUTDATA_LISTENER, @"Inconsistent about announce and about data should be reported as error");

    [self.bus disconnect];
    [self.bus stop];
}

- (void)testShouldReportMissingFieldInAboutData
{
    self.testMissingAboutDataField = YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_ABOUT_INVALID_ABOUTDATA_LISTENER, @"Missing about data field should be reported as error");

    [self.bus disconnect];
    [self.bus stop];
}

- (void)testShouldReportMissingFieldInAnnounceData
{
    self.testMissingAnnounceDataField = YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_ABOUT_INVALID_ABOUTDATA_LISTENER, @"Missing about data field should be reported as error");

    [self.bus disconnect];
    [self.bus stop];
}

- (void)testShouldHandleUnsupportedLanguageForAbout
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;
    client.testUnsupportedLanguage= YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testForNonDefaultLanguageAbout
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;
    client.testUnsupportedLanguage= YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    // Create AboutProxy
    AJNAboutProxy *aboutProxy = [[AJNAboutProxy alloc] initWithBusAttachment:client.bus busName:client.busNameToConnect sessionId:client.testSessionId];

    NSMutableDictionary *aboutData;
    status = [aboutProxy getAboutDataForLanguage:@"en" usingDictionary:&aboutData];
    XCTAssertTrue(status == ER_OK, @"Non default language should not throw error");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testForNonDefaultLanguageUTFAbout
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;
    client.testNonDefaultUTFLanguage= YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    // Create AboutProxy
    AJNAboutProxy *aboutProxy = [[AJNAboutProxy alloc] initWithBusAttachment:client.bus busName:client.busNameToConnect sessionId:client.testSessionId];

    NSMutableDictionary *aboutData;
    status = [aboutProxy getAboutDataForLanguage:@"en" usingDictionary:&aboutData];
    XCTAssertTrue(status == ER_OK, @"Non default language should not throw error");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testForAboutProxyGetAboutObjectDescription
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];
    client.isTestClient = YES;
    client.testAboutObjectDescription = YES;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testWhoImplementsCallForWildCardPositive
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"*"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testWhoImplementsCallForNull
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    client.isTestClient = YES;
    client.didReceiveAnnounce = NO;

    // Service
    BasicObject *basicObject = [[BasicObject alloc] initWithBusAttachment:self.bus onPath:kBusObjectTestsObjectPath];
    [self.bus registerBusObject:basicObject];

    QStatus status = [self.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus failed to start.");
    status = [self.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Connection to bus via null transport failed.");

    AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:YES proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

    status = [self.bus bindSessionOnPort:kBusAttachmentTestsServicePort withOptions:sessionOptions withDelegate:self];
    XCTAssertTrue(status == ER_OK, @"Bind session on port %ld failed.", (long)kBusAttachmentTestsServicePort);

    AJNAboutObject *aboutObj = [[AJNAboutObject alloc] initWithBusAttachment:self.bus withAnnounceFlag:ANNOUNCED];
    status = [aboutObj announceForSessionPort:kBusAttachmentTestsServicePort withAboutDataListener:self];
    XCTAssertTrue(status == ER_OK, @"Bus failed to announce");

    // Client
    [client.bus registerAboutListener:client];
    status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:nil];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");

    XCTAssertTrue([client waitForCompletion:20 onFlag:&receiveAnnounce], @"The about listener should have been notified that the announce signal is received.");

    [self.bus disconnect];
    [self.bus stop];

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

- (void)testCancelWhoImplementsMismatch
{
    BusAttachmentTests *client = [[BusAttachmentTests alloc] init];
    [client setUp];

    // Client
    [client.bus registerAboutListener:client];
    QStatus status = [client.bus start];
    XCTAssertTrue(status == ER_OK, @"Bus for client failed to start.");
    status = [client.bus connectWithArguments:@"null:"];
    XCTAssertTrue(status == ER_OK, @"Client connection to bus via null transport failed.");
    status = [client.bus whoImplementsInterface:@"org.alljoyn.bus.sample.strings"];
    XCTAssertTrue(status == ER_OK, @"Client call to WhoImplements Failed");
    status = [client.bus cancelWhoImplementsInterface:@"org.alljoyn.bus.sample.strings.mismatch"];
    XCTAssertTrue(status == ER_BUS_MATCH_RULE_NOT_FOUND, @"Test for mismatched CancelWhoImplements Failed");

    [client.bus disconnect];
    [client.bus stop];

    [client.bus unregisterBusListener:self];
    [client.bus unregisterAllAboutListeners];
    [client tearDown];
}

#pragma mark - AJNAboutListener delegate methods

- (void)didReceiveAnnounceOnBus:(NSString *)busName withVersion:(uint16_t)version withSessionPort:(AJNSessionPort)port withObjectDescription:(AJNMessageArgument *)objectDescriptionArg withAboutDataArg:(AJNMessageArgument *)aboutDataArg
{

    NSLog(@"Received Announce signal from %s Version : %d SessionPort: %d", [busName UTF8String], version, port);

    self.didReceiveAnnounce = YES;

    if (self.isTestClient) {
        AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:NO proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];
        [self.bus enableConcurrentCallbacks];
        AJNSessionId sessionId = [self.bus joinSessionWithName:busName onPort:port withDelegate:self options:sessionOptions];
        self.testSessionId = sessionId;
        self.sessionPortToConnect = port;
        self.busNameToConnect = busName;

        // Create AboutProxy
        AJNAboutProxy *aboutProxy = [[AJNAboutProxy alloc] initWithBusAttachment:self.bus busName:busName sessionId:sessionId];

        // Make a call to GetAboutData and GetVersion
        uint16_t version;
        QStatus status;
        NSMutableDictionary *aboutData;
        [aboutProxy getVersion:&version];
        XCTAssertTrue(version == 1, @"Version value is incorrect");
        if (self.testUnsupportedLanguage == YES) {
            status = [aboutProxy getAboutDataForLanguage:@"bar" usingDictionary:&aboutData];
            XCTAssertTrue(status != ER_OK, @"Unsupported language not should throw error");
        } else {
            status = [aboutProxy getAboutDataForLanguage:@"en" usingDictionary:&aboutData];
            XCTAssertTrue(status == ER_OK, @"Default language not should throw error");
        }
        NSLog(@"Version %d Size %lu", version, [aboutData count]);
        // Verify data by comparing the data that you set with the data that you received
        XCTAssertTrue([gDefaultAboutData isEqualToDictionary:aboutData], @"The announce data is correct");

        if (self.testAboutObjectDescription == YES) {
            XCTAssertNotNil(objectDescriptionArg, @"Object Description message argument is invalid");

            AJNAboutObjectDescription *testInitWithMsgArg = [[AJNAboutObjectDescription alloc] initWithMsgArg:objectDescriptionArg];
            XCTAssertNotNil(testInitWithMsgArg, @"Fail");

            AJNAboutObjectDescription *aboutObjectDescription = [[AJNAboutObjectDescription alloc] init];
            [aboutObjectDescription createFromMsgArg:objectDescriptionArg];
            XCTAssertNotNil(aboutObjectDescription, @"Fail");

            BOOL test = [aboutObjectDescription hasPath:@"/basic_object"];
            XCTAssertTrue(test == YES, @"hasPath test failed");

            test = [aboutObjectDescription hasPath:@"/basic_"];
            XCTAssertFalse(test, @"Negative hasPath test failed");

            test = [aboutObjectDescription hasInterface:@"org.alljoyn.bus.sample.strings" withPath:@"/basic_object"];
            XCTAssertTrue(test == YES, @"hasInterface:withPath test failed");

            test = [aboutObjectDescription hasInterface:@"org.alljoyn.bus.sample.strings" withPath:@"/basic_"];
            XCTAssertFalse(test, @"hasInterface:withPath test failed");

            NSArray *paths = aboutObjectDescription.paths;
            XCTAssertTrue(paths.count == 2, @"getPaths:withSize test failed");

            NSArray *interfacePaths = [aboutObjectDescription getInterfacePathsForInterface:@"org.alljoyn.bus.sample.strings"];
            XCTAssertTrue(interfacePaths.count == 1, @"getPaths:withSize test failed");

            NSArray *interfaces = [aboutObjectDescription getInterfacesForPath:@"/basic_object"];
            XCTAssertTrue(interfaces.count == 2, @"getInterfacesForPath failed");

        }
        receiveAnnounce = YES;
    }

}

#pragma mark - AJNAboutDataListener delegate methods

- (QStatus)getAboutData:(AJNMessageArgument *__autoreleasing *)msgArg withLanguage:(NSString *)language
{
    AJNAboutData *aboutData = [[AJNAboutData alloc] initWithLanguage:@"en"];
    uint8_t originalAppId[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
    [aboutData setAppId:originalAppId];

    [aboutData setDefaultLanguage:@"en"];

    if (self.testBadAnnounceData == YES) {
        [aboutData setDeviceName:@"foo" andLanguage:@"en"];
    } else {
        [aboutData setDeviceName:@"Device Name" andLanguage:@"en"];
    }

    if (self.testMissingAboutDataField == YES) {
        [aboutData setDeviceId:@""];
    } else {
        [aboutData setDeviceId:@"avec-awe1213-1234559xvc123"];
    }

    if (self.testMissingAnnounceDataField == YES) {
        [aboutData setAppName:@"" andLanguage:@"en"];
    } else {
        [aboutData setAppName:@"App Name" andLanguage:@"en"];
    }

    [aboutData setManufacturer:@"Manufacturer" andLanguage:@"en"];

    [aboutData setModelNumber:@"ModelNo"];

    [aboutData setSupportedLanguage:@"en"];
    [aboutData setSupportedLanguage:@"foo"];

    if (self.testNonDefaultUTFLanguage == YES) {
        [aboutData setDescription:@"Sólo se puede aceptar cadenas distintas de cadenas nada debe hacerse utilizando el método" andLanguage:@"foo"];
    } else {
        [aboutData setDescription:@"Description" andLanguage:@"en"];
    }

    [aboutData setDateOfManufacture:@"1-1-2014"];

    [aboutData setSoftwareVersion:@"1.0"];

    [aboutData setHardwareVersion:@"00.00.01"];

    [aboutData setSupportUrl:@"some.random.url"];

    return [aboutData getAboutData:msgArg withLanguage:language];
}

- (QStatus)getAnnouncedAboutData:(AJNMessageArgument *__autoreleasing *)msgArg
{
    AJNAboutData *aboutData = [[AJNAboutData alloc] initWithLanguage:@"en"];
    uint8_t originalAppId[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
    [aboutData setAppId:originalAppId];

    [aboutData setDefaultLanguage:@"en"];

    [aboutData setDeviceName:@"Device Name" andLanguage:@"en"];

    [aboutData setDeviceId:@"avec-awe1213-1234559xvc123"];

    [aboutData setAppName:@"App Name" andLanguage:@"en"];

    [aboutData setManufacturer:@"Manufacturer" andLanguage:@"en"];

    [aboutData setModelNumber:@"ModelNo"];

    [aboutData setSupportedLanguage:@"en"];
    [aboutData setSupportedLanguage:@"foo"];

    if (self.testNonDefaultUTFLanguage == YES) {
        [aboutData setDescription:@"Sólo se puede aceptar cadenas distintas de cadenas nada debe hacerse utilizando el método" andLanguage:@"foo"];
    } else {
        [aboutData setDescription:@"Description" andLanguage:@"en"];
    }

    [aboutData setDateOfManufacture:@"1-1-2014"];

    [aboutData setSoftwareVersion:@"1.0"];

    [aboutData setHardwareVersion:@"00.00.01"];

    [aboutData setSupportUrl:@"some.random.url"];

    return [aboutData getAnnouncedAboutData:msgArg];
}

#pragma mark - Asynchronous test case support

- (BOOL)waitForBusToStop:(NSTimeInterval)timeoutSeconds
{
    return [self waitForCompletion:timeoutSeconds onFlag:&_busWillStopCompleted];
}

- (BOOL)waitForCompletion:(NSTimeInterval)timeoutSeconds onFlag:(BOOL*)flag
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSeconds];

    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
        if ([timeoutDate timeIntervalSinceNow] < 0.0) {
            break;
        }
    } while (!*flag);

    return *flag;
}

#pragma mark - AJNBusListener delegate methods

- (void)listenerDidRegisterWithBus:(AJNBusAttachment*)busAttachment
{
    NSLog(@"AJNBusListener::listenerDidRegisterWithBus:%@",busAttachment);
    self.listenerDidRegisterWithBusCompleted = YES;
}

- (void)listenerDidUnregisterWithBus:(AJNBusAttachment*)busAttachment
{
    NSLog(@"AJNBusListener::listenerDidUnregisterWithBus:%@",busAttachment);
    self.listenerDidUnregisterWithBusCompleted = YES;
}

- (void)didFindAdvertisedName:(NSString*)name withTransportMask:(AJNTransportMask)transport namePrefix:(NSString*)namePrefix
{
    NSLog(@"AJNBusListener::didFindAdvertisedName:%@ withTransportMask:%u namePrefix:%@", name, transport, namePrefix);
    if ([name compare:kBusAttachmentTestsAdvertisedName] == NSOrderedSame) {
        self.didFindAdvertisedNameCompleted = YES;
        if (self.isTestClient) {

            [self.bus enableConcurrentCallbacks];

            AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:NO proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

            self.testSessionId = [self.bus joinSessionWithName:name onPort:kBusAttachmentTestsServicePort withDelegate:self options:sessionOptions];
            XCTAssertTrue(self.testSessionId != -1, @"Test client failed to connect to the service %@ on port %ld", name, (long)kBusAttachmentTestsServicePort);

            self.clientConnectionCompleted = YES;
        }
        else if (self.isAsyncTestClientBlock) {

            [self.bus enableConcurrentCallbacks];

            AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:NO proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

            [self.bus joinSessionAsyncWithName:name onPort:kBusAttachmentTestsServicePort withDelegate:self options:sessionOptions joinCompletedBlock:^(QStatus status, AJNSessionId sessionId, AJNSessionOptions *opts, void *context) {
                self.testSessionId = sessionId;
                XCTAssertTrue(self.testSessionId != -1, @"Test client failed to connect asynchronously using block to the service on port %ld", (long)kBusAttachmentTestsServicePort);

                self.clientConnectionCompleted = YES;

            } context:nil];
        }
        else if (self.isAsyncTestClientDelegate) {

            [self.bus enableConcurrentCallbacks];

            AJNSessionOptions *sessionOptions = [[AJNSessionOptions alloc] initWithTrafficType:kAJNTrafficMessages supportsMultipoint:NO proximity:kAJNProximityAny transportMask:kAJNTransportMaskAny];

            [self.bus joinSessionAsyncWithName:name onPort:kBusAttachmentTestsServicePort withDelegate:self options:sessionOptions joinCompletedDelegate:self context:nil];
        }
    }
}

- (void) pingPeerHasStatus:(QStatus)status context:(void *)context
{
    NSLog(@"Ping Peer Async callback");
    XCTAssertTrue(status == ER_OK, @"Ping Peer Async failed");
    self.isPingAsyncComplete = YES;
}

- (void)didLoseAdvertisedName:(NSString*)name withTransportMask:(AJNTransportMask)transport namePrefix:(NSString*)namePrefix
{
    NSLog(@"AJNBusListener::listenerDidUnregisterWithBus:%@ withTransportMask:%u namePrefix:%@",name,transport,namePrefix);
    self.didLoseAdvertisedNameCompleted = YES;
}

- (void)nameOwnerChanged:(NSString*)name to:(NSString*)newOwner from:(NSString*)previousOwner
{
    NSLog(@"AJNBusListener::nameOwnerChanged:%@ to:%@ from:%@", name, newOwner, previousOwner);
    if ([name compare:kBusAttachmentTestsAdvertisedName] == NSOrderedSame) {
        self.nameOwnerChangedCompleted = YES;
    }
}

- (void)busWillStop
{
    NSLog(@"AJNBusListener::busWillStop");
    self.busWillStopCompleted = YES;
}

- (void)busDidDisconnect
{
    NSLog(@"AJNBusListener::busDidDisconnect");
    self.busDidDisconnectCompleted = YES;
}

#pragma mark - AJNSessionListener methods

- (void)sessionWasLost:(AJNSessionId)sessionId forReason:(AJNSessionLostReason)reason
{
    NSLog(@"AJNBusListener::sessionWasLost %u", sessionId);
    if (self.testSessionId == sessionId) {
        self.sessionWasLost = YES;
    }

}

- (void)didAddMemberNamed:(NSString*)memberName toSession:(AJNSessionId)sessionId
{
    NSLog(@"AJNBusListener::didAddMemberNamed:%@ toSession:%u", memberName, sessionId);
    if (self.testSessionId == sessionId) {
        self.didAddMemberNamed = YES;
    }
}

- (void)didRemoveMemberNamed:(NSString*)memberName fromSession:(AJNSessionId)sessionId
{
    NSLog(@"AJNBusListener::didRemoveMemberNamed:%@ fromSession:%u", memberName, sessionId);
    if (self.testSessionId == sessionId) {
        self.didRemoveMemberNamed = YES;
    }
}

#pragma mark - AJNSessionPortListener implementation

- (BOOL)shouldAcceptSessionJoinerNamed:(NSString*)joiner onSessionPort:(AJNSessionPort)sessionPort withSessionOptions:(AJNSessionOptions*)options
{
    NSLog(@"AJNSessionPortListener::shouldAcceptSessionJoinerNamed:%@ onSessionPort:%u withSessionOptions:", joiner, sessionPort);
    if (sessionPort == kBusAttachmentTestsServicePort) {
        self.shouldAcceptSessionJoinerNamed = YES;
        return YES;
    }
    return NO;
}

- (void)didJoin:(NSString*)joiner inSessionWithId:(AJNSessionId)sessionId onSessionPort:(AJNSessionPort)sessionPort
{
    NSLog(@"AJNSessionPortListener::didJoin:%@ inSessionWithId:%u onSessionPort:%u withSessionOptions:", joiner, sessionId, sessionPort);
    if (sessionPort == kBusAttachmentTestsServicePort) {
        self.testSessionId = sessionId;
        self.didJoinInSession = YES;
    }
}

#pragma mark - AJNSessionDelegate implementation

- (void)didJoinSession:(AJNSessionId)sessionId status:(QStatus)status sessionOptions:(AJNSessionOptions *)sessionOptions context:(AJNHandle)context
{
    self.testSessionId = sessionId;
    XCTAssertTrue(self.testSessionId != -1, @"Test client failed to connect asynchronously using delegate to the service on port %ld", (long)kBusAttachmentTestsServicePort);

    self.clientConnectionCompleted = YES;

}

@end

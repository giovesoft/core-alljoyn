////////////////////////////////////////////////////////////////////////////////
// Copyright AllSeen Alliance. All rights reserved.
//
//    Permission to use, copy, modify, and/or distribute this software for any
//    purpose with or without fee is hereby granted, provided that the above
//    copyright notice and this permission notice appear in all copies.
//
//    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
//    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
//    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
////////////////////////////////////////////////////////////////////////////////

#import <alljoyn/InterfaceDescription.h>
#import "AJNInterfaceDescription.h"
#import "AJNTranslatorImpl.h"
#import "AJNBusAttachment.h"

@interface AJNBusAttachment()
- (void)holdTranslatorImpl:(void*)translatorImpl;
@end

@interface AJNInterfaceDescription()

/**
 * Helper to return the C++ API object that is encapsulated by this objective-c class
 */
@property (nonatomic, readonly) ajn::InterfaceDescription* interfaceDescription;

@end

@implementation AJNInterfaceDescription

/**
 * Helper to return the C++ API object that is encapsulated by this objective-c class
 */
- (ajn::InterfaceDescription*)interfaceDescription
{
    return static_cast<ajn::InterfaceDescription*>(self.handle);
}

- (NSString*)name
{
    return [NSString stringWithCString:self.interfaceDescription->GetName() encoding:NSUTF8StringEncoding];
}

- (NSArray*)members
{
    size_t memberCount = self.interfaceDescription->GetMembers();
    NSMutableArray *members = [[NSMutableArray alloc] initWithCapacity:memberCount];
    const ajn::InterfaceDescription::Member** pInterfaceMembers = new const ajn::InterfaceDescription::Member *[memberCount];
    self.interfaceDescription->GetMembers(pInterfaceMembers, memberCount);
    for (int i = 0; i < memberCount; i++) {
        const ajn::InterfaceDescription::Member *member = pInterfaceMembers[i];
        [members addObject:[[AJNInterfaceMember alloc] initWithHandle:(AJNHandle)member]];
    }
    delete [] pInterfaceMembers;
    return members;
}

- (NSArray*)properties
{
    size_t propertyCount = self.interfaceDescription->GetProperties();
    NSMutableArray *properties = [[NSMutableArray alloc] initWithCapacity:propertyCount];
    const ajn::InterfaceDescription::Property** pInterfaceProperties = new const ajn::InterfaceDescription::Property *[propertyCount];
    self.interfaceDescription->GetProperties(pInterfaceProperties, propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        const ajn::InterfaceDescription::Property *property = pInterfaceProperties[i];
        [properties addObject:[[AJNInterfaceProperty alloc] initWithHandle:(AJNHandle)property]];
    }
    delete [] pInterfaceProperties;
    return properties;
}

- (NSString*)xmlDescription
{
    return [NSString stringWithCString:self.interfaceDescription->Introspect(2).c_str() encoding:NSUTF8StringEncoding];
}

- (NSString *)language
{
    return [NSString stringWithCString:self.interfaceDescription->GetDescriptionLanguage() encoding:NSUTF8StringEncoding];
}

- (NSSet*)languages
{
    std::set<qcc::String> languagesSet = self.interfaceDescription->GetDescriptionLanguages();
    NSMutableSet *ajnLanguages = [[NSMutableSet alloc] initWithCapacity:languagesSet.size()];
    
    for (auto &it : languagesSet) {
        NSString* str = [NSString stringWithCString:it.c_str() encoding:NSUTF8StringEncoding];
        [ajnLanguages addObject:str];
    }
    
    return ajnLanguages;
}

- (BOOL)isSecure
{
    return self.interfaceDescription->IsSecure();
}

- (BOOL)hasProperties
{
    return self.interfaceDescription->HasProperties() ? YES : NO;
}

- (BOOL)hasCacheableProperties
{
    return self.interfaceDescription->HasCacheableProperties() ? YES : NO;
}

- (BOOL)hasDescription
{
    return self.interfaceDescription->HasDescription() ? YES : NO;
}

- (AJNInterfaceSecurityPolicy) securityPolicy
{
    return (AJNInterfaceSecurityPolicy)self.interfaceDescription->GetSecurityPolicy();
}

- (QStatus)addMember:(AJNMessageType)type name:(NSString *)name inputSig:(NSString *)inputSig outSig:(NSString *)outSig argNames:(NSString *)argNames
{
    return self.interfaceDescription->AddMember((ajn::AllJoynMessageType)type, [name UTF8String], [inputSig UTF8String], [outSig UTF8String], [argNames UTF8String]);
}

- (QStatus)addMember:(AJNMessageType)type name:(NSString *)name inputSig:(NSString *)inputSig outSig:(NSString *)outSig argNames:(NSString *)argNames annotation:(uint8_t)annotation accessPerms:(NSString *)accessPerms
{
    return self.interfaceDescription->AddMember((ajn::AllJoynMessageType)type, [name UTF8String], [inputSig UTF8String], [outSig UTF8String], [argNames UTF8String], annotation, [accessPerms UTF8String]);
}

- (QStatus)addMethodWithName:(NSString*)methodName inputSignature:(NSString*)inputSignature outputSignature:(NSString*)outputSignature argumentNames:(NSArray*)arguments annotation:(AJNInterfaceAnnotationFlags)annotation accessPermissions:(NSString*)accessPermissions
{
    QStatus result = ER_OK;
    if (self.interfaceDescription) {
        result = self.interfaceDescription->AddMethod([methodName UTF8String], [inputSignature UTF8String], [outputSignature UTF8String], [[arguments componentsJoinedByString:@","] UTF8String], annotation, [accessPermissions UTF8String]);
        if (result != ER_OK && result != ER_BUS_MEMBER_ALREADY_EXISTS) {
            NSLog(@"ERROR: Failed to create method named %@. %s", methodName, QCC_StatusText(result) );
        }
    }
    return result;
}

- (QStatus)addMethodWithName:(NSString*)methodName inputSignature:(NSString*)inputSignature outputSignature:(NSString*)outputSignature argumentNames:(NSArray*)arguments annotation:(AJNInterfaceAnnotationFlags)annotation
{
    return [self addMethodWithName:methodName inputSignature:inputSignature outputSignature:outputSignature argumentNames:arguments annotation:annotation accessPermissions:nil];
}

- (QStatus)addMethodWithName:(NSString*)methodName inputSignature:(NSString*)inputSignature outputSignature:(NSString*)outputSignature argumentNames:(NSArray*)arguments
{
    return [self addMethodWithName:methodName inputSignature:inputSignature outputSignature:outputSignature argumentNames:arguments annotation:0 accessPermissions:nil];
}

- (AJNInterfaceMember*)methodWithName:(NSString *)methodName
{
    return [[AJNInterfaceMember alloc] initWithHandle:(AJNHandle)self.interfaceDescription->GetMethod([methodName UTF8String])];
}

- (QStatus) addSignalWithName:(NSString*)name
{
    QStatus result = ER_OK;
    if (self.interfaceDescription) {
        result = self.interfaceDescription->AddSignal([name UTF8String], "", "", 0);
        if (result != ER_OK && result != ER_BUS_MEMBER_ALREADY_EXISTS) {
            NSLog(@"ERROR: Failed to create signal named %@. %s", name, QCC_StatusText(result) );
        }
    }
    return result;
}

- (QStatus) addSignalWithName:(NSString *)name inputSignature:(NSString *)inputSignature argumentNames:(NSArray *)arguments
{
    return [self addSignalWithName:name inputSignature:inputSignature argumentNames:arguments annotation:0 accessPermissions:nil];
}

- (QStatus)addSignalWithName:(NSString *)name inputSignature:(NSString *)inputSignature argumentNames:(NSArray *)arguments annotation:(AJNInterfaceAnnotationFlags)annotation
{
    return [self addSignalWithName:name inputSignature:inputSignature argumentNames:arguments annotation:annotation accessPermissions:nil];
}

- (QStatus)addSignalWithName:(NSString *)name inputSignature:(NSString *)inputSignature argumentNames:(NSArray *)arguments annotation:(AJNInterfaceAnnotationFlags)annotation accessPermissions:(NSString *)permissions
{
    QStatus result = ER_OK;
    if (self.interfaceDescription) {
        result = self.interfaceDescription->AddSignal([name UTF8String], [inputSignature UTF8String], [[arguments componentsJoinedByString:@","] UTF8String], annotation, [permissions UTF8String]);
        if (result != ER_OK && result != ER_BUS_MEMBER_ALREADY_EXISTS) {
            NSLog(@"ERROR: Failed to create signal named %@. %s", name, QCC_StatusText(result) );
        }
    }
    return result;
}

- (AJNInterfaceMember*)signalWithName:(NSString *)signalName
{
    return [[AJNInterfaceMember alloc] initWithHandle:(AJNHandle)self.interfaceDescription->GetSignal([signalName UTF8String])];
}

- (QStatus)addPropertyWithName:(NSString*)name signature:(NSString*)signature accessPermissions:(AJNInterfacePropertyAccessPermissionsFlags)permissions
{
    QStatus result = ER_OK;
    if (self.interfaceDescription) {
        result = self.interfaceDescription->AddProperty([name UTF8String], [signature UTF8String], permissions);
        if (result != ER_OK && result != ER_BUS_MEMBER_ALREADY_EXISTS) {
            NSLog(@"ERROR: Failed to create signal named %@. %s", name, QCC_StatusText(result) );
        }
    }
    return result;
}

- (AJNInterfaceProperty*)propertyWithName:(NSString *)propertyName
{
    return [[AJNInterfaceProperty alloc] initWithHandle:(AJNHandle)self.interfaceDescription->GetProperty([propertyName UTF8String])];
}

- (BOOL)hasPropertyWithName:(NSString *)propertyName
{
    return self.interfaceDescription->HasProperty([propertyName UTF8String]);
}

- (AJNInterfaceMember*)memberWithName:(NSString*)name
{
    const ajn::InterfaceDescription::Member *member = self.interfaceDescription->GetMember([name UTF8String]);
    AJNInterfaceMember *interfaceMember;
    if (member) {
        interfaceMember = [[AJNInterfaceMember alloc] initWithHandle:(AJNHandle)member];
    }
    return interfaceMember;
}

- (BOOL)hasMemberWithName:(NSString *)name inputSignature:(NSString *)inputs outputSignature:(NSString *)outputs
{
    return self.interfaceDescription->HasMember([name UTF8String], [inputs UTF8String], [outputs UTF8String]) ? YES : NO;
}

- (NSString *)annotationWithName:(NSString *)annotationName
{
    NSString *annotationValue;
    qcc::String value;
    qcc::String name = [annotationName UTF8String];
    bool result = self.interfaceDescription->GetAnnotation(name, value);
    if (result) {
        annotationValue = [NSString stringWithCString:value.c_str() encoding:NSUTF8StringEncoding];
    }
    return annotationValue;
}

- (QStatus)addAnnotationWithName:(NSString *)annotationName value:(NSString *)annotationValue
{
    QStatus status;
    qcc::String name = [annotationName UTF8String];
    qcc::String value = [annotationValue UTF8String];
    status = self.interfaceDescription->AddAnnotation(name, value);
    return status;
}


- (NSString *)memberAnnotationWithName:(NSString *)annotationName forMemberWithName:(NSString *)memberName
{
    NSString *annotationValue;
    qcc::String value;
    qcc::String name = [annotationName UTF8String];
    bool result = self.interfaceDescription->GetMemberAnnotation([memberName UTF8String], name, value);
    if (result) {
        annotationValue = [NSString stringWithCString:value.c_str() encoding:NSUTF8StringEncoding];
    }
    return annotationValue;
}

- (QStatus)addMemberAnnotationWithName:(NSString *)annotationName value:(NSString *)annotationValue forMemberWithName:(NSString *)memberName
{
    QStatus status;
    qcc::String name = [annotationName UTF8String];
    qcc::String value = [annotationValue UTF8String];
    status = self.interfaceDescription->AddMemberAnnotation([memberName UTF8String], name, value);
    return status;
}

- (NSString *)annotationWithName:(NSString *)annotationName forPropertyWithName:(NSString *)propertyName
{
    NSString *annotationValue;
    qcc::String value;
    qcc::String name = [annotationName UTF8String];
    bool result = self.interfaceDescription->GetPropertyAnnotation([propertyName UTF8String], name, value);
    if (result) {
        annotationValue = [NSString stringWithCString:value.c_str() encoding:NSUTF8StringEncoding];
    }
    return annotationValue;
}

- (QStatus)addPropertyAnnotationWithName:(NSString *)annotationName value:(NSString *)annotationValue forPropertyWithName:(NSString *)propertyName
{
    QStatus status;
    qcc::String name = [annotationName UTF8String];
    qcc::String value = [annotationValue UTF8String];
    status = self.interfaceDescription->AddPropertyAnnotation([propertyName UTF8String], name, value);
    return status;
}

- (QStatus)addArgAnnotationWithName:(NSString *)member arg:(NSString *)arg name:(NSString *)name value:(NSString *)value
{
    qcc::String annotationName = [name UTF8String];
    qcc::String annotationValue = [value UTF8String];
    return self.interfaceDescription->AddArgAnnotation([member UTF8String], [arg UTF8String], annotationName, annotationValue);
}

- (NSString *)getArgAnnotationWithName:(NSString *)member arg:(NSString *)arg name:(NSString *)name
{
    NSString *argAnnotation;
    qcc::String value;
    qcc::String annotationName = [name UTF8String];
    bool result = self.interfaceDescription->GetArgAnnotation([member UTF8String], [arg UTF8String], annotationName, value);
    if (result) {
        argAnnotation = [NSString stringWithCString:value.c_str() encoding:NSUTF8StringEncoding];
    }
    return argAnnotation;
}

- (void)setDescriptionLanguage:(NSString *)language
{
    if(self.interfaceDescription){
        self.interfaceDescription->SetDescriptionLanguage([language UTF8String]);
    }
}
- (void)setDescription:(NSString *)description
{
    if(self.interfaceDescription){
        self.interfaceDescription->SetDescription([description UTF8String]);
    }
}

- (QStatus)setDescriptionForLanguage:(NSString*)description forLanguage:(NSString*)languageTag
{
    return self.interfaceDescription->SetDescriptionForLanguage([description UTF8String], [languageTag UTF8String]);
}

- (QStatus)setMemberDescription:(NSString *)description forMemberWithName:(NSString *)member
{
    return self.interfaceDescription->SetMemberDescription([member UTF8String], [description UTF8String]);
}

- (NSString*)descriptionForLanguage:(NSString*)languageTag
{
    qcc::String givenDescription;
    if (self.interfaceDescription->GetDescriptionForLanguage(givenDescription, [languageTag UTF8String]))
    {
        return [NSString stringWithCString:givenDescription.c_str() encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}


- (QStatus)setMemberDescription:(NSString *)description forMemberWithName:(NSString *)member sessionlessSignal:(BOOL)sessionless
{
    return self.interfaceDescription->SetMemberDescription([member UTF8String], [description UTF8String], sessionless);
}

 - (QStatus)setMemberDescriptionForLanguage:(NSString*)member withDescription:(NSString*)description forLanguage:(NSString*)languageTag
{
    return self.interfaceDescription->SetMemberDescriptionForLanguage([member UTF8String], [description UTF8String], [languageTag UTF8String]);
}

- (NSString*)memberDescriptionForLanguage:(NSString*)memberName forLanguage:(NSString*)languageTag
{
    qcc::String description;
    if (self.interfaceDescription->GetMemberDescriptionForLanguage([memberName UTF8String], description, [languageTag UTF8String])) {
        return [NSString stringWithCString:description.c_str() encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (QStatus)setPropertyDescription:(NSString *)description forPropertyWithName:(NSString *)propName
{
    return self.interfaceDescription->SetPropertyDescription([propName UTF8String], [description UTF8String]);
}

- (QStatus)setPropertyDescriptionForLanguage:(NSString*)propertyName withDescription:(NSString*)description withLanguage:(NSString*)languageTag
{
    return self.interfaceDescription->SetPropertyDescriptionForLanguage([propertyName UTF8String], [description UTF8String], [languageTag UTF8String]);
}

- (NSString*)propertyDescriptionForLanguage:(NSString*)propertyName withLanguage:(NSString*)languageTag
{
    qcc::String description;
    if (self.interfaceDescription->GetPropertyDescriptionForLanguage([propertyName UTF8String], description, [languageTag UTF8String])) {
        return [NSString stringWithCString:description.c_str() encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (QStatus)setArgDescription:(NSString *)description forArgument:(NSString *)argName ofMember:(NSString *)member
{
    return self.interfaceDescription->SetArgDescription([member  UTF8String], [argName UTF8String], [description UTF8String]);
}

- (QStatus)setArgDescriptionForLanguage:(NSString*)memberName forArg:(NSString*)argName withDescription:(NSString*)description withLanguage:(NSString*)languageTag
{
    return self.interfaceDescription->SetArgDescriptionForLanguage([memberName UTF8String], [argName UTF8String], [description UTF8String], [languageTag UTF8String]);
}

- (NSString*)argDescriptionForLanguage:(NSString*)memberName forArg:(NSString*)argName withDescription:(NSString*)description withLanguage:(NSString*)languageTag;
{
    qcc::String argDescription;
    
    if (self.interfaceDescription->GetArgDescriptionForLanguage([memberName UTF8String], [argName UTF8String], argDescription, [languageTag UTF8String])) {
        return [NSString stringWithCString:argDescription.c_str() encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (void)setDescriptionTranslator:(id<AJNTranslator>)translator
{
    AJNTranslatorImpl* translatorImpl = new AJNTranslatorImpl(translator);
    [self interfaceDescription]->SetDescriptionTranslator(translatorImpl);
    [self.bus holdTranslatorImpl:translatorImpl];
}

- (void)activate
{
    if (self.interfaceDescription) {
        self.interfaceDescription->Activate();
    }
}

- (id)initWithHandle:(AJNHandle)handle
{
    return [super initWithHandle:handle];
}

- (id)initWithHandle:(AJNHandle)handle shouldDeleteHandleOnDealloc:(BOOL)deletionFlag;
{
    return [super initWithHandle:handle shouldDeleteHandleOnDealloc:deletionFlag];
}


@end

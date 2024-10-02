//
//  GeometryConverter.h
//  IFC SimpleView
//
//  Created by Danil Andreevich on 15.09.24.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface GeometryConverter: NSObject

+ (SCNView *)extractGeometry:(const char*)filePath;

@end

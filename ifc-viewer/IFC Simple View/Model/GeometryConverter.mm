//
//  GeometryConverter.mm
//  IFC SimpleView
//
//  Created by Danil Andreevich on 15.09.24.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "GeometryConverter.h"
#include "ifcparse/IfcParse.h"
#include "ifcgeom/Iterator.h"
#include "ifcgeom/IteratorSettings.h"

@implementation GeometryConverter

+ (SCNView *)extractGeometry:(const char*)filePath{
    
    IfcParse::IfcFile file(filePath);
    if (!file.good()) {
        std::cerr << "Error: Failed to load IFC file from " << filePath << std::endl;
    }
    
    ifcopenshell::geometry::Settings settings_;
    try {
        settings_.set("use-world-coords", true);
    } catch (const std::exception& e) {
        std::cerr << "Exception caught while setting 'use-world-coords': " << e.what() << std::endl;
        return nil;
    }
    
    try {
        settings_.set("weld-vertices", false);
    } catch (const std::exception& e) {
        std::cerr << "Exception caught while setting 'weld-vertices': " << e.what() << std::endl;
        return nil;
    }
    
    try {
        settings_.set("apply-default-materials", true);
    } catch (const std::exception& e) {
        std::cerr << "Exception caught while setting 'apply-default-materials': " << e.what() << std::endl;
        return nil;
    }
    
    IfcGeom::Iterator* it = new IfcGeom::Iterator(*(&settings_), &file);
    
    if (!it->initialize()) {
        std::cout << "Failed to initialize the iterator";
        delete it;
    }
    
    SCNView *sceneView = [[SCNView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    SCNScene *scene = [SCNScene new];
    
    
    do {
        const IfcGeom::TriangulationElement* triElem = static_cast<const IfcGeom::TriangulationElement*>(it->get());
        
        const boost::shared_ptr<IfcGeom::Representation::Triangulation>& triElemGeom = triElem->geometry_pointer();
        
        const std::vector<int>& elemFaces = triElemGeom->faces();
        const std::vector<double>& elemVertices = triElemGeom->verts();
        const std::vector<ifcopenshell::geometry::taxonomy::style::ptr>& elemMats = triElemGeom->materials();
        const std::vector<int>& elemMatIds = triElemGeom->material_ids();
        
        std::vector<SCNVector3> vertices;
        for (size_t i = 0; i < elemVertices.size(); i += 3) {
            SCNVector3 vertex = SCNVector3Make(elemVertices[i], elemVertices[i + 1], elemVertices[i + 2]);
            vertices.push_back(vertex);
        }
        
        SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices.data() count:vertices.size()];
        
        
        NSMutableArray<SCNGeometryElement *> *geometryElements = [NSMutableArray array];
        NSMutableArray<SCNMaterial *> *materials = [NSMutableArray array];
        
        for (size_t i = 0; i < elemFaces.size(); i += 3) {
            int data[3] = { elemFaces[i], elemFaces[i + 1], elemFaces[i + 2] };
            NSData *faceData = [NSData dataWithBytes:data length:3 * sizeof(int)];
            SCNGeometryElement *geometryElement = [SCNGeometryElement geometryElementWithData:faceData primitiveType:SCNGeometryPrimitiveTypeTriangles primitiveCount:1 bytesPerIndex:sizeof(int)];
            [geometryElements addObject:geometryElement];
            
            ifcopenshell::geometry::taxonomy::style::ptr mat = elemMats[elemMatIds[i / 3]];
            SCNMaterial *material = [SCNMaterial new];
            material.diffuse.contents = [NSColor colorWithCalibratedRed:mat->diffuse.r() green:mat->diffuse.g() blue:mat->diffuse.b() alpha:1.0];
            material.specular.contents = [NSColor colorWithCalibratedRed:mat->specular.r() green:mat->specular.g() blue:mat->specular.b() alpha:1.0];
            
            // TODO: check if DefaultMaterial is rendered correctly
            if (mat->has_transparency()) {
                material.transparent.contents = [NSNumber numberWithDouble:1.0 - mat->transparency];
            } else {
                material.transparent.contents = [NSNumber numberWithDouble:0.0];
            }
            if (mat->has_specularity()) {
                material.specular.contents = [NSNumber numberWithDouble:1.0 - mat->specularity];
            } else {
                material.specular.contents = [NSNumber numberWithDouble:0.0];
            }
            [materials addObject:material];
        }
        
        SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource] elements:geometryElements];
        
        geometry.materials = materials;
        
        SCNNode *node = [SCNNode nodeWithGeometry:geometry];
        [scene.rootNode addChildNode:node];
        
        std::string elemInfo = triElem->type();
        elemInfo += triElem->name() == "" ? "" : ": " + triElem->name() + " geometry added";
        std::cout << elemInfo + "\n";
        
    } while (it->next());
    
    delete it;
    
    sceneView.scene = scene;
    sceneView.allowsCameraControl = YES;
    sceneView.autoenablesDefaultLighting = YES;
    
    return sceneView;
}
@end

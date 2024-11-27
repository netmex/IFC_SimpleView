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
    
    // "Use-world-coords" specifies whether to apply the local placements of building elements directly to the coordinates of the representation mesh rather than to represent the local placement in the 4x3 matrix, which will in that case be the identity matrix.
    try {
        settings_.set("use-world-coords", true);
    } catch (const std::exception& e) {
        std::cerr << "Exception caught while setting 'use-world-coords': " << e.what() << std::endl;
        return nil;
    }
    
    // "Weld-vertices" specifies whether vertices are welded, meaning that the coordinates vector will only contain unique xyz-triplets. This results in a manifold mesh which is useful for modelling applications, but might result in unwanted shading artefacts in rendering applications.
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
    
    int numThreads = std::thread::hardware_concurrency();
    IfcGeom::Iterator* it = new IfcGeom::Iterator("opencascade", *(&settings_), &file, numThreads);


    if (!it->initialize()) {
        std::cout << "Failed to initialize the iterator";
        delete it;
    }
    
    SCNView *sceneView = [[SCNView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    SCNScene *scene = [SCNScene new];
    
    do {
        const IfcGeom::TriangulationElement* triElem = static_cast<const IfcGeom::TriangulationElement*>(it->get());
        
        if (triElem->type() == "IfcOpeningElement" || triElem->type() == "IfcSpace") {
            continue;
        }
        
        const boost::shared_ptr<IfcGeom::Representation::Triangulation>& triElemGeom = triElem->geometry_pointer();
        
        const std::vector<int>& elemFaces = triElemGeom->faces();
        const std::vector<double>& elemVertices = triElemGeom->verts();
        const std::vector<ifcopenshell::geometry::taxonomy::style::ptr>& elemMats = triElemGeom->materials();
        const std::vector<int>& elemMatIds = triElemGeom->material_ids();
        
        /* Creating vertex source for building geometry later*/
        std::vector<SCNVector3> vertices;
        for (size_t i = 0; i < elemVertices.size(); i += 3) {
            SCNVector3 vertex = SCNVector3Make(elemVertices[i], elemVertices[i + 1], elemVertices[i + 2]);
            vertices.push_back(vertex);
        }
        SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices.data() count:vertices.size()];
        
        /* Material preprocessing */
        NSMutableArray<SCNMaterial *> *materialCache = [NSMutableArray arrayWithCapacity:elemMats.size() * sizeof(SCNMaterial*)];
        for (const auto& mat : elemMats) {
            SCNMaterial *material = [SCNMaterial new];
            material.diffuse.contents = [NSColor colorWithCalibratedRed:mat->diffuse.r() green:mat->diffuse.g() blue:mat->diffuse.b() alpha:(mat->has_transparency()? 1.0 - mat->transparency : 1.0)];
            material.specular.contents = [NSColor colorWithCalibratedRed:mat->specular.r() green:mat->specular.g() blue:mat->specular.b() alpha:(mat->has_specularity()? 1.0 - mat->transparency : 1.0)];
            [materialCache addObject:material];
        }
        
        /* Grouping faces by material IDs */
        std::map<int, std::vector<int>> elemFacesGroupedByMatId;
        auto fit = elemFaces.begin();
        for (const int& matId : elemMatIds) {
            for (int i = 0; i < 3; i++) {
                elemFacesGroupedByMatId[matId].push_back(*fit++);
            }
        }
        if (fit != elemFaces.end()) {
            std::cerr << "Mapping faces to material IDs failed!" << std::endl;
        }
        
        /* Creating geometry elements based on faces grouped by materials */
        /* (one SCNGeometryElement per material) */
        NSMutableArray<SCNGeometryElement *> *geometryElements = [NSMutableArray arrayWithCapacity:elemMats.size() * sizeof(SCNGeometryElement*)];
        NSMutableArray<SCNMaterial *> *materials = [NSMutableArray arrayWithCapacity:elemMats.size() * sizeof(SCNMaterial*)];
        
        for (const auto& group : elemFacesGroupedByMatId) {
            int matId = group.first;
            std::vector<int> faces = group.second;
            size_t facesSize = faces.size();
            NSData *facesData = [NSData dataWithBytes:faces.data() length:facesSize * sizeof(int)];
            SCNGeometryElement *geometryElement = [SCNGeometryElement geometryElementWithData:facesData primitiveType:SCNGeometryPrimitiveTypeTriangles primitiveCount:facesSize / 3 bytesPerIndex:sizeof(int)];
            [geometryElements addObject:geometryElement];
            
            SCNMaterial *material = materialCache[matId];
            [materials addObject:material];
        }
        
        
        /* Creating geometry based on vertices and indexes */
        SCNGeometry *geometry = [SCNGeometry geometryWithSources:@[vertexSource] elements:geometryElements];
        
        geometry.materials = materials;
        
        SCNNode *node = [SCNNode nodeWithGeometry:geometry];
        [scene.rootNode addChildNode:node];
        
        std::string elemInfo = triElem->type();
        elemInfo += triElem->name() == "" ? "" : ": " + triElem->name() + " - geometry added";
        std::cout << elemInfo + "\n";
        
    } while (it->next());
    
    delete it;
    
    sceneView.scene = scene;
    sceneView.allowsCameraControl = YES;
    sceneView.autoenablesDefaultLighting = YES;
    
    return sceneView;
}
@end

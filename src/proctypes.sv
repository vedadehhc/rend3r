// Data types
typedef logic [15:0] float16;
typedef logic [31:0] float32;

// Instruction types
typedef enum { 
    opFrame,
    opCameraSet,
    opLightInit,
    opLightSet,
    opShapeInit,
    opShapeSet,
    opShapeData
} InstructionType;


// C-type (Camera)
parameter CAMERA_PROPERTY_SIZE = 5;
typedef enum logic[CAMERA_PROPERTY_SIZE-1:0] { 
    null        = 5'd0;
    xLocation   = 5'd1;
    yLocation   = 5'd2;
    zLocation   = 5'd3;
    xForward    = 5'd4;
    yForward    = 5'd5;
    zForward    = 5'd6;
    xUp         = 5'd7;
    yUp         = 5'd8;
    zUp         = 5'd9;
    nearClip    = 5'd10;
    farClip     = 5'd11;
    fovHor      = 5'd12;
    fovVer      = 5'd13;
 } CameraProperty;


// L-type (Light)
parameter LIGHT_INDEX_SIZE = 6;
typedef logic [LIGHT_INDEX_SIZE-1:0] LightIndex;

parameter LIGHT_PROPERTY_SIZE = 5;
typedef enum logic[LIGHT_PROPERTY_SIZE-1:0] { 
    null        = 5'd0;
    xLocation   = 5'd1;
    yLocation   = 5'd2;
    zLocation   = 5'd3;
    xForward    = 5'd4;
    yForward    = 5'd5;
    zForward    = 5'd6;
    color       = 5'd7;
    intensity   = 5'd8;
} LightProperty;


// S-type (Shape)
parameter SHAPE_INDEX_SIZE = 19;
typedef logic [SHAPE_INDEX_SIZE-1:0] ShapeIndex;

parameter SHAPE_PROPERTY_SIZE = 5;
typedef enum logic[SHAPE_PROPERTY_SIZE-1:0] { 
    null        = 5'd0;
    xLocation   = 5'd1;
    yLocation   = 5'd2;
    zLocation   = 5'd3;
    xForward    = 5'd4;
    yForward    = 5'd5;
    zForward    = 5'd6;
    xScale      = 5'd7;
    yScale      = 5'd8;
    zScale      = 5'd9;
    material    = 5'd10;
} ShapeProperty;




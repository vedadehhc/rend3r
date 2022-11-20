// Data types
typedef logic [15:0] float16;
typedef logic [31:0] float32;

// Decoded instruction
typedef struct packed {
    InstructionType iType;
    LightIndex lIndex;
    ShapeIndex sIndex;
    LightType lType;
    ShapeType sType;
    Prop prop;
    Prop prop2;
    float16 data;
    float16 data2;
} DecodedInst;


// Instruction types
typedef enum { 
    opRender,
    opFrame,
    opCameraSet,
    opLightInit,
    opLightSet,
    opShapeInit,
    opShapeSet,
    opShapeData
} InstructionType;

parameter PROPERTY_SIZE = 5;
typedef logic [PROPERTY_SIZE-1:0] Prop;

// C-type (Camera)
typedef enum Prop { 
    cpNull        = 5'd0,
    cpXLocation   = 5'd1,
    cpYLocation   = 5'd2,
    cpZLocation   = 5'd3,
    cpXForward    = 5'd4,
    cpYForward    = 5'd5,
    cpZForward    = 5'd6,
    cpXUp         = 5'd7,
    cpYUp         = 5'd8,
    cpZUp         = 5'd9,
    cpNearClip    = 5'd10,
    cpFarClip     = 5'd11,
    cpFovHor      = 5'd12,
    cpFovVer      = 5'd13
 } CameraProperty;


// L-type (Light)
parameter LIGHT_INDEX_SIZE = 6;
typedef logic [LIGHT_INDEX_SIZE-1:0] LightIndex;

typedef enum Prop { 
    lpNull        = 5'd0,
    lpXLocation   = 5'd1,
    lpYLocation   = 5'd2,
    lpZLocation   = 5'd3,
    lpXForward    = 5'd4,
    lpYForward    = 5'd5,
    lpZForward    = 5'd6,
    lpColor       = 5'd7,
    lpIntensity   = 5'd8
} LightProperty;

typedef enum logic[1:0] { 
    ltOff         = 2'd0,
    ltDirectional = 2'd1,
    ltPoint       = 2'd2
 } LightType;


// S-type (Shape)
parameter SHAPE_INDEX_SIZE = 19;
typedef logic [SHAPE_INDEX_SIZE-1:0] ShapeIndex;

typedef enum Prop { 
    spNull        = 5'd0,
    spXLocation   = 5'd1,
    spYLocation   = 5'd2,
    spZLocation   = 5'd3,
    spXForward    = 5'd4,
    spYForward    = 5'd5,
    spZForward    = 5'd6,
    spXScale      = 5'd7,
    spYScale      = 5'd8,
    spZScale      = 5'd9,
    spMaterial    = 5'd10
} ShapeProperty;

typedef enum logic[4:0] { 
    stOff         = 2'd0,
    stTriangle    = 2'd1,
    stPlane       = 2'd2,
    stSphere      = 2'd3,
    stCube        = 2'd4,
    stCylinder    = 2'd5
} ShapeType;


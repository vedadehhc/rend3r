package proctypes;
    // FPU IP types
    typedef enum logic [5:0] {
        fpuOpAdd            = 6'b000000,
        fpuOpSub            = 6'b000001,
        fpuOpUnord          = 6'b000100,
        fpuOpLt             = 6'b001100,
        fpuOpEq             = 6'b010100,
        fpuOpLeq            = 6'b011100,
        fpuOpGt             = 6'b100100,
        fpuOpNeq            = 6'b101100,
        fpuOpGeq            = 6'b110100
    } FpuOperation;

    // Data types
    typedef logic [15:0] float16;
    typedef float16 vec3 [2:0];
    typedef float16 quaternion [3:0];

    // Instruction types
    typedef enum logic [2:0] { 
        ocFType     = 3'b000,
        ocCType     = 3'b001,
        ocLType     = 3'b011,
        ocSIType    = 3'b100,
        ocSEType    = 3'b101 
    } OpCode;

    typedef enum logic[2:0] { 
        opUnsupported,
        opRender,
        opFrame,
        opCameraSet,
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
        lpType        = 5'd0,
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
        stOff           = 5'd0,
        stEqTriangle    = 5'd1,
        stRtTriangle    = 5'd2,
        stPlane         = 5'd3,
        stInfPlane      = 5'd4,
        stSphere        = 5'd5,
        stCube          = 5'd6,
        stCylinder      = 5'd7,
        stInfCylinder   = 5'd8
    } ShapeType;
    
    // Decoded instruction
    typedef struct packed {
        InstructionType iType;
        LightIndex lIndex;
        ShapeIndex sIndex;
        ShapeType sType;
        Prop prop;
        Prop prop2;
        float16 data;
        float16 data2;
    } DecodedInst;
endpackage

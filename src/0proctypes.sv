// TODO: update based on ISA
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

package proctypes;

    // Render mode
    typedef enum logic [1:0] {
        renderNone = 2'b00,
        renderRasterization = 2'b01,
        renderRaytracing = 2'b11
    } RenderMode;
    parameter RENDERING_MODE = renderRasterization;

    // Instruction Bank
    typedef enum logic {
        fetchStall     = 1'b0,
        fetchDequeue   = 1'b1
    } FetchAction;

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

    typedef enum logic[3:0] { 
        opUnsupported,
        opEnd,
        opRender,
        opFrame,
        opLoop,
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
        spRRotation   = 5'd4,
        spIRotation   = 5'd5,
        spJRotation   = 5'd6,
        spKRotation   = 5'd7,
        spXScale      = 5'd8,
        spYScale      = 5'd9,
        spZScale      = 5'd10,
        spColor       = 5'd11,
        spMaterial    = 5'd12,
        spType        = 5'd13
    } ShapeProperty;

    typedef enum logic[3:0] { 
        stOff         = 4'd0,
        stSphere      = 4'd1,
        stCylinder    = 4'd2,
        stCone        = 4'd3
    } ShapeType;
    
    // Triangle properties

    typedef enum Prop {
        tpNull        = 5'd0,
        tpX1          = 5'd1,
        tpY1          = 5'd2,
        tpZ1          = 5'd3,
        tpX2          = 5'd4,
        tpY2          = 5'd5,
        tpZ2          = 5'd6,
        tpX3          = 5'd7,
        tpY3          = 5'd8,
        tpZ3          = 5'd9,
        tpColor       = 5'd11,
        tpMaterial    = 5'd12
    } TriangleProperty;

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
    

//// IMPORTANT GLOBALS
    // Data Size
    typedef struct packed {
        float16 xloc;
        float16 yloc;
        float16 zloc;
        float16 xfor;
        float16 yfor;
        float16 zfor;
        float16 xup;
        float16 yup;
        float16 zup;
        float16 nclip;
        float16 fclip;
        float16 hfov;
        float16 vfov;
    } Camera;
    parameter CAMERA_WIDTH = $bits(Camera);

    typedef struct packed {
        LightType       lType;
        float16         xloc;
        float16         yloc;
        float16         zloc;
        float16         xfor;
        float16         yfor;
        float16         zfor;
        logic [15:0]    col;
        float16         intensity;
    } Light;
    parameter LIGHT_WIDTH = $bits(Light);
    parameter NUM_LIGHTS = 8;
    parameter LIGHT_ADDR_WIDTH = $clog2(NUM_LIGHTS);
    typedef logic[LIGHT_ADDR_WIDTH-1:0] LightAddr;
    

    typedef struct packed {
        logic [15:0]    col;
        logic [1:0]     mat;
        float16         x1;
        float16         y1;
        float16         z1;
        float16         x2;
        float16         y2;
        float16         z2;
        float16         x3;
        float16         y3;
        float16         z3;
    } Triangle;
    parameter TRIANGLE_WIDTH = $bits(Triangle);
    parameter NUM_TRIANGLES = 1024;
    parameter TRIANGLE_ADDR_WIDTH = $clog2(NUM_TRIANGLES);
    typedef logic[TRIANGLE_ADDR_WIDTH-1:0] TriangleAddr;

    typedef struct packed {
        ShapeType       sType;
        logic [15:0]    col;
        logic [1:0]     mat;
        float16         xloc;
        float16         yloc;
        float16         zloc;
        float16         rrot;
        float16         irot;
        float16         jrot;
        float16         krot;
        float16         xscl;
        float16         yscl;
        float16         zscl;
    } Shape;
    parameter SHAPE_WIDTH = $bits(Shape);
    parameter NUM_SHAPES = 16;
    parameter SHAPE_ADDR_WIDTH = $clog2(NUM_SHAPES);
    typedef logic[4-1:0] ShapeAddr;

    parameter GEOMETRY_WIDTH = (RENDERING_MODE == renderRasterization) ? TRIANGLE_WIDTH : SHAPE_WIDTH;
    parameter GEOMETRY_DEPTH = (RENDERING_MODE == renderRasterization) ? NUM_TRIANGLES  : NUM_SHAPES;
    parameter GEOMETRY_ADDR_WIDTH = $clog2(GEOMETRY_DEPTH);
    typedef logic[GEOMETRY_ADDR_WIDTH-1:0] GeometryAddr;

    parameter INSTRUCTION_WIDTH = 32;
    typedef logic [INSTRUCTION_WIDTH-1:0] Instruction;
    parameter DECODED_INSTRUCTION_WIDTH = $bits(DecodedInst);
    parameter NUM_INSTRUCTIONS = 1024;
    parameter NUM_INSTRUCTIONS_WIDTH = $clog2(NUM_INSTRUCTIONS);
    typedef logic [NUM_INSTRUCTIONS_WIDTH-1:0] InstructionAddr;

    parameter SCREEN_WIDTH = 1024;
    parameter LOG_SCREEN_WIDTH = $clog2(SCREEN_WIDTH);
    typedef logic[LOG_SCREEN_WIDTH-1:0] ScreenX;
    parameter SCREEN_HEIGHT = 768;
    parameter LOG_SCREEN_HEIGHT = $clog2(SCREEN_HEIGHT);
    typedef logic[LOG_SCREEN_HEIGHT-1:0] ScreenY;

endpackage

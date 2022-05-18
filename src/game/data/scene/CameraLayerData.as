package game.data.scene
{
	public class CameraLayerData
	{
		public var asset:String;
		public var rate:Number;				   // rate of parallax movement.  1 moves with camera, 0 stays in fixed position.
		public var id:String;
		public var hit:Boolean;				   // If true layer won't get bitmapped and be scanned for hits.
		public var autoScale:Boolean;		   // Should this layer be scaled based on rate, dimensions and viewport dimensions so the entire layer is possible to see in scene?
		public var matchViewportSize:Boolean;  // Should this layer's dimensions always match the viewport size?
		public var bitmap:Boolean;
		public var offsetX:Number;			   // position offset applied to this layer from 0,0
		public var offsetY:Number;
		public var width:Number; 			   // width can override camera width
		public var height:Number; 			   // width can override camera height
		public var wrapX:Number; 			   // value at which layer will wrap
		public var wrapY:Number; 			   // value at which layer will wrap
		public var event:String; 			   // an event this layer is tied to.
		public var zIndex:uint;				   // can be used to set an explicit z-index for this layer, otherwise implied by order in <layers> in scene.xml (bottom up).
		public var elementsToBitmap:Array;     // displayObjects within this layer that should be bitmapped.  
		public var absoluteFilePaths:Boolean;  // should absolute file paths (starting at /assets/) be used to load this url?
		public var tileSize:int;			   // if this layer's bitmap is sliced into tiles (on platforms w/ max bitmap sizes), this determines the size.
		public var condition:String;           // a condition and value used to determine if this layer should be shown, hidden or merged
		public var conditionValue:*;
		
		// MOTION WRAP VARIABLES
		// flag to start on system addNode
		public var autoStart:Boolean;
		// subGroup to be used for movingTile layers
		public var subGroup:String;
		// flag to align the layers
		public var align:Boolean;
		// rate to apply the motion ( CURRENTLY USING :: .5 - backgrounds, 0 - interactive, 1.5 - foregrounds )
		public var motionRate:Number = 0;
	}
}
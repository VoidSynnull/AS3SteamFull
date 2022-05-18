
package game.scenes.survival2.beaverDen.components
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class BeaverComponent extends Component
	{
		public const BUSY:String			= 		"busy";
		public const BONKED:String 			= 		"bonked";
		public const DEFEATED:String 		=		"defeated";
		public const GRUMPY:String			= 		"grumpy";
		public const FRO:String				= 		"fro";
		public const IDLE:String 			= 		"idle";
		public const HURT:String			= 		"hurt";
		public const OFF:String				= 		"off";
		public const RECOVER:String 		= 		"recover";
		public const REPAIR:String 	 		=		"repair";
		public const SWIM_TO_DEN:String		= 		"swim_to_den";
		public const RUN:String 			= 		"run";
		public const SURFACING:String		= 		"surfacing";
		public const SWIM_TO_ENTRANCE:String =		"swim_to_entrance";
		public const SWIM_TO_HOLE:String 	= 		"swim_to_hole";
		public const SWIM_TO:String			= 		"swim_to";
		public const SWIM_FRO:String		= 		"swim_fro";
		public const TO:String				=		"to";
		public const TURN:String			= 		"turn";
		
		public var state:String 			= BUSY;
		public var subState:String			= TO;
		
		public const MOVE_VELOCITY:Number 	= 350;
		public var isBusy:Boolean 			= false;
		public var isMoving:Boolean			= false;
		public var isDefeated:Boolean		= false;
		
		public var exitTarget:Spatial 		= new Spatial( 3165, 1200 );
		public var holeTarget:Spatial;
		public var originTarget:Spatial		= new Spatial( 3340, 1050 );
		public var pointA:Spatial 			= new Spatial( 3200, 1050 );
		public var pointB:Spatial			= new Spatial( 3750, 1050 );
		
		public var leak:LeakComponent;
		
		public var timer:Number				= 0;
		
		public const WATER_DEFEAT_Y:Number  = 1220;
		public const SWIM_Y:Number			= 1320;
	}
}
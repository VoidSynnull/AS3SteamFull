package game.scenes.survival2.beaverDen.components
{
	import ash.core.Component;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class LeakComponent extends Component
	{
		public const START_RATE:Number 		= 4;
		public const MAX_RATE:Number		= 7;
		public const STEP_DURATION:Number	= 3;	// in seconds 
		public var leakRate:Number			= 0;
		public var tended:Boolean 			= false;
		public var spawnY:Number;
		
		public var state:String 			= OFF;
		public var expandTimer:Number		= 0;
		public var START:String 			= "start";
		public var ON:String 				= "on";
		public var OFF:String 				= "off";
		public var READY:String				= "ready";
		public var DEAD:String 				= "dead";
		public var REPAIR:String 			= "repair";
		public var REPAIRING:String 		= "repairing";

		
		public var timer:Number				= 0;
		
		public var emitterRateUnit:Number	= 0;
		public var emitterRate:Number		= 0;
		public var bubbleEmitter:Emitter2D;
		public var deathZone:DeathZone;
	}
}
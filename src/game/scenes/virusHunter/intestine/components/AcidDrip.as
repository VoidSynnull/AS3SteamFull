package game.scenes.virusHunter.intestine.components 
{
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.util.Utils;
	
	public class AcidDrip extends Component
	{
		public var state:String;	
		public var elapsedTime:Number;
		public var waitTime:Number;
		public var acid:Entity;
		public var emitter:Entity;
		public var startY:Number;
		public var endY:Number;
		
		public static const IDLE_STATE:String 		= "idle_state";
		public static const DRIPPING_STATE:String	= "dripping_state";
		public static const FALLING_STATE:String	= "falling_state";
		
		public function AcidDrip(acid:Entity, emitter:Entity, endY:Number)
		{
			this.state = AcidDrip.IDLE_STATE;
			this.elapsedTime = 0;
			this.waitTime = Utils.randNumInRange(0.25, 1);
			this.acid = acid;
			this.emitter = emitter;
			this.startY = acid.get(Spatial).y;
			this.endY = endY;
		}
	}
}
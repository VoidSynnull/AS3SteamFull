package game.scenes.ghd.shared.fallingRocks
{
	import ash.core.Component;
	
	import game.util.MotionUtils;
	
	import org.osflash.signals.Signal;
	
	public class Meteor extends Component
	{
		public static const FALLING:String = "falling";
		public static const EXPLODE:String = "explode";
		public static const RESETTING:String = "resetting";
		
		public var fallSpeed:Number = MotionUtils.GRAVITY;
		public var spinRate:Number = 0;
		public var xDrift:Number = 110;
		
		public var targetRadius:Number = 100;
		
		public var state:String = FALLING;
		
		public var respawnDelay:Number = 2;
		public var respawnTimer:Number = 0;
		
		public var impactSig:Signal;
		
		
		public function Meteor()
		{
			super();
		}
		
		override public function destroy():void
		{
			if(impactSig){
				impactSig.removeAll();
				impactSig = null;
			}
			super.destroy();
		}
	}
}
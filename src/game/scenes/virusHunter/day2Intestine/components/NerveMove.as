package game.scenes.virusHunter.day2Intestine.components 
{
	import ash.core.Component;
	
	import game.util.Utils;
	
	public class NerveMove extends Component
	{
		public static const IDLE_STATE:String 	= "idle_state";
		public static const MOVE_STATE:String	= "move_state";
		public static const SHOCK_STATE:String	= "shock_state";
		public static const MAX_ANGLE:Number	= 10;
		
		public var state:String;	
		public var elapsedTime:Number;
		public var waitTime:Number;
		public var direction:Boolean;
		
		public function NerveMove()
		{
			this.state = NerveMove.IDLE_STATE;
			this.elapsedTime = 0;
			this.waitTime = Utils.randNumInRange(3, 6);
			this.direction = true;
		}
	}
}
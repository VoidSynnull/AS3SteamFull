package game.scenes.poptropolis.hurdles.components
{
	import ash.core.Component;
	
	import game.components.input.Input;
	
	public class Hurdler extends Component
	{

		public function Hurdler()
		{
		}
		
		public var state:String;
		public var trackIndex:int;
		public var groundPosY:Number;
		public var startPosX:Number;
		public var isPlayer:Boolean;
		public var triggerJump:Boolean;
		public var crossedFinish:Boolean;
		
		// used by npcs to determine when they jump
		public var nextJumpX:Number
		public var nextHurdleX:Number 
		
		public function onActiveInput( input:Input=null ):void
		{
			triggerJump = true;
		}
	}
}
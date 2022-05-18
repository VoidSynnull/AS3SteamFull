package game.scenes.viking.shared.balanceGame
{
	import ash.core.Component;
	
	import engine.components.Display;
	
	public class BalanceSegment extends Component
	{
		public function BalanceSegment()
		{
			
		}
		
		override public function destroy():void
		{
			display = null;
			super.destroy();
		}
		
		public var tilt:Number = 0;
		public var tiltMultiplier:Number = 0.2;
		
		public var baseSegment:Boolean = false;
		
		public var display:Display;
	}
}
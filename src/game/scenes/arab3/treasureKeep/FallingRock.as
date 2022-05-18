package game.scenes.arab3.treasureKeep
{
	import ash.core.Component;
		
	public class FallingRock extends Component
	{
		public const FALLING:String = "falling";
		public const LOCKED:String = "locked";
		public const RESETING:String = "reseting";
		
		public function FallingRock()
		{
		}
		
		public function setState(state:String):void
		{
			if(this.state != state){
				this.state = state;
				stateChanged = true;
			}
		}
		
		override public function destroy():void
		{
			super.destroy();;
		}
		
		public var stateChanged:Boolean = true;
		public var state:String = FALLING;
		public var startY:Number = -200;
		public var xMin:Number = 1285;
		public var xMax:Number = 2360;
		public var speed:Number = 500;
		public var spinSpeed:Number = 45;
		public var yLimit:Number = 1000;
		public var resettime:Number = 1.6;
		public var resetOffet:Number = 0.4;
		public var timer:Number = 0;
		public var scale:Number = 1.0;
	}
}
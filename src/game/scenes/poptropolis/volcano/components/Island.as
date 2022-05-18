package game.scenes.poptropolis.volcano.components 
{
	import ash.core.Component;
	
	public class Island extends Component
	{
		public var wait:Number = 0;
		public var startX:Number = 0;
		public var startY:Number = 0;
		public var shake:Boolean = true;
		public var shakeAmount:Number = 1;
		
		public function Island(xpos:Number, ypos:Number)
		{
			startX = xpos;
			startY = ypos;
		}
	}
}
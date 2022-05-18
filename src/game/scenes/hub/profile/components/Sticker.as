package game.scenes.hub.profile.components
{	
	import ash.core.Component;
	
	public class Sticker extends Component
	{
		public var startX:Number;
		public var startY:Number;
		public var num:Number;
		public var onBoard:Boolean;
		public var moving:Boolean;
		public var id:Number;
		public var name:String;
		
		public function Sticker(n:Number, i:Number, sx:Number, sy:Number, ob:Boolean)
		{
			num = n;
			id = i;
			startX = sx;
			startY = sy;
			onBoard = ob;
			moving = false;
		}
	}
}
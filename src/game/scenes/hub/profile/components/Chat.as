package game.scenes.hub.profile.components
{
	import flash.display.Sprite;
	import flash.text.TextField;
	
	import ash.core.Component;
	
	public class Chat extends Component
	{
		public var txt:TextField;
		public var color:Sprite;
		public var whiteArrow:Sprite;
		public var colorArrow:Sprite;
		public var on:Boolean;
		public var pane:Number;
		public var num:Number;
		public var startY:Number;
		
		public function Chat(t:TextField, c:Sprite, p:Number, n:Number, sy:Number, wa:Sprite=null, ca:Sprite=null, o:Boolean=false)
		{
			txt = t;
			color = c;
			pane = p;
			num = n;
			startY = sy;
			whiteArrow = wa;
			colorArrow = ca;
			on = o;
		}
	}
}
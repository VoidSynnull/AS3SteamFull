package game.components.specialAbility
{
	import flash.geom.ColorTransform;
	
	import ash.core.Component;
	
	public class ColorChanger extends Component
	{
		public var colors:Array;
		public var changeTime:Number;
		public var time:Number;
		public var startColor:ColorTransform = new ColorTransform();
		public var nextColor:ColorTransform = new ColorTransform();
		public var index:int = -1;
		public function ColorChanger(colors:Array, changeTime:Number = 2)
		{
			this.colors = colors;
			this.changeTime = changeTime;
		}
	}
}
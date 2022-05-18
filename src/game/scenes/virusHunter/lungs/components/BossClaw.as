package game.scenes.virusHunter.lungs.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.util.Utils;
	
	public class BossClaw extends Component
	{
		public var isActive:Boolean;
		public var target:Point;
		public var degree:Number;
		
		public function BossClaw()
		{
			this.isActive = false;
			this.target = new Point(Utils.randInRange(-50, 50), Utils.randInRange(-350, -550));
			this.degree = 30;
		}
	}
}
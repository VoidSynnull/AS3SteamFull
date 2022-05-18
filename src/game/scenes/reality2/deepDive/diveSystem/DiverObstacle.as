package game.scenes.reality2.deepDive.diveSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class DiverObstacle extends Component
	{
		public var airModifier:Number;
		public var motionModifier:Point;
		public function DiverObstacle(air:Number = 5, motionModifier:Point = null)
		{
			this.airModifier = air;
			
			this.motionModifier = motionModifier;
		}
	}
}
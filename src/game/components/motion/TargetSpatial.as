package game.components.motion
{
	import ash.core.Component;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	public class TargetSpatial extends Component
	{
		public function TargetSpatial( target:Spatial = null )
		{
			this.target = target;
		}
		
		public var target:Spatial;
		public var addition:SpatialAddition;
		
		override public function destroy():void
		{
			this.target = null;
			this.addition = null;
			super.destroy();
		}
	}
}
package game.scenes.shrink.shared.Systems.WeakLiftSystem
{
	import ash.core.Component;
	
	import game.data.scene.hit.MovingHitData;
	
	public class WeakLift extends Component
	{
		public var defaultVelocity:Number;
		
		public var liftEfficiency:Number;
		
		public function WeakLift(liftEfficiency:Number, liftData:MovingHitData)
		{
			this.liftEfficiency = liftEfficiency;
			this.defaultVelocity = liftData.velocity;
		}
	}
}
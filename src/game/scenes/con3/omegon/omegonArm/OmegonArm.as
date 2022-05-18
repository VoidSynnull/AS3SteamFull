package game.scenes.con3.omegon.omegonArm
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	public class OmegonArm extends Component
	{
		public var handSpatial:Spatial;
		
		public function OmegonArm(handSpatial:Spatial)
		{
			this.handSpatial = handSpatial;
		}
	}
}
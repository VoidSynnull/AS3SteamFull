package game.scene.template.ads.shared.ShooterMechanics
{
	import ash.core.Component;
	
	public class Bullet extends Component
	{
		public var shooter:Shooter;
		public var isActive:Boolean = true; // bullet is active after a period of time after firing
		
		public function Bullet(shooter:Shooter)
		{
			this.shooter = shooter;
		}
	}
}
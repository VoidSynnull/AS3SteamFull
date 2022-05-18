package game.scenes.custom.StarShooterSystem
{
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class EnemyPattern extends Component
	{
		public var init:Boolean = false;
		public var active:Boolean = false;
		public var cleared:Signal = new Signal(Number);
		public var points:Number = 1000;
	}
}
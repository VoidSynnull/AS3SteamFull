package game.scenes.deepDive2.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Breakable extends Component
	{
		public function Breakable(strength:uint = 3):void
		{
			this.strength = strength; // default is 3
			wallHit = new Signal(Entity);
		}

		public var strength:uint;
		public var wallHit:Signal;
		public var impact:Boolean = false;
	}
}
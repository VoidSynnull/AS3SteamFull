package game.scenes.custom.StarShooterSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Pooler extends Component
	{
		public var type:String;
		public var isPooled:Boolean = false;
		public var pooled:Signal;
		public function Pooler(type:String)
		{
			this.type = type;
			pooled = new Signal(String, Entity);
		}
	}
}
package game.components.entity
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	/**
	 * @author Scott Wszalek
	 */	
	public class NPCDetector extends Component
	{
		public function NPCDetector(dist:Number, yVar:Number = 0)
		{
			distance = dist;
			yVariant = yVar;
			detected = new Signal(Entity);
		}
		
		public var distance:Number;
		public var detected:Signal;
		public var yVariant:Number;
	}
}
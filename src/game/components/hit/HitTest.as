package game.components.hit
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class HitTest extends Component
	{
		public var hit:Boolean;
		public var onEnter:Signal;
		public var onExit:Signal;
		public var hitIds:Vector.<String>;
		public function HitTest(enterFunction:Function = null, enterOnce:Boolean = false, exitFunction:Function = null, exitOnce:Boolean = false)
		{
			onEnter = new Signal(Entity, String);
			onExit = new Signal(Entity, String);
			hitIds = new Vector.<String>();
			
			if(enterFunction != null)
			{
				if(enterOnce)
					onEnter.addOnce(enterFunction);
				else
					onEnter.add(enterFunction);
			}
			
			if(exitFunction != null)
			{
				if(exitOnce)
					onExit.addOnce(exitFunction);
				else
					onExit.add(exitFunction);
			}
		}
		
		public function isHitting(id:String):Boolean
		{
			if(hitIds.indexOf(id) == -1)
				return false;
			return true;
		}
	}
}
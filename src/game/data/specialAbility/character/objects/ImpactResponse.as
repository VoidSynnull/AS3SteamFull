package game.data.specialAbility.character.objects
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import org.osflash.signals.Signal;
	
	public class ImpactResponse
	{
		public var complete:Signal;
		
		public function ImpactResponse()
		{
			complete = new Signal();
		}
		
		public function init(container:DisplayObjectContainer, parent:Group):void
		{
			
		}
		
		public function destroy():void
		{
			complete.removeAll();
			complete = null;
		}
		
		public function activate(hitObject:Entity, projectile:Entity, callback:Function = null):void
		{
			
		}
	}
}
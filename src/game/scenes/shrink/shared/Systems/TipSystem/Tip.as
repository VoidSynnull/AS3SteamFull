package game.scenes.shrink.shared.Systems.TipSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.hit.HitTest;
	import game.systems.hit.HitTestSystem;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;
	
	public class Tip extends Component
	{
		public var hit:HitTest;
		public var tippingPoint:Number;
		public var currentHit:Entity;
		public var tipped:Signal;
		public var state:String;
		
		public function Tip(hit:HitTest, group:Group, tippingPoint:Number = 45)
		{
			this.hit = hit;
			this.tippingPoint = tippingPoint;
			state = BALLANCED;
			hit.onEnter.add(Command.create(push, group));
			hit.onExit.add(stoppedPushing);
			tipped = new Signal(Entity);
		}
		
		private function stoppedPushing(entity:Entity, hitId:String):void
		{
			currentHit = null;
			state = TIPPING;
		}
		
		private function push(entity:Entity, hitId:String, group:Group):void
		{
			currentHit = group.getEntityById(hitId);
			state = PUSHING;
		}
		
		public static function addNeededSystems(group:Group):void
		{
			if( group.getSystem(HitTestSystem) == null)
				group.addSystem(new HitTestSystem(), SystemPriorities.checkCollisions);
			if(group.getSystem(TipSystem) == null)
				group.addSystem(new TipSystem());
		}
		
		public static const PUSHING:String = "pushing";
		public static const TIPPING:String = "tipping";
		public static const BALLANCED:String = "ballanced";
	}
}
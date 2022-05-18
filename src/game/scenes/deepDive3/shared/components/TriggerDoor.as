package game.scenes.deepDive3.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
		
	public class TriggerDoor extends Component
	{
		public var hitClass:Class;
		public var doorSets:Array;
		public var hit:Entity;
		public var originalHit:Component;
		
		public function TriggerDoor(hitClass:Class, hitEntity:Entity, sets:Array = null, origHit:Component = null)
		{
			this.hitClass = hitClass;
			this.hit = hitEntity;
			this.originalHit = (origHit) ? origHit : hit.get(hitClass);
			this.doorSets = (sets != null) ? sets : new Array();
		}
		
		override public function destroy():void{
			hitClass = null;
			hit = null;
			originalHit = null;
			doorSets = null;
			super.destroy();
		}
	}
}
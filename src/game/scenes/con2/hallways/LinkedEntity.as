package game.scenes.con2.hallways
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class LinkedEntity extends Component
	{
		public var link:Entity;
		//hold enity for reference later
		public function LinkedEntity(ent:Entity)
		{
			this.link = ent;
		}
		
		override public function destroy():void
		{
			link = null;
		}
	}
}
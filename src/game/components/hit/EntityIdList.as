package game.components.hit
{
	import ash.core.Component;
	
	public class EntityIdList extends Component
	{
		public var entities:Vector.<String> = new Vector.<String>;
		public var presentFlag:Boolean = false;
		
		public function get hasEntities():Boolean
		{
			return entities.length > 0;
		}
	}
}
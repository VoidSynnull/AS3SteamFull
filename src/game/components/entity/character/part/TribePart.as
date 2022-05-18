package game.components.entity.character.part
{	
	import ash.core.Component;
	
	import game.data.character.part.InstanceData;
	
	public class TribePart extends Component
	{
		public function TribePart( instancePath:String = "active_obj" ):void
		{
			instanceData = new InstanceData( instancePath );
		}
		
		public var instanceData:InstanceData;
	}
}

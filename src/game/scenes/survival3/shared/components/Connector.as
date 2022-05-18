package game.scenes.survival3.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Connector extends Component
	{
		public var connectedEntity:Entity;
		public var connected:Boolean;
		public function Connector(connectedEntity:Entity = null)
		{
			this.connectedEntity = connectedEntity;
		}
		
		public function connect(entity:Entity):void
		{
			connectedEntity = entity;
			connected = true;
		}
		
		public function disconnect():Entity
		{
			var entity:Entity = connectedEntity;
			if(entity == null)
				return entity;
			
			var connection:Connector = connectedEntity.get(Connector);
			if(connection != null)
			{
				connection.connectedEntity = null;
				connection.connected = false;
			}
			connectedEntity = null;
			connected = false;
			return entity;
		}
	}
}
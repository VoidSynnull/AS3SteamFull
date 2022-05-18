package game.components.entity
{	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Id;
	
	public class Children extends Component
	{
		public function Children(child:Entity=null)
		{
			children = new Vector.<Entity>;
			if(child != null){
				children.push(child);
			}
		}
		
		public function getChildByName( childId:String ):Entity
		{
			var childEntity:Entity = null;
			for (var i:int = 0; i < children.length; i++) 
			{
				childEntity = children[i];
				var id:Id = childEntity.get(Id);
				if( id )
				{
					if( id.id == childId )
					{
						return childEntity;
					}
					else
					{
						var childComponent:Children = childEntity.get(Children);
						if(childComponent)
						{
							childEntity = childComponent.getChildByName(childId);
							if(childEntity != null)
							{
								return childEntity;
							}
						}
					}
				}
			}
			return null;
		}
		
		public var children:Vector.<Entity>;
	}
}
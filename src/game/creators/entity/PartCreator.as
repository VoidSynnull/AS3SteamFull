package game.creators.entity
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Parent;
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.Part;
	import game.components.entity.character.part.PartLayer;
	import game.data.animation.entity.PartRigData;
	import game.util.EntityUtils;

	/**
	 * Creates part entities for each character asset layer.
	 * Part entities shares Spatial from corresponding with joint entity.
	 * Note :: joint entities must be created before part entities.
	 */
	public class PartCreator
	{
		public function PartCreator()
		{
			
		}
		
		/**
		 * Creates part entities for each character asset layer.
		 * Part entities shares Spatial from corresponding with joint entity.
		 * Note :: joint entities must be created before part entities.
		 * @param	character
		 * @param	rig
		 * @param	skin
		 * @param	group
		 * @param	systemManager
		 */
		public function createParts( group:Group, character:Entity, rig:Rig ):void
		{
			var partEntity:Entity;
			var part:Part;
			var partLayer:PartLayer;
			var parent:Parent;
			var partData:PartRigData;

			for ( var i:uint = 0; i < rig.data.partNames.length; i++ )
			{
				partEntity = new Entity();
				partData = rig.data.getPartData( rig.data.partNames[i] );
			
				// create Part component
				part = new Part(); 
				part.id = partData.id;
				part.type = partData.partType;
				partEntity.add( part );
				
				// create PartLayer component
				partLayer = new PartLayer();
				partLayer.layer = partData.layer;
				partLayer.invalidate = false;
				partEntity.add( partLayer );
				
				// add Parent, which is character
				//partEntity.add( new Parent( character ) );
				EntityUtils.addParentChild(partEntity, character);
				
				// add Rig, used to access other parts
				partEntity.add( rig );
				
				// create Id component
				partEntity.add( new Id( partData.id ) );
				
				// create MetaPart (holds meta data)
				partEntity.add( new MetaPart( part.id, part.type, rig.data.assetPath, rig.data.dataPath ) );
				
				// add Spatial from corresponding joint entity to share with part entity
				partEntity.add( rig.getJoint( partData.jointId ).get(Spatial));

				// create Display
				partEntity.add( new Display( new MovieClip(), character.get(Display).displayObject ) );
				
				rig.addPart(partEntity);

				group.addEntity(partEntity);
			}
		}
	}
}

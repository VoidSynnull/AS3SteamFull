package game.creators.entity
{
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.Joint;
	import game.data.animation.entity.PartRigData;
	import game.util.EntityUtils;
	
	/**
	 * Creates joint entities to be positioned by rig animation data.
	 * Joint entities owned by character, with one entity created for each animation layer. 
	 */
	public class JointCreator
	{
		public function JointCreator()
		{
			
		}
		
		/**
		 * Creates joint entities positioned from rig animation data.
		 * Creates entities for each each animation layer. 
		 * @param	groupManager
		 * @param	character
		 * @param	rig
		 * @param	group
		 * @param	systemManager
		 */
		public function createJoints( group:Group, character:Entity, rig:Rig ):void
		{
			var jointEntity:Entity;
			var joint:Joint;
			var partData:PartRigData;
			
			for ( var i:uint = 0; i < rig.data.partNames.length; i++ )
			{
				partData = rig.data.getPartData( rig.data.partNames[i] );
				
				if ( rig.getJoint( partData.jointId ) )		// if joint has already been created continue to next	
				{
					continue;
				}
				else										// create new joint
				{
					jointEntity = new Entity();
					
					if ( partData.animDriven )
					{
						joint = new Joint();
						joint.id = partData.jointId;
						joint.ignoreRotation = partData.ignoreRotation;
						jointEntity.add(joint);
					}
					
					jointEntity.add( new Spatial() );
					jointEntity.add( new Id( Joint.PREFIX + partData.jointId ) );
					jointEntity.add( new Sleep(false,true) );
					EntityUtils.addParentChild(jointEntity, character);
					
					rig.addJoint(jointEntity);
					
					group.addEntity( jointEntity );
				}	
			}
		}
	}
}

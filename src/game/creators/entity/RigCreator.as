package game.creators.entity
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.character.Rig;
	import game.data.animation.entity.RigParser;
	
	/**
	 * Creates entities necessary for a rig animated character.
	 * Rigs consist of:
	 * joint entities - created for each aniamtion layer, positioned each frame animation data, contain no display.
	 * part entities - created for each asset layer, contains display, position is driven by joint entity.
	 */
	public class RigCreator
	{
		public function RigCreator()
		{
			_jointCreator = new JointCreator();
			_partCreator = new PartCreator();
			rigParser = new RigParser();
		}
		/**
		 * Creates entities necessary for a rig animated character.
		 * Rigs consist of:
		 * joint entities - created for each aniamtion layer, positioned each frame animation data, contain no display.
		 * part entities - created for each asset layer, contains display, position is driven by joint entity.
		 * @param	groupManager
		 * @param	group
		 * @param	character
		 * @param	rigXml
		 * @param	systemManager
		 * @return
		 */
		public function create( group:Group, character:Entity, rigXml:XML ):Rig
		{
			var rig:Rig = new Rig();
			rig.data = rigParser.parse( rigXml );
			
			createJointsParts(group, character, rig);
			
			return rig;
		}
		
		public function createJointsParts( group:Group, character:Entity, rig:Rig ):void
		{
			// NOTE :: must create joints before creating parts
			_jointCreator.createJoints( group, character, rig);	// create joint Entitites for each part in rig animation
			_partCreator.createParts( group, character, rig );	// create part Entities for each part
		}
		
		/*
		public function createPart( group:Group, character:Entity):void
		{
			// create a part with necessary joint after the charater has already been initiated.
		}
		*/
		
		private var _jointCreator:JointCreator;
		private var _partCreator:PartCreator;
		public var rigParser:RigParser;
	}
}

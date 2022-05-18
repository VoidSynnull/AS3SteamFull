package game.data.animation.entity.character
{
	import ash.core.Entity;
	
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.Joint;

	public class Trip extends Default
	{
		public function Trip()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "trip" + ".xml";
		}
		
		
/*		override public function addComponentsTo(entity:Entity):void
		{
			var neck:Entity = Rig( entity.get( Rig )).joints[ "joint_neck" ];
			var joint:Joint = neck.get( Joint );
			
			joint.ignoreRotation = false;
		}
		
		override public function remove(entity:Entity):void
		{
			var neck:Entity = Rig( entity.get( Rig )).joints[ "joint_neck" ];
			var joint:Joint = neck.get( Joint );
			
			joint.ignoreRotation = false;
		}
*/
	}
}
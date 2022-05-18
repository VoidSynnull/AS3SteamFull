package game.data.animation.entity.character 
{
	import engine.managers.GroupManager;
	
	import game.components.Emitter;
	import game.systems.ParticleSystem;

	public class Dizzy extends Default
	{
		private const LABEL_LOOP:String = "loop";
		private const LABEL_START_PARTICLES:String 	= "startParticles";
		private const EMITTER_ID:String = "stars";
		
		[Inject]
		public var _groupManager:GroupManager;
		
		public function Dizzy()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "dizzy" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		/*override public function addComponentsTo(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			
			// If the emitter still exists when we try and create it, simply allow it to continue and turn off remove.
			if( emitterEntity == null )
			{
				addStars( entity );
			}
			else
			{
				emitterEntity.get(Emitter).remove = false;
			}
		}
		
		private function addStars(character:Entity):void
		{
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD_JOINT ).get(Spatial);
			
			var stars:DizzyStars = new DizzyStars();
			stars.init();
			stars.counter.stop();
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			//var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, stars, 0, 0, character, EMITTER_ID, followTarget);
		}*/
	}
}
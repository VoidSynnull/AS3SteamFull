package game.scene.template
{
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	
	import game.components.audio.Mic;
	import game.systems.audio.MicSystem;
	
	/**
	 * Very lightweight Group for adding microphone functionality to another Group. Creates and adds a basic
	 * Entity with Id and Mic components and the MicSystem to the Group.
	 * 
	 * <p>This microphone Entity acts as a singleton and should (in most cases) be the only Entity with a Mic component.
	 * Other systems that want to access the microphone should get the MicNode NodeList (which should only have 1 MicNode)
	 * and get the Mic.microphone values from there.</p>
	 * 
	 * <p>More functionality could be added to this Group once more microphone features and systems get implemented.</p>
	 * @author Drew Martin
	 */
	public class MicrophoneGroup extends Group
	{
		private const MICROPHONE:String = "microphone";
		
		public function MicrophoneGroup()
		{
			super();
			
			this.id = "microphoneGroup";
		}
		
		public function createMicrophoneEntity():Entity
		{
			var entity:Entity = new Entity(MICROPHONE);
			entity.add(new Id(MICROPHONE));
			entity.add(new Mic());
				
			this.addEntity(entity);
			this.addSystem(new MicSystem());
			
			return entity;
		}
		
		public function get microphoneEntity():Entity { return this.getEntityById(MICROPHONE); }
	}
}
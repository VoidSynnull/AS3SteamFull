package game.data.animation.entity.character 
{
	import ash.core.Entity;
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.group.Group;
	import engine.managers.GroupManager;
	import engine.components.Spatial;
	import flash.display.DisplayObjectContainer;
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.particles.emitter.characterAnimations.Tears;
	import game.util.CharUtils;
	import game.systems.ParticleSystem;

	public class Cry extends Default
	{
		private const LABEL_START_PARTICLES:String 	= "startParticles";
		private const LABEL_STOP_PARTICLES:String 	= "stopParticles";
		
		public function Cry()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "cry" + ".xml";
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var leftEyeTears:Entity = _groupManager.getEntityById(_emitterID_L, null, entity);
			var rightEyeTears:Entity = _groupManager.getEntityById(_emitterID_R, null, entity);
			
			// If the emitter still exists when we try and create it, simply allow it to continue and turn off remove.
			if(leftEyeTears == null)
			{
				addTears(entity, _emitterID_L);
			}
			else
			{
				leftEyeTears.get(Emitter).remove = false;
			}
			
			if(rightEyeTears == null)
			{
				addTears(entity, _emitterID_R);
			}
			else
			{
				rightEyeTears.get(Emitter).remove = false;
			}
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var leftEyeEmitter:Entity = _groupManager.getEntityById(_emitterID_L, null, entity);
			var rightEyeEmitter:Entity = _groupManager.getEntityById(_emitterID_R, null, entity); 

			//check label
			if ( label == LABEL_START_PARTICLES )
			{
				Tears(leftEyeEmitter.get(Emitter).emitter).rate = RATE;
				Tears(rightEyeEmitter.get(Emitter).emitter).rate = RATE;
			}
			else if ( label == LABEL_STOP_PARTICLES )
			{
				Tears(leftEyeEmitter.get(Emitter).emitter).rate = 0;
				Tears(rightEyeEmitter.get(Emitter).emitter).rate = 0;
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var leftEyeEmitterEntity:Entity = _groupManager.getEntityById(_emitterID_L, null, entity);
			leftEyeEmitterEntity.get(Emitter).remove = true;
			var rightEyeEmitterEntity:Entity = _groupManager.getEntityById(_emitterID_R, null, entity);
			rightEyeEmitterEntity.get(Emitter).remove = true;
		}
		
		private function addTears(character:Entity, id:String):void
		{
			// set target
			var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.HEAD_JOINT ).get(Spatial);
			
			// set offset & direction
			var offsetX:int;
			var direction:int;
			if(id == _emitterID_L)
			{
				offsetX = -60;
				direction = -1;
			}
			else
			{
				offsetX = 54;
				direction = 1;
			}
			
			// create emitter entity
			var tears:Tears = new Tears()
			tears.init(direction);
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			//var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, tears, offsetX, 0, character, id, followTarget);
		}
		
		[Inject]
		public var _groupManager:GroupManager;
		
		private const RATE:Number = 5;
		
		private var _emitterID_L:String = "leftEyeTears";
		private var _emitterID_R:String = "rightEyeTears";
	}
}
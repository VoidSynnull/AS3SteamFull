package game.data.animation.entity.character.poptropolis
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.GroupManager;
	
	import game.components.Emitter;
	import game.components.audio.HitAudio;
	import game.components.motion.Edge;
	import game.creators.entity.EmitterCreator;
	import game.data.PlatformType;
	import game.data.animation.entity.character.Default;
	import game.data.sound.SoundAction;
	import game.particles.emitter.characterAnimations.Dust;
	import game.systems.ParticleSystem;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;

	public class LongJumpRun extends Default
	{
		public function LongJumpRun()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "poptropolis/longJumpRun" + ".xml";
			
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
			{
				var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
				
				if( emitterEntity == null )
				{
					addEmitter( entity );
				}
				else
				{
					var emitter:Emitter = emitterEntity.get(Emitter);
					emitter.emitter.counter.resume();
					emitter.remove = false;
				}
			}
		}
		
		override public function remove(entity:Entity):void
		{
			var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
			if(emitterEntity != null)
			{
				var emitter:Emitter = emitterEntity.get(Emitter);
				//emitter.emitter.stop();
				emitter.remove = true;
			}
		}
		
		override public function reachedFrameLabel(entity:Entity, label:String):void
		{
			var hitAudio:HitAudio = entity.get(HitAudio);
			
			if(hitAudio != null)
			{
				if(label == SoundAction.STEP)
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.STEP;
				}
			}
			
			// create particles if quality is high enough
			if(PerformanceUtils.qualityLevel  >= PerformanceUtils.QUALITY_HIGH)
			{
				if( label == LABEL_START_RUN )
				{
					var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity);
					if( emitterEntity == null )
					{
						addEmitter( entity );
					}
					else
					{
						var emitter:Emitter = emitterEntity.get(Emitter);
						emitter.emitter.counter.resume();
						emitter.remove = false;
					}
				}
			}
		}
		
		private function addEmitter(character:Entity):Entity
		{
			//var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.FOOT_FRONT ).get(Spatial);
			var followTarget:Spatial = character.get(Spatial);
			
			var emitter:Dust = new Dust();
			emitter.init(followTarget);
			// TODO :: Would be nice to check ground to determine Dust color and behavior
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			var container:DisplayObjectContainer = Display(character.get(Display)).container;	// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, emitter, 0,  Edge(character.get(Edge)).rectangle.bottom, character, EMITTER_ID, followTarget);
			return emitterEntity;
		}
		
		private const LABEL_START_RUN:String 	= "startRun";
		
		[Inject]
		public var _shellApi:ShellApi;
		[Inject]
		public var _groupManager:GroupManager;
		private const EMITTER_ID:String = "dust";
	}
}



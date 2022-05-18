package game.data.animation.entity.character 
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
	import game.components.entity.collider.EmitterCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Edge;
	import game.creators.entity.EmitterCreator;
	import game.data.scene.hit.EmitterHitData;
	import game.data.sound.SoundAction;
	import game.particles.emitter.characterAnimations.Dust;
	import game.systems.ParticleSystem;
	import game.util.PerformanceUtils;

	public class Run extends Default
	{
		public function Run()
		{
			super.apeXmlPath = super.XML_PATH + super.TYPE_APE + "navigation/run" + ".xml";
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "navigation/run" + ".xml";
			super.creatureXmlPath = super.XML_PATH + super.TYPE_CREATURE + "navigation/run" + ".xml";
			super.petBabyQuadXmlPath = super.XML_PATH + super.TYPE_PET_BABYQUAD + "navigation/run" + ".xml";
			
			super.systems = [ParticleSystem];
			super.components = [Emitter];
		}
		
		override public function addComponentsTo(entity:Entity):void
		{
			var emitterCollider:EmitterCollider = entity.get( EmitterCollider );
			
			if( !ignoreEffects && PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
			{
				if( super.isAnimateChar(entity) && !emitterCollider )
				{
					var emitterEntity:Entity = _groupManager.getEntityById( EMITTER_ID, null, entity );
					
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
			var emitterCollider:EmitterCollider = entity.get(EmitterCollider);
			var emitterHitData:EmitterHitData;
			var currentHit:CurrentHit = entity.get( CurrentHit );
			
			if( currentHit != null )
			{
				if( currentHit.hit )
				{
					emitterHitData = currentHit.hit.get( EmitterHitData );
				}
			}
			
			if( hitAudio != null )
			{
				if(label == SoundAction.STEP)
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.STEP;
				}
			}
			
				// If there is emitter data for this platform
			if( emitterCollider )
			{
				if( label == SoundAction.STEP )
				{
					emitterCollider.setEmitterData( emitterHitData, SoundAction.STEP, true );
				}
			}			
		}
		
		private function addEmitter(character:Entity):void
		{
			//var followTarget:Spatial = CharUtils.getJoint( character, CharUtils.FOOT_FRONT ).get(Spatial);
			var followTarget:Spatial = character.get(Spatial);
			var emitter:Dust = new Dust();
			emitter.init(followTarget);
			// TODO :: Would be nice to check ground to determine Dust color and behavior. - Bard
			var group:Group = OwningGroup(character.get(OwningGroup)).group;
			//var container:DisplayObjectContainer = Display(character.get(Display)).displayObject;	// container within character
			var container:DisplayObjectContainer = Display(character.get(Display)).container;		// container within scene
			var emitterEntity:Entity = EmitterCreator.create( group, container, emitter, 0, Edge(character.get(Edge)).rectangle.bottom, character, EMITTER_ID, followTarget);
		}
		
		[Inject]
		public var _shellApi:ShellApi;
		[Inject]
		public var _groupManager:GroupManager;
		private const EMITTER_ID:String = "dust";
		public var ignoreEffects:Boolean = false;
	}
}
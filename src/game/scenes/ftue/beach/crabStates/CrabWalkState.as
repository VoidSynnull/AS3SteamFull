package game.scenes.ftue.beach.crabStates
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.Emitter;
	import game.components.motion.Edge;
	import game.components.motion.MotionTarget;
	import game.creators.entity.EmitterCreator;
	import game.particles.emitter.characterAnimations.Dust;
	import game.scenes.ftue.beach.components.Crab;
	import game.systems.entity.character.clipChar.MovieclipState;
	
	public class CrabWalkState extends MovieclipState
	{
		public function CrabWalkState()
		{
			super.type = MovieclipState.WALK;
		}
		
		private const EMITTER_ID:String = "crab_dust";
		
		override public function start():void
		{
			var crab:Crab = node.entity.get(Crab);
			var label:String = crab.hasWrench?"walkingWrench":"walking";
			super.setLabel(label);
			
			var target:MotionTarget = node.motionTarget;
			
			if(target.targetX < node.spatial.x)
				node.motion.velocity.x = -crab.speed;
			else				
				node.motion.velocity.x = crab.speed;
			
			var emitterEntity:Entity = node.entity.group.groupManager.getEntityById( EMITTER_ID, null, node.entity );
			
			if( emitterEntity == null )
			{
				addEmitter( node.entity );
			}
			else
			{
				var emitter:Emitter = emitterEntity.get(Emitter);
				emitter.emitter.counter.resume();
				emitter.remove = false;
			}
		}
		
		override public function exit():void
		{
			var emitterEntity:Entity = node.entity.group.groupManager.getEntityById( EMITTER_ID, null, node.entity);
			if(emitterEntity != null)
			{
				var emitter:Emitter = emitterEntity.get(Emitter);
				//emitter.emitter.stop();
				emitter.remove = true;
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
		
		override public function update(time:Number):void
		{
			var target:MotionTarget = node.motionTarget;
			var crab:Crab = node.entity.get(Crab);
			
			if(Math.abs(target.targetDeltaX) <= 25)
			{
				if(crab.leftBlocked && crab.rightBlocked)
					node.fsmControl.setState("surrender");
				else
					node.fsmControl.setState(MovieclipState.STAND);
				return;
			}
		}
	}
}
package game.scenes.examples.customCharacter
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.components.Viewport;
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.audio.HitAudio;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Player;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.TargetEntity;
	import game.creators.animation.FSMStateCreator;
	import game.scene.template.CharacterGroup;
	import game.scenes.examples.customCharacter.states.CustomCharacterState;
	import game.scenes.examples.customCharacter.states.FallState;
	import game.scenes.examples.customCharacter.states.HurtState;
	import game.scenes.examples.customCharacter.states.JumpState;
	import game.scenes.examples.customCharacter.states.LandState;
	import game.scenes.examples.customCharacter.states.RunState;
	import game.scenes.examples.customCharacter.states.SkidState;
	import game.scenes.examples.customCharacter.states.StandState;
	import game.scenes.examples.customCharacter.states.SwimState;
	import game.scenes.examples.customCharacter.states.WalkState;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.TimelineUtils;

	public class CustomCharacterCreator
	{
		public function create(scene:Scene, container:DisplayObjectContainer, clip:MovieClip, x:Number, y:Number, target:Spatial = null, isPlayer:Boolean = false, id:String = null, motionControlBase:MotionControlBase = null, timelineAnimation:Boolean = false):Entity
		{
			var entity:Entity 	= new Entity();		
			var spatial:Spatial = new Spatial(x, y);			
			var motion:Motion 	= new Motion();
			motion.friction 	= new Point(1, 1);
			motion.maxVelocity 	= new Point(25 * 32, 32 * 32);
			motion.minVelocity 	= new Point(1 * 32, 0);
			
			var edge:Edge = new Edge();
			edge.unscaled.setTo(-28, -28, 56, 56);
			
			entity.add(edge);
			entity.add(spatial);
			entity.add(new Display(clip, container));
			entity.add(motion);
			entity.add(new MotionTarget());
			entity.add(new Navigation());
			entity.add(new Dialog());
			entity.add(new CustomCharacterComponent());

			var sceneObjectMotion:SceneObjectMotion = new SceneObjectMotion();
			entity.add(sceneObjectMotion);
			
			var bitmapCollider:BitmapCollider = new BitmapCollider();
			bitmapCollider.addAccelerationToVelocityVector = true;
			entity.add(bitmapCollider);
						
			var characterMovement:CharacterMovement = new CharacterMovement();
			characterMovement.adjustHeadWithVelocity = false;
			entity.add(characterMovement); 
			var characterMotionControl:CharacterMotionControl = new CharacterMotionControl();
			characterMotionControl.directionByVelocity = true;
			entity.add(characterMotionControl);
			var motionTarget:MotionTarget = new MotionTarget();
			entity.add(motionTarget);
			
			var viewport:Viewport = new Viewport(scene.shellApi.viewportWidth, scene.shellApi.viewportHeight);
			characterMotionControl.viewportChanged(viewport);
			entity.add(viewport);
			
			if(id != null) { entity.add(new Id(id)); }
			
			container.addChild(clip);
			
			var motionControl:MotionControl = new MotionControl();
			var targetEntity:TargetEntity = new TargetEntity();
			targetEntity.target = target;
			targetEntity.applyCameraOffset = true;
					
			if(isPlayer)
			{
				entity.add(new Player());
				// needed for scene interactions and speech bubbles, need to remove this requirement.
				entity.add(new Id("player"));
			}
			else
			{
				motionControl.forceTarget = true;
				targetEntity.applyCameraOffset = false;
			}
			
			entity.add(motionControl);
			entity.add(targetEntity);
			entity.add(new Audio());
			var destination:Destination = new Destination();
			entity.add(destination);
			
			entity.add(new MotionBounds(scene.sceneData.bounds));
			
			var characterGroup:CharacterGroup = scene.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			characterGroup.addColliders(entity);
			
			if(timelineAnimation)
			{
				setupTimelineAnimation(entity, clip);
			}
			
			// this must happen last so the states have access to all needed components on their 'node'.
			addStates(entity, scene, new <Class>[/*JumpState, RunState, StandState, WalkState, */FallState, SkidState, HurtState, LandState, SwimState]);
			
			// associating animation frames with states.
			createCharacterState(JumpState, entity, "", "jump");
			createCharacterState(RunState, entity, "", "walk");
			createCharacterState(StandState, entity, CharacterState.STAND, "stand", true);
			createCharacterState(WalkState, entity, "", "walk");

			return(entity);
		}
		
		public function setupTimelineAnimation(entity:Entity, clip:MovieClip):void
		{
			TimelineUtils.convertClip(clip, null, entity, null, false);
		}
				
		private function addStates(entity:Entity, scene:Group, stateClasses:Vector.<Class> = null, startState:String = ""):void
		{
			// add FSMControl and states
			var fsmControl:FSMControl = entity.get(FSMControl);
			
			if(!fsmControl)
			{
				fsmControl = new FSMControl(super.shellApi);
				entity.add(fsmControl);
				entity.add(new FSMMaster());
				
				if(stateClasses == null)
				{
					stateClasses = new <Class>[JumpState, RunState, StandState, WalkState, FallState, SkidState, HurtState, LandState, SwimState];//characterGroup.characterStateSet;
				}
				
				for each(var stateClass:Class in stateClasses)
				{
					createCharacterState(stateClass, entity);
				}

				// if startState not defined, stand state is used
				startState = (DataUtils.validString( startState )) ? startState : CharacterState.STAND;
				fsmControl.setState( startState );	
				
				entity.add(fsmControl);
			}
		}
		
		public function createCharacterState( stateClass:Class, character:Entity, stateType:String = "", animationId:String = null, makeStart:Boolean = false):CustomCharacterState
		{
			var fsmControl:FSMControl = character.get( FSMControl ) as FSMControl;
			if ( fsmControl )
			{
				var stateCreator:FSMStateCreator = new FSMStateCreator();
				var state:CustomCharacterState = stateCreator.createState( character, stateClass, CustomCharacterNode, stateType) as CustomCharacterState; 
				
				state.animationId = animationId;
				
				// set viewport
				var viewPort:Viewport = character.get( Viewport );
				viewPort.changed.add( state.setViewport );	// TODO :: handle this
				state.setViewport( viewPort );
				
				// add fsm to main animation entity ( since that is what it will be running )
				var animationControl:AnimationControl = character.get( AnimationControl );
				if(animationControl)
				{
					var primaryAnimEntity:Entity = animationControl.getEntityAt();
					if( !primaryAnimEntity.has( FSMControl ) )
					{
						primaryAnimEntity.add( fsmControl );
					}
				}
				
				if(makeStart)
				{
					fsmControl.setState( stateType );	
				}
				
				return state;
			}
			return null;
		}
	}
}
package game.creators.entity.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.systems.RenderSystem;
	
	import game.components.entity.character.Character;
	import game.data.animation.AnimationSequence;
	import game.data.character.CharacterData;
	import game.data.character.CharacterSceneData;
	import game.data.character.LookData;
	import game.systems.SystemPriorities;
	import game.systems.animation.FSMSystem;
	import game.systems.entity.AnimationControlSystem;
	import game.systems.entity.AnimationEndSystem;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.AnimationSequenceSystem;
	import game.systems.entity.AnimationStateSystem;
	import game.systems.entity.ColorDisplaySystem;
	import game.systems.entity.DrawLimbSystem;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.JointAnimationSystem;
	import game.systems.entity.PartLayerSystem;
	import game.systems.entity.SkinSystem;
	import game.systems.entity.character.CharacterUpdateSystem;
	import game.systems.entity.character.TalkRigSystem;
	import game.systems.entity.character.clipChar.TalkClipSystem;
	import game.systems.entity.character.part.GooglyEyesSystem;
	import game.systems.entity.character.part.DressSystem;
	import game.systems.entity.character.part.DripPartSystem;
	import game.systems.entity.character.part.FlipPartSystem;
	import game.systems.entity.character.part.ItemMotionSystem;
	import game.systems.entity.character.part.TribePartSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.SpringSystem;
	import game.systems.render.PlatformDepthCollisionSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.timeline.TimelineRigSystem;
	
	/**
	 * Creates start of a characters.
	 * Creates an entity and assigns data used by the CharacterUpdateSystem to finalize creation.
	 */
	public class CharacterCreator
	{
		/**
		 * Creates start of a character.
		 * Creates an entity and passes variables used by the CharacterUpdateSystem to finalize creation.
		 * @param	groupManager
		 * @param	container
		 * @param	skin
		 * @param	x
		 * @param	y
		 * @param	direction
		 * @param	id
		 * @param	type
		 * @param	variant
		 * @param	scale
		 * @param	animSequence
		 * @param	group
		 * @param	systemManager
		 * @return
		 */
		public function create( group:Group, id:String, look:LookData, x:int, y:int, direction:String = "right", container:DisplayObjectContainer = null, type:String = null, variant:String = null, scale:Number = NaN, animSequence:AnimationSequence = null ) : Entity
		{
			var charData:CharacterData = new CharacterData();
			
			charData.type			= ( type == null ) ? CharacterCreator.TYPE_NPC : type;
			charData.variant		= ( variant == null ) ? CharacterCreator.VARIANT_HUMAN : variant;
			
			charData.id 			= id;
			charData.look 			= look;
			charData.position.x 	= x;
			charData.position.y 	= y;
			charData.direction 		= direction;
			charData.scale 			= scale;
			charData.animSequence 	= animSequence;
	
			//return createFromCharData( group, id, charData, container );
			return createFromCharData( group, charData, container );
		}
		
		/**
		 * Creates start of a characters.
		 * Creates an entity and assigns data used by the CharacterUpdateSystem to finalize creation.
		 * @param	groupManager
		 * @param	container
		 * @param	charSceneData
		 * @param	group
		 * @param	systemsManager
		 * @return
		 */
		public function createFromCharData( group:Group, charData:CharacterData, container:DisplayObjectContainer = null ) : Entity
		{
			var charSceneData:CharacterSceneData = new CharacterSceneData( charData.id );
			charSceneData.addCharData( charData );
			return createFromCharSceneData( group, charSceneData, container );
		}
		
		public function createFromCharSceneData( group:Group, charSceneData:CharacterSceneData, container:DisplayObjectContainer = null ) : Entity
		{
			var charEntity : Entity = new Entity();
			
			// add Character
			var character:Character 	= new Character();
			character.id				= charSceneData.charId;
			character._charSceneData 	= charSceneData;
			
			// Makes Character component listen for scene events, updates Character's nextCharData
			if( character.type != CharacterCreator.TYPE_DUMMY )
			{
				// setups up Character to listen for events, while using current evnst to define Character.
				// calls Character's eventTriggered, which defines nextCharData, type, & variant.
				group.shellApi.setupEventTrigger(character);
				if ( character.nextCharData )	// if there is a currently active event that corresponds to a CharacterData
				{
					character.type		= ( character.nextCharData.type == null ) ? CharacterCreator.TYPE_NPC : character.nextCharData.type;
					character.variant	= ( character.nextCharData.variant == null ) ? CharacterCreator.VARIANT_HUMAN : character.nextCharData.variant;
				}
			}
			charEntity.add(character);
			
			// add Display
			var display : Display = new Display( new MovieClip() );
			display.setContainer( container );
			charEntity.add( display );
			
			// add Spatial	
			// NOTE :: Have to add this now because of the camera system
			var spatial:Spatial = new Spatial();
			charEntity.add( spatial );
			
			// add Id		
			// NOTE :: Have to add this now because scenes begin looking for characters before they have completed loading
			charEntity.add(new Id( character.id ));
			
			group.addEntity( charEntity );
			
			return(charEntity);
		}
		
		/**
		 * Adds systems necessary for character
		 * TODO :: could add flag for just adding systems for Dummy characters
		 * @param	group
		 */
		public function addSystems( group:Group ) : void
		{
			group.addSystem(new AnimationStateSystem(), SystemPriorities.update);
			group.addSystem(new CharacterUpdateSystem(), SystemPriorities.update);
			group.addSystem(new SpecialAbilityControlSystem(), SystemPriorities.update);
			group.addSystem(new TalkRigSystem(), SystemPriorities.update );
			group.addSystem(new TalkClipSystem(), SystemPriorities.update );
			group.addSystem(new TimelineControlSystem(), SystemPriorities.timelineControl);
			group.addSystem(new TimelineRigSystem(), SystemPriorities.timelineEvent);
			group.addSystem(new TimelineClipSystem(), SystemPriorities.timelineEvent);
			group.addSystem(new JointAnimationSystem(), SystemPriorities.animate);
			group.addSystem(new FollowTargetSystem(), SystemPriorities.move);			
			group.addSystem(new SpringSystem(), SystemPriorities.preRender);
			group.addSystem(new AnimationEndSystem(), SystemPriorities.updateAnim);
			group.addSystem(new AnimationSequenceSystem(), SystemPriorities.sequenceAnim);
			group.addSystem(new AnimationControlSystem(), SystemPriorities.checkAnimActive);
			group.addSystem(new FSMSystem(), SystemPriorities.autoAnim);	
			group.addSystem(new AnimationLoaderSystem, SystemPriorities.loadAnim);		// loads new animations, these updates won't be processed until next update
			group.addSystem(new PartLayerSystem(), SystemPriorities.preRender);
			group.addSystem(new SkinSystem(), SystemPriorities.preRender);
			group.addSystem(new DrawLimbSystem(), SystemPriorities.render);
			group.addSystem(new PlatformDepthCollisionSystem());
			
			group.addSystem(new ColorDisplaySystem());
			group.addSystem(new MotionTargetSystem());
			group.addSystem(new RenderSystem());
			
			// part specific, would like to pull in as needed
			group.addSystem(new EyeSystem(), SystemPriorities.render);
			group.addSystem(new GooglyEyesSystem(), SystemPriorities.update);
			group.addSystem(new FlipPartSystem(), SystemPriorities.update);
			group.addSystem(new DressSystem(), SystemPriorities.render);
			group.addSystem(new DripPartSystem(), SystemPriorities.render);
			group.addSystem(new ItemMotionSystem, SystemPriorities.render);
			group.addSystem(new TribePartSystem, SystemPriorities.render);
		}
		
		public static const TYPE_PLAYER:String 			= "player";
		public static const TYPE_NPC:String 			= "npc";
		public static const TYPE_DUMMY:String 			= "dummy";
		public static const TYPE_PORTRAIT:String 		= "portrait";
		
		public static const VARIANT_MOVIECLIP:String	= "movieclip";
		public static const VARIANT_APE:String			= "ape";
		public static const VARIANT_BIRD:String			= "bird";
		public static const VARIANT_BIPED:String		= "biped";
		public static const VARIANT_HUMAN:String 		= "human";
		public static const VARIANT_CREATURE:String 	= "creature";
		public static const VARIANT_PET_BABYQUAD:String = "pet_babyquad";
		public static const VARIANT_NINJA:String 		= "ninja";
		public static const VARIANT_HEAD:String 		= "head";
		public static const VARIANT_MANNEQUIN:String 	= "mannequin";
	}
}

package game.util
{	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.CharacterWander;
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.DrawLimb;
	import game.components.entity.character.Player;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Skin;
	import game.components.entity.character.Talk;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.AnimationSlot;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.Part;
	import game.components.entity.character.part.PartLayer;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.entity.character.part.item.ItemMotion;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.BounceWireCollider;
	import game.components.entity.collider.ClimbCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.TargetEntity;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.data.animation.AnimationData;
	import game.data.animation.AnimationSequence;
	import game.data.character.part.ColorAspectData;
	import game.data.character.part.SkinPartId;
	import game.data.profile.ProfileData;
	import game.data.sound.SoundAction;
	import game.data.specialAbility.SpecialAbilityData;
	import game.managers.SpecialAbilityManager;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.ui.photo.CharacterPoseData;
	import game.ui.photo.PartPoseData;
	
	public class CharUtils
	{	
		/////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////// PARTS ////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Get part Entity 
		 * @param entity
		 * @param partName
		 * @return 
		 */
		public static function getPart( entity:Entity, partName:String ):Entity
		{
			var rig:Rig = entity.get(Rig);
			if( rig )
			{
				return rig.getPart( partName );
			}
			return null;
		}
		
		public static function getJoint( entity:Entity, jointName:String ):Entity
		{
			var rig:Rig = entity.get(Rig);
			if(rig)
			{
				return rig.getJoint(jointName);
			}
			return null;
		}
		
		public static function setPartColor( entity:Entity, partName:String, colorValue:Number, colorId:String = "" ):void
		{
			var partEntity:Entity = entity.get(Rig).getPart( partName );
			if ( partEntity )
			{
				var colorSet:ColorSet = partEntity.get( ColorSet ) as ColorSet;
				if ( colorSet )
				{
					var colorAspect:ColorAspectData;
					if ( DataUtils.validString( colorId ) )
					{
						colorAspect = colorSet.setColorAspect( colorValue, colorId );
						if ( !colorAspect )
						{
							colorAspect = colorSet.addColorAspect( new SkinPartId( partName, partName ), colorId, colorValue );
						}
					}
					else
					{
						colorAspect = colorSet.addColorAspect( new SkinPartId( partName, partName ), "", colorValue );
					}
				}
			}
		}
		
		public static function getPartColor( entity:Entity, partName:String, colorId:String = "" ):Number
		{
			var rig:Rig = entity.get(Rig);
			if( rig )
			{
				var partEntity:Entity = rig.getPart( partName );
				if ( partEntity )
				{
					var colorSet:ColorSet = partEntity.get( ColorSet ) as ColorSet;
					if ( colorSet )
					{
						var colorAspect:ColorAspectData;
						if ( DataUtils.validString( colorId ) )
						{
							colorAspect = colorSet.getColorAspect( colorId );
						}
						else
						{
							colorAspect = colorSet.getColorAspectLast();
						}
						
						if( colorAspect )
						{
							return colorAspect.value;
						}
					}
				}
			}
			return NaN;
		}
		
		public static function bitmapPart(entity:Entity, partName:String):void
		{
			var partEntity:Entity = getPart(entity, partName);
			try
			{
				partEntity.remove(Rig);
				partEntity.remove(Skin);
				partEntity.remove(ColorSet);
				partEntity.remove(MetaPart);
				partEntity.remove(Part);
				partEntity.remove(PartLayer);
				partEntity.remove(SkinPart);	
				
				var display:Display = partEntity.get(Display);
				DisplayUtils.convertToBitmapSprite(display.displayObject);
			} 
			catch(error:Error) 
			{
				trace("ERROR: CharUtils :: bitmapPart : No displayObject for " + partName + ":: " + error);
			}
		}
		
		/**
		 * Get the PartLayer component from the character's specified part entity.
		 * @param	entity
		 * @param	partName - refers to the part name ( 
		 * @return
		 */
		public static function getPartLayer( entity:Entity, partName:String ):PartLayer
		{
			var part:Entity = CharUtils.getPart( entity, partName );
			if ( part )
			{
				return part.get( PartLayer ) as PartLayer;
			}
			return null;
		}
		
		public static function getDisplayObject( entity:Entity ):DisplayObjectContainer
		{
			return Display(entity.get(Display)).displayObject;
		}
		
		

		/////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////// ANIMATION /////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		public static function getTimeline( entity:Entity, priority:int = 0 ):Timeline
		{
			return AnimationControl(entity.get(AnimationControl)).getEntityAt(priority).get( Timeline );
		}
		
		public static function getRigAnim( entity:Entity, index:int = 0 ):RigAnimation
		{
			return AnimationControl(entity.get(AnimationControl)).getAnimAt(index);
		}
		
		/**
		 * Determines if the current animation has reached the last frame
		 * @param	entity
		 * @param	animClass
		 * @return
		 */
		public static function animAtLastFrame( entity:Entity, animClass:Class ):Boolean
		{
			var rigAnim:RigAnimation = CharUtils.getRigAnim( entity );
			if ( rigAnim )
			{
				if ( ClassUtils.getClassByObject(rigAnim.current) == animClass )
				{
					var timeline:Timeline = CharUtils.getTimeline( entity );
					if ( timeline )
					{
						if ( timeline.currentIndex == ( timeline.data.duration - 1 ) )
						{
							return true;
						}
					}
				}
			}
			return false;
		}
		
		/**
		 * Manually set the state of the character, they must be setup with the character FSM.
		 * character state type are accessible through CharacterState as static consts (e.g. CharacterState.JUMP, CharacterState.WALK, CharacterState.DUCK );
		 */
		public static function setState( entity:Entity, stateType:String ):void
		{
			var fsmControl:FSMControl = entity.get(FSMControl);
			if( fsmControl )
			{
				CharUtils.stateDrivenOn( entity );
				fsmControl.setState( stateType );
			}
		}
		
		/**
		 * Get the current state type (e.g. CharacterState.JUMP, CharacterState.WALK, CharacterState.DUCK );
		 */
		public static function getStateType( entity:Entity ):String
		{
			var fsmControl:FSMControl = entity.get(FSMControl);
			if( fsmControl )
			{
				return fsmControl.state.type;
			}
			return null;
		}
		
		/**
		 * Manually change a character's animation. 
		 * @param	entity - the character you are applying the animation to, must contain the necessary components
		 * @param	animClass - the animation Class you are applying
		 * @param	waitForEnd - if true the new animation will not take effect until the current one ends.
		 * @param	priority - the animation slot you are changing, unless you are layering animations it will be 0.
		 * @param	duration - set a duration for the applied animation, if set animation will play for that amount of frames.
		 * @param deactivateSequence - flag to interrupt active sequences
		 */
		public static function setAnim( entity:Entity, animClass:Class, waitForEnd:Boolean = false, duration:int = 0, priority:int = 0, deactivateSequence:Boolean = false, fsmActive:Boolean = false ):void
		{
			var animControl:AnimationControl = entity.get(AnimationControl);
			trace("CharUtils :: setAnim : entity: " + entity + " animContol: " + animControl);
			if(animControl)
			{
				var animSlotEntity:Entity = animControl.getEntityAt( priority );
				if ( animSlotEntity )
				{
					var rigAnim:RigAnimation = animSlotEntity.get( RigAnimation );
					if ( rigAnim )
					{
						// if primary animation, turn off 'auto' controls and movement
						if ( priority == 0 )
						{
							var fsmControl:FSMControl = entity.get( FSMControl );
							if( fsmControl )
							{
								fsmControl.active = fsmActive;
							}
							var charMovement:CharacterMovement = entity.get( CharacterMovement );
							if( charMovement )
							{
								charMovement.active = fsmActive;
							}
						}
					
						// deactivate sequence, must reactivate to turn back on
						var animSequencer:AnimationSequencer;
						if( deactivateSequence )
						{
							animSequencer = animSlotEntity.get( AnimationSequencer );
							if ( animSequencer )
							{
								animSequencer.active = false;	// NOTE :: To turn sequence back on, must set active back to true
							}
						}
						
						// set anim
						if( !waitForEnd )
						{
							// assign animClass, and check if assignment was valid
							rigAnim.next = animClass;
							rigAnim.waitForEnd = false;
							if ( rigAnim.next && (rigAnim.next == animClass))	// if animClass was successfully set as new next		
							{	
		
								// if AnimationSequencer is active, set interrupt to true.
								animSequencer = AnimationControl(entity.get(AnimationControl)).getEntityAt(priority).get( AnimationSequencer );
								if ( animSequencer )			
								{
									if( animSequencer.active )
									{
										animSequencer.interrupt = true;
									}
								}
								
								// lock timeline until next animation has loaded, 
								// this saves any current/pending timeline commands for the next animation
								var timeline:Timeline = animSlotEntity.get( Timeline );
								if ( timeline )	
								{
									timeline.lock = true;	
								}
							}
						}
						else
						{
							var hasActiveSequence:Boolean = false
							animSequencer = AnimationControl(entity.get(AnimationControl)).getEntityAt(priority).get( AnimationSequencer );
							if ( animSequencer )			// if AnimationSequencer contains a sequence, replace current sequence
							{
								hasActiveSequence = animSequencer.active;
							}
							
							// if sequence is active, replace current sequence with a sequence containing the animClass
							// TODO :: Should revert to default when complete
							if( hasActiveSequence )	
							{
								animSequencer.currentSequence = AnimationSequence.create( animClass );
							}
							else
							{
								rigAnim.next = animClass;
								if ( rigAnim.next && (rigAnim.next == animClass) )	// if animClass was successfully set as new next		
								{	
									rigAnim.waitForEnd = true;
								}
							}
						}
						
						// apply duration ( if duration is left at 0, duration is essentially ignored )
						if( ClassUtils.getClassByObject( rigAnim.current ) == animClass )	// if animClass is same as current, set the current duration
						{
							rigAnim.duration = duration;
						}
						else													// otherwise set the nextDuration
						{
							rigAnim.nextDuration = duration;
						}
					}
				}
			}
		}
		
		/**
		 * Turn on a characters state driven animation system.
		 * @param	entity
		 * @param	waitForEnd - if state driven should take effect only after current animation has ended.
		 * @param	duration - the number of frames that should pass before state driven should take effect.
		 */
		public static function stateDrivenOn( entity:Entity, waitForEnd:Boolean = false, duration:int = 0 ):void
		{
			var fsmControl:FSMControl = entity.get( FSMControl );
			// TODO :: could call function to add state components...
			if(fsmControl)
			{
				if ( !fsmControl.active )
				{
					if ( waitForEnd )	// if waiting for end, make a new seuqence that will set auto once current animation ends
					{
						// priority 0 animations will revert to stateDriven automatically once animation has ended
						
						// if Entity has an active animation sequence, then need to make sure sequence doesn't continue
						// and stateDriven is turned on once current animation is done playing
						var animationControl:AnimationControl = entity.get(AnimationControl);
						if(animationControl)
						{
							var animSequencer:AnimationSequencer = animationControl.getEntityAt(0).get( AnimationSequencer );
							if ( animSequencer )			// if AnimationSequencer contains a sequence, replace current sequence
							{
								if( animSequencer.active )
								{
									// this basically create a sequence with null as the only animation, when null is found it defaults to stateDriven
									// so if the sequence is active, we make the sequence use stateDriven
									// what we probably want to do is just turn the auto sequence off, and then check if there is a sequence when we turn 
									// state drive off
									animSequencer.interruptSequence();
								}
							}
						}
						
					}
					else
					{
						fsmControl.active = true;
					}
					
					var animControl:AnimationControl = entity.get( AnimationControl );
					if( animControl )
					{
						if(animControl.primary)
						{
							// if duration was specified, then set current duration
							// if duration was not specified then current duration is set to 0, which makes it inactive
							animControl.primary.duration = duration;	
						}
					}
				}
			}
		}

		/**
		 * Turns off character's state driven animation system.
		 * Manually set animation do not get overridden by interaction with the environment.
		 * @param	entity
		 * @param	delay - How long the current animation will play, before it will end.  Only necessary for animation that do not end by themselves.
		 */
		public static function stateDrivenOff( entity:Entity, delay:int = 1 ):void
		{
			var fsmControl:FSMControl = entity.get( FSMControl );
			if( fsmControl)
			{
				if( fsmControl.active )
				{
					fsmControl.active = false;
					
					var charMovement:CharacterMovement = entity.get( CharacterMovement );
					if( charMovement )
					{
						charMovement.active = false;
					}
					
					// set duration of current animation TODO :: Need to investigate the usefulness of this. -bard
					var animControl:AnimationControl = entity.get( AnimationControl );
					if( animControl )
					{
						animControl.primary.duration = delay;		// sets duration for current animation
					}
					
					// if animSequencer has deault, trun back on
					var animationControl:AnimationControl = entity.get(AnimationControl);
					if(animationControl)
					{
						var animSequencer:AnimationSequencer = animationControl.getEntityAt(0).get( AnimationSequencer );
						if ( animSequencer.defaultSequence )
						{
							animSequencer.currentSequence = animSequencer.defaultSequence;
						}
					}
				}
			}
		}
		
		/**
		 * Makes the character do the sequence of animations given
		 * Will constantly loop if made true, best way to stop is set it's animation again.
		 * @param entity
		 * @param animation - Vector of Animation Classes to loop through.
		 * @param loop - repeats the animation sequence if true.
		 */
		public static function setAnimSequence(entity:Entity, animations:Vector.<Class>, loop:Boolean = false):void
		{
			var animControl:AnimationControl = entity.get(AnimationControl);
			var animEntity:Entity = animControl.getEntityAt();
			var animSequencer:AnimationSequencer = animEntity.get(AnimationSequencer);
			
			if(animSequencer == null)
			{
				animSequencer = new AnimationSequencer();
				animEntity.add(animSequencer);
			}
			
			var sequence:AnimationSequence = new AnimationSequence();
			for (var i:int = 0; i < animations.length; i++) 
			{
				sequence.add(new AnimationData(animations[i]));
			}
			
			sequence.loop = loop;
			animSequencer.currentSequence = sequence;
			animSequencer.start = true;
		}
		
		/**
		 * Freezes a character
		 * @param	character - character entity to freeze
		 * @param	bool - to freeze or not to freeze, that is the question.
		 */
		public static function freeze( character:Entity, bool:Boolean = true ):void
		{
			// pause all animation
			var animationControl:AnimationControl = character.get( AnimationControl );
			if (animationControl)
				animationControl.pause( bool );
			
			// pause motion & other general components
			EntityUtils.freeze( character, bool );
			
			// lock eyes
			var eyePart:Entity = CharUtils.getPart( character, SkinUtils.EYES );
			if( eyePart )
			{
				var eyes:Eyes = eyePart.get(Eyes);
				if( eyes )
				{
					eyes.locked = bool;
				}
			}

			// TODO :: turn off emitters associated with animations (like run dust)
		}
		
		/**
		 * Make pupils target an Entity's display.
		 * @param character
		 * @param target
		 * @param targetDisplay
		 */
		public static function eyesFollowTarget( character:Entity, target:Entity = null, targetDisplay:DisplayObject = null ):void
		{
			if( targetDisplay == null )
			{
				if( target == null )
				{
					trace( "Error :: CharUtils : eyesFollowTarget : Either target entity or a targetDisplay must be specified.");
					return;
				}
				targetDisplay = EntityUtils.getDisplayObject(target);
			}
			
			if( targetDisplay != null )
			{
				var eyeEntity:Entity = getPart( character, EYES_PART );
				if( eyeEntity != null )
				{
					var eyes:Eyes = eyeEntity.get(Eyes);
					if( eyes != null )
					{
						eyes.targetDisplay = targetDisplay;
					}
				}
			}
			else
			{
				trace( "Error :: CharUtils : eyesFollowTarget : targetDisplay is null.");
				return;
			}
		}
		
		/**
		 * Make pupils target mouse input.
		 * @param character
		 */
		public static function eyesFollowMouse( character:Entity):void
		{
			var eyeEntity:Entity = getPart( character, EYES_PART );
			if( eyeEntity != null )
			{
				var eyes:Eyes = eyeEntity.get(Eyes);
				if( eyes != null )
				{
					eyes.targetDisplay = null;
				}
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////

		/////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////// DIALOG ///////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
	
		public static function getDialog( entity:Entity, event:String = "" ):*
		{
			var dialog:Dialog = entity.get(Dialog);
			if ( dialog )
			{
				if ( event == "" )
				{
					return dialog.current;
				}
				else
				{
					return dialog.getDialog( event );
				}
			}
		}
		
		
		/**
		 * Set character's current dialog 
		 * @param entity
		 * @param dialogId
		 */
		public static function setDialogCurrent( entity:Entity, dialogId:String ):void
		{
			if( entity )
			{
				var dialog:Dialog = entity.get(Dialog);
				if ( dialog )
				{
					dialog.setCurrentById(dialogId);
				}
			}
		}
		
		/**
		 * Force character to say dialog, if dialog id is not specified character will say current 
		 * @param entity - character entity, should contain a Dialog component
		 * @param id - id of dialog
		 */
		public static function sayDialog( entity:Entity, id:String = "" ):void
		{
			var dialog:Dialog = entity.get(Dialog);
			if ( dialog )
			{
				if( DataUtils.validString(id) )
				{
					dialog.sayById( id );
				}
				else
				{
					dialog.sayCurrent();
				}
			}
		}

		/**
		 * Set a handler for when the current or next dialog completes.
		 * DialogData is returned with the signal, so handler shoudl account for a DialogData being passed to it.
		 * @param	entity
		 * @param	handler
		 */
		public static function dialogComplete( entity:Entity, handler:Function ):void
		{
			var dialog:Dialog = entity.get(Dialog);
			if ( dialog )
			{
				dialog.complete.addOnce( handler );
			}
		}
		
		/**
		 * Adds all necessary components to allow entity to use dialog.
		 * Should NOT be used on Entities handled during scene load, such as player &amp; standard NPCs.
		 * Likely use cases are for timeline driven 'characters', or characters created post scene load.
		 * @param entity
		 * @param group - if not specified checks for OwningGroup component on Entity
		 * @param id - id of the Entity, used to assign scene's dialog.  If not given id is given checks for Id component &amp; then Entity.name. 
		 * @param faceSpeaker - whether spatial is flipped to faces entity that is speaking to it.
		 * @param dialogPercentX - used for positioning word ballloon, a value of 0 will position word ballloon at entity's x position.
		 * @param dialogPercentY - used for positioning word ballloon, a value of 1 will position word ballloon directly above entity.
		 * @param assignSceneDialog - if true, scene dialog with matching id is assigned to entity
		 * 
		 */
		public static function assignDialog( entity:Entity, group:Group = null, id:String = "", faceSpeaker:Boolean = false, dialogPercentX:Number = 0, dialogPercentY:Number = 1, assignSceneDialog:Boolean = true ):void
		{
			var display:Display = entity.get( Display );
			if( display )
			{
				// check/add Edge
				var edge:Edge = entity.get( Edge );
				if( !edge  )
				{
					edge = new Edge();
					edge.unscaled = display.displayObject.getBounds(display.displayObject);
					entity.add(edge);
				}
				
				// check/add Dialog
				var dialog:Dialog = entity.get( Dialog );
				if( !dialog  )
				{
					dialog = new Dialog();
					entity.add(dialog);
				}
				dialog.faceSpeaker = faceSpeaker;
				dialog.dialogPositionPercents = new Point(dialogPercentX, dialogPercentY);
				
				// check/add Talk
				// NOTE :: Talk is really only necessary if it's associated with an animation or asset
				if( !entity.has( Talk )  )	{ entity.add( new Talk() ); }

				// assign scene dialog
				if( assignSceneDialog )
				{
					if( group == null )
					{
						var owningGroup:OwningGroup = entity.get(OwningGroup);
						if( owningGroup )	{ group = owningGroup.group; }
					}
					if( group != null )
					{
						var dialogGroup:CharacterDialogGroup = group.getGroupById("characterDialogGroup") as CharacterDialogGroup;
						if( dialogGroup )	{ dialogGroup.assignDialog( entity, id ); }
						else { trace("Error :: CharUtils : assignDialog :: CharacterDialogGroup must be added to group in order to assign dialog." ); } 
					}
					else { trace("Error :: CharUtils : assignDialog :: group must be define in order assign dialog from CharacterDialogGroup." ); }
				}
			}
			else { trace("Error :: CharUtils : assignDialog :: entity must have a Display for method to work." ); }
		}
		
		/////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////// SPECIAL ABILITY ///////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Check if character entity has special ability.
		 * @param character
		 * @param value - can by the id, class, or SpecialAbilityData file
		 * @return 
		 */
		public static function hasSpecialAbility( charEntity:Entity, value:* ):Boolean
		{
			var specialControl:SpecialAbilityControl;
			if(charEntity)
				specialControl = charEntity.get( SpecialAbilityControl ) as SpecialAbilityControl;
			// if not there check profile? - bard
			if ( specialControl )
			{
				if(value is String)
				{
					return (specialControl.getSpecialById( String(value) ) != null );
				}
				
				if(value is Class)
				{
					return (specialControl.getSpecialByClass( Class(value) ) != null);
				}
				
				if(value is SpecialAbilityData)
				{
					return (specialControl.getSpecialById(SpecialAbilityData(value).id) != null);
				}
			}
			return false;
		}
				
		/**
		 * Add special ability to character Entity.
		 * Adds necessary components and determines if Entity is player.
		 * @param charEntity - entity to apply special ability to
		 * @param specialAbilityData - instantiated class defining special ability
		 * @param activate - flag to trigger special ability, so it becomes active as soon as it is added
		 * 
		 */
		public static function addSpecialAbility( charEntity:Entity, specialAbilityData:SpecialAbilityData, activate:Boolean = false):SpecialAbilityData
		{
			var removeData:SpecialAbilityData;
			if( charEntity != null )
			{
				// TODO :: May need be more strict about types that ability can be applied to (not Dummy, Portrait, etc.)
				// Don't allow special abilities to be add to characters of type "portrait"
				var character:Character = charEntity.get(Character);
				if( character )
				{
					if( character.type == CharacterCreator.TYPE_PORTRAIT )
					{
						return null;
					}
				}

				// create & add SpecialAbilityControl component if Entity does not yet own one
				var specialControl:SpecialAbilityControl = charEntity.get( SpecialAbilityControl ) as SpecialAbilityControl;
				if ( !specialControl )
				{
					// add SpecialAbilityControl component
					specialControl = new SpecialAbilityControl();
					charEntity.add( specialControl );

					if( charEntity.get(Player) != null )
					{
						specialControl.userActivated = true
						// adds key listener, so spacebar can trigger ability
						if(PlatformUtils.isDesktop)
						{
							var interaction:Interaction = charEntity.get( Interaction );
							if( interaction )
							{
								if(interaction.keyDown)
									interaction.keyDown.add( specialControl.onKeyDownHandler );
							}
						}
					}
				}
				
				removeData = specialControl.checkExistingType(specialAbilityData);
				specialAbilityData = specialControl.addSpecial( specialAbilityData );
				specialAbilityData.activate = activate;
			}
			
			return removeData;
		}
		
		/**
		 * Remove special ability from a character by the id of the ability
		 * @param charEntity
		 * @param id
		 * @param save
		 * 
		 */		
		public static function removeSpecialAbilityById(charEntity:Entity, id:String, save:Boolean = false):void
		{
			var control:SpecialAbilityControl = charEntity.get(SpecialAbilityControl);
			if(control)
			{
				var data:SpecialAbilityData = control.getSpecialById(id);
				if(data)
				{
					removeSpecialAbility(charEntity, data, save);
				}
			}
		}
		
		/**
		 * Remove a special ability from a character Entity by special ability's class
		 * @param character
		 * @param specialClass
		 * @param save
		 */
		public static function removeSpecialAbilityByClass(charEntity:Entity, specialClass:Class, save:Boolean = false):void
		{
			var control:SpecialAbilityControl = charEntity.get(SpecialAbilityControl);
			if(control)
			{
				var specialData:SpecialAbilityData = control.getSpecialByClass(specialClass);
				if(specialData)
				{
					removeSpecialAbility(charEntity, specialData, save);
				}
			}
		}
		
		/**
		 * Remove a special ability from a character Entity by reference to the instantiated special ability class
		 * @param character
		 * @param specialAbilityData
		 * @param save
		 */
		public static function removeSpecialAbility( character:Entity, specialAbilityData:SpecialAbilityData, save:Boolean = false ):void
		{
			var specialControl:SpecialAbilityControl = character.get( SpecialAbilityControl ) as SpecialAbilityControl;
			if ( specialControl )
			{
				specialControl.removeSpecialAbility( specialAbilityData );
				if(save)
				{
					var group:Group = OwningGroup(character.get(OwningGroup)).group;
					group.shellApi.specialAbilityManager.removeSpecialAbility(character, specialAbilityData.id);
				}
			}
		}
		
		public static function removeCharacterLevelSpecialAbilities(charEntity:Entity, profile:ProfileData):void
		{
			var numAbilities:int = profile.specialAbilities.length;
			for (var i:int=0; i<numAbilities; i++) 
			{
				var sid:String = profile.specialAbilities[i];
				CharUtils.removeSpecialAbilityById(charEntity, sid, false);
			}
		}

		/**
		 * Manually trigger a special ability
		 * @param character
		 * @param isItPlayerTriggered - used in the common rooms. filter out popups, inputlock, etc
		 */
		public static function triggerSpecialAbility( character:Entity, playerTriggered:Boolean=true ):void
		{
			var specialControl:SpecialAbilityControl = character.get( SpecialAbilityControl ) as SpecialAbilityControl;
			var shouldTrigger:Boolean = true;
			if ( specialControl )
			{
				if(!playerTriggered)
				{
					var group:Group = OwningGroup(character.get(OwningGroup)).group;
					var specialManager:SpecialAbilityManager = SpecialAbilityManager(group.shellApi.getManager(SpecialAbilityManager));
					
					for(var i:Number=0;i<specialControl.specials.length;i++)
					{
						for(var j:Number=0;j<specialManager.doNotBroadcastAbilities.length;j++)
						{
							if(specialControl.specials[i].type == specialManager.doNotBroadcastAbilities[j] || specialControl.specials[i].disableBroadcast )
								shouldTrigger = false;
						}
						
					}
					if(shouldTrigger)
						specialControl.trigger = true;
				}
				else
					specialControl.trigger = true;
			}
		}
		
		
		/////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////// SCALE & POSITION //////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		public static function setScale( character:Entity, scale:Number ):void
		{			
			var edge:Edge = character.get(Edge);
			var spatial:Spatial = character.get(Spatial);
			
			if(edge != null && spatial.scale != 0)
			{
				// get original edge values prior to scaling
				var top:Number = edge.rectangle.top / spatial.scale;
				var bottom:Number = edge.rectangle.bottom / spatial.scale;
				var left:Number = edge.rectangle.left / spatial.scale;
				var right:Number = edge.rectangle.right / spatial.scale;
				var bottomDelta:Number = bottom * scale - edge.rectangle.bottom;
				
				// apply new scale value to edges
				edge.rectangle.top = top * scale;
				edge.rectangle.bottom = bottom * scale;
				edge.rectangle.left = left * scale;
				edge.rectangle.right = right * scale;
				
				// subtract the change in bottom edge so char doesn't fall through platform.
				spatial.y -= bottomDelta;
			}
			
			spatial.scale = scale;
		}
		
		public static function setAlpha(character:Entity, alpha:Number):void{
			var display : Display = character.get(Display);
			display.alpha = alpha;
		}
		
		public static function setDirection( character:Entity, faceRight:Boolean ):void
		{
			var spatial :Spatial = character.get(Spatial);
			// NOTE :: a positive scaleX = facing left, a negative scaleX = facing right
			if ( (spatial.scaleX > 0 && faceRight) || ( spatial.scaleX < 0 && !faceRight ) )
			{
				spatial.scaleX *= -1;
			}
		}
		
		/**
		 * Get the character's edge, if none is avaialble on eis created. 
		 * @param	entity
		 * @return
		 */
		public static function getEdge( entity : Entity ) : Edge
		{
			var edge:Edge = entity.get(Edge);
			if ( !edge )
			{
				edge = new Edge();
				edge.unscaled.setTo(0, 0, 0, 0);
			}
			return edge;
		}
		
		/**
		 * Position character, takes into account the character's current Edge values.
		 * @param	entity
		 * @return
		 */
		public static function position( entity:Entity, x:Number = NaN, y:Number = NaN ) : void
		{
			var spatial:Spatial = entity.get(Spatial);
			if( !isNaN(x) )
			{
				spatial.x = x;
			}
			if( !isNaN(y) )
			{
				var edge:Edge = entity.get(Edge);
				if ( edge )
				{
					y = y - edge.rectangle.bottom;
				}
				spatial.y = y;
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////// MOTION & CONTROL //////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Moves entity to target via the use of its control target.
		 * @param    character : The entity to move
		 * @param    targetX : x to move a character to.
		 * @param    targetY : y to move a character to.
		 * @param    lockControl : Lock the characters control while moving to this target (don't allow clicks to stop the moving to target).
		 * @param    handler : A function to be called when reaching the target, signal returns Entity that reached target
		 * @param	 minTargetDist - Point holding the min x &amp; y distances necessray to trigger a target reached.
		 * @param    directionTargetX : The position to use for the characters facing direction once arriving at the point.	// TODO :: might want to refactor this, not very user friedly
		 */
		public static function moveToTarget(character:Entity, targetX:Number, targetY:Number, lockControl:Boolean = false, handler:Function = null, minTargetDelta:Point = null):Destination //, minTargetDist:Point = null ):void
		{
			return CharUtils.followPath( character, new <Point>[new Point(targetX, targetY)], handler, lockControl, false, minTargetDelta ); 
		}
		
		/**
		 * Moves entity along the provided path.
		 * @param	char
		 * @param	scene
		 * @param	path
		 * @param	handler	- Function called when char reaches final path point, signal returns Entity so handler should account for it
		 * @param	cameraTarget - camera targets character
		 * @param	lockControl	- locks characters motion controls
		 * @param	faceDirection - turns char in given direction on reahing final point, valid entries are CharUtils.DIRECTION_RIGHT &amp; CharUtils.DIRECTION_RIGHT
		 * @param	minDist - Point holding the min x &amp; y distances necessray to trigger a target reached.
		 */
		//public static function followPath( character:Entity, path:Vector.<Point>, handler:Function = null, lockControl:Boolean = true, directionFace:String = "", minTargetDelta:Point = null, loop:Boolean = false, faceX:Number = NaN, faceY:Number = NaN ):void
		public static function followPath( character:Entity, path:Vector.<Point>, handler:Function = null, lockControl:Boolean = true, loop:Boolean = false, minTargetDelta:Point = null, ignorePlatformTarget:Boolean = false ):Destination
		{
			character.remove(CharacterWander);
			
			// requires FSM and necessary components
			var fsmControl:FSMControl = character.get( FSMControl );
			if( !fsmControl )
			{
				var parentGroup:Group = OwningGroup( character.get( OwningGroup ) ).group;
				fsmControl = CharacterGroup( parentGroup.getGroupById("characterGroup") ).addFSM( character );
				fsmControl = character.get( FSMControl );
			}
			fsmControl.active = true;	// turn on fsm

			var destination:Destination = MotionUtils.followPath( character, path, handler, lockControl, loop, minTargetDelta );
			destination.motionToZero.push("x");			// for character path, by default want to halt x motion upon reaching destination
			//destination.motionToZero.push("rotation");	// TODO :: do we also want to set rotation to 0 on reaching destination? - bard
			destination.ignorePlatformTarget = ignorePlatformTarget;
			return destination;
		}

		/**
		 * Causes the char to follow the leader entity.
		 * @param	leader : The entity to follow
		 * @param	follower : The entity following 
		 * @param	distance : The minimum distance the entities can be apart before the follower moves.
		 * @param   lockControl : Whether the input will be locked, when locked input changes cannot interrupt following.
		 * @return 
		 */
		public static function followEntity( follower:Entity, leader:Entity, minTargetDist:Point = null, applyCameraOffset:Boolean = false, lockControl:Boolean = true ):Destination
		{
			// requires FSM and necessary components
			if( !follower.get( FSMControl ) )
			{
				var parentGroup:Group = OwningGroup( follower.get( OwningGroup ) ).group;
				CharacterGroup( parentGroup.getGroupById("characterGroup") ).addFSM( follower );
			}
			
			var destination:Destination = MotionUtils.followEntity( follower, leader, minTargetDist, applyCameraOffset, lockControl );
			destination.ignorePlatformTarget = false;
			return destination;
		}

		/**
		 * Stops a follower from following another Entity
		 * @param	follower : The entity following 
		 */
		public static function stopFollowEntity(follower:Entity):void
		{
			follower.remove(TargetEntity);
			follower.remove(Destination);
		}

		/**
		 * turn character to face any entity with a spatial component
		 */
		public static function faceTargetEntity(char:Entity, targetEntity:Entity):void
		{
			var spatial:Spatial = char.get(Spatial);
			var targ:Spatial = targetEntity.get(Spatial);
			if( spatial.x < targ.x){
				setDirection(char,true);
			}else{
				setDirection(char,false);
			}
		}

		/**
		 * Locks or unlocks a character entity's motion control.
		 * Locking motion control prevent character from receiving the input that make it move.
		 * @param	character
		 */
		public static function lockControls( character:Entity, lockInput:Boolean = true, lockInputTargeting:Boolean = true ):void
		{
			var motionControl:MotionControl = character.get(MotionControl)
			if ( motionControl )
			{
				motionControl.lockInput = lockInput;	//TODO :: Need to check onthis.
				motionControl.moveToTarget = false;
				motionControl.inputActive = false;
			}
			
			var targetEntity:TargetEntity = character.get(TargetEntity);
			if(targetEntity)
			{
				targetEntity.active = !lockInputTargeting;
			}
		}

		public static function removeCollisions( entity:Entity ):void
		{
			entity.remove( SceneCollider );
			entity.remove( PlatformCollider );
			entity.remove( ClimbCollider );
			entity.remove( WaterCollider );
			entity.remove( HazardCollider );
			entity.remove( BitmapCollider );
			entity.remove( ZoneCollider );
			entity.remove( MotionBounds );
			entity.remove( WallCollider );
			entity.remove( BounceWireCollider );
		}
		
		/**
		 * Get the friction value from the character's current platform
		 * @param	entity
		 * @return
		 */
		public static function getFriction( entity:Entity ):Point
		{
			var currentHit:CurrentHit = entity.get(CurrentHit);
			if( currentHit != null )
			{
				if( currentHit.hit != null )
				{
					var platform:Platform = currentHit.hit.get(Platform);
					if( platform != null )
					{
						if( platform.friction != null )
						{
							return platform.friction;
						}
					}
				}
			}
			return null;
		}
		
		/////////////// AUDIO /////////////////////
		
		public static function playImpactAudio(entity:Entity):void
		{
			if(entity)
			{
				var hitAudio:HitAudio = entity.get(HitAudio);
				
				if(hitAudio != null)
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.IMPACT;
				}
			}
		}
		
		public static function poseCharacter(char:Entity, poseData:CharacterPoseData):void
		{
			char.remove(AnimationControl);
			char.remove(RigAnimation);
			
			var rig:Rig = char.get(Rig);
			var jointEntity:Entity;
			var partEntity:Entity;
			var jointSpatial:Spatial;
			var partSpatial:Spatial;
			var display:Display;
			var partDisplayObject:DisplayObjectContainer;
			
			var eyes:Entity = SkinUtils.getSkinPartEntity(char, SkinUtils.EYES);
			
			if(DataUtils.validString(poseData.mouthState))
				SkinUtils.setSkinPart(char, SkinUtils.MOUTH, poseData.mouthState,false);
			
			if(DataUtils.validString(poseData.eyeState))
				SkinUtils.setEyeStates(char, poseData.eyeState);
			
			// have the eyes look at poseData.lookTarget
			if(poseData.lookTarget != null)
				CharUtils.eyesFollowTarget( char, null, poseData.lookTarget );
			
			for each (var partId:String in poseData.PART_ORDER)
			{
				jointEntity = rig.getJoint(partId);
				jointEntity.remove(AnimationSlot);
				partEntity = rig.getPart(partId);
				
				jointSpatial = jointEntity.get(Spatial);
				if(partEntity != null)
				{
					partEntity.remove(Sleep);
					if(partId == "item")
						partEntity.remove(ItemMotion);
					partSpatial = partEntity.get(Spatial);
					partDisplayObject = EntityUtils.getDisplayObject(partEntity);
				}
				var data:PartPoseData = poseData.getPart(partId);
				
				if(!isNaN(data.x))
				{
					jointSpatial.x = data.x;
					if(partEntity!= null)
						partSpatial.x = partDisplayObject.x = data.x;
				}
				if(!isNaN(data.y))
				{
					jointSpatial.y = data.y;
					if(partEntity!= null)
						partSpatial.y = partDisplayObject.y = data.y;
				}
				if(data.limb)
				{
					var draw:DrawLimb = partEntity.get(DrawLimb);
					if(poseData.container.hasOwnProperty(poseData.MANUALLY_DRAWN_LIMBS+partId))
					{
						partEntity = rig.getPart(partId);
						display = partEntity.get(Display);
						draw.pose = true;
						var limb:MovieClip = poseData.container[poseData.MANUALLY_DRAWN_LIMBS+partId];
						display.swapDisplayObject(limb);
					}
					else
					{
						draw.pose = false;
						// don't want to apply rotation if drawing limb in code
						continue;
					}
				}
				if(!isNaN(data.rotation))
				{
					jointSpatial.rotation = data.rotation;
					if(partEntity!= null)
						partSpatial.rotation = partDisplayObject.rotation = data.rotation;
				}
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////
		
		public static const DENSITY:Number 				= .8;
		public static const SURFACE_RESISTANCE:Number 	= .18;

		
		public static const DIRECTION_RIGHT:String 	= "right";
		public static const DIRECTION_LEFT:String 	= "left";

		// dual parts/joints, share the same name
		public static const PACK:String 			= "pack";
		public static const HAIR:String 			= "hair";
		public static const ARM_BACK:String 		= "arm2";
		public static const HAND_BACK:String 		= "hand2";
		public static const LEG_BACK:String 		= "leg2";
		public static const FOOT_BACK:String 		= "foot2";
		public static const LEG_FRONT:String 		= "leg1";
		public static const FOOT_FRONT:String 		= "foot1";
		public static const ARM_FRONT:String 		= "arm1";
		public static const HAND_FRONT:String 		= "hand1";
		public static const ITEM:String 			= "item";
		public static const ABILITY:String			= "specialAbility";
		
		// joint only
		public static const BODY_JOINT:String 		= "body";
		public static const NECK_JOINT:String 		= "neck";
		public static const HEAD_JOINT:String 		= "head";
		
		// part only
		public static const BODY_PART:String 		= "bodySkin";
		public static const PANTS_PART:String 		= "pants";
		public static const SHIRT_PART:String 		= "shirt";
		public static const OVERPANTS_PART:String 	= "overpants";
		public static const OVERSHIRT_PART:String 	= "overshirt";
		public static const HEAD_PART:String 		= "headSkin";
		public static const MARKS_PART:String 		= "marks";
		public static const EYES_PART:String 		= "eyes";
		public static const MOUTH_PART:String 		= "mouth";
		public static const FACIAL_PART:String 		= "facial";
		
		// pet part only
		public static const OVERBODY_PART:String 	= "overbody";		
		public static const HAT_PART:String 		= "hat";		
	}
}
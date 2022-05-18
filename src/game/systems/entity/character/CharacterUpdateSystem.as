package game.systems.entity.character
{
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.DepthChecker;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterWander;
	import game.components.entity.character.Creature;
	import game.components.entity.character.DrawLimb;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Player;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Skin;
	import game.components.entity.character.Talk;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.collider.ItemCollider;
	import game.components.input.MotionControlInputMap;
	import game.components.motion.Edge;
	import game.components.motion.EdgeState;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.Spring;
	import game.components.render.Line;
	import game.components.render.PlatformDepthCollider;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.RigCreator;
	import game.creators.entity.SkinCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Stand;
	import game.data.character.CharacterData;
	import game.data.character.DrawLimbData;
	import game.data.character.DrawLimbParser;
	import game.data.character.DrawLimbSet;
	import game.data.character.EdgeData;
	import game.data.character.LookData;
	import game.data.character.SizeData;
	import game.data.character.SizeParser;
	import game.data.character.VariantData;
	import game.data.character.VariantLibrary;
	import game.data.motion.spring.SpringData;
	import game.data.motion.spring.SpringParser;
	import game.data.motion.spring.SpringSet;
	import game.data.scene.labels.LabelData;
	import game.data.ui.ToolTipType;
	import game.nodes.entity.character.CharacterUpdateNode;
	import game.scene.template.CharacterGroup;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.util.CharUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Bard McKinley
	 * 
	 * Create and updates characters based on scene events.
	 * Completes character creation based on character type.
	 * Listens for scene events that should be applied to all characters (or all characters of a type)
	 */
	public class CharacterUpdateSystem extends ListIteratingSystem
	{
		public function CharacterUpdateSystem()
		{
			super( CharacterUpdateNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( gameEgine : Engine ) : void
		{
			super.addToEngine( gameEgine );
			
			_rigCreator 	= new RigCreator();
			_skinCreator 	= new SkinCreator();
			_springParser 	= new SpringParser();
			_limbParser 	= new DrawLimbParser();
			_sizeParser 	= new SizeParser();
			_charGroup 		= super.group.getGroupById("characterGroup") as CharacterGroup;
			loadComplete 	= new Signal();
		}
		
		private function updateNode(node:CharacterUpdateNode, time:Number):void
		{
			var char:Character = node.character;
			
			// if new CharData has been set, create or update character
			if( char.nextCharData != null )
			{
				if ( char.nextCharData != char.currentCharData )
				{
					// if currentCharData has not been set, create new character entity
					if ( char.currentCharData == null )
					{
						// this gets called until character has been fully initialized
						createCharacter( node );
					}
					else
					{
						// character has been fully initialized, need to update 
						updateFromCharData( node );
					}
				}
			}	
		}
		
		////////////////////////////////////////////////////////////////
		///////////////////////////  UPDATE  ///////////////////////////
		////////////////////////////////////////////////////////////////
		
		/**
		 * Update the character using CharacterData
		 * @param	node
		 * @param	charData
		 */
		private function updateFromCharData( node:CharacterUpdateNode ):void
		{
			var nextCharData:CharacterData = node.character.nextCharData;
			
			// apply LookData to Skin, which propogates LookAspectData to corresponding SkinPart
			var skin:Skin = node.entity.get(Skin);
			if(skin)
			{
				skin.applyLook(nextCharData.look);	// merge new skin with existing skin
			}
			
			this.setSpatialFromEdge(node);
			
			// update scale if specified
			if( !isNaN(nextCharData.scale) ) 
			{
				CharUtils.setScale( node.entity, nextCharData.scale );
			}
			
			// if Npc, set target
			if ( node.character.type == CharacterCreator.TYPE_NPC )
			{
				var motionTarget:MotionTarget = node.entity.get(MotionTarget);
				motionTarget.targetX 	= node.spatial.x;	// TODO :: May not need to automatically add Control
				motionTarget.targetY	= node.spatial.y;
				
				// check for ignoreDepth
				var npc:Npc = node.entity.get(Npc);
				npc.ignoreDepth = nextCharData.ignoreDepth;
				node.character.costumizable = nextCharData.costumizable;
				
				if(nextCharData.range != null)
				{
					if(nextCharData.range.length > 0)
					{
						var wander:CharacterWander = node.entity.get(CharacterWander);
						
						if(wander == null)
						{
							wander = new CharacterWander();
							node.entity.add(wander);
						}
						
						wander.rangeX = nextCharData.range.x;
						wander.rangeY = nextCharData.range.y;
						
						var motion:Motion = node.entity.get(Motion);
						
						if(motion == null)
						{
							motion = new Motion();
							motion.maxVelocity = new Point(200, 200);
							node.entity.add(motion);
						}
					}
				}
				
				// add tooltip if current CharData or SceneCharData have their addToolTip flag set
				if( nextCharData.addToolTip || node.character._charSceneData.addToolTip )
				{
					// don't add tooltip if pet
					if (nextCharData.variant != CharacterData.VARIANT_PET_BABYQUAD)
					{
						addToolTip( node.entity, nextCharData );
					}
				}
			}
			
			// apply animSequence as new default (if specified)
			if ( nextCharData.animSequence != null )					// change animation
			{
				var sequenceSequencer:AnimationSequencer = AnimationControl(node.entity.get(AnimationControl)).getEntityAt(0).get(AnimationSequencer);
				sequenceSequencer.defaultSequence = nextCharData.animSequence;
				sequenceSequencer.start = true;	// start the new sequence
			}

			node.character.currentCharData = node.character.nextCharData;
			
			// stop timeline & joints until asset loading completes
			var animControl:AnimationControl = node.entity.get( AnimationControl );
			if(animControl)
			{
				animControl.sleeping( true );
			}
			
			var rig:Rig = node.entity.get( Rig );
			if(rig)
			{
				rig.jointsSleeping( true );
			}
			
			// check load complete
			if(skin)
			{
				skin.partsLoading.length = 0;
				skin.lookLoadComplete.addOnce( Command.create(partsComplete, node.entity) ); 
				var skinPart:SkinPart;
				for each( var partEntity:Entity in rig.parts )	
				{
					skinPart = partEntity.get( SkinPart );
					if ( skinPart )
					{
						if ( skinPart._invalidate )	// if skinPart is invalidated, has an asset to update 
						{
							skin.partsLoading.push( skinPart.id );
							skinPart.loaded.addOnce( skin.partLoaded );
						}
					}
				}
			}
			else if(node.character.currentCharData.movieClip)
			{
				node.entity.group.shellApi.loadFile(node.entity.group.shellApi.assetPrefix + node.character.currentCharData.movieClip, Command.create(movieClipLoaded, node));
			}
		}
		
		/**
		 * Add a tooltip to npc character.
		 * If Entity already has a tooltip will not add another.
		 * @param entity
		 * @param characterData
		 */
		public function addToolTip(entity:Entity, characterData:CharacterData):void
		{
			var labelData:LabelData = characterData.label;
			if(labelData == null)
			{
				labelData = new LabelData();
				labelData.type = ToolTipType.CLICK;
			}
			
			ToolTipCreator.addToEntity(entity, labelData.type, labelData.text, labelData.offset, true, 1);
		}
		
		private function movieClipLoaded(clip:MovieClip, node:CharacterUpdateNode):void
		{
			if(clip)
			{
				clip.gotoAndStop(1);
				
				var edge:Edge = new Edge();
				
				var edgeClip:DisplayObject = clip.getChildByName("edge");
				if(edgeClip)
				{
					edge.unscaled = edgeClip.getBounds(edgeClip.parent);
				}
				
				this.addDialog(node.entity, node.character.nextCharData, null);
				
				node.entity.add(edge);
				
				this.setSpatialFromEdge(node);
				
				node.display.swapDisplayObject(clip);
				this.addSceneInteraction(node);
				
				TimelineUtils.convertAllClips(clip, null, node.entity.group, true, 32, node.entity);
				
				var talk:Talk = node.entity.get(Talk);
				talk.instances.push(node.character.nextCharData.talkMouth);
				
				node.entity.add(new BitmapCharacter());
			}
			
			node.character.loadComplete.dispatch();
		}
		
		private function partsComplete( charEntity:Entity ):void
		{
			// activate animations
			var animControl:AnimationControl = charEntity.get( AnimationControl );
			animControl.removeSleep();
			
			// activate joints
			Rig( charEntity.get( Rig ) ).removeSleep();
			
			//  active fsm, if available
			var fsmControl:FSMControl = charEntity.get( FSMControl );
			if( fsmControl )
			{
				CharUtils.stateDrivenOn( charEntity );
			}
			
			// react activate screen based sleep once loading is complete (except in case of type player)
			var character:Character = charEntity.get(Character)
			if( character.type != CharacterCreator.TYPE_PLAYER )
			{
				Sleep(charEntity.get(Sleep)).ignoreOffscreenSleep = false;
			}
			
			// rlh: force pet eyes to be open (don't know why I have to do this - should work automatically)
			if ((charEntity.get(Character).type != CharacterCreator.TYPE_DUMMY) && (charEntity.get(Character).variant == CharacterCreator.VARIANT_PET_BABYQUAD))
			{
				SkinUtils.setEyeStates(charEntity, EyeSystem.OPEN);
			}
			
			// if mobile then track avatar load time
			if ((PlatformUtils.isMobileOS) && (charEntity == _shellApi.player))
			{
				var elapsed:Number = getTimer() - _trackingTimer;
				_shellApi.track("AvatarLoadTime", _shellApi.profileManager.active.login, null, null, "TimeSpent", elapsed);
			}
			
			// dispatch character complete
			character.loadComplete.dispatch();				// dispatched when all of part assets have completed loading, passes Chararacter component
		}
		
		////////////////////////////////////////////////////////////////
		/////////////////////////  INITIALIZE  /////////////////////////
		////////////////////////////////////////////////////////////////
		
		/**
		 * Begin character creation process.
		 * Retrieve appropriate variant data, once received initialize character.
		 * @param	node
		 * @param	charData
		 */
		private function createCharacter( node:CharacterUpdateNode ):void
		{
			var variantData:VariantData = getVariantData( node.character.variant );
			if ( variantData )	// once VariantData has loaded, continue with init
			{
				initChar( node, variantData );
				updateFromCharData(node);
			}
		}
		
		/**
		 * Retrieve variant from library.
		 * Variant data must be loaded from xml, will return null until load has completed.
		 * @param	variant
		 * @return
		 */
		private function getVariantData( variant:String ):VariantData
		{
			//MovieClip variants don't have variant-related XMLs since all MovieClip character can be different.
			
			var variantData:VariantData = _variantLibrary.getVariantData( variant );
			if(!variantData)							// if variantData null, then not yet loaded
			{
				if(variant == CharacterCreator.VARIANT_MOVIECLIP)
				{
					variantData = _variantLibrary.createVariantData(variant);
					_variantLibrary.onXMLLoaded(variantData);
				}
				else
				{
					_variantLibrary.add( variant );	// will load once, once complete getVariantData will return VariantData
				}
				
			}
			return variantData;
		}
		
		/**
		 * Complete character creation, adding necessary components.
		 * @param node
		 * @param variantData
		 */
		private function initChar( node:CharacterUpdateNode, variantData:VariantData ):void
		{
			var charEntity:Entity 		= node.entity;
			var display:Display 		= node.display;
			var charData:CharacterData	= node.character.nextCharData;
			
			// if mobile, then get start time for later tracking
			if ((PlatformUtils.isMobileOS) && (node.entity == _shellApi.player))
			{
				_trackingTimer = getTimer();
			}
			
			var sleep:Sleep = node.entity.get(Sleep);
			if( sleep == null )	{ sleep = new Sleep(); }
			// character entity should ignore offscreen sleep until loading is complete
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			charEntity.add(sleep);
			// adjust for character variant
			switch ( node.character.variant )
			{
				case CharacterCreator.VARIANT_CREATURE:
					charData.costumizable = false;
					charEntity.add(new Creature());
					break;
				case CharacterCreator.VARIANT_PET_BABYQUAD:
					charData.costumizable = false;
					charEntity.add(new Creature(CharacterCreator.VARIANT_PET_BABYQUAD));
					break;
				case CharacterCreator.VARIANT_APE:
					charData.costumizable = false;
					charEntity.add(new Creature( CharacterCreator.VARIANT_APE ));
					break;
				case CharacterCreator.VARIANT_MOVIECLIP:
					charData.costumizable = false;
					break;
				default:
					break;
			}
			
			if(node.character.variant != CharacterCreator.VARIANT_MOVIECLIP)
			{
				// set scale, if charData doesn't specify scale, use scale from variant's sizeDefault.xml
				var sizeData:SizeData = _sizeParser.parse( variantData.sizeXml );	// parse sizeXml
				node.spatial.scale = node.character.scaleDefault = ( isNaN(charData.scale) ) ? sizeData.scale : charData.scale;
				
				var edge:Edge = new Edge();
				var edgeState:EdgeState = new EdgeState();
				// Possible to have different edge parameters, say for when a charater is crouching
				for each ( var edgeData:EdgeData in sizeData.edgeDatas )
				{
					edgeState.add(edgeData);
					edge.unscaled.left = edgeData.left;
					edge.unscaled.top = edgeData.top;
					edge.unscaled.right = edgeData.right;
					edge.unscaled.bottom = edgeData.bottom;
				}
				//edge.setEdgeData( node.spatial.scale );	// apply scale to default EdgeData
				charEntity.add( edge );
				
				// add AnimationControl
				var animControl : AnimationControl = new AnimationControl();
				charEntity.add( animControl );
				
				// create & add Rig and joint & part entities
				var rig:Rig;
				//var skin:Skin;
				if ( charData.dynamicParts || PlatformUtils.isDesktop)
				{
					rig = _rigCreator.create( node.owningGroup.group, charEntity, variantData.rigXml );
					charEntity.add( rig );
					
					// create & add Skin and skinparts entities ( look is applied to skin later )
					_skinCreator.create( node.owningGroup.group, charEntity, rig, variantData.skinXml );
				}
				else	// only creates part & joint entities necessary to fulfill look requirements
				{
					// create LookData from default & current look values
					var look:LookData = _skinCreator.parseLookData( variantData.skinXml );
					look.merge( charData.look );
					
					// using look strip out unused parts from rig
					rig = new Rig();
					rig.data = _rigCreator.rigParser.parseWithLook( variantData.rigXml, look );
					_rigCreator.createJointsParts( node.owningGroup.group, charEntity, rig );
					charEntity.add( rig );
					
					// create & add Skin and skinparts entities ( look is applied to skin later )
					_skinCreator.create( node.owningGroup.group, charEntity, rig, variantData.skinXml );
				}
				
				// add springs/folowTargets
				if ( variantData.springXml )
				{
					if ( node.character.type == CharacterCreator.TYPE_PORTRAIT )
					{
						createFollowTargets( charEntity, rig, variantData.springXml );
					}
					else
					{
						createSprings( charEntity, rig, variantData.springXml );
					}
				}
				
				
				//add drawLimbs
				if ( node.character.variant != CharacterCreator.VARIANT_HEAD && node.character.variant != CharacterCreator.VARIANT_MANNEQUIN )
				{
					createDrawLimbs( charEntity, rig, node.character.variant, variantData.limbXml );
				}
				
				// NOTE :: Must have Rig & AnimControl added to character before making animSlotEntity
				AnimationSlotCreator.create( charEntity, null, 0 );
			}
			
			// npc interaction box
			var squareWidth:int = 250;
			var squareHeight:int = 300;
			
			
			// character type specific settings
			var sceneInteraction:SceneInteraction;
			var motionControl:MotionControl;	
			var motionTarget:MotionTarget;
			
			switch ( node.character.type )
			{
				case CharacterCreator.TYPE_PLAYER:
					
					charEntity.add(new Player());
					charEntity.add(new PlatformDepthCollider(1));
					
					// add Dialog & Talk
					addDialog( charEntity, charData, sizeData );
					
					// add fsm
					_charGroup.addFSM( charEntity, false );	// don't turn on until parts have finished loading
					
					// add audio
					_charGroup.addAudio( charEntity );
					
					// add control & navigation
					charEntity.add(new MotionControlInputMap());	// motion control driven by input		
					charEntity.add(new Navigation());				// target driven by path (used for doors)
					MotionControl(charEntity.get( MotionControl )).moveToTarget = false; // turn this off at first				
					
					// players can collide with items
					charEntity.add(new ItemCollider());
					
					// players swaps depth with other npcs based on y
					charEntity.add(new DepthChecker());
					
					// add interaction for player
					InteractionCreator.addToEntity(charEntity, [InteractionCreator.KEY_DOWN, InteractionCreator.KEY_UP]);
					
					// parts should not be clickable TODO : exception for costumizer
					display.displayObject.mouseChildren = false;
					break;
				
				case CharacterCreator.TYPE_NPC:
										
					charEntity.add(new Npc());
					//charEntity.add(new PlatformDepthCollider()); // Moved to AddColliders in CharacterGroup
					
					// needed for speech
					charEntity.add(new Audio());
					
					// Not sure we need these two? - Bard
					motionControl = new MotionControl();
					motionControl.lockInput = true;		// lock input so npc does not respond to input
					charEntity.add(motionControl);
					
					motionTarget = new MotionTarget();
					charEntity.add(motionTarget);
					
					// if pet, then no interaction
					if (node.character.variant == CharacterCreator.VARIANT_PET_BABYQUAD)
					{
						CharUtils.setAnim( charEntity, Stand );
					}
					else if(node.character.variant != CharacterCreator.VARIANT_MOVIECLIP)
					{
						// add Dialog
						this.addDialog( charEntity, charData, sizeData );
						this.addHitArea(node);
						this.addSceneInteraction(node);
						CharUtils.setAnim( charEntity, Stand );
					}
					break;
				
				case CharacterCreator.TYPE_DUMMY:
					CharUtils.setAnim( charEntity, Stand );
					break;
				case CharacterCreator.TYPE_PORTRAIT:
					CharUtils.setAnim( charEntity, Stand );
					CharUtils.getTimeline( charEntity ).stop();
					break;			
			}
		}
		
		private function setSpatialFromEdge(node:CharacterUpdateNode):void
		{
			var nextCharData:CharacterData = node.character.nextCharData;
			
			// position from data
			if( node.character.nextCharData.position != null )
			{
				node.spatial.x = nextCharData.position.x;
				node.spatial.y = nextCharData.position.y;
			}
			else
			{
				node.spatial.x = 0;
				node.spatial.y = 0;
			}
			
			var edge:Edge = node.entity.get(Edge);
			
			if(edge)
			{
				node.spatial.y -= edge.unscaled.bottom * node.spatial.scaleY;
			}
			
			if(node.spatial.scaleX >= 0 && nextCharData.direction == CharUtils.DIRECTION_RIGHT)
			{
				node.spatial.scaleX *= -1;
			}
			else if(node.spatial.scaleX < 0 && nextCharData.direction == CharUtils.DIRECTION_LEFT)
			{
				node.spatial.scaleX *= -1;
			}
		}
		
		private function addSceneInteraction(node:CharacterUpdateNode):void
		{
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = 120;
			sceneInteraction.offsetY = 0;
			sceneInteraction.minTargetDelta.x = 25;
			sceneInteraction.minTargetDelta.y = 100;
			node.entity.add(sceneInteraction);
			
			// add interaction for npc
			var interaction:Interaction = InteractionCreator.addToEntity(node.entity, [InteractionCreator.CLICK]);
		}
		
		/**
		 * Adds invisible square for clicking.
		 * @param node
		 * @param edge
		 * 
		 */
		private function addHitArea( node:CharacterUpdateNode, multiplier:Number = 1 ):void
		{
			// add invisible square for clicking.  TODO : make this based on charScale, handled elsewhere.
			var edge:Edge = node.entity.get(Edge);
			var display:Display = node.display;

			// use edge to determine rectangle
			// add invisible square for clicking.  TODO : make this based on charScale, handled elsewhere.
			var square:MovieClip = display.displayObject as MovieClip;
			square.graphics.beginFill(0xFFFFFF,0);
			square.graphics.drawRect(-HIT_AREA_WIDTH/2,-HIT_AREA_HEIGHT/1.7,HIT_AREA_WIDTH,HIT_AREA_HEIGHT);
			//square.graphics.drawRect(edge.unscaled.left * multiplier, edge.unscaled.top * multiplier, edge.unscaled.width * multiplier, edge.unscaled.height * multiplier);
			square.graphics.endFill();
		}
		
		private function addDialog( charEntity:Entity, charData:CharacterData, sizeData:SizeData):void
		{
			// add Dialog
			var dialog:Dialog = charEntity.get(Dialog);
			if(dialog == null)
			{
				dialog = new Dialog();
				charEntity.add(dialog);
			}
			dialog.faceSpeaker = charData.faceSpeaker;
			
			if ( sizeData && sizeData.dialogPositionPercent )
			{
				dialog.dialogPositionPercents = sizeData.dialogPositionPercent;
			}
			else
			{
				dialog.dialogPositionPercents = new Point(0, 1);
			}
			
			// add Talk
			var talk:Talk = new Talk();
			if( charData.talkMouth )
			{
				talk.talkPart = charData.talkMouth;
			}
			charEntity.add( talk );
		}
		
		/**
		 * Create springs.
		 * @param	character
		 * @param	rig
		 * @param	springXML
		 */
		private function createSprings(character:Entity, rig:Rig, springXML:XML):void
		{
			var spring:Spring;
			var springData:SpringData;
			var springSet:SpringSet;
			var joint:Entity;
			var spatial:Spatial;
			
			springSet = _springParser.parseSet( springXML );
			
			for ( var i:int = 0; i < springSet.springs.length; i++ )
			{
				springData = springSet.springs[i];
				joint = rig.getJoint( springData.joint );
				if( joint == null )	{ continue; }
				
				if ( springData.rotateByVelocity )
				{
					springData.rotateRatio = .5;
				}
				else if ( springData.rotateByLeader )
				{
					springData.rotateRatio = .8;
				}
				
				spring = new Spring();
				spring.applyData( springData );
				spring.startPositioned = true;
				spring.leader = rig.getJoint(springData.leader).get(Spatial);
				joint.add( spring );
			}
		}
		
		private function createFollowTargets(character:Entity, rig:Rig, springXML:XML):void
		{
			var followTarget:FollowTarget;
			var springData:SpringData;
			var jointEntity:Entity;
			var leaderJoint:Entity;
			
			var springSet:SpringSet = _springParser.parseSet( springXML );
			
			for ( var i:int = 0; i < springSet.springs.length; i++ )
			{
				springData = springSet.springs[i];
				jointEntity = rig.getJoint( springData.joint );
				leaderJoint = rig.getJoint( springData.leader )
				if( jointEntity == null || leaderJoint == null  )	{ continue; }
				followTarget = new FollowTarget();
				followTarget.target = leaderJoint.get(Spatial);
				followTarget.offset = new Point( springData.offsetX, springData.offsetY );
				jointEntity.add( followTarget );
				// TODO :: Need to account for possible joint roatation.  below don;t cut the musatrd. - bard
				/*
				if( springData.rotateByLeader )
				{
					followTarget.accountForRotation = true;
				}
				*/
			}
		}
		
		/**
		 * Sets up components for drawing limbs.
		 * @param character
		 * @param rig
		 * @param bottom - delta of character center and character bottom, prior to scaling
		 * @param variant
		 * 
		 */
		private function createDrawLimbs(character:Entity, rig:Rig, variant:String, limbXML:XML=null ):void
		{
			var line:Line;
			//line.lineWidth;/// = 4;		// TODO :: line width should be defined and updated by the skin
			var maxDist:Number;/// 	= ( variant == CharacterCreator.VARIANT_CREATURE ) ? 60 : 80;
			var offset:int;///; = -36;
			var drawLimb:DrawLimb;
			var joint:Entity;
			var limbData:DrawLimbData;
			var limbSet:DrawLimbSet;
			
			limbSet = _limbParser.parseSet(limbXML);

			for( var number:int = 0; number < limbSet.limbs.length; number ++ )
			{
				limbData = limbSet.limbs[ number ];
				line = new Line();
				
				joint = CharUtils.getPart( character, limbData.joint );
				if( joint == null )	{ continue; }
									
				drawLimb = new DrawLimb();
				drawLimb.leader = rig.getJoint( limbData.leader ).get( Spatial );
				drawLimb.applyData( limbData );
				line.lineWidth = drawLimb.lineWidth;
				
				joint.add( drawLimb );
				joint.add( line );
			}
		}
		
		[Inject]
		public var _variantLibrary:VariantLibrary;
		[Inject]
		public var _shellApi:ShellApi;
		
		private const HIT_AREA_WIDTH:int 	= 250;
		private const HIT_AREA_HEIGHT:int 	= 300;
		
		public var loadComplete:Signal;			// dispatched once all initial characters have been loaded with assets 
		public var sceneBounds:Rectangle;		// used when creating collisions
		
		private var _springParser:SpringParser;
		private var _limbParser:DrawLimbParser;
		private var _rigCreator:RigCreator;
		private var _skinCreator:SkinCreator;
		private var _sizeParser:SizeParser;
		private var _charGroup:CharacterGroup;
		private var _trackingTimer:Number;
	}
}


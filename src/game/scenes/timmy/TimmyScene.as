package game.scenes.timmy
{		
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.hit.Bounce;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.BitmapTimeline;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMaster;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ParamList;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.WaveFront;
	import game.data.game.GameEvent;
	import game.data.sound.SoundAction;
	import game.data.sound.SoundModifier;
	import game.nodes.entity.character.NpcNode;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.timmy.shared.popups.DetectiveLogPopup;
	import game.systems.entity.character.CharacterDepthSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.BounceHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.render.PlatformDepthCollisionSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quartic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class TimmyScene extends PlatformerGameScene
	{
		protected var _total:Entity;
		protected var _events:TimmyEvents;
		protected var _audioGroup:AudioGroup;
		protected var _characterGroup:CharacterGroup;
		protected var _itemGroup:ItemGroup;
		protected var _totalDistraction:Boolean 	=	false;
		protected var _trashBounce:Bounce;
		
		private var _stinkTimeline:Timeline;
		private var _stinkSequence:BitmapSequence;
		private var blinkTimers:Vector.<TimedEvent> = new <TimedEvent>[];
		
		protected const TRIGGER:String 				=	"trigger";
		protected const TRIGGER_OUT:String 			=	"trigger_out";
		protected const BLINK:String 				=	"blink";
		protected const TIRE:String 				=	"tire";
		
		private const BACK:String 					=	"back";
		private const FRONT:String 					=	"front";
		private const PANTS:String 					=	"pants";
		private const TIMMYS_HOUSE:String 			=	"TimmysHouse";
		private const CLINK:String 					=	"clink";
		private const CLIP:String 					=	"clip";
		private const DROP:String 					=	"drop";
		private const DROP_BOX:String 				=	"drop_box";
		private const EAT:String 					=	"eat";
		private const GRAB:String 					=	"grab";
		private const HINGE:String 					=	"hinge";
		private const HIT:String 					=	"hit";
		private const KNOCK:String 					=	"knock";
		private const PANT:String 					=	"pant";
		private const PEDAL:String 					=	"pedal";
		private const SING:String 					=	"sing";
		private const SLAP:String 					=	"slap";
		private const STRUGGLE:String 				=	"struggle";
		private const DRIVE:String 					=	"drive";
		private const STINK_TIMELINE_PATH:String = "scenes/timmy/shared/stinkTimeline.swf";
		private const AUDIO_RANGE_DEFAULT:int = 1000;
		
		override public function destroy():void
		{
			/*
			Reset Total's presence after every scene. He could've been present for one scene, but
			in the next scene he isn't following anymore.
			*/
			this.shellApi.removeEvent(_events.TOTAL_PRESENT);
			shellApi.eventTriggered.remove( eventTriggered );
			
			var timer:TimedEvent;
			while( blinkTimers.length > 0 )
			{
				timer 					=	blinkTimers.pop();
				timer.stop();
				timer 					=	null;
			}
			blinkTimers					=	null;
			
			if( _stinkSequence != null )
			{
				_stinkSequence.destroy();
			}
			_stinkSequence = null
			_stinkTimeline = null;
			
			super.destroy();
		}
		
		public function TimmyScene()
		{
			super();
		}
		
		override public function loaded():void
		{
			_events 								=	shellApi.islandEvents as TimmyEvents;
			_audioGroup 							=	getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_characterGroup 						=	getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			_itemGroup 								=	getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			
			if( getSystem( PlatformDepthCollisionSystem ))
			{
				removeSystemByClass( PlatformDepthCollisionSystem );
				addSystem( new CharacterDepthSystem());
			}
			
			shellApi.eventTriggered.add( eventTriggered );
			
			this.addSystem(new BounceHitSystem());
			
			setupNpcStepAudio();
			setupTotal();
			setupTrash();
			super.loaded();
		}
		
		private function setupTotal():void
		{
			_total 										=	getEntityById( "total" );
			
			if( _total )
			{
				if(!_total.get(FSMControl))
				{
					_characterGroup.addFSM( _total );
				}
				var fsmControl:FSMControl = _total.get(FSMControl);
				fsmControl.removeState(CharacterState.JUMP);
				
				var displayObject:MovieClip 							=	Display( _total.get( Display )).displayObject as MovieClip;
				displayObject.mouseChildren 							=	false;
				displayObject.mouseEnabled								=	false;
				
				_total.remove( SceneInteraction );
				ToolTipCreator.removeFromEntity( _total );
				
				if( shellApi.sceneName != TIMMYS_HOUSE || shellApi.checkEvent( _events.TOTAL_FOLLOWING ))
				{
					if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ))
					{
						this.setHideTotal(false);
						var playerSpatial:Spatial = player.get(Spatial);
						var totalSpatial:Spatial = _total.get(Spatial);
						totalSpatial.x = playerSpatial.x;
						totalSpatial.x += playerSpatial.scaleX < 0 ? -100 : 100;
						CharUtils.faceTargetEntity(_total, player);
						this.totalFollow();
					}
					else
					{
						setHideTotal(true);
					}
				}
				else if( shellApi.sceneName == TIMMYS_HOUSE )
				{
					this.setHideTotal(false);
					this.shellApi.completeEvent(_events.TOTAL_PRESENT);
				}
			}
		}		
		
		protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var dialog:Dialog 								=	player.get( Dialog );
			if( event == _events.CALL_TOTAL )
			{
				if( !( shellApi.checkEvent( _events.FREED_ROLLO ) && !shellApi.checkEvent( _events.FREED_TOTAL )))
				{
					if(!this.shellApi.checkEvent(_events.TOTAL_PRESENT))
					{
						this.callTotalOver();
					}
				}
				else
				{
					dialog.sayById( "free_total" );
				}
			}
			else if( event == _events.USE_TREATS )
			{
				this.feedTotalAndThen(this.totalFollow);
			}
			else if( event == _events.USE_BONBONS )
			{
				this.feedTotalAndThen(this.totalDance);
			}
				
			else if(event.indexOf("hasItem_") != -1 && !shellApi.checkEvent( _events.CHASE_COMPLETE )){
				checkForAssembledParts(event);
			}
			else if( event == _events.GOT_DETECTIVE_LOG_PAGE + "9" && !shellApi.checkEvent( _events.CHASE_COMPLETE ))
			{
				checkForAssembledParts(event);				
			}
		}
		
		protected function setupNpcStepAudio():void
		{
			var npcNodes:NodeList 		= 	systemManager.getNodeList( NpcNode );
			var npcNode:NpcNode;
			var npc:Entity;
			var timeline:Timeline;
			var id:Id;
			var blink:Entity;
			var blinkTimer:TimedEvent;
			
			for( npcNode = npcNodes.head; npcNode; npcNode = npcNode.next )
			{
				npc 					=	npcNode.entity;
				
				//This is to avoid picking up ad NPCs, but it's not great...
				if(!npc.get(Character)) continue;
				
				id						=	npc.get( Id );
				_characterGroup.addAudio( npc );
				npc.add( new AudioRange( 1200 ));
				
				timeline = npc.get( Timeline );
				if(timeline)
				{
					timeline.labelReached.add( Command.create( playCharacterAudio, npc ));
				}
				
				// ADD BLINK's
				var children:Children = Children( npc.get( Children ));
				if (children)
				{
					blink					=	children.getChildByName( BLINK );
					if( blink )
					{
						blinkTimer	 		=	 new TimedEvent(( Math.random() * 10 ) + 7, 0, Command.create( npcBlink, blink ))
						blinkTimers.push( blinkTimer );
						
						if(id)
						{
							SceneUtil.addTimedEvent( this, blinkTimer, id.id + "blink" );
						}
					}
				}
			}
		}
		
		private function npcBlink( blink:Entity ):void
		{
			var timeline:Timeline		=	blink.get( Timeline );
			if(timeline){
				timeline.gotoAndPlay( "blink" );
			}
		}
		
		private function playCharacterAudio( label:String, character:Entity ):void
		{
			var audio:Audio 			=	character.get( Audio );
			var hitAudio:HitAudio 		=	character.get( HitAudio );
			var path:String;
			
			
			if( label.indexOf( SoundAction.STEP ) > -1 && label.indexOf( SoundAction.STEP ) < 1 )
			{ 
				if( hitAudio )
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.STEP;
				}
			}
			else if( label.indexOf( SoundAction.IMPACT ) > -1 && label.indexOf( SoundAction.IMPACT ) < 1 )
			{
				if( hitAudio )
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.IMPACT;
				}
			}
			else if( label.indexOf( CLINK ) > -1 && label.indexOf( CLINK ) < 1 )
			{
				path 				=	"metal_ball_tap_06.mp3";
			}
			else if( label.indexOf( CLIP ) > -1 && label.indexOf( CLIP ) < 1 )
			{
				path 				=	"coin_02.mp3";
			}
			else if( label.indexOf( DROP ) > -1 && label.indexOf( DROP ) < 1 )
			{
				if( hitAudio )
				{
					hitAudio.active = true;
					hitAudio.action = SoundAction.IMPACT;
				}
			}
			else if( label.indexOf( DROP_BOX ) > -1 && label.indexOf( DROP_BOX ) < 1 )
			{
				path 				=	"falling_01.mp3";
			}
				
			else if( label.indexOf( EAT ) > -1 && label.indexOf( EAT ) < 1 )
			{
				path 				=	"chewing_2a.mp3";
			}
			else if( label.indexOf( GRAB ) > -1 && label.indexOf( GRAB ) < 1 )
			{
				path 				=	"metal_impact_05.mp3";
			}
			else if( label.indexOf( HINGE ) > -1 && label.indexOf( HINGE ) < 1 )
			{
				path 				=	"creaky_metal_03.mp3";
			}
			else if( label.indexOf( HIT ) > -1 && label.indexOf( HIT ) < 1 )
			{
				path 				=	"whack_01.mp3";
			}
			else if( label.indexOf( KNOCK ) > -1 && label.indexOf( KNOCK ) < 1)
			{
				path 				=	"ls_glass_01.mp3";
			}
			else if( label.indexOf( PANT ) > -1 && label.indexOf( PANT ) < 1 )
			{
				path 				=	"lion_roar_01.mp3";
			}
			else if( label.indexOf( PEDAL ) > -1 && label.indexOf( PEDAL ) < 1 )
			{
				path 				=	"metal_chains_02.mp3";
			}			
			else if( label.indexOf( SING ) > -1 && label.indexOf( SING ) < 1 )
			{
				path 				=	"retro_chatter_04.mp3";
			}
			else if( label.indexOf( SLAP ) > -1 && label.indexOf( SLAP ) < 1 )
			{
				path 				=	"npc_click_01.mp3";
			}
			else if( label.indexOf( STRUGGLE ) > -1 && label.indexOf( STRUGGLE ) < 1 )
			{
				path 				=	"rubber_stretch_14.mp3";
			}
			
			if( path )
			{
				audio.play( SoundManager.EFFECTS_PATH + path, false, SoundModifier.POSITION );
			}
		}
		
		protected function showDetectivePage( pageNumber:int, handler:Function = null ):void
		{			
			var popup:DetectiveLogPopup		=	addChildGroup( new DetectiveLogPopup()) as DetectiveLogPopup;
			popup.id = "detectivePopup";
			var paramList:ParamList 		=	new ParamList();
			paramList.addParam( "totalPages", 9 );
			paramList.addParam( "pageEvent", "got_detective_log_page_" );
			paramList.addParam( "bookEvent", "gotItem_detective_log" );
			paramList.addParam( "screenAsset", "detective_log.swf" );
			paramList.addParam( "groupPrefix", "scenes/timmy/shared/popups/" );
			paramList.addParam( "flipPages", true );
			
			popup.setParams( paramList );
			
			popup.closeClicked.addOnce( Command.create( relockScene, handler ));			
			popup.init( overlayContainer );
			popup.ready.addOnce( Command.create( popup.openToPage, pageNumber ));
			
		}
		
		private function relockScene( popup:DetectiveLogPopup, handler:Function ):void
		{
			if( handler )
			{
				handler();
			}
		}
		
		protected function callTotalOver(...p):void
		{
			CharUtils.faceTargetEntity(player, _total);
			CharUtils.setAnim(player, WaveFront);
			
			var sleep:Sleep = _total.get(Sleep);
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			Display(_total.get(Display)).visible = true;
			
			var playerSpatial:Spatial = player.get(Spatial);
			var totalSpatial:Spatial = _total.get(Spatial);
			CharUtils.moveToTarget(_total, playerSpatial.x, totalSpatial.y, false, totalReached, new Point(180, 100));
		}
		
		private function totalReached(...p):void
		{
			shellApi.completeEvent(_events.TOTAL_FOLLOWING);
			CharUtils.triggerSpecialAbility(player);
		}
		
		private function checkForAssembledParts(event:String):void
		{
			// lazy bear 2000
			if(shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE+"2") && !shellApi.checkEvent( _events.GOT_ALL_LAZYBEAR_PARTS )){
				if( event == GameEvent.HAS_ITEM +_events.BOX && shellApi.checkHasItem(_events.PERMANENT_MARKER) && shellApi.checkHasItem(_events.CAMERA)){
					lazybearReady();
				}
				else if( event == GameEvent.HAS_ITEM + _events.PERMANENT_MARKER && shellApi.checkHasItem(_events.CAMERA) && shellApi.checkHasItem(_events.BOX)){
					lazybearReady();			
				}
				else if( event == GameEvent.HAS_ITEM + _events.CAMERA && shellApi.checkHasItem(_events.BOX) && shellApi.checkHasItem(_events.PERMANENT_MARKER)){
					lazybearReady();			
				}
			}
			
			// total mobile
			if(shellApi.checkEvent(_events.GOT_DETECTIVE_LOG_PAGE+"9") && !shellApi.checkEvent( _events.GOT_ALL_TOTALMOBILE_PARTS )){
				if( event ==  GameEvent.HAS_ITEM + _events.WAGON && shellApi.checkHasItem(_events.BUCKET) && shellApi.checkHasItem(_events.CHICKEN_NUGGETS) && shellApi.checkHasItem(_events.ROPE)){
					totalMobileReady();
				}
				else if( event ==  GameEvent.HAS_ITEM + _events.BUCKET && shellApi.checkHasItem(_events.CHICKEN_NUGGETS) && shellApi.checkHasItem(_events.ROPE) && shellApi.checkHasItem(_events.WAGON)){
					totalMobileReady();
				}
				else if( event ==  GameEvent.HAS_ITEM + _events.CHICKEN_NUGGETS && shellApi.checkHasItem(_events.ROPE) && shellApi.checkHasItem(_events.WAGON) && shellApi.checkHasItem(_events.BUCKET)){
					totalMobileReady();
				}
				else if( event ==  GameEvent.HAS_ITEM + _events.ROPE && shellApi.checkHasItem(_events.WAGON) && shellApi.checkHasItem(_events.BUCKET) && shellApi.checkHasItem(_events.CHICKEN_NUGGETS)){
					totalMobileReady();
				}
				else if( event == _events.GOT_DETECTIVE_LOG_PAGE + "9" && shellApi.checkHasItem(_events.BUCKET) && shellApi.checkHasItem(_events.CHICKEN_NUGGETS) && shellApi.checkHasItem(_events.ROPE) && shellApi.checkHasItem( _events.WAGON ))
				{
					totalMobileReady();
				}
			}
		}
		
		private function lazybearReady():void
		{
			EntityUtils.removeAllWordBalloons(this);
			var dialog:Dialog =	player.get( Dialog );
			dialog.sayById("got_lazybear");
			shellApi.completeEvent(_events.GOT_ALL_LAZYBEAR_PARTS);
		}
		
		private function totalMobileReady():void
		{
			var dialog:Dialog =	player.get( Dialog );
			dialog.sayById("got_totalmobile");
			shellApi.completeEvent(_events.GOT_ALL_TOTALMOBILE_PARTS);
		}
		
		protected function totalUnfollow():void
		{
			CharUtils.stopFollowEntity( _total );
			shellApi.removeEvent( _events.TOTAL_FOLLOWING );
		}
		
		protected function totalFollow():void
		{
			this.shellApi.completeEvent(_events.TOTAL_PRESENT);
			
			var display:Display 		=	_total.get( Display );
			//		display.alpha 				=	1;
			display.visible 			=	true;
			
			CharUtils.stateDrivenOn(_total);
			CharUtils.followEntity(_total, player, new Point( 240, 100 ));
			shellApi.completeEvent( _events.TOTAL_FOLLOWING );
		}
		
		// move total out of the way
		protected function setHideTotal(hide:Boolean):void
		{
			var sleep:Sleep = _total.get( Sleep );
			if( !sleep )
			{
				sleep =	new Sleep();
				_total.add( sleep );
			}
			sleep.sleeping = hide;
			sleep.ignoreOffscreenSleep = true;
			
			Display( _total.get( Display )).visible = !hide;
		}
		
		protected function positionTotal( isOnLeft:Boolean, handler:Function = null ):void
		{
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ))
			{
				var targetX:Number 					=	isOnLeft ? -200 : 200;
				CharUtils.moveToTarget( _total, Spatial( player.get( Spatial )).x + targetX, Spatial( _total.get( Spatial )).y, true, Command.create( totalFacePlayer, isOnLeft, handler ),new Point(50,100));
			}
			else
			{
				if(handler){
					handler();
				}
			}
		}
		
		private function totalFacePlayer( total:Entity, isOnLeft:Boolean, handler:Function  = null):void
		{
			CharUtils.setDirection( _total, isOnLeft );
			CharUtils.followEntity(_total, player, new Point( 200, 100 ));
			if(handler){
				handler();
			}
		}
		
		/**
		 * DISTRACT WITH BONBONS
		 */
		protected function totalDance():void
		{
			Timeline(_total.get(Timeline)).gotoAndPlay("dance");
			_totalDistraction = true;
			
			var npcNodes:NodeList =	systemManager.getNodeList( NpcNode );//.head as NpcNode;
			
			for( var npcNode:NpcNode = npcNodes.head; npcNode; npcNode = npcNode.next )
			{
				var npcEntity:Entity =	npcNode.entity;
				if(npcEntity.sleeping) continue;
				
				if( npcEntity != _total )
				{
					// MAKE THEM DISTRACTED
					
					//Drew - Checking if the NPC is a MovieClip-based entity
					var character:Character = npcEntity.get(Character);
					if(character.variant == CharacterCreator.VARIANT_MOVIECLIP)
					{
						CharUtils.stateDrivenOff(npcEntity);
						Timeline(npcEntity.get(Timeline)).gotoAndPlay("distracted");
						
						CharUtils.faceTargetEntity(npcEntity, _total);
					}
					else
					{
						CharUtils.setAnimSequence( npcEntity, new <Class>[ Dizzy, Dizzy ], true );
					}
				}
			}
		}
		
		protected function stopDistractedNPCs():void
		{
			_totalDistraction = false;
			
			var npcNodes:NodeList =	systemManager.getNodeList( NpcNode );
			
			for( var npcNode:NpcNode = npcNodes.head; npcNode; npcNode = npcNode.next )
			{
				var npcEntity:Entity =	npcNode.entity;
				// apparentally you may be able to have an npc with out a character...
				var character:Character = npcEntity.get(Character);
				if( npcEntity != _total && character)
				{
					// MAKE THEM DISTRACTED
					
					//Drew - Checking if the NPC is a MovieClip-based entity
					
					if(character.variant == CharacterCreator.VARIANT_MOVIECLIP)
					{
						CharUtils.stateDrivenOff(npcEntity);
						Timeline(npcEntity.get(Timeline)).gotoAndPlay("stand");
					}
					else
					{
						CharUtils.setAnim(npcEntity, Stand);
					}
				}
			}
		}
		
		/**
		 * Templatized way of feeding Total, followed by either following you or dancing. The current options for a handler are totalDance() or totalFollow().
		 */
		protected function feedTotalAndThen(handler:Function):void
		{
			this.totalReset();
			
			CharUtils.faceTargetEntity(player, _total);
			CharUtils.faceTargetEntity(_total, player);
			
			var timeline:Timeline = _total.get(Timeline);
			timeline.gotoAndPlay("treat");
			timeline.handleLabel("treat_end", handler);
		}
		
		protected function totalReset():void //See what I did there?!
		{
			this.showTrash(true); //Revert trash cans back to being visible.
			this.toggleTrashBounce( false );
			
			this.stopDistractedNPCs();
			
			this.totalUnfollow();
			CharUtils.stateDrivenOff(_total);
			Motion(_total.get(Motion)).zeroMotion("x");
			Sleep(_total.get(Sleep)).sleeping = false;
			
			var timeline:Timeline = _total.get(Timeline);
			timeline.removeLabelHandler(this.totalDance);
			timeline.removeLabelHandler(this.totalFollow);
		}
		
		/**
		 * TRASH LOGIC
		 */
		private function setupTrash():void
		{
			var trash:Entity = this.getEntityById("trashInteraction");
			if(trash)
			{
				var trashDisplay:DisplayObjectContainer = Display(trash.get(Display)).displayObject;
				var bounds:Rectangle = trashDisplay.getBounds(trashDisplay);
				var flies:SwarmingFlies = new SwarmingFlies();
				flies.init(new Point(0, bounds.top));
				EmitterCreator.create(this, trashDisplay, flies);
				var sceneInteraction:SceneInteraction = trash.get(SceneInteraction);
				sceneInteraction.reached.add( playerReachedTrash );
				
				_audioGroup.addAudioToEntity( trash );
				trash.add( new AudioRange( 600 ));
				Audio( trash.get( Audio )).playCurrentAction( TRIGGER );
				
				this.showTrash(true);
				toggleTrashBounce( false );
			}
		}
		
		private function playerReachedTrash( player:Entity, trash:Entity ):void
		{
			if( shellApi.checkEvent( _events.TOTAL_FOLLOWING ))
			{
				var trashBounce:Entity = this.getEntityById("trashBounce");
				if(trashBounce)
				{
					this.totalUnfollow();
					var trashSpatial:Spatial = trashBounce.get(Spatial);
					
					CharUtils.moveToTarget(_total, trashSpatial.x, trashSpatial.y, false, Command.create(totalReachedTrash, trash), new Point(10, 100));
				}
			}
			else
			{
				if( shellApi.checkEvent( _events.UNLOCKED_CABINET ))
				{
					Dialog( player.get( Dialog )).sayById( "wheres_total" );	
				}
				else
				{
					Dialog( player.get( Dialog )).sayById( "cant_use_trash" );
				}
			}
		}
		
		private function totalReachedTrash(total:Entity, trash:Entity):void
		{
			if(!shellApi.checkEvent( _events.TOTAL_FOLLOWING ))
			{				
				CharUtils.stateDrivenOff(_total);
				CharUtils.faceTargetEntity(_total, trash);
				
				var timeline:Timeline = _total.get(Timeline);
				timeline.gotoAndPlay("trash");
				timeline.handleLabel( "hide_trash", showTrash );//(false);
				timeline.handleLabel( "impact", toggleTrashBounce );
			}
		}
		
		protected function showTrash( show:Boolean = false ):void
		{
			var trash:Entity = this.getEntityById("trashInteraction");
			if(trash)
			{
				Display(trash.get(Display)).visible = show;
				if(show)
				{
					ToolTipCreator.addToEntity(trash);
				}
				else
				{
					ToolTipCreator.removeFromEntity(trash);
				}
			}
		}
		
		private function toggleTrashBounce( on:Boolean = true ):void
		{
			var trashBounce:Entity = this.getEntityById("trashBounce");
			if(trashBounce)
			{
				if( on )
				{
					if(_trashBounce)
						trashBounce.add(_trashBounce);
				}
				else
				{
					var bounce:Bounce = trashBounce.remove(Bounce) as Bounce;
					this._trashBounce = bounce ? bounce : this._trashBounce;
				}
			}
		}
		
		// GENERIC ENTITY CREATOR, ADDS SOUNDS, OPTIONAL BITMAP SEQUENCE AND TIMELINE PARAMETERS
		protected function makeEntity( asset:MovieClip, sequence:BitmapSequence = null, frameLabel:String = null, playing:Boolean = false, quality:Number = NaN ):Entity
		{
			var entity:Entity;
			var timeline:Timeline;
			var bitmapQuality:Number 								=	 quality ? quality : PerformanceUtils.defaultBitmapQuality + 1.0;
			
			if( sequence )
			{
				entity 												=	EntityUtils.createSpatialEntity( this, asset );
				entity 												=	BitmapTimelineCreator.convertToBitmapTimeline( entity, asset, true, sequence, bitmapQuality );
				timeline 											=	entity.get( Timeline );
				
				if( frameLabel )
				{
					if( playing )
					{
						timeline.gotoAndPlay( frameLabel );						
					}
					else
					{
						timeline.gotoAndStop( frameLabel );
					}
				}
				else
				{
					timeline.gotoAndStop( 0 );
				}
			}
			else
			{
				if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH){
					super.convertContainer( asset, bitmapQuality );
				}
				entity 												=	EntityUtils.createSpatialEntity( this, asset );				
			}
			entity.add( new Id( asset.name )).add( new AudioRange( 1200 ));
			_audioGroup.addAudioToEntity( entity );
			
			return entity;
		}
		
		
		// cars
		protected function makeAutomobile( group:Group, asset:MovieClip, moveToTop:Boolean = true ):Entity 
		{
			var vehicle:Entity;
			var tire:Entity;
			
			var number:int 								=	1;
			var tireClip:MovieClip		 				=	asset[ TIRE + number ];
			
			vehicle								=	EntityUtils.createSpatialEntity( this, asset );	
			vehicle.add( new Id( asset.name )).add( new Motion()).add( new AudioRange( 1200 ));
			_audioGroup.addAudioToEntity( vehicle );
			
			if( moveToTop )
			{
				DisplayUtils.moveToTop( Display( vehicle.get( Display )).displayObject );
			}
			
			if( asset[ PANTS ])
			{
				super.convertContainer( asset[ PANTS ], PerformanceUtils.defaultBitmapQuality + 1.0 );
			}
			
			if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
			{
				if( asset[ FRONT ])
				{
					super.convertContainer( asset[ FRONT ], PerformanceUtils.defaultBitmapQuality + 1.0 );
				}
				if( asset[ BACK ])
				{
					super.convertContainer( asset[ BACK ], PerformanceUtils.defaultBitmapQuality + 1.0 );					
				}
			}
			
			do{
				if( PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH )
				{
					super.convertContainer( tireClip, PerformanceUtils.defaultBitmapQuality + 1.0 );
				}
				tire 								=	EntityUtils.createSpatialEntity( this, tireClip );
				tire.add( new Id( TIRE + number )).add( new Motion());
				
				number ++;
				tireClip 								=	asset[ TIRE + number ];
				EntityUtils.addParentChild( tire, vehicle );
			}while( tireClip );
			
			
			return vehicle;
		}
		
		protected function moveVehicle( vehicle:Entity, destinationX:Number, velocity:Number, handler:Function ):void
		{
			var spatial:Spatial 				=	vehicle.get( Spatial );
			rotateWheels( vehicle, velocity );
			
			var motion:Motion 					=	vehicle.get( Motion );
			motion.velocity.x 					=	velocity;
			
			var audio:Audio	 					=	vehicle.get( Audio );
			audio.playCurrentAction( DRIVE );
			
			var operator:String 				=	spatial.x > destinationX ? "<=" : ">=";
			var threshold:Threshold 			=	new Threshold( "x", operator );
			threshold.threshold 				=	destinationX;
			threshold.entered.addOnce( Command.create( handler, vehicle ));
			vehicle.add( threshold );
			
			if( !getSystem( ThresholdSystem ))
			{
				addSystem( new ThresholdSystem());
			}
		}
		
		protected function rotateWheels( vehicle:Entity, rotationVelocity:Number ):void
		{
			var motion:Motion;
			var number:int						=	1;	
			var tire:Entity;		
			
			tire 								=	EntityUtils.getChildById( vehicle, TIRE + number );
			do
			{
				motion							=	tire.get( Motion );
				motion.rotationVelocity			=	rotationVelocity;
				
				number ++;
				tire 							=	EntityUtils.getChildById( vehicle, TIRE + number );
			}while( tire );
		}
		
		protected function vehicleSmoke( vehicle:Entity, offset:Point = null, accel:Point = null ):void
		{
			if( PerformanceUtils.defaultBitmapQuality >= PerformanceUtils.QUALITY_MEDIUM )
			{
				var emitter2D:Emitter2D 							=	new Emitter2D;
				emitter2D.counter = new Random( 20, 25 );
				
				emitter2D.addInitializer( new ImageClass( Blob, [ 17, 0xEEEEEE ], true, 30 ));
				emitter2D.addInitializer( new AlphaInit( .6, .7 ));
				emitter2D.addInitializer( new Lifetime( 1, 2 )); 
				
				var startVelX:Point 			=	accel ? new Point( 20, -20 ) : new Point( -250, -20 );
				var startVelY:Point				=	accel ? new Point( 100, -40 ) : new Point( -300, -40 );
				emitter2D.addInitializer( new Velocity( new LineZone( startVelX, startVelY )));
				emitter2D.addInitializer( new Position( new EllipseZone( new Point( 0,0 ), 4, 3 )));
				
				emitter2D.addAction( new Age( Quartic.easeInOut ));
				emitter2D.addAction( new Move());
				emitter2D.addAction( new RandomDrift( 100, 100 ));
				emitter2D.addAction( new ScaleImage( .7, 1.5 ));
				emitter2D.addAction( new Fade( .8, .1 ));
				
				var accelX:Number 		=	 accel ? accel.x : 50;
				var accelY:Number 		=	 accel ? accel.y : -120;
				emitter2D.addAction( new Accelerate( accelX, accelY ));
				
				var offsetX:Number 		=	offset ? offset.x : 0;
				var offsetY:Number 		=	offset ? offset.y : 0;
				EmitterCreator.create( this, _hitContainer, emitter2D, offsetX, offsetY, vehicle, "exhaust", vehicle.get( Spatial ));
			}
		}
		
		/**
		 * Setup fly / trash stink movie clips
		 */
		public function setupStink( group:Group, clipToReplace:MovieClip = null, completeHandler:Function = null ):void
		{
			loadTimelineStink( group, clipToReplace, completeHandler );
		}
		
		private function loadTimelineStink( group:Group, clipToReplace:MovieClip = null, loadHandler:Function = null ):void
		{
			group.shellApi.loadFile( group.shellApi.assetPrefix + STINK_TIMELINE_PATH, Command.create( onTimelineStinkLoaded, null, clipToReplace, loadHandler ) );
		}
		
		private function onTimelineStinkLoaded( clip:MovieClip, entity:Entity = null, clipToReplace:MovieClip = null, loadHandler:Function = null ):void
		{
			if( _stinkSequence == null )
			{								
				_stinkSequence = BitmapTimelineCreator.createSequence( clip );
				_stinkTimeline = new Timeline();
				TimelineUtils.parseMovieClip( _stinkTimeline, clip );
				if( entity != null )
				{
					createTimelineStink( entity.group, clipToReplace, entity );
				}
				
				if( loadHandler != null )
				{
					loadHandler();
				}
			}
		}
		
		protected function createTimelineStink( group:Group, clipToReplace:DisplayObjectContainer = null, entity:Entity = null, addAudio:Boolean = false, target:Entity = null ):Entity
		{
			if( entity == null )
			{
				entity = EntityUtils.createSpatialEntity( group, clipToReplace );
				entity.add( new Id( "stink" ));
			}
			
			if( _stinkSequence == null )
			{
				group.shellApi.loadFile( group.shellApi.assetPrefix + STINK_TIMELINE_PATH, Command.create( onTimelineStinkLoaded, entity, clipToReplace ) );
			}
			else
			{
				entity.add( _stinkSequence );
				var timeline:Timeline = _stinkTimeline.duplicate();
				entity.add( timeline );
				entity.add( new TimelineMaster());
				timeline.reset();
				
				var display:Display = entity.get( Display );
				DisplayUtils.removeAllChildren( display.displayObject );
				
				var bitmapContainer:Bitmap = new Bitmap( null, "auto", true );
				display.displayObject.addChild( bitmapContainer );
				display.alpha = clipToReplace.alpha;
				MovieClip(display.displayObject).filters = new Array();	// remove any filters (should be applied during bitmap sequence creation)
				
				entity.add( new BitmapTimeline( bitmapContainer ));	
			}
			
			if( addAudio )
			{
				addStinkAudio( group, entity, clipToReplace.scaleX );
			}
			
			if( target )
			{
				var followTarget:FollowTarget 		=	new FollowTarget( target.get( Spatial ));
				followTarget.offset					=	new Point( 0, Edge( target.get( Edge )).rectangle.top );
				entity.add( followTarget );
				
				EntityUtils.addParentChild( entity, target );
			}
			
			return entity;
		}
		
		private function addStinkAudio( group:Group, entity:Entity, scale:Number ):void
		{
			entity.add( new AudioRange( AUDIO_RANGE_DEFAULT * scale, 0.01, 1 ));
			_audioGroup.addAudioToEntity( entity );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
	}
}
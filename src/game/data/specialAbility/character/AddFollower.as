// Used by:
// Cards 2446 (essix), 2548 (plane), 2520 (dragon), 2555 (ghd ship), 2686 (timmy), 2725 (woodstock)
// Card 2450 using ability follower_sebastian (4 text strings) - not in current repo
// Card 2582 using ability follower_skull_jar (disable flip and plays audio and animation)
// Card 2591 using ability follower_gold_fish (flip clip)
// Card 2593 using ability follower_sirena (disable flip and has text)
// card 2652 using ability follower _oh_pig (disable flip)
// Card 2682 using ability follower_car (swap clip)
// Card 2538 using ability follower_fairy_ring (disable flip)
// Cards 3051, 3075, 3148, 3159, 3263, 3303, 3333, 3341, 3359, 3381, 3448

package game.data.specialAbility.character
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.motion.TargetSpatial;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.specialAbility.character.Follower;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ColoredSmoke;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.specialAbility.character.FollowerSystem;
	import game.ui.hud.Hud;
	import game.util.CharUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.counters.Counter;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ExternalSwfImage;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.osflash.signals.Signal;
	
	/**
	 * Floating animating follower (swf) behind avatar
	 * 
	 * Required params:
	 * swfPath					String		Path to follower swf
	 * 
	 * Optional params:
	 * disableFlip				Boolean		Don't flip follower (default is false)
	 * clickableAnimation		Boolean		Animation plays when clicked
	 * flipClip					String		Name of clip to flip in animation
	 * swapClip					String		Name of clip to swap when flipping
	 * clickableAudioPath		String		Path to audio file
	 * clickableTextsCycle		Boolean		Text cycles instead of random
	 * clickableTextN			String		Text to show when clicked (can be one or more)
	 * playerTransparent		Boolean		Make player transparent (default if false)
	 * followerTransparent		Boolean		Make follower transparent (default if false)
	 * transparencyAmount		Number		Transparency value (default is 1)
	 * headTransparencyAmount	Number		Transparent value for player head (default is 1)
	 * useSpecialActionBtn		Boolean		Use special action button on mobile and make triggerable on web (default is false)
	 * tracking					String		Tracking campaign and choice (comma-delimited)
	 */
	public dynamic class AddFollower extends SpecialAbility
	{		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			_node = node;
			specialClassLoaded = new Signal(SpecialAbilityData);
			if(!_loaded)
			{
				super.loadAsset(_swfPath, loadComplete);
				
				// get particle if provided
				if (_particlePath != null)
				{
					super.loadAsset(_particlePath, gotParticle);
				}
				
				// if "clickableText1" parameter is detected
				if ( _clickableText1 )
				{
					_clickableText = true;
					
					// retrieve clickable text lines of dialogue and check to see if lines should cycle or be random
					_clickableTexts = new Array();
					var clickableTextIndex:int = 1;
					while ( this["_clickableText" + clickableTextIndex] )
					{
						_clickableTexts.push( this["_clickableText"  + clickableTextIndex] );
						clickableTextIndex++;
					}
				}
				
				// if using audio file, load it
				if ( _clickableAudioPath )
				{
					_clickableAudio = true;
					var path:String = SoundManager.SOUND_PATH + _clickableAudioPath;
					// if mobile then use full path to sound
					if (AppConfig.mobile)
					{
						path = super.shellApi.siteProxy.secureHost + "/game/" + path;
					}
					_clickableAudioFileRequest = new URLRequest(path);
					_clickableAudioSound = new Sound(_clickableAudioFileRequest);
					_clickableAudioSound.addEventListener(Event.COMPLETE, clickableAudioSoundLoaded);
				}
				
				// if any clickable action is enabled, toggle that it should be setup once clip is loaded
				if ( _clickableAnimation || _clickableAudio || _clickableText  )
					trace("rick clickable");
					_clickable = true;
			}
			else
			{
				if(_useSpecialActionBtn || _clickable)
				{	
					followerTrigger();
					followerAction();
				}
			}
			
		}
		
		private function followerTrigger(...args):void
		{
			
			
			var partsToColor:Vector.<String> = new<String>[
				CharUtils.SHIRT_PART,
				CharUtils.PANTS_PART,
				CharUtils.FACIAL_PART,
				CharUtils.MARKS_PART,
				CharUtils.PACK,
				CharUtils.HAIR,
				CharUtils.ITEM,
				CharUtils.OVERPANTS_PART,
				CharUtils.OVERSHIRT_PART,
				CharUtils.BODY_PART,
				CharUtils.LEG_FRONT,CharUtils.LEG_BACK,
				CharUtils.ARM_BACK,
				CharUtils.ARM_FRONT,
				CharUtils.HAND_BACK,
				CharUtils.HAND_FRONT,
				CharUtils.FOOT_BACK,
				CharUtils.FOOT_FRONT];
		
			
			if(_followerTransparent){
				if(followerEntity.get(Display).alpha < 1)
					followerEntity.get(Display).alpha = 1;
				else
					followerEntity.get(Display).alpha = _transparencyAmount;
			}
			if(_playerTransparent)
			{
				if(_isPlayerTransparent)
				{
					var i:int
					for (i = 0; i < partsToColor.length; i++) 
					{
						var partEntity:Entity = CharUtils.getPart(_node.entity, partsToColor[i]);
						if (partEntity)
						{
							partEntity.get(Display).alpha = 1;
						}
						var partEntity4:Entity = CharUtils.getPart(_node.entity, CharUtils.HEAD_PART);
						partEntity4.get(Display).alpha = 1;
					}
					_isPlayerTransparent = false;
				}
				else
				{
					var y:int
					for (y = 0; y < partsToColor.length; y++) 
					{
						var partEntity2:Entity = CharUtils.getPart(_node.entity, partsToColor[y]);
						if (partEntity2)
						{
							partEntity2.get(Display).alpha = _transparencyAmount;
						}
						var partEntity3:Entity = CharUtils.getPart(_node.entity, CharUtils.HEAD_PART);
						partEntity3.get(Display).alpha = _headTransparencyAmount;
					}
					_isPlayerTransparent = true;
					
				}
			}
			
			
		}
		private function followerAction(entity:Entity = null):void
		{
			// trigger click functions on trigger
			processActionClick();
			processClick(entity);
		}
		private function processActionClick():void
		{
			// if have campaign name and clicked, then track
			if (_campaignTracking)
			{
				// if clicked
				if (entity)
				{
					super.shellApi.adManager.track(_campaignTracking[0], AdTrackingConstants.TRACKING_CLICKED, "Follower");
				}
					// if spacebar tap or action button
				else
				{
					if (PlatformUtils.isMobileOS)
					{
						super.shellApi.adManager.track(_campaignTracking[0], SpecialAbilityControlSystem.TRACKING_ACTION_BTN_TRIGGER, "Follower");
					}
					else
					{
						super.shellApi.adManager.track(_campaignTracking[0], SpecialAbilityControlSystem.TRACKING_SPACE_BAR_TRIGGER, "Follower");
					}
				}
			}
			
			actionCall(SpecialAbilityData.CLICK_ACTIONS_ID);
		}
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			// Add the Follower Sytem if it's not there already (RLH: fixes a bug with cards that show ability)
			if( super.group.getSystem(FollowerSystem) == null )
				super.group.addSystem( new FollowerSystem() );
		}
		
		/**
		 * When follower loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			// if no clip exists, don't add follower
			if(clip == null)
				return;
			
			// make active
			super.setActive( true );
			
			// if any random animations, then play from random frame
			if (clip.shape != null)
			{
				for (var i:int = 1; i!= 6; i++)
				{
					var anim:MovieClip = clip.shape["random" + i];
					if (anim == null)
						break;
					else
					{
						anim.gotoAndPlay(Math.ceil(anim.totalFrames * Math.random()));
					}
				}
			}
			
			// Add the Follower Sytem if it's not there already
			if( super.group.getSystem(FollowerSystem) == null )
				super.group.addSystem( new FollowerSystem() );
			
			// Create the new entity and set the display and spatial
			followerEntity = new Entity();
			
			// add Display, container is character's Display
			followerEntity.add(new Display(clip, super.entity.get(Display).container));
			
			// add Follower
			var follower:Follower = new Follower();
			follower.flipDisabled = _disableFlip;	// disable flipping if requested in XML
			
			// convert animation if stored in content movie clip and has more than one frame
			if ( ( clip.content != null ))// && ( clip.content.totalFrames > 1 ) )// assuming its only the content that has the animation and not its children is presumptous
			{
				_followerTimelineEntity = TimelineUtils.convertAllClips(clip.content, null, super.group);
				_followerTimeline = _followerTimelineEntity.get( Timeline );
				if ( _flipClip )
					follower.flipClip = _followerTimelineEntity.get( TimelineClip ).mc[_flipClip];
			}
			else if (clip.shape)
			{
				clip.shape.gotoAndStop(0);
				_clickableAnimation = false;
			}
			
			// if art needs to be swapped when flipped
			if ( _swapClip )
			{
				var entity:Entity = TimelineUtils.convertClip(clip.content[_swapClip], super.group);
				follower.swapTimeline = entity.get(Timeline);
				follower.swapTimeline.gotoAndStop(0);
			}
			
			followerEntity.add(follower);
			
			// add Spatial
			var charSpatial:Spatial = super.entity.get(Spatial);
			var xPos:Number = charSpatial.x - 4;
			var yPos:Number = charSpatial.y - 110;
			followerEntity.add(new Spatial(xPos, yPos));
			
			followerEntity.add(new TargetSpatial(super.entity.get(Spatial)));
			super.group.addEntity(followerEntity);
			
			// if needed, create the ability to receive mouse clicks (and set up speech bubbles if needed)
			if ( _clickable )
			{
				trace("rick clickable 2");
				_useSpecialActionBtn = true;
				InteractionCreator.addToEntity( followerEntity, [ InteractionCreator.CLICK ]);
				ToolTipCreator.addToEntity( followerEntity );
				
				var interaction:Interaction = followerEntity.get( Interaction );
				interaction.click.add( processClick );
				
				if ( _clickableText )
					followerEntity.add( new Dialog () );
			}
			
			
			if(_useSpecialActionBtn)
			{	
				data.triggerable = true;
				if(AppConfig.mobile)
				{
					var hud:Hud = super.group.getGroupById( Hud.GROUP_ID ) as Hud;
					if( hud )
					{
						// rlh: this seems to remove triggers for other actions
						//hud.removeActionButtonHandler(_node.specialControl.onTrigger);
						hud.addActionButtonHandler( followerTrigger );
					}
				}
			}
			
			if(_addParticles)
				addEmitter();
			
			this.data.entity = followerEntity;
			_loaded = true;
			specialClassLoaded.dispatch(data);
		}
		
		private function gotParticle(clip:MovieClip):void
		{
			if (clip != null)
				_particleSwf = clip;
		}
		
		private function addEmitter():void
		{
			// if emitter exists then remove
			if(_emitter)
			{
				//_partEntity.group.removeEntity(_emitterEntity);
				_emitterEntity = null;
				_emitter = null;
			}
			
			// create new emitter
			if(!_particleClass) _particleClass = game.particles.emitter.specialAbility.ColoredSmoke;
			
			var counter:Counter = new Random(10, 25);
			if(_particleCount) counter = new Steady(_particleCount);
			_emitter = new _particleClass();
			_emitter.init(counter, _particleColor,_particleSpeedX,_particleSpeedY,_particleSize,_particleLife,
								_particleRadiusX,_particleRadiusY, _particleAlpha, _particleDriftX, _particleDriftY);
			
			// if using image
			if (_particleSwf != null)
			{
				_emitter.addInitializer( new ExternalSwfImage(_particleSwf, true ) );
			}
			
			// create emitter entity in part group
			var container:DisplayObjectContainer = followerEntity.get(Display).displayObject;
			var holder:Sprite = new Sprite();
			container = DisplayObjectContainer(container.addChildAt(holder, 0));
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, 0, 0 );
		}
		
		/**
		 * Process mouse click input 
		 * @param entity
		 */
		private function processClick( entity:Entity ):void
		{
			trace("rick process click");
			// if a sound should be played and it isn't ready, hold off on allowing the interaction
			if ( (_clickableAudio) && (!_clickableAudioSoundLoaded) )
				return;
			
			// check to see that the previous click effects have finished
			if ( !( checkAnimationFinished() && checkAudioFinished() && checkDialogFinished() ) )
				return;
			
			// tracking on click
			if (_campaignTracking)
			{
				shellApi.adManager.track(_campaignTracking[0], AdTrackingConstants.TRACKING_CLICKED, _campaignTracking[1]);
			}
			
			// if clickable animation, then animate follower (play animate frame)
			if ( _clickableAnimation ){
				trace("rick animate");
				_followerTimeline.gotoAndPlay("animate");
				
			}
			
			// if audio and loaded, then play it
			if ( _clickableAudio && _clickableAudioSoundLoaded )
			{
				_clickableAudioSoundChannel = _clickableAudioSound.play();
				_clickableAudioSoundChannel.addEventListener(Event.SOUND_COMPLETE, clickableAudioSoundComplete);
				_clickLockForAudio = true;
			}
			
			// if clickable text
			if ( _clickableText )
			{
				_dialog = entity.get( Dialog );
				var clickableTextIndex:int;
				
				// either cycle through lines of text or randomly pick one, depending on parameters parsed earlier
				if ( _clickableTextsCycle )
				{
					_clickableTextsIndex++;
					if ( _clickableTextsIndex == _clickableTexts.length )
						_clickableTextsIndex = 0;
				}
				else
				{
					if (_clickableTexts.length == 1)
						_clickableTextsIndex = 0;
					else
						_clickableTextsIndex = randomTextPos();
				}
				
				_dialog.say( _clickableTexts[ _clickableTextsIndex ]);
			}
			
			actionCall(SpecialAbilityData.CLICK_ACTIONS_ID);
		}
		
		/**
		 * Get random text index 
		 * @return int
		 */
		private function randomTextPos():int
		{
			while (true)
			{
				// get number in range
				var index:int = Math.floor(Math.random() * _clickableTexts.length);
				// if not same as last test index, then break
				if (index != _clickableTextsIndex)
					break;
			}
			return index;
		}
		
		/**
		 * Check if animation finished 
		 * @return Boolean
		 */
		private function checkAnimationFinished():Boolean
		{
			return _clickableAnimation ? _followerTimeline.currentFrameData.index == 0 : true;
		}
		
		/**
		 * Check if audio finished 
		 * @return boolean
		 * 
		 */
		private function checkAudioFinished():Boolean
		{
			return _clickableAudio ? !_clickLockForAudio : true;
		}
		
		/**
		 * Check if dialog finished 
		 * @return boolean
		 */
		private function checkDialogFinished():Boolean
		{
			if ( !_clickableText || !_dialog )
				return true;
			return !_dialog.speaking;
		}
		
		/**
		 * When audio file has been loaded
		 * @param event
		 */
		private function clickableAudioSoundLoaded(event:Event):void
		{
			_clickableAudioSoundLoaded = true;
		}
		
		/**
		 * When audio file has finished playing
		 * @param event
		 */
		private function clickableAudioSoundComplete(event:Event):void
		{
			_clickLockForAudio = false;
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{				
			super.group.removeEntity(followerEntity);
			if(_useSpecialActionBtn && AppConfig.mobile)
			{	
				var hud:Hud = super.group.getGroupById( Hud.GROUP_ID ) as Hud;
				if( hud )
				{
					hud.removeActionButtonHandler(followerTrigger);

					// remove action button if there are no other current actions
					// to do: check pop followers for action button triggers
					var hasOtherTriggers:Boolean = false;
					var nodeList:NodeList = super.systemManager.getNodeList( SpecialAbilityNode );
					for( var saNode:SpecialAbilityNode = nodeList.head; saNode; saNode = saNode.next )
					{
						// check standard abilities
						var control:SpecialAbilityControl = saNode.specialControl;
						if (control.hasActionBtnUsers)
						{
							hasOtherTriggers = true;
							break;
						}
						// check followers
						for ( var i:int; i < control.specials.length; i++ )
						{
							var sData:SpecialAbilityData = control.specials[i];
							// if has special action button and not this, then skip out
							if (sData.specialAbility != null && (sData.specialAbility._useSpecialActionBtn) && (sData.specialAbility != this))
							{
								hasOtherTriggers = true;
								break;
							}
						}
					}
					// if not other triggers, then remove action button
					if (!hasOtherTriggers)
					{
						hud.removeActionButton();
					}
				}
			}
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _disableFlip:Boolean = false;
		public var _clickableAnimation:Boolean;
		public var _flipClip:String;
		public var _swapClip:String;
		public var _clickableAudioPath:String;
		public var _clickableTextsCycle:Boolean = false;
		public var _clickableText1:String;
		public var _clickableText2:String;
		public var _clickableText3:String;
		public var _clickableText4:String;
		public var _playerTransparent:Boolean = false;
		public var _followerTransparent:Boolean = false;
		public var _transparencyAmount:Number = 1;
		public var _headTransparencyAmount:Number = 1;
		public var _addParticles:Boolean = false;
		public var _particleColor:Number = 0x000000;
		public var _particleSpeedY:Number = 10;
		public var _particleSpeedX:Number = 10;
		public var _particleSize:Number = 10;
		public var _particleLife:Number = 3;
		public var _particleRadiusX:Number = 3;
		public var _particleRadiusY:Number = 3;
		public var _particleAlpha:Number = .5;
		public var _particleCount:Number;
		public var _particleDriftX:Number = 100;
		public var _particleDriftY:Number = 100;
		public var _particleClass:Class;
		public var _particlePath:String;
		public var _particleSwf:MovieClip;
		public var _campaignTracking:Array;
		
		private var _isPlayerTransparent:Boolean = false;
		private var _currentFollowerTransparency:Number = 1;
		private var followerEntity:Entity;
		private var _dialog:Dialog;
		
		private var _clickable:Boolean = false;
		
		private var _followerTimelineEntity:Entity;
		private var _followerTimeline:Timeline;
		
		private var _clickableAudio:Boolean = false;
		private var _clickableAudioFileRequest:URLRequest;
		private var _clickableAudioSound:Sound;
		private var _clickableAudioSoundChannel:SoundChannel;
		private var _clickableAudioSoundLoaded:Boolean = false;
		
		private var _clickableText:Boolean = false;
		private var _clickableTexts:Array;
		private var _clickableTextsIndex:int = -1;
		
		private var _clickLockForAudio:Boolean = false;
		private var _clickLockForText:Boolean = false;
		private var _node:SpecialAbilityNode;
		private var _loaded:Boolean = false;
		
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}


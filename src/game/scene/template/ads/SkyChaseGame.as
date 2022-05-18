package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.audio.HitAudio;
	import game.components.entity.FlyingPlatformHealth;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	import game.components.entity.Sleep;
	import game.components.entity.character.Npc;
	import game.components.hit.CurrentHit;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControlBase;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.StandNinja;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.AudioGroup;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.systems.entity.LooperCollisionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.utils.LoopingSceneUtils;
	
	game.data.animation.entity.character.Hurt;
	game.data.animation.entity.character.StandNinja;
	
	/**
	 * Game template for vertical sky chase game
	 * The object starting positions in SegmentPatterns.xml are based on the clip centers
	 * For collision objects, make sure to list them in game.xml
	 * If you are using a progress bar, you will need to set goal distance in motionMaster.xml
	 * You can calculate goal distance by uncommenting line 196 in MotionMasterSystem.as
	 * @author uhockri
	 */
	public class SkyChaseGame extends AdGameTemplate
	{
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		/**
		 * Constructor 
		 */
		public function SkyChaseGame()
		{
			this.id = "SkyChaseGame";
		}
		
		/**
		 * Setup game based on xml 
		 * @param group
		 * @param xml
		 * @param hitContainer
		 */
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void
		{
			super.setupGame(scene,xml,hitContainer);
			
			// need threshold system
			_scene.addSystem( new ThresholdSystem());
			
			// get segment data and merge into scene
			// the segment background names in the xml need to match the named tile instances in the interactive layer
			// there must be at least two background tiles
			// the tiles need to be at least 700 pixels tall
			// tiles need to be at least 1000 pixels wide to work on wider Android screens
			// the camera limits and camera bounds should be 640 high
			// the first tile needs to be 640 pixels high (to match the camera limits)
			// make sure the first tile is layered behind the other tiles (I suggest an overlap at top of 60 pixels, tile y position is -60)
			var data:XML = SceneUtil.mergeSharedData( _scene, "segmentPatterns.xml", "ignore" );
			
			// process segments
			_raceSegmentCreator = new RaceSegmentCreator();
			var audioGroup:AudioGroup = AudioGroup(_scene.getGroupById( AudioGroup.GROUP_ID ));
			_raceSegmentCreator.createSegments( _scene, data, _hitContainer, audioGroup );
			
			
			// get scene ui group
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID));
			
			// set up hud
			var hud:MovieClip = _hitContainer["hud"];
			if (hud)
			{
				// create into timeline and stop on first frame
				var hudEntity:Entity = TimelineUtils.convertClip(hud, _scene);
				_hudTimeline = hudEntity.get(Timeline);
				_hudTimeline.gotoAndStop(0);
				// add to scene ui group so hud won't move around
				sceneUIGroup.groupContainer.addChild(hud);
			}
			
			// set up progress bar display, if any
			if (_hitContainer["progress"])
			{
				// add to scene ui group so progress bar won't move around
				// if progress bar back, then move to scene ui group
				if (_hitContainer["progressBack"])
					sceneUIGroup.groupContainer.addChild(_hitContainer["progressBack"]);
				sceneUIGroup.groupContainer.addChild(_hitContainer["progress"]);
			}
			
			// setup summon animations (up to six)
			// named summmon1, summon2, summon3, etc.
			for (var i:int = 1; i!= 7; i++)
			{
				var anim:MovieClip = _hitContainer["summon" + i];
				if (anim)
				{
					_summonAnimCount++;
					var animEntity:Entity = TimelineUtils.convertClip(anim, _scene);
					animEntity.get(Timeline).gotoAndStop(0);
					animEntity.add(new Display(anim));
					animEntity.add(new Spatial(0,-100));
					// this prevents offscreen animations from going to sleep
					animEntity.add(new Sleep(false, true));
				}
			}
			
			if(_looks != null)
			{
				var selectionPopup:AdChoosePopup = QuestGame(scene).loadChoosePopup() as AdChoosePopup;
				selectionPopup.ready.addOnce(gameSetUp.dispatch);
				selectionPopup.selectionMade.addOnce(QuestGame(scene).playerSelection);
			}
			else
			{
				gameSetUp.dispatch(this);
				playerSelected();
			}
		}
		
		
		override protected function playerSelected(...args):void
		{
			// setup player
			setupPlayer();
			// setup player for flying scene
			LoopingSceneUtils.setupFlyingPlayer(_scene, _initialRotation);
			// start game
			startGame();
			
			// if not waiting for intro (dialog) and no initial animation, then start flying right away
			if ((!_waitForIntro) && (_initialTimeline == null))
				startFlying();
			else
			{
				// if cut scene (animation or dialog)
				// lock input
				SceneUtil.lockInput(_scene, true);
				
				// any initial dialog is triggered by "initScene' event sent by QuestGame
				// if initial animation, then play it now
				if (_initialTimeline)
					_initialTimeline.gotoAndPlay(2);
			}
		}
		/**
		 * Parse game xml for game parameters
		 * @param xml
		 */
		override protected function parseXML(xml:XML):void
		{
			super.parseXML(xml);
			// note: returnX and returnY are pulled on QuestGame.as
			
			// get y offset of platform from avatar
			if (String(xml.platformOffsetY) != "")
				_platformOffsetY = Number(xml.platformOffsetY);
			
			// if avatar gets item in hand
			if (String(xml.item) != "")
				_item = String(xml.item);
			
			// platform depth in relation to avatar
			// use "cover" when you want the platform to hide the feet (flying carpet)
			// use "straddle" when straddling an object (broom)
			// use "stand" when you want the avatar to be standing on top of the platform
			if (String(xml.platformDepth) != "")
				_platformDepth = String(xml.platformDepth);
			
			// wait for intro trigger "startGame"
			// if false or missing, then flying game starts immediately
			if (String(xml.waitForIntro) != "")
				_waitForIntro = (String(xml.waitForIntro) == "true");
			
			// number of obstacle hits before you lose
			if (String(xml.numHits) != "")
				_numHits = uint(xml.numHits);
			
			// falling hit obstacles (must correspond to movie clips in FLA and obstacles in segmentPatterns.xml)
			if (String(xml.obstacles) != "")
			{
				// convert comma-delimited list to array
				var list:Array = String(xml.obstacles).split(",");
				// append "Hit" cause framwork expects it
				for each (var obstacle:String in list)
				{
					_obstacles.push(obstacle + "Hit");
				}
			}
			
			// get initial rotation of avatar and NPCs
			if (String(xml.initialRotation) != "")
				_initialRotation = Number(xml.initialRotation);
			
			// if initial animation
			if (String(xml.initialAnim) != "")
			{
				// look for clips that are named anim1, anim2, anim3
				var anim:Entity = TimelineUtils.convertClip(_hitContainer[xml.initialAnim], _scene);
				// if entity created
				if (anim)
				{
					// get timeline
					_initialTimeline = anim.get(Timeline);
					// stop on first frame
					_initialTimeline.gotoAndStop(0);
					// listener
					_initialTimeline.handleLabel( "ending", startFlying, false );
				}
			}
			
			var clip:MovieClip = _hitContainer["anim" + 1];
			var i:int = 1;
			while(clip)
			{
				// look for clips that are named anim1, anim2, anim3
				anim = TimelineUtils.convertClip(clip, _scene);
				// if entity created
				if (anim)
				{
					// get timeline
					var timeline:Timeline = anim.get(Timeline);
					// stop on first frame
					timeline.gotoAndStop(0);
					// add to vector
					_randomAnims.push(timeline);
					// listener
					timeline.handleLabel( "ending", randomAnim, false );
					// get associated sounds if any
					var sound:String = String(xml["randomAnimSound" + i]);
					_randomAnimSounds.push(sound);
				}
				clip = _hitContainer["anim"+(++i)];
			}
		}
		
		/**
		 * setup player for scene 
		 * @param fileName
		 */
		private function setupPlayer():void
		{
			// get player
			_player = _scene.shellApi.player;
			// set rotation, if any
			_player.get(Spatial).rotation = _initialRotation;
			
			// apply handheld item, if any
			if (_item)
			{
				var lookData:LookData = new LookData();
				var lookAspect:LookAspectData = new LookAspectData( SkinUtils.ITEM, _item ); 
				lookData.applyAspect( lookAspect );		
				SkinUtils.applyLook( _player, lookData, false );
			}
			
			// setup health system for player
			_player.add( new FlyingPlatformHealth( _numHits, loseGame, gotHit, hitFeedBack));
			// setup player for looping scene using motionMaster xml
			LoopingSceneUtils.setupPlayer(_scene, "motionMaster.xml", _hitContainer["progress"]);
			
			// get flying platform swf in scene
			// note that clip gets scaled down 36% because it is added as a child of the avatar
			var clip:MovieClip = _hitContainer["flyingPlatform"];
			// if clip exists
			if( clip )
			{
				var selectionClip:MovieClip = clip["selection"];
				if(_selection != -1 && selectionClip != null)
				{
					selectionClip.gotoAndStop(_selection);
				}
				// move platform in relation to avatar
				clip.y = _platformOffsetY;
				clip.x = 0;
				
				// add platform to avatar clip
				var avatarContainer:DisplayObjectContainer = Display( _player.get( Display )).displayObject;
				var platformClip:MovieClip;
				switch (_platformDepth)
				{
					case "stand": // standing on top of platform
						platformClip = MovieClip(avatarContainer.addChildAt( clip, 0));
						break;
					
					case "straddle": // straddling platform
						platformClip = MovieClip(avatarContainer.addChildAt( clip, 6));
						// hide back foot and leg
						var leg:Entity = CharUtils.getPart(_player, CharUtils.LEG_BACK);
						leg.get(Display).visible = false;
						var foot:Entity = CharUtils.getPart(_player, CharUtils.FOOT_BACK);
						foot.get(Display).visible = false;
						break;
					case "hide":
						platformClip = MovieClip(_hitContainer.addChild( clip ));
						DisplayUtils.moveToTop(platformClip);
						EntityUtils.visible(_player, false);
						break;
					case "cover": // cover feet with platform
					default:
						platformClip = MovieClip(avatarContainer.addChild( clip ));
						// move avatar above npcs
						DisplayUtils.moveToTop(avatarContainer);
						break;
				}
				// convert platform into entity with timeline
				_platform = EntityUtils.createSpatialEntity( _scene, platformClip);
				TimelineUtils.convertClip( platformClip, _scene, _platform );
				// apply rotation to platfoem
				_platform.get(Spatial).rotation = _initialRotation;
				if(_platformDepth == "hide")
				{
					_platform.add( new FollowTarget(_player.get(Spatial)));
				}
				
				// for each NPC
				var npcNodes:NodeList = _scene.systemManager.getNodeList(NpcNode);
				for( var node:NpcNode = npcNodes.head; node; node = node.next )
				{
					// get npc
					var npc:Entity = node.entity;
					// ignore depth
					npc.get(Npc).ignoreDepth = true;
					
					// need this for looping collisions
					npc.add(new LooperCollider(hitNPC));
					npc.add(new Motion());
					npc.add(new CurrentHit());
					npc.add(new HitAudio());
					
					// set initial animation
					CharUtils.setAnim( npc, StandNinja );
					// set initial rotation
					npc.get(Spatial).rotation = _initialRotation;
					
					switch (_platformDepth)
					{
						case "stand": // standing on top of platform
							// move npc above avatar
							DisplayUtils.moveToOverUnder(npc.get(Display).displayObject, avatarContainer, true);
							break;
						
						case "straddle": // straddling platform
							// move npc above avatar
							DisplayUtils.moveToOverUnder(npc.get(Display).displayObject, avatarContainer, true);
							// hide back foot and leg
							leg = CharUtils.getPart(npc, CharUtils.LEG_BACK);
							leg.get(Display).visible = false;
							foot = CharUtils.getPart(npc, CharUtils.FOOT_BACK);
							foot.get(Display).visible = false;
							break;
					}
				}
			}
		}
		
		/**
		 * Start game with player on flying platform 
		 */
		private function startGame():void
		{
			// setup game mechanics
			LoopingSceneUtils.hideObstacles(_raceSegmentCreator, _obstacles);
			LoopingSceneUtils.createMotion(_scene, true, winGame);
			LoopingSceneUtils.stopSceneMotion(_scene);
		}
		
		/**
		 * Start flying with scrolling background
		 * Can also be called by event trigger in QuestGame
		 */
		public function startFlying():void
		{
			// only do once, can be called by end of initial animation or initial dialog
			if (!_playing)
			{
				_playing = true;
				var motionMaster:MotionMaster = _scene.shellApi.player.get(MotionMaster);
				
				// enable player input now
				SceneUtil.lockInput(_scene, false);
				
				// setup game mechanics
				LoopingSceneUtils.triggerLayers(_scene);
				LoopingSceneUtils.triggerObstacles(_scene);
				LoopingSceneUtils.startObstacles(_scene, _raceSegmentCreator, _obstacles);
				LoopingSceneUtils.startFlyingPlayer(_scene, _componentInstances);
				
				// setup player to follow input in horizontal direction
				var inputSpatial:Spatial = _scene.shellApi.inputEntity.get( Spatial );
				var followTarget:FollowTarget 		= new FollowTarget( inputSpatial, .05 );
				if(motionMaster.axis == "y")
					followTarget.properties			 	= new <String>["x"];
				else
					followTarget.properties			 	= new <String>["y"];
				followTarget.allowXFlip 			= true;
				_player.add(followTarget);
				
				// get player spatial
				var playerSpatial:Spatial = _player.get(Spatial);
				
				// setup npcs to align with player
				var npcNodes:NodeList = _scene.systemManager.getNodeList(NpcNode);
				// for each NPC
				for( var node:NpcNode = npcNodes.head; node; node = node.next )
				{
					var npc:Entity = node.entity;
					followTarget = new FollowTarget(playerSpatial);
					followTarget.offset = new Point(npc.get(Spatial).x - playerSpatial.x, 0);
					npc.add(followTarget);
				}
				
				// if random animations, then trigger
				if (_randomAnims.length != 0)
					randomAnim();
			}
		}
		
		/**
		 * When npc hits obstacle 
		 */
		private function hitNPC(id:String):void
		{
			// set npcHit flag in Health component
			_player.get(FlyingPlatformHealth).npcHit = true;
			// get npc
			var npc:Entity = _scene.getEntityById(id);
			// set Hurt animation
			CharUtils.setAnim(npc, Hurt);
			// wait for end, then trigger returnToStand
			npc.get(Timeline).handleLabel( "ending", Command.create(returnToStand, npc), false );
		}
		
		/**
		 * when hurt animation is done 
		 * @param npc
		 */
		private function returnToStand(npc:Entity):void
		{
			// set stand animation
			CharUtils.setAnim(npc, StandNinja);
			// check health: if dead, then lose
			if (_player.get(FlyingPlatformHealth).calculateHits(true))
				loseGame();
		}
		
		/**
		 * trigger random animation
		 * triggers same function when animation completes
		 */
		private function randomAnim():void
		{
			// get random animation that is not same as last
			while (true)
			{
				var num:int = Math.floor(_randomAnims.length * Math.random());
				// if only one animation or not matching last
				if ((_randomAnims.length == 1) || (num != _lastRandomAnim))
				{
					_lastRandomAnim = num;
					break;
				}
			}
			_randomAnims[num].gotoAndPlay(2);
			
			// audio effect if provided
			var sound:String = _randomAnimSounds[num];
			if ((sound != null) && (sound != ""))
				AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + sound, 1);
		}
		
		private function hitFeedBack():void
		{
			if(_platform)
				Timeline(_platform.get(Timeline)).gotoAndPlay("hit");
		}
		/**
		 * When getHit
		 */
		private function gotHit(health:int):void
		{
			
			if (_hudTimeline)
				// update to next frame in hud
				_hudTimeline.gotoAndStop(_numHits - health);
		}
		
		/**
		 * Animation when obstaccle is summoned (need 4 animations for cases where multiple objects are dropping)
		 * @param obstacle
		 * @param callback
		 */
		public function summonObstacle( obstacle:Entity, callback:Function):void
		{
			if (_playing)
			{
				// if no summon animations, then call callback
				// fails if called immediately, so add a slight delay
				if (_summonAnimCount == 0)
					SceneUtil.addTimedEvent(_scene, new TimedEvent(0.05, 1, callback));
				else
				{
					// if summon animations
					// update summon slot - increment through available slots
					_summonSlot = (_summonSlot % _summonAnimCount) + 1;
					var entity:Entity = _scene.getEntityById("summon" + _summonSlot);
					entity.get(Spatial).x = obstacle.get(Spatial).x;
					// note that the obstacle is placed at 50 in summonObstacle() in LoopingSceneUtils.as
					entity.get(Spatial).y = obstacle.get(Spatial).y;
					entity.get(Timeline).gotoAndPlay(1);
					entity.get(Timeline).handleLabel( "ending", callback, true );
				}
			}
		}
		
		/**
		 * When game ends 
		 */
		private function endGame():void
		{
			_playing = false
			
			// stop scene scrolling
			LoopingSceneUtils.stopSceneMotion( _scene, true );
			
			// make avatar stop
			_player.remove(FollowTarget);
			_player.remove( MotionControlBase );
			CharUtils.lockControls(_player);
			MotionUtils.zeroMotion( _player );
			
			// remove collision system
			_scene.removeSystemByClass(LooperCollisionSystem);
		}
		
		/**
		 * When lose game 
		 */
		private function loseGame():void
		{
			if (_playing)
			{
				endGame();
				// show lose popup
				QuestGame(_scene).loadLosePopup();
			}
		}
		
		/**
		 * When win game 
		 */
		private function winGame():void
		{
			if (_playing)
			{
				var motionMaster:MotionMaster = _scene.shellApi.player.get( MotionMaster );
				trace("SkyChaseGame: final goal distance: x: " + motionMaster.distanceX + " y: " + motionMaster.distanceY);
				endGame();
				// load win popup
				QuestGame(_scene).loadWinPopup();
			}
		}
		
		public function get playing():Boolean { return _playing; }
		
		private var _player:Entity;
		private var _componentInstances:Array = [];
		private var _raceSegmentCreator:RaceSegmentCreator;
		private var _platform:Entity;
		private var _hudTimeline:Timeline;
		private var _playing:Boolean = false;
		
		private var _obstacles:Vector.<String> = new Vector.<String>();
		private var _item:String;
		private var _numHits:uint = 4;
		private var _platformOffsetY:Number = 105;
		private var _platformDepth:String = "cover";
		private var _waitForIntro:Boolean = false;
		private var _initialRotation:Number = 0;
		private var _initialTimeline:Timeline;
		private var _randomAnims:Vector.<Timeline> = new Vector.<Timeline>();
		private var _summonAnimCount:int = 0;
		private var _summonSlot:int = 0;
		private var _randomAnimSounds:Array = new Array();
		private var _lastRandomAnim:int = -1;
	}
}
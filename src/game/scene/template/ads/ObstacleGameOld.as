package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.CameraLayerCreator;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.BitmapHit;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.render.Light;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.render.LightCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MoverHitData;
	import game.data.scene.hit.MovingHitData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.deepDive2.shared.popups.PuzzleKey2Popup;
	import game.scenes.time.graff.components.MovingHazard;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	public class ObstacleGame extends AdGameTemplate
	{
		public function ObstacleGame(container:DisplayObjectContainer=null)
		{
			super(container);
			this.id = "ObstacleGame";
		}
		
		override public function destroy():void
		{			
			super.groupContainer = null;
			super.destroy();
		}
		
		// initialization /////////////////////////////////////////////////////
		
		override protected function parseXML(xml:XML):void
		{
			super.parseXML(xml);
			super.parseGameXML(xml);
			
			// update hit objects
			// since they can be positioned way off screen, you can add the coords to the name such as obstacle1000x800
			// and the framework will position them for you based on their name
			var hitContainer:MovieClip = MovieClip(PlatformerGameScene(_scene).hitContainer);
			for (var i:int = hitContainer.numChildren - 1; i!= -1; i--)
			{
				var child:DisplayObjectContainer = DisplayObjectContainer(hitContainer.getChildAt(i));
				if (child is MovieClip)
				{
					var clip:MovieClip = MovieClip(child);
					// look for underscore (all hit objects need to have underscore in name)
					// objects without underscores are ignored
					var pos:int = clip.name.indexOf("_");
					if (pos != -1)
					{
						// set position if coordinates given with NxN
						var id:String = clip.name.substr(pos+1);
						var xpos:int = id.indexOf("x");
						if (xpos != -1)
						{
							clip.x = Number(id.substr(0,xpos));
							clip.y = Number(id.substr(xpos+1)); 
						}
						// setup hit
						var hitCreator:HitCreator = new HitCreator();
						hitCreator.showHits = true;
						var audioGroup:AudioGroup = _scene.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
						// if has shoot prefix then set to hazard
						// most hit types will use default values if hitData is left out.
						
						// bounce objects
						if (clip.name.substr(0, 1) == "b")
						{
							var velocity:Number = Number(clip.name.substr(1,pos-1));
							var moverHitData:MoverHitData = new MoverHitData();
							moverHitData.velocity = new Point(0, -velocity);
							// if more than one frame, then convert timeline and set animate flag
							if (clip.totalFrames != 1)
							{
								moverHitData.animate = true;
								moverHitData.timeline = TimelineUtils.convertClip(clip, _scene);
							}
							var bouncyHit:Entity = hitCreator.createHit(clip, HitType.BOUNCE, moverHitData, _scene);
							bouncyHit.add(new Id("bouncehit"));
							hitCreator.addHitSoundsToEntity( bouncyHit, audioGroup.audioData, _scene.shellApi );
						}
						else if (clip.name.substr(0, 7) == "animate")
						{
							// bounce objects
							if(clip.totalFrames > 1)
							{
								TimelineUtils.convertClip(clip, _scene);
							}
						}
						else if (clip.name.substr(0, 3) == "obs")
						{
							// set to wall and platform top
							var platformHit:Entity = hitCreator.createHit(clip, HitType.PLATFORM_TOP, null, _scene);
							platformHit.add(new Id("platformhit"));
							hitCreator.createHit(clip, HitType.WALL, null, _scene);
							hitCreator.addHitSoundsToEntity( platformHit, audioGroup.audioData, _scene.shellApi );
						}
						else if (clip.name.substr(0, 7) == "collect")
						{
							//HANDLED BY ITEMMANAGER NOW
						}
						else if (clip.name.substr(0, 10) == "movingPlat") 
						{
							
							var movingHitData:MovingHitData = new MovingHitData();
							movingHitData.loop = true;
							movingHitData.velocity = 200;
							movingHitData.points = [new Point(360, 420), new Point(360, 180)];
							hitCreator.createHit(clip, HitType.MOVING_PLATFORM, movingHitData, _scene);
						}
						else if (clip.name.substr(0, 7) == "endZone") 
						{
							_hasEndZone = true;
							var endentity:Entity =_scene.getEntityById(clip.name);
							var endzone:Zone = endentity.get(Zone);
							endzone.pointHit = true;
							endzone.inside.addOnce(triggerEnd);
						}
						else if (clip.name.substr(0, 3) == "hud")
						{
							_HUD = MovieClip(DisplayGroup(_scene).container.addChild(clip));
							_HUD.addEventListener(Event.ENTER_FRAME,updateHUD);
							if(_HUD.count != null)
							{
								TextUtils.refreshText(_HUD.count, _fontName);
							}
						}
						else if (clip.name.substr(0, 10) == "endMessage")
						{
							_endMessage = clip;
							_endMessage.visible = false;
							_endMessage.addEventListener(Event.ENTER_FRAME,updateEndMessage);
						}
						
					}
					if(clip.name.substr(0,10) == "cAnimation")
					{
						_collectAnimation = TimelineUtils.convertClip(clip,_scene);
						//_collectAnimation.add(new Spatial());
						var timeline:Timeline = _collectAnimation.get(Timeline);
						timeline.handleLabel("stopAnimation", Command.create(stopAnimation, _collectAnimation), false);
						timeline.gotoAndStop(0);
						DisplayUtils.moveToTop(clip);
					}
					if(clip.name.substr(0,10) == "ringPuzzle")
					{
						//setup ring puzzle hotspot
						var ringPuzzleEntity:Entity = EntityUtils.createSpatialEntity(_scene, clip);
						TimelineUtils.convertClip(clip,_scene, ringPuzzleEntity);
						var sceneInt:SceneInteraction = new SceneInteraction();
						InteractionCreator.addToEntity(ringPuzzleEntity, ["click"]);
						sceneInt.reached.addOnce(startRingPuzzle);
						ringPuzzleEntity.add(sceneInt);
						
						//setup door assocaited with puzzle
						var door:Entity = EntityUtils.createSpatialEntity(_scene, _hitContainer["ringDoor"]);
						var doorAnimation:Entity = TimelineUtils.convertClip(_scene.hitContainer["ringDoorClip"],_scene,null,null,false);
						var timeline:Timeline = doorAnimation.get( Timeline );
						timeline.handleLabel( "removeDoor", Command.create( removeDoor, "ringDoor" ), false );
						//var _sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
						//var door:Entity = _sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x, clip.y);
						door.add( new Platform() );
						door.add(new Id("ringDoor"));
						door.add(new Wall());
						door.add(new WallCollider());
						
						door.add(new HitData());
						
						door.add(new BitmapCollider());
						door.add(new BitmapHit());
						
					}
					if(clip.name.substr(0,9) == "trap_dart") 
					{
						var porcupineHit2:Entity = EntityUtils.createSpatialEntity(_scene, clip);	
						var movingHaz2:MovingHazard = new MovingHazard();
						movingHaz2.visible = TimelineUtils.convertClip(_scene.hitContainer[clip.name],_scene,porcupineHit2,null,false);		
						movingHaz2.leftThreshHold = _scene.sceneData.bounds.left;
						movingHaz2.rightThreshHold = _scene.sceneData.bounds.right;
						movingHaz2.isDart = true;
						porcupineHit2.add(new Motion());
						if(clip.scaleX < 0) {
							porcupineHit2.get(Motion).velocity = new Point( _dartSpeed, 0 );
							porcupineHit2.add(new Threshold( "x", ">" ));
						} else {
							porcupineHit2.get(Motion).velocity = new Point( -_dartSpeed, 0 );
							porcupineHit2.add(new Threshold( "x", "<" ));
						}
						movingHaz2.startingLocation = new Point(clip.x, clip.y);
						//porcupineHit2.get(Motion).velocity = new Point( 110, 0 );
						porcupineHit2.add(movingHaz2);
						porcupineHit2.remove(Sleep);
					}
				}
			}
		}
		private function removeDoor(door:String):void
		{
			_scene.getEntityById(door+"Clip").get(Timeline).gotoAndStop("removeDoor");
			var wall:Entity = _scene.getEntityById(door);
			wall.remove(Wall);
			wall.remove(HitData);
			wall.remove(Platform);
			wall.remove(BitmapCollider);
			wall.remove(BitmapHit);
			EntityUtils.visible(wall, false);
		}
		private function startRingPuzzle(player:Entity, clickedEntity:Entity):void {
			var ringPuzzle:PuzzleKey2Popup = new PuzzleKey2Popup(_scene.overlayContainer);
			ringPuzzle.removed.addOnce(openRingDoor);
			_scene.addChildGroup(ringPuzzle);
		}
		private function openRingDoor(group:Group):void {
			trace("remove ring door ");
			var door:Entity = _scene.getEntityById("ringDoorClip");
			//Timeline(door.get(Timeline)).handleLabel( "removeDoor", Command.create( removeDoor, index) );//, "triggerLoop" ));
			Timeline(door.get(Timeline)).play();
		}
		private function stopAnimation(entity:Entity):void
		{
			//stop and move animation offscreen
			var timeline:Timeline = entity.get(Timeline);
			timeline.stop();
			entity.get( TimelineClip ).mc.x = -5000;
		}
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void
		{
			super.setupGame(scene,xml,hitContainer);
			
			// catch events that get triggered
			_scene.shellApi.eventTriggered.add(handleEventTriggered);
			if(_nightMode == true) {
				initLights();
			}
			
			// if showing timer
			if(_showTimer)
			{
				if (!_textTimer)
				{
					var textFormat:TextFormat = new TextFormat( _fontName, _fontSize, _fontColor, false, false, false, null, null, "left", null, 0, null, 0 );
					
					_textField = new TextField();
					
					_textField.embedFonts = true;
					_textField.wordWrap = false;
					_textField.defaultTextFormat = textFormat;
					_textField.width = 175; //prevent numbers from getting cut off
					_textField.text = "null";
					_textField.x = _fontX;
					_textField.y = _fontY;
					
					var _textContainer:Sprite = new Sprite();
					
					_textContainer.addChild(_textField);
					scene.container.addChild(_textContainer);
				}
				else
				{
					_textField = _HUD.timer;
				}
				_textField.addEventListener(Event.ENTER_FRAME,fnTimer);
			}
			
			// apply part, if any
			if (_partType)
			{
				var lookData:LookData = new LookData();
				var lookAspect:LookAspectData = new LookAspectData( _partType, _partValue ); 
				lookData.applyAspect(lookAspect);		
				SkinUtils.applyLook(scene.shellApi.player, lookData, false );
			}
			
			if(_looks != null && _choose == true)
			{
				// show selection popup and return
				var selectionPopup:AdChoosePopup = QuestGame(scene).loadChoosePopup() as AdChoosePopup;
				selectionPopup.ready.addOnce(gameSetUp.dispatch);
				selectionPopup.selectionMade.addOnce(QuestGame(scene).playerSelection);
			}
			else
			{
				// if no selection popup then continue
				gameSetUp.dispatch(this);
				//playerSelected();
				if(_looks != null) {
					SkinUtils.applyLook(_scene.shellApi.player, _looks[0],false,playerSelected);
				}
			}
		}
		
		override protected virtual function playerSelected(...args):void
		{
			if (_timeout != 0)
				startTimer();
		}
		
		private function startTimer():void
		{
			_time = getTimer();
			_secs = _timeout / 1000;
		}
		
		// game play ////////////////////////////////////////////////////////////
		
		/**
		 * To capture any game triggers 
		 * @param event
		 * @param makeCurrent
		 * @param init
		 * @param removeEvent
		 */
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			trace("CollectionGame: handleEvent: " + event);
			switch (event)
			{
				case "restartGame":
					if (_wonGame)
					{
						
					}
					break;
			}
		}
		
		// timer enterFrame event
		private function fnTimer(e:Event):void
		{
			var vSecs:Number = Math.floor(_timeout - (getTimer() - _time) / 1000);
			if (vSecs != _secs)
			{
				// don't allow negative times
				if (vSecs < 0)
					vSecs = 0;
				
				_secs = vSecs;
				fnShowTime();
				if ((vSecs == 0) && (!_triggeredLose))
				{
					removeHUD();
					removeEndMessage();
					triggerLose();
				}
			}
		}
		
		protected function initLights():void
		{
			var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
			var lightLayerDisplay:Sprite = new Sprite();
			lightLayerDisplay.name = 'lightLayer';
			_scene.addEntity(cameraLayerCreator.create(lightLayerDisplay, 0, "lightLayer"));
			_scene.groupContainer.addChild(lightLayerDisplay);
			lightLayerDisplay.mouseChildren = false;
			lightLayerDisplay.mouseEnabled = false;
			addLightOverlay();
		}
		private function addLightOverlay():void
		{
			var lightCreator:LightCreator = new LightCreator();
			var lightLayerDisplay:DisplayObjectContainer = _scene.getEntityById("lightLayer").get(Display).displayObject;
			lightCreator.setupLight(_scene, lightLayerDisplay, _darkness);
			var light:Light = new Light(300, _darkness, .0, true, 0xD2F088);
			var entity:Entity = EntityUtils.createSpatialEntity(_scene, new MovieClip(), _hitContainer);
			var follow:FollowTarget = new FollowTarget(_scene.shellApi.player.get(Spatial),1,false,false,true);
			entity.add(follow).add(light);
		}
		// update timer display
		private function fnShowTime():void
		{
			var vMins:Number = Math.floor(_secs / 60);
			var vLeft:Number = _secs - vMins * 60;
			var vDigits:String = "0";
			if (vLeft < 10)
			{
				vDigits += String(vLeft);
			}
			else
			{
				vDigits = String(vLeft);
				
			}
			_textField.text = String(vMins) + ":" + vDigits;
		}
		
		// keep HUD aligned
		private function updateHUD(e:Event):void
		{
			if(_scene.shellApi.camera)
			{
				_HUD.x = _hudOffsetX;
				_HUD.y = _hudOffsetY;
			}
		}
		
		// keep end message aligned (although invisible for duration of game)
		private function updateEndMessage(e:Event):void
		{
			//make these values pull from xml
			if(_scene.shellApi.camera)
			{
				_endMessage.y = -_scene.shellApi.camera.y - 220;
				_endMessage.x = -_scene.shellApi.camera.x - 300;
			}
		}
		
		
		// when lose
		private function triggerLose():void
		{
			QuestGame(_scene).loadLosePopup();
			_triggeredLose = true;
		}
		
		public function gotAllItems():void
		{
			stopTimer();
			
			// make player speak
			if (_winPhrase != null)
			{
				if (_avatarSpeakDelay == 0)
				{
					playerSpeak();
				}
				else
				{
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _avatarSpeakDelay, 1, playerSpeak));
				}
			}
			// make NPC speak (assumes player is not speaking)
			if (_winNPCPhrase != null)
			{
				if (_NPCSpeakDelay == 0)
				{
					npcSpeak();
				}
				else
				{
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _NPCSpeakDelay, 1, npcSpeak));
				}
			}
			
			// if need to wait until player enters end zone first
			if (_hasEndZone)
			{
				// if need to display end message first (requires end zone entry)
				if (_endMessage != null)
				{
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _endMessageDelay, 1, triggerEndMessage));
				}
			}
			else
			{
				winGame();
			}
		}
		
		private function stopTimer():void
		{
			if (_textField)
				_textField.removeEventListener(Event.ENTER_FRAME, fnTimer);
		}
		
		private function playerSpeak():void
		{
			_scene.shellApi.player.get(Dialog).say(_winPhrase);
		}
		
		private function npcSpeak():void
		{
			_scene.getEntityById(_winNPC).get(Dialog).say(_winNPCPhrase);
		}
		
		// show end message and wait to enter end zone
		private function triggerEndMessage():void
		{
			_endMessage.visible = true;
		}
		
		// when enter end zone
		private function triggerEnd(zoneId:String, characterId:String):void
		{
			// if end message
			if (_endMessage != null)
			{
				// if end message is displayed
				if (_endMessage.visible)
				{
					// if not yet triggered win, then do so
					if (!_triggeredWin)
					{
						_triggeredWin = true;
						winGame();
					}
				}
			}
				// if no end message, then end game
			else
			{
				winGame();
			}
		}
		
		// win game and show popup or award card
		private function winGame():void
		{
			_wonGame = true;
			
			// remove end message if any
			removeEndMessage();
			
			// remove hud
			removeHUD();
			
			var timedEvent:TimedEvent;
			if (_awardCard != null)
			{
				timedEvent = new TimedEvent(_endDelay, 1, awardCard);
				SceneUtil.addTimedEvent(_scene, timedEvent);
				// trigger win event
				if (_winEvent != null)
				{
					_scene.shellApi.triggerEvent(_winEvent, false, false);
				}
				// don't lock player movement so can keep explorimg
				return;
			}
			else if (_endPopup != null)
			{
				timedEvent = new TimedEvent(_endDelay, 1, showEndPopup);
			}
			else
			{
				timedEvent = new TimedEvent(_endDelay, 1, QuestGame(_scene).loadWinPopup);
			}
			SceneUtil.addTimedEvent(_scene, timedEvent);
			
			// make avatar stop
			CharUtils.lockControls(_scene.shellApi.player);
		}
		
		private function removeEndMessage():void
		{
			if (_endMessage)
			{
				_endMessage.removeEventListener(Event.ENTER_FRAME, updateEndMessage);
				_endMessage = null;
			}
		}
		
		private function removeHUD():void
		{
			if (_HUD)
			{
				_HUD.removeEventListener(Event.ENTER_FRAME, updateHUD);
				_HUD.visible = false;
			}
		}
		
		private function awardCard():void
		{
			_scene.shellApi.getItem(_awardCard,"custom", true);
		}
		
		private function showEndPopup():void
		{
			// load end popup and load win popup when that is closed
			QuestGame(_scene).loadAnimPopup(_endPopup, QuestGame(_scene).loadWinPopup);
		}
		
		// from XML
		public var _showTimer:Boolean = false;		// to display timer
		public var _timeout:Number = 0; 			// when left as zero, then timer is disabled
		public var _winPhrase:String;				// what player says when win game
		public var _winNPC:String;					// NPC who speaks when win game
		public var _winNPCPhrase:String;			// NPC phrase when win game
		public var _winDelay:Number = 0;			// delay after speaking when win game
		public var _NPCSpeakDelay:Number = 0;		// NPC speak delay when win game
		public var _avatarSpeakDelay:Number = 0;	// player speak delay when win game
		public var _endPopup:String;				// path to popup to display when win game
		public var _awardCard:String;				// card to award when win game
		public var _endMessageDelay:Number = 0;		// delay before showing end message clip
		public var _endDelay:Number = 0;			// delay before showing end popup, win popup, end message, or awarding card
		public var _winEvent:String;				// event to trigger on win
		public var _partType:String;				// part type to update
		public var _partValue:String;				// part value for part type
		public var _textCounter:Boolean = false;	// text counter for items such as x of x items instead of visual display
		public var _textTimer:Boolean = false;		// text display of timer (no font detials needed)
		public var _nightMode:Boolean = false;		// night mode 
		public var _darkness:Number = .5;			// how dark night mode is
		public var _dartSpeed:Number = 100;			// how fast darts move

		// HUD from xml (default is 20 pixels from upper left)
		public var _hudOffsetX:Number = -460;
		public var _hudOffsetY:Number = -300;
		
		// Timer Font from xml
		public var _fontX:Number;
		public var _fontY:Number;
		public var _fontName:String;
		public var _fontColor:String;
		public var _fontSize:Number;

		//choose player flag
		public var _choose:Boolean = false;
		// HUD
		private var _HUD:MovieClip;		
		// end game
		private var _wonGame:Boolean = false;
		private var _triggeredWin:Boolean = false;
		private var _hasEndZone:Boolean = false;
		private var _endMessage:MovieClip;
		private var _hasAllItems:Boolean = false;
		
		// timer
		private var _textField:TextField;
		private var _time:Number;
		private var _secs:Number;
		private var _triggeredLose:Boolean = false;
		
		//collect animation that plays on collect
		private var _collectAnimation:Entity;
	}
}
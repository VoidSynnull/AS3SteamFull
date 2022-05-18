package game.scene.template.ads
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Zone;
	import game.components.input.Input;
	import game.components.motion.Destination;
	import game.components.motion.MotionControl;
	import game.components.motion.Threshold;
	import game.components.render.Line;
	import game.components.specialAbility.WhoopeeComponent;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.DuckSpin;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MoverHitData;
	import game.data.ui.ToolTipType;
	import game.managers.ScreenManager;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.AudioGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.PlayerRunSystem;
	import game.scenes.custom.RaceGameSystem;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.poptropolis.hurdles.Hurdles;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.systems.specialAbility.character.WhoopeeCushionSystem;
	import game.util.ArrayUtils;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	import org.hamcrest.object.nullValue;
	
	public class RaceGame extends AdGameTemplate
	{
		public function RaceGame(container:DisplayObjectContainer=null)
		{
			super(container);
			this.id = "RaceGame";
		}
		
		override public function destroy():void
		{		
			if(_stationaryEffect)
				_stationaryEffect.removeEventListener(Event.ENTER_FRAME,updateStationaryEffect);
			super.groupContainer = null;
			super.destroy();
		}
		
		override protected function playerSelected(...args):void
		{
			// show player
			_player.get(Display).visible = true;
			// start running game now
			startRunningGame();
		}
		
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void
		{
			super.setupGame(scene,xml,hitContainer);
			_player = scene.shellApi.player;
			_shellApi = scene.shellApi;
			
			// set up threshold for NPCs
			getLeftMostEntity();
			if (!scene.getSystem(ThresholdSystem))
				scene.addSystem(new ThresholdSystem());
			
			// if clearing all avatar costume parts (used when applying a brand new look)
			if (_clearParts)
			{
				var lookData:LookData = new LookData();
				// list of parts except head, body, eyes, mouth, and limbs
				var partsList:Array = [SkinUtils.FACIAL, SkinUtils.MARKS, SkinUtils.HAIR, SkinUtils.SHIRT, SkinUtils.PANTS, SkinUtils.PACK, SkinUtils.ITEM, 
					SkinUtils.OVERPANTS, SkinUtils.OVERSHIRT];
				for each (var part:String in partsList)
				{
					var lookAspect:LookAspectData = new LookAspectData( part, "empty" );
					lookData.applyAspect(lookAspect);
				}
				SkinUtils.applyLook(_player, lookData, false );
			}
			
			// if hiding body
			if (_hideBody)
			{
				// list of all body parts (note: mouth doesn't stay hidden because of animations)
				partsList = ["head", "body", "arm1", "arm2", "hand1", "hand2", "leg1", "leg2", "foot1", "foot2", "eyes", "mouth"];
				SkinUtils.hideSkinParts(_player, partsList);
			}
			if (_hideHead)
			{
				partsList = ["head", "eyes", "mouth"];
				SkinUtils.hideSkinParts(_player, partsList);
			}
			// apply handheld item, if any
			if (_item)
			{
				lookData = new LookData();
				lookAspect = new LookAspectData( SkinUtils.ITEM, _item ); 
				lookData.applyAspect(lookAspect);
				SkinUtils.applyLook(_player, lookData, false );
			}
			
			// apply part(s), if any (_partType and _partValue can be comma-delimited lists)
			if (_partType)
			{
				// check if array
				var types:Array = _partType.split(",");
				var values:Array = _partValue.split(",");
				lookData = new LookData();
				for (var i:int = types.length - 1; i != -1; i--)
				{
					lookAspect = new LookAspectData( types[i], values[i] ); 
					lookData.applyAspect(lookAspect);		
				}
				SkinUtils.applyLook(_player, lookData, false );
			}	
			if(_playerScale != 1)
				CharUtils.setScale(_player,_playerScale);
			//set limb width
			if(_lineThickness != 0)
			{
				var partList:Array = [CharUtils.LEG_FRONT, CharUtils.LEG_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK];
				for each (var charpart:String in partList)
				{
					var npcPart:Entity = CharUtils.getPart( _player, charpart );
					if (npcPart != null)
						npcPart.get(Line).lineWidth = _lineThickness;					
				}
			}

			// look for HUD
			if (hitContainer["HUD"] != null)
			{
				_HUD = MovieClip(DisplayGroup(scene).container.addChild(hitContainer["HUD"]));
				_HUD.x = -scene.shellApi.camera.viewport.width/2/scene.container.scaleX;
				_HUD.y = -scene.shellApi.camera.viewport.height/2/scene.container.scaleY;
				_HUDEntity = TimelineUtils.convertClip(_HUD, scene, null, null, false);
				// platform specific elements
				if (AppConfig.mobile)
				{
					if (_HUD["web"] != null)
						_HUD["web"].visible = false;
				}
				else
				{
					if (_HUD["mobile"] != null)
						_HUD["mobile"].visible = false;
				}
				if (_HUD.progress == null)
				{
					trace("======ERROR: HUD is missing progress bar!");
				}
				else
				{
					scene.addSystem( new RaceGameSystem(this, _player, _HUD.progress, _winDistance), SystemPriorities.update );
				}
				
				_textField = _HUD.timer;
				if(_textField && _timeout != 0)
				{
					_textField.addEventListener(Event.ENTER_FRAME,fnTimer);
				}
			}
			
			if(_collectionScore != 0)
			{
				_ScoreHUD = hitContainer["ScoreHUD"];
				if(_ScoreHUD != null)
				{
					_HUD.parent.addChild(_ScoreHUD);
					_textField = TextUtils.refreshText(_ScoreHUD.score, "Billy Bold");
					_ScoreHUD.x = _HUD.x + _HUD.width + 10;
					_ScoreHUD.y = _HUD.y;
				}
			}

			if (hitContainer["groundEffect"] != null)
			{
				_groundEffect = MovieClip(DisplayGroup(scene).container.addChild(hitContainer["groundEffect"]));
				_groundEffect.x = 0;
				_groundEffect.y = scene.shellApi.camera.viewport.height;
				_groundEffect.addEventListener(Event.ENTER_FRAME, updateGroundEffect);
				_groundEffectEntity = TimelineUtils.convertClip(_groundEffect, scene, null, null, false);
			}
			if (hitContainer["stationaryEffect"] != null)
			{
				_stationaryEffect = hitContainer["stationaryEffect"];
				_stationaryEffect.x = 0;
				_stationaryEffect.y = scene.shellApi.camera.viewport.height;
				_stationaryEffect.scaleX = scene.shellApi.screenManager.appScale;
				_stationaryEffect.scaleY = scene.shellApi.screenManager.appScale;
			//	_stationaryEffectEntity = EntityUtils.createSpatialEntity(scene,_stationaryEffect);
				_stationaryEffect.play();
				//_stationaryEffectEntity = TimelineUtils.convertClip(_stationaryEffect, scene, null, null, false);
				//_stationaryEffectEntity.add(new Spatial(0,0));
				_stationaryEffect.addEventListener(Event.ENTER_FRAME, updateStationaryEffect);

			}
			
			// if endless running game, then make player run and make background scroll
			if (_runningGame)
			{
				SceneUtil.getInput( scene ).inputDown.add( runningClick );
				
				// look for ouch bubble
				var ouchBubble:MovieClip = hitContainer["ouchBubble"];
				if (ouchBubble != null)
				{
					_ouchBubble = TimelineUtils.convertClip(ouchBubble, _scene, null, null, false);
					_ouchBubble.add(new Spatial(ouchBubble.x, ouchBubble.y));
					_ouchBubble.add(new Display(ouchBubble, hitContainer));
					DisplayUtils.moveToTop(_ouchBubble.get(Display).displayObject);
					_ouchBubble.get(Sleep).ignoreOffscreenSleep = true;
				}
				
				// look for flash clip
				var flash:MovieClip = hitContainer["flash"];
				if (flash != null)
				{
					_flash = TimelineUtils.convertClip(flash, _scene, null, null, false);
					_flash.add(new Spatial(flash.x, flash.y));
					_flash.add(new Display(flash, hitContainer));
					_flash.get(Sleep).ignoreOffscreenSleep = true;
				}
				
				//look for custom player
				var customPlayer:MovieClip = hitContainer["player"];
				if (customPlayer != null)
				{
					_player.add(new Display(customPlayer));
				}
				
				// look for explosion
				var explosion:MovieClip = hitContainer["explosionEffect"];
				if (explosion != null)
				{
					_explosion = TimelineUtils.convertClip(explosion, _scene, null, null, false);
					_explosion.add(new Spatial(explosion.x, explosion.y));
					_explosion.add(new Display(explosion, hitContainer));
					_explosion.get(Sleep).ignoreOffscreenSleep = true;
				}
			}
			
			// if look data, then load choose popup
			if(_choose)
			{
				if(_looks != null)
				{
					var selectionPopup:AdChoosePopup = QuestGame(scene).loadChoosePopup() as AdChoosePopup;
					selectionPopup.ready.addOnce(gameSetUp.dispatch);
					selectionPopup.selectionMade.addOnce(QuestGame(scene).playerSelection);
				}
			}
			else
			{
				// dispatch doesn't trigger
				gameSetUp.dispatch(this);
				QuestGame(_scene).gameSetUp();
				
				playerSelection();
				
				// start running game if no choose popup
				startRunningGame();
			}
			var startAnimation:MovieClip = hitContainer["startAnimation"];
			if (startAnimation != null)
			{
				_startAni = startAnimation;
				SceneUtil.lockInput(_scene,true);
				var startAni:Entity = TimelineUtils.convertClip(startAnimation, _scene, null, null, false);
				startAni.get(Timeline).play();
				startAni.get(Timeline).handleLabel("endAnimation",unlockInput);
			}
		}
		
		private function startTimer():void
		{
			_time = getTimer();
			_secs = _timeout / 1000;
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
					triggerLose();
				}
			}
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
		
		private function startRunningGame():void
		{
			if (_timeout != 0)
				startTimer();
			
			_scene.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			
			if (_runningGame)
			{
				_playerRunSystem = PlayerRunSystem(_scene.addSystem(new PlayerRunSystem(this)));
				// if running, not biking, else leave as standing
				if (_raceSpeed != 0)
				{
					CharUtils.setAnim(_player, Run);
					_playerRunSystem.setPlayerSpeed(_raceSpeed, _player);
				}
				else
				{
					// if biking
					// force skid speed higher to prevent skidding altogether (normally 320)
					_player.get(CharacterMotionControl).skidSpeed = 800;
					_playerRunSystem.setPlayerSpeed(_bikeSpeed, _player);
				}
			}
			
		}
		
		protected function unlockInput():void
		{
			if (_startNPCPhrase != null)
			{
				if (_StartNPCSpeakDelay == 0)
					npcSpeakStart();
				else
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _StartNPCSpeakDelay, 1, npcSpeakStart));				
			}
			_startAni.visible = false;
			SceneUtil.lockInput(_scene,false);
		}
		/**
		 * Parse xml and setup obstacles and chaser
		 * @param xml
		 */
		override protected function parseXML(xml:XML):void
		{
			super.parseXML(xml);
			parseGameXML(xml);
			
			// hide player
			_scene.shellApi.player.get(Display).visible = false;
			
			if (isNaN(_chaserSpeed) || _chaserSpeed == 0)
				_chaserSpeed = int(xml.npcSpeed);
			
			// if avatar says something when win
			if (xml.hasOwnProperty("winPhrase"))
			{
				_avatarWinPhrase = xml.winPhrase;
				_avatarSpeakDelay = int(xml.winPhrase.attribute("delay"));
			}
			
			// if npc says something when starting
			if (xml.hasOwnProperty("startNPCPhrase"))
			{
				_startNPCPhrase = xml.startNPCPhrase;
				_startNPC = xml.startNPCPhrase.attribute("npc");
				_StartNPCSpeakDelay = int(xml.startNPCPhrase.attribute("delay"));
			}
			// if npc says something when win
			if (xml.hasOwnProperty("winNPCPhrase"))
			{
				_winNPCPhrase = xml.winNPCPhrase;
				_winNPC = xml.winNPCPhrase.attribute("npc");
				_NPCSpeakDelay = int(xml.winNPCPhrase.attribute("delay"));
			}
			if (xml.hasOwnProperty("winNPCPhrase2"))
			{
				_winNPCPhrase2 = xml.winNPCPhrase2;
				_winNPC2 = xml.winNPCPhrase2.attribute("npc");
			}
			if (xml.hasOwnProperty("winNPCPhrase3"))
			{
				_winNPCPhrase3 = xml.winNPCPhrase3;
				_winNPC3 = xml.winNPCPhrase3.attribute("npc");
			}
			
			// name of animating clip that chases avatar
			if (xml.hasOwnProperty("chaserClip"))
			{
				// get clip within scene (might be animating clip)
				var chaserClip:MovieClip = _hitContainer[xml.chaserClip];
				// if found
				if (chaserClip)
				{
					// convert to timeline and add components
					_chaserClipEntity = TimelineUtils.convertClip(chaserClip, _scene);
					_chaserClipEntity.add(new Spatial(chaserClip.x, chaserClip.y));
					_chaserClipEntity.add(new Display(chaserClip, _hitContainer));
					_chaserClipEntity.add(new Motion());
					_chaserClipEntity.add(new Sleep(false, true));
					_chaserClipEntity.get(Timeline).play();
				}
			}
			
			// if action to trigger when win
			if (xml.hasOwnProperty("winNPCAction"))
			{
				_winNPCAction = xml.winNPCAction;
				_winNPCForAction = xml.winNPCAction.attribute("npc");
				_winNPCActionParam = xml.winNPCAction.attribute("param");
				_winNPCActionDelay = int(xml.winNPCAction.attribute("delay"));
			}
			
			// race speed for running game
			if (xml.hasOwnProperty("raceSpeed"))
			{
				_runningGame = true;
			}
			
			// bike speed for endless biking game
			if (xml.hasOwnProperty("bikeSpeed"))
			{
				_runningGame = true;
				
				_canRoll = false;
			}
			
			if(_runningGame)
			{
				if (xml.hasOwnProperty("numHits"))
				{
					_numHits = int(xml.numHits);
					_health = _numHits;
				}
				var cameraSystem:CameraSystem = CameraSystem(_scene.getSystem(CameraSystem));
				cameraSystem.offsetX = _runningOffset;
			}

			// create array of obstacles
			// need to do this because we are deleting movieClips as we process them
			var obstacleList:Array = [];
			for (var i:int = _hitContainer.numChildren - 1; i != -1; i--)
			{
				// if movie clip
				if (_hitContainer.getChildAt(i) is MovieClip)
				{
					var clip:MovieClip = MovieClip(_hitContainer.getChildAt(i));
					// stop on first frame
					clip.gotoAndStop(0);
					// only get clips that have underscore in name
					// all hit objects need to have underscore in name
					// objects without underscores are ignored
					var pos:int = clip.name.indexOf("_");
					if (pos != -1)
					{
						obstacleList.push(clip);
					}
				}
			}
			// update hit objects
			// since they can be positioned way off screen, you can add the coords to the name such as obstacle1000x800
			// and the framework will position them for you based on their name
			for (i = obstacleList.length - 1; i != -1; i--)
			{
				clip = obstacleList[i];
				// obsXXX_ are basic hit obstacles you crash into (not effective for endless runner games)
				// bxxx_ are bounce hit obstacles (not effective for endless runner games)
				// shootXXX_ are non-hit obstacles you can shoot (you can't crash into these)
				// animXXX_ are obstacles that animate when entering the scene (like earth drill)
				// zoneXXX_ are obstacles that have an interaction when entering the zone (hit or non-hit)
				// zoneObsXXX_ are zone obstacles above that trigger ouch animation on hit and trigger a hit animation
				
				pos = clip.name.indexOf("_");
				var prefix:String = clip.name.substr(0,pos);
				
				// set position if coordinates given with NxN
				var suffix:String = clip.name.substr(pos+1);
				var xpos:int = suffix.indexOf("x");
				if (xpos != -1)
				{
					clip.x = Number(suffix.substr(0,xpos));
					clip.y = Number(suffix.substr(xpos+1)); 
				}
				// else reposition based on clip position when wrap provided
				else if (_obstacleWrap != 0)
				{
					//DisplayUtils.moveToTop(clip);

					var row:Number = Math.floor((clip.y - _obstacleStartY)/_obstacleSpaceY) + 1;
					clip.x = clip.x + _obstacleWrap * row;
					
					// start offset at bottom bounds
					var offsetY:Number = -clip.getBounds(clip).bottom;
					
					// if using regpoint clip then shift by regpoint y
					if (clip.regpoint != null)
						offsetY += clip.regpoint.y;
					
					// if using alignment clip, then use obstacle y not bottom boumds
					// requires obstacle have registration point at bottom
					if (clip.align != null)
					{
						clip.align.visible = false;
						offsetY = -clip.align.y;
					}
					clip.y = _obstacleY + offsetY;
				}
				
				trace("Positioning clip: " + clip.name + " at " + clip.x + "," + clip.y);
				
				// setup hit if running game
				if (_runningGame)
				{
					// if zones to be triggered
					// zones beyond win distance will extend game
					if (clip.name.substr(0,4) == "zone")
					{
						var zoneEntity:Entity =_scene.getEntityById(clip.name);
						var endzone:Zone = zoneEntity.get(Zone);
						endzone.pointHit = true;
						endzone.inside.add(enterZone);
						// set spatial since we have just moved clip
						zoneEntity.get(Spatial).x = clip.x;
						zoneEntity.get(Spatial).y = clip.y;
						zoneEntity.get(Sleep).ignoreOffscreenSleep = true;
						// make zone visible
						zoneEntity.get(Display).visible = true;
						setupTimelineAnimation(prefix, zoneEntity, clip);
					}
					// all other obstacles
					else
					{
						if(clip.x > _winDistance)
						{
							clip.parent.removeChild(clip);
							continue;
						}
						var entity:Entity = EntityUtils.createSpatialEntity(_scene, clip, _hitContainer);
						entity.add(new Id(clip.name));
						setupTimelineAnimation(prefix, entity, clip);
					}
				}
				
				// for standard race game (not endless runner game)
				var hitCreator:HitCreator = new HitCreator();
				hitCreator.showHits = true;
				var audioGroup:AudioGroup = _scene.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
				
				// most hit types will use default values if hitData is left out.
				// if has shoot prefix then set to hazard
				if (clip.name.substr(0, 5) == "shoot")
				{
					hitCreator.createHit(clip, HitType.HAZARD, null, _scene);
				}
				else if (clip.name.substr(0, 1) == "b")
				{
					// bounce objects
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
				else if (clip.name.substr(0, 3) == "obs")
				{
					// set to wall and platform top
					var platformHit:Entity = hitCreator.createHit(clip, HitType.PLATFORM_TOP, null, _scene);
					platformHit.add(new Id("platformhit"));
					hitCreator.createHit(clip, HitType.WALL, null, _scene);
					hitCreator.addHitSoundsToEntity( platformHit, audioGroup.audioData, _scene.shellApi );
				}
				else if (clip.name.substr(0, 3) == "haz")
				{
					// set up hazard
					var hazardHitData2:HazardHitData = new HazardHitData();
					hazardHitData2.knockBackVelocity = new Point(500,500);
					hazardHitData2.knockBackCoolDown = .75;
					hazardHitData2.velocityByHitAngle = true;
					var hazard:Entity = hitCreator.createHit(clip, HitType.HAZARD, hazardHitData2, _scene);
				}
				else if (clip.name.substr(0,4) == "slip")
				{
					if (_scene.getSystem(WhoopeeCushionSystem) == null) 
					{
						_scene.addSystem(new WhoopeeCushionSystem());
					}
					
					var whoopeeCushion:WhoopeeComponent = new WhoopeeComponent();
					whoopeeCushion.slip = true;
					whoopeeCushion.vSpeed = -400;
					whoopeeCushion.hSpeed = 1000;
					whoopeeCushion.spin = 700;
					whoopeeCushion.vAccel = 600;
					entity = EntityUtils.createSpatialEntity(_scene, clip, _hitContainer);
					entity.add(whoopeeCushion);
				}
			}
			// if running game, then sort animating entities
			if (_runningGame)
			{
				_animatingEntities.sortOn("xpos", Array.NUMERIC);
			}
		}
		
		private function setupTimelineAnimation(prefix:String, entity:Entity, clip:MovieClip):void
		{
			if (clip.totalFrames != 1)
			{
				var clipEntity:Entity;
				var useClip:Boolean = true;
				// check if in pool and skip out if found
				if (_animatingPool[prefix] != null)
				{
					useClip = false;
					clipEntity = entity;
				}
				
				if (useClip)
				{
					// convert clip
					//var clipEntity:Entity = TimelineUtils.convertClip(clip, _scene, entity, null, false);
					trace("processing clip " + clip.name);
					clipEntity = BitmapTimelineCreator.convertToBitmapTimeline(entity, clip, true, null, PerformanceUtils.defaultBitmapQuality);
					var timeline:Timeline = clipEntity.get(Timeline);
					_animatingPool[prefix] = entity;
				}
				
				// if has two labels: hit label and stop label and no idle labels (or two stop labels)
				// assumes no idle animation but static frame
				if (clip.currentLabels.length == 2)
				{
					if (useClip)
					{
						// stop on first frame
						timeline.gotoAndStop(0);
					}
					// add to animating entities array
					_animatingEntities.push({"entity":clipEntity, "xpos":clip.x, "loop":false, "prefix":prefix});
					trace("Stopping " + clip.name + " on first frame");
				}
				// if need to loop on idle with hit following (assumes 3 labels: idle, idleEnd, hit, stop)
				else if (clip.currentLabels.length == 4)
				{
					if (useClip)
					{
						timeline.labelReached.add(Command.create(checkAnimLabel, timeline));
					}
					// add to animating entities array
					_animatingEntities.push({"entity":clipEntity, "xpos":clip.x, "loop":true, "prefix":prefix});
					trace("Looping " + clip.name + " on idle frames");
				}
				// no labels or other than 2 or 4 labels - assumes basic looping animation
				else
				{
					// add to animating entities array
					_animatingEntities.push({"entity":clipEntity, "xpos":clip.x, "loop":true, "prefix":prefix});
					trace("Looping " + clip.name + " timeline");
				}
				
				// if not using clip then delete it
				if (!useClip)
				{
					entity.get(Display).displayObject = new MovieClip();
					clip.parent.removeChild(clip);
				}
			}
			// if one frame, then convert to bitmap
			else
			{
				var sprite:Sprite = BitmapUtils.createBitmapSprite(clip, 1);
				sprite = Sprite(_hitContainer.addChildAt(sprite, 1));
				
				entity.get(Display).displayObject = sprite;
				clip.parent.removeChild(clip);
			}
			
		}
		
		// check animation label (for idle loops)
		private function checkAnimLabel(label:String, timeline:Timeline):void
		{
			if (label == "idleEnd")
				timeline.gotoAndPlay("idle");
		}
		
		/**
		 * Get leftmost entity (NPC or animating clip)
		 */
		private function getLeftMostEntity():void
		{
			var dist:Number = 10000000;
			var entity:Entity;
			var chaseEntity:Entity;
			var threshold:Threshold;
			
			// if running game
			if (_runningGame)
			{
				// if any animating entities left
				if (_animatingEntities.length != 0)
				{
					// get next entity and set threshold
					entity = _animatingEntities[0]["entity"];
					threshold = new Threshold( "x", ">", entity, _edgeThreshold );
					threshold.entered.add(animateObstacle);
				}
			}
			else
			{
				// get all NPCs
				var npcList:NodeList = _scene.systemManager.getNodeList( NpcNode );
				for ( var npcNode:NpcNode = npcList.head; npcNode; npcNode = npcNode.next )
				{
					entity = npcNode.entity;
					// get leftmost NPC that is not processed
					if ((entity.get(Spatial).x < dist) && (entity.get(Display).displayObject.processed != true))
					{
						// if not chasing entity then mark as processed
						if (entity.get(Id).id.indexOf(_chaserPrefix) == -1)
						{
							entity.get(Display).displayObject.processed = true;
						}
						else
						{
							// if chasing entity
							chaseEntity = npcNode.entity;
							dist = chaseEntity.get(Spatial).x;
						}
					}
				}
				// if chaser clip entity and not processed, then set
				if ((_chaserClipEntity) && (!_chaserClipEntity.get(Display).displayObject.processed))
					chaseEntity = _chaserClipEntity;
				
				// if entity found or chaser clip entity then make that the next threshold
				if (chaseEntity)
				{
					_follower = chaseEntity;
					_follower.get(Display).displayObject.processed = true;
					// threshold for chasing when walking past NPC
					threshold = new Threshold( "x", ">", _follower, _chaseDistance );
					// signal for when chase distance is exceeded
					threshold.entered.add( triggerChase );
				}
			}
			// if no threshold and no animating entities, then set to end threshold
			if ((_animatingEntities.length == 0) && (threshold == null || _winDistance > 0))
			{
				if(!chaseEntity)
				{
					chaseEntity = new Entity().add( new Spatial(_winDistance,0));
					_scene.addEntity(chaseEntity);
					threshold = new Threshold( "x", ">", chaseEntity, 0 );
					threshold.entered.add( triggerWin );	
				}	
			}
			if(_forceWinThreshold)
			{
				if(!chaseEntity)
				{
					chaseEntity = new Entity().add( new Spatial(_winDistance,0));
					_scene.addEntity(chaseEntity);
					threshold = new Threshold( "x", ">", chaseEntity, 0 );
					threshold.entered.add( triggerWin );	
				}	
			}
			// add threshold to player
			_threshold = threshold;
			_player.add( _threshold );
		}
		
		/**
		 * Trigger NPC or animated clip chase
		 */
		private function triggerChase():void
		{
			var overlap:int = 0;
			// if chaser clip entity (non NPC)
			if (_chaserClipEntity)
			{
				// start moving chaser clip
				_chaserClipEntity.get(Motion).velocity.x = _chaserSpeed;
				overlap = 0;
			}
			else
			{
				// if NPC entity as chaser
				var destination:Destination = CharUtils.followEntity(_follower, _player);
				// this code doesn't seem to work but it's okay for now
				destination.ignorePlatformTarget = _ignorePlatforms;
				// this code seems to cause the NPC to fall through floor
				//if (_ignorePlatforms)
				//_follower.remove(PlatformCollider);
				if (_ignoreWalls)
					_follower.remove(WallCollider);
				
				// set npc speed (default is 800, anything less than 440 will be walking only)
				_follower.get(CharacterMotionControl).maxVelocityX = _chaserSpeed;
				overlap = -100;
			}
			
			// add threshold for overlapping player after chase starts (to trigger losing game)
			var threshold:Threshold = new Threshold( "x", ">", _player, overlap );
			threshold.entered.add( triggerLose );
			_follower.add(threshold);
			
			// get leftmost entity to chase or animate
			getLeftMostEntity();
		}
		
		// END GAME FUNCTIONS ////////////////////////////////////////////////
		
		/**
		 * Trigger lose
		 */
		private function triggerLose():void
		{
			if(_textField)
			{
				_textField.removeEventListener(Event.ENTER_FRAME, fnTimer);
			}
			_playing = false;
			if (_runningGame)
			{
				CharUtils.setAnim(_player, Stand);
				_playerRunSystem.setPlayerSpeed(0);
			}
			stopAllCharacters();
			QuestGame(_scene).loadLosePopup();
		}
		
		/**
		 * Trigger win
		 */
		private function triggerWin():void
		{
			if(_textField)
			{
				_textField.removeEventListener(Event.ENTER_FRAME, fnTimer);
			}
			_playing = false;
			// force standing player if running game
			if (_runningGame || _stopPlayer)
			{
				CharUtils.setAnim(_player, Stand);
				_playerRunSystem.setPlayerSpeed(0);
			}
			
			// if avatar says something
			if (_avatarWinPhrase != null)
			{
				if (_avatarSpeakDelay == 0)
					playerSpeak();
				else
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _avatarSpeakDelay, 1, playerSpeak));
			}
			
			// if npc says something
			if (_winNPCPhrase != null)
			{
				if (_NPCSpeakDelay == 0)
					npcSpeak();
				else
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _NPCSpeakDelay, 1, npcSpeak));

			}
			
			// if npc has action
			if (_winNPCAction != null)
			{
				if (_winNPCActionDelay == 0)
					npcAction();
				else
					SceneUtil.addTimedEvent(_scene, new TimedEvent( _winNPCActionDelay, 1, npcAction));
			}
			// stop all characters
			stopAllCharacters();
			
			// if no win delay then load win popuop
			if (_winDelay == 0)
			{
				QuestGame(_scene).loadWinPopup();
			}
			else
			{
				// else need timer before loading popup
				SceneUtil.addTimedEvent(_scene, new TimedEvent( _winDelay, 1, QuestGame(_scene).loadWinPopup));
			}
		}
		
		/**
		 * Player speak at win
		 */
		private function playerSpeak():void
		{
			_player.get(Dialog).say(_avatarWinPhrase);
		}
		
		/**
		 * NPC speak at win
		 */
		private function npcSpeak():void
		{
			var winNPC:Entity = _scene.getEntityById(_winNPC);
			winNPC.get(Dialog).say(_winNPCPhrase);
			
			if(_winNPCPhrase2 != null)
				SceneUtil.addTimedEvent(_scene, new TimedEvent( _NPCSpeakDelay, 1, npcSpeak2));
			if (_lockCameraNPC)
				SceneUtil.setCameraTarget(_scene, winNPC);
			
		}
		private function npcSpeakStart():void
		{
			_scene.getEntityById(_startNPC).get(Dialog).say(_startNPCPhrase);	
		}
		private function npcSpeak2():void
		{
			_scene.getEntityById(_winNPC2).get(Dialog).say(_winNPCPhrase2);
			if(_winNPCPhrase3 != null)
				SceneUtil.addTimedEvent(_scene, new TimedEvent( _NPCSpeakDelay, 1, npcSpeak3));
		}
		private function npcSpeak3():void
		{
			_scene.getEntityById(_winNPC3).get(Dialog).say(_winNPCPhrase3);
		}
		
		/**
		 * Win NPC action 
		 */
		private function npcAction():void
		{
			switch(_winNPCAction)
			{
				case "run":
					var coords:Array = _winNPCActionParam.split(",");
					var npc:Entity = _scene.getEntityById(_winNPCForAction);
					if (npc)
					{
						var destination:Destination = CharUtils.moveToTarget(npc, Number(coords[0]), Number(coords[1]), false);
						// if action npc is also npc to ignore platforms then ignore platforms
						if (_winNPCForAction == _npcIgnorePlatforms)
						{
							// this code doesn't seem to work, but it's okay for now
							destination.ignorePlatformTarget = true;
						}
						// if action npc is also npc to ignore platforms then ignore platforms
						if (_winNPCForAction == _npcIgnoreWalls)
						{
							npc.remove(WallCollider);
						}
					}
					else
					{
						trace(this," :: Can't find entity for npcAction: " + _winNPCForAction);
					}
					
					break;
				default:
					trace(this," :: unrecognized win action param: " + _winNPCActionParam);
			}
		}
		
		/**
		 * Stop all characters
		 */
		private function stopAllCharacters():void
		{
			// make avatar stop
			CharUtils.lockControls(_player);
			// make NPCs stop
			var npcList:NodeList = _scene.systemManager.getNodeList( NpcNode );
			for ( var npcNode:NpcNode = npcList.head; npcNode; npcNode = npcNode.next )
			{
				CharUtils.lockControls(npcNode.entity);
				// turn off move to target
				var npcMotionControl:MotionControl = npcNode.entity.get(MotionControl);
				if (npcMotionControl)
					npcMotionControl.forceTarget = false;
			}
			// stop chaser clip
			if (_chaserClipEntity)
			{
				_chaserClipEntity.get(Timeline).stop();
				_chaserClipEntity.get(Motion).velocity.x = 0;
			}
		}
		
		// ENDLESS RUNNER FUNCTIONS //////////////////////////////////////////
		
		/**
		 * When clicking during running game
		 * @param input
		 */
		private function runningClick(input:Input):void
		{
			var motion:Motion = _player.get(Motion);
			
			// if airborne
			if(!_multiJump || _currJump >= _numOfJumps  && _numOfJumps > 0)
			{
				if (motion.velocity.y == 0)
					_currJump = 0;
				if (motion.velocity.y != 0)
					return;
			}
			// if click above player or rolling is not allowed, then jump
			if ((!_canRoll) || (input.target.y - (_player.get(Spatial).y - _shellApi.camera.viewport.y) < 0))
			{
				motion.velocity.y = -_jumpSpeed;
				motion.acceleration.y = _jumpAccel;
				_currJump++;
				_groundEffectFade = true;
				if (_raceSpeed != 0)
				{
					CharUtils.setAnimSequence( _player, new <Class>[HurdleJump, Run]);
				}
				else
				{
					_player.get(Spatial).rotation = -20;
				}
				CharUtils.getTimeline( _player ).labelReached.add(checkGround);
			}
			else
			{
				// if click below player
				// roll player
				_rolling = true;
				var motionCtrl:CharacterMotionControl = _player.get(CharacterMotionControl);
				motionCtrl.ignoreVelocityDirection = false;
				motionCtrl.spinning = true;
				motionCtrl.spinCount = 1;							
				motionCtrl.spinSpeed = 800;			
				motion.friction.x = motionCtrl.duckFriction;				
				CharUtils.setAnim(_player, DuckSpin);
				
				// listen to animation label
				CharUtils.getTimeline( _player ).labelReached.add(resumeRunning);
			}
			if(DataUtils.validString(_partType))
			{
				var entity:Entity = SkinUtils.getSkinPartEntity(_player, _partType);
				var time:Timeline = entity.get(Timeline);
				if(time != null)
				{
					if(time.getLabelIndex("jump") > 0)
					{
						time.gotoAndPlay("jump");
						_resetTimeline = true;
					}
				}
			}
		}
		
		/**
		 * update ground effect
		 */
		private function updateGroundEffect(e:Event):void
		{
			if(_groundEffectFade && _groundEffect.alpha > 0)
				_groundEffect.alpha -= .05;
			else if(!_groundEffectFade && _groundEffect.alpha < 1)
				_groundEffect.alpha += .05;
		}
		/**
		 * update ground effect
		 */
		private function updateStationaryEffect(e:Event):void
		{
			var point:Point = DisplayUtils.localToLocalPoint(new Point(0, 0), _shellApi.screenManager.stage, _hitContainer);
			_hitContainer.setChildIndex(_stationaryEffect,0);
			_stationaryEffect.x = point.x;
		}
		
		/**
		 * Resume running
		 * @param label
		 * @param player
		 */
		private function resumeRunning(label:String):void
		{
			// if end of duck spin animation
			if (label == "end")
			{
				_rolling = false;
				// remove trigger
				CharUtils.getTimeline(_player).labelReached.remove(resumeRunning);
				// set Run animation
				CharUtils.setAnim(_player, Run);
				
				if(_resetTimeline)
				{
					var time:Timeline = SkinUtils.getSkinPartEntity(_player, _partType).get(Timeline);
					time.gotoAndPlay(0);
				}
					
			}
			if ((label == "stand") && (_groundEffect != null))
				_groundEffect.visible = true;
		}
		
		/**
		 * check ground
		 * @param label
		 * @param player
		 */
		private function checkGround(label:String):void
		{
			if(label == "stand")
			{
				_groundEffectFade = false;
				CharUtils.getTimeline(_player).labelReached.remove(checkGround);
				if(_resetTimeline)
				{
					var time:Timeline = SkinUtils.getSkinPartEntity(_player, _partType).get(Timeline);
					time.gotoAndPlay(0);
				}
			}
		}
		
		/**
		 * Lose health
		 */
		private function loseHealth():void
		{
			// subtract health
			_health--;

			// update health meter
			var timeline:Timeline = _HUDEntity.get(Timeline);
			timeline.gotoAndStop(timeline.currentIndex + 1);
			
			// lose if health is zero
			if (_health == 0)
				triggerLose();
		}
		
		/**
		 * When player enters zone
		 * @param zoneId
		 * @param characterId
		 */
		private function enterZone(zoneId:String, characterId:String):void
		{
			var zoneEntity:Entity =_scene.getEntityById(zoneId);
			
			// ignore if not playing
			if (!_playing)
			{
				var endzone:Zone = zoneEntity.get(Zone);
				endzone.inside.remove(enterZone);
				_player.remove(Threshold);
				trace("Ignoring zone as game is over");
				return;
			}
			
			// get zone name and make current
			// check against previous zone
			
			
			
			if ((zoneId != _currentZone) && (zoneId != _prevZone))
			{
				// remember zones
				_prevZone = _currentZone;
				_currentZone = zoneId;
				
				// get obstacle name from zone ID
				var index:int = zoneId.indexOf("_");
				var name:String = zoneId.substr(4, index-4);
				var sub:String = name.substr(0,3);
				
				if(sub == "Obs" || sub == "Col")
				{
					var time:Timeline;
					// play hit animation
					if ((zoneEntity != null) && (zoneEntity.has(Timeline)))
					{
						time = zoneEntity.get(Timeline);
						time.gotoAndPlay("hit");
						if(sub == "Col")
						{
							time.handleLabel("ending", Command.create(_scene.removeEntity, zoneEntity, true));
						}
					}
					// play sfx (get sound from sounds.xml with lowercase object + "Hit" such as "boxHit"
					var audioGroup:AudioGroup = _scene.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
					var materialHit:String = name.substr(3).toLowerCase() + "Hit";
					var hitDict:Dictionary = audioGroup.audioData[materialHit];
					if (hitDict != null)
					{
						var assets:* = hitDict[GameEvent.DEFAULT]["impact"].asset;
						var asset:String;
						if(typeof(assets) == "object")
						{
							asset = ArrayUtils.getRandomElement(assets);
						}
						else
						{
							asset = assets;
						}
						AudioUtils.play(_scene, asset);
					}
					if (name.substr(0,3) == "Obs")
					{
						if(DataUtils.validString(_partType))
						{
							var entity:Entity = SkinUtils.getSkinPartEntity(_player, _partType);
							time = entity.get(Timeline);
							if(time != null)
							{
								if(time.getLabelIndex("hit") > 0)
								{
									time.gotoAndPlay("hit");
								}
							}
						}
						
						// slow down player 100%
						_playerRunSystem.slowDown(1.0, 1.0);
						// position ouch bubble
						if (_ouchBubble)
						{
							_ouchBubble.get(Timeline).gotoAndPlay(2);
							_ouchBubble.get(Spatial).x = _player.get(Spatial).x;
							_ouchBubble.get(Spatial).y = _player.get(Spatial).y;
						}
						loseHealth();
					}
					else if (name.substr(0,3) == "Col")
					{
						_score += _collectionScore;
						if(_textField != null)
						{
							_textField.text = "" + _score;
						}
						if ((zoneEntity != null) && !(zoneEntity.has(Timeline)))
						{
							_scene.removeEntity( zoneEntity);
						}
						trace("score: " + _score);
					}
				}
				else
				{
					// check name
					switch (name)
					{
						case "Puddle":
							// play sfx
							AudioUtils.play(_scene, "effects/water_splash_06.mp3");
							// slow down player 80%
							_playerRunSystem.slowDown(0.8, 1.0);
							break;
						
						case "Pipe":
							if (_rolling)
								break;
							
						case "Drilldown":
						case "Drillup":
							// play sfx
							AudioUtils.play(_scene, "effects/machine_impact_02.mp3");
							// slow down player 100%
							_playerRunSystem.slowDown(1.0, 1.0);
							// play hurt animation
							CharUtils.setAnim( _player, Hurt);
							CharUtils.getTimeline( _player ).labelReached.add(resumeRunning);
							// position ouch bubble
							if (_ouchBubble)
							{
								_ouchBubble.get(Timeline).gotoAndPlay(2);
								_ouchBubble.get(Spatial).x = _player.get(Spatial).x;
								_ouchBubble.get(Spatial).y = _player.get(Spatial).y;
							}
							if (name == "Drillup")
							{
								loseHealth();
							}
							break;
					}
				}
			}
		}
		
		/**
		 * Animate zone obstacle when obstacle comes into view
		 */
		private function animateObstacle():void
		{
			var obstacle:Object = _animatingEntities[0];
			// get entity
			var entity:Entity = obstacle["entity"];
			var prefix:String = obstacle["prefix"];
			// strip off zone from name
			var name:String = prefix.substr(4);
			
			// use pool object
			var pool:Entity = _animatingPool[prefix];
			if (pool == null)
			{
				trace("Missing pool entity for " + prefix);
			}
			else
			{
				// position pool display to align with entity
				pool.get(Spatial).x = entity.get(Spatial).x;
				pool.get(Display).displayObject.x = entity.get(Spatial).x;
				
				if (pool.has(Timeline))
				{
					pool.get(Timeline).gotoAndPlay(0);
				}
				else
				{
					trace(prefix + " has no timeline");
				}
				
				// play audio
				switch (name)
				{
					case "Drilldown":
					case "Drillup":
						AudioUtils.play(_scene, "effects/turn_engine_on_01.mp3");
						break;
					
					case "ObsBear":
						_flash.get(Timeline).gotoAndPlay(2);
						_flash.get(Spatial).x = entity.get(Spatial).x;
						_flash.get(Spatial).y = entity.get(Spatial).y;
						break;
				}
			}
			
			// get next obstacle in sequence
			_animatingEntities.splice(0,1);
			getLeftMostEntity();
		}
		
		// from XML
		public var _winDistance:int;						// target distance to win game
		public var _timeout:Number = 0; 			// when left as zero, then timer is disabled
		public var _numHits:int = 9;						// number of collisions before losing game
		public var _item:String;							// item to put into avatar's hand
		public var _clearParts:Boolean = false;			// clear all costume parts from avatar
		public var _hideBody:Boolean = false;				// hide avatar body
		public var _hideHead:Boolean = false;				// hide avatar head
		public var _partType:String;						// part type(s) to change for avatar
		public var _partValue:String;						// part value(s) to change for avatar
		public var _raceSpeed:int = 0;						// race speed for endless runner game
		public var _bikeSpeed:int = 0;						// bike speed for endless biking game
		public var _chaseDistance:int;							// distance to exceed before NPC starts chasing you
		public var _chaserSpeed:int;						// speed of chasing NPC or entity
		public var _chaserPrefix:String = "chaser";		// prefix of chasing NPC or entity
		public var _ignorePlatforms:Boolean =  false;		// Cchasing NPCs ignore platforms
		public var _ignoreWalls:Boolean = false;			// chasing NPCs ignore walls
		public var _npcIgnorePlatforms:String;				// Oother NPCs ignore platforms
		public var _npcIgnoreWalls:String;					// other NPCs ignore walls
		public var _avatarWinPhrase:String;				// phrase you say on winning
		public var _avatarSpeakDelay:int = 0;				// delay before avatar speaks
		public var _startNPC:String;						// NPC who speaks on winning
		public var _winNPC:String;							// NPC who speaks on winning
		public var _winNPC2:String;						// NPC who speaks on winning
		public var _winNPC3:String;						// NPC who speaks on winning
		public var _startNPCPhrase:String;					// phrase win NPC says on winning
		public var _winNPCPhrase:String;					// phrase win NPC says on winning
		public var _winNPCPhrase2:String;					// phrase win NPC says on winning
		public var _winNPCPhrase3:String;					// phrase win NPC says on winning
		public var _winDelay:int = 0;						// delay when winning before win popup appears to allow time for final dialog
		public var _winNPCAction:String;					// win NPC action to execute
		public var _winNPCForAction:String;				// NPC targeted for action
		public var _winNPCActionParam:String;				// win NPC action param
		public var _winNPCActionDelay:int = 0;				// win NPC action delay time
		public var _NPCSpeakDelay:int;						// delay before win NPC speaks
		public var _StartNPCSpeakDelay:int;				// delay before win NPC speaks
		public var _canRoll:Boolean = false;				// clicking below player in running/biking game will make avatar roll
		public var _jumpSpeed:int = 800;					// vertical jump speed
		public var _jumpAccel:int = Hurdles.JUMP_ACCEL_Y;	// vertical jump acceleration
		public var _multiJump:Boolean = false;				// can stack jumps to go higher
		public var _numOfJumps:Number = 0;					// can set number of jumps in multi-jump mode
		public var _currJump:Number = 0;					// jump counter
		public var _obstacleWrap:int = 0;					// horizontal distance used to calculate row width for obstacles
		public var _obstacleY:int = 0;						// y position for all obstacles (bottoms will be aligned to this)
		public var _obstacleStartY:int = 0;				// y position of first obstacle row
		public var _obstacleSpaceY:int = 0;				// vertical spacing between rows
		public var _startAni:MovieClip;                    // starting animation to play before the game starts
		public var _playerScale:Number = 1;				// player scale
		public var _lineThickness:Number = 0;				// player line thickness
		public var _edgeThreshold:Number = -750;			// edge threshold for when animating objects appear (negative distance to right of avatar)
		public var _runningOffset:Number = 350;			// offset of camera for running game (0 is centered, 350 is at far left)
		public var _lockCameraNPC:Boolean = false;			// lock camera on NPC at end
		public var _choose:Boolean = false;	
		public var _forceWinThreshold:Boolean = false;
		public var _collectionScore:int = 0;
		
		
		private var _shellApi:ShellApi;						// reference to shellApi
		private var _playing:Boolean = true;				// game is currently playing
		private var _player:Entity;							// reference to player
		private var _follower:Entity;						// reference to current follower (can be used for multiple NPCs)
		private var _chaserClipEntity:Entity;				// reference to chasing clip entity (not NPC)
		
		// timer
		private var _textField:TextField;
		private var _time:Number;
		private var _secs:Number;
		private var _triggeredLose:Boolean = false;
		
		// used for endless running/biking/gliding game with HUD
		private var _runningGame:Boolean = false;			// is endless running/biking/gliding game
		private var _playerRunSystem:PlayerRunSystem;		// reference to running player system
		private var _HUD:MovieClip;							// reference to HUD
		private var _ScoreHUD:MovieClip;					// reference to ScoreHUD
		private var _HUDEntity:Entity;						// reference to HUD entity
		private var _groundEffect:MovieClip;				// reference to ground effect (dust)
		private var _groundEffectEntity:Entity;				// reference to ground effect entity
		private var _stationaryEffect:MovieClip;		    // reference to ground effect (dust)
		private var _stationaryEffectEntity:Entity;			// reference to ground effect entity
		private var _groundEffectFade:Boolean = false;		// ground effect
		private var _health:int = _numHits;					// current health value
		private var _currentZone:String = "";				// current active zone (next zone to right of player)
		private var _prevZone:String = "";					// previous active zone
		private var _animatingEntities:Array = [];			// array of entities that animate when they enter the scene
		private var _ouchBubble:Entity;						// reference to ouch bubble
		private var _flash:Entity;							// reference to flash clip
		private var _explosion:Entity;						// reference to explosion (triggered by ShootRay ability)
		private var _rolling:Boolean = false;				// avatar is rolling
		private var _stopPlayer:Boolean = false;		    // avatar is rolling
		private var _animatingPool:Object = {};				// pool of animating obstacles
		private var _threshold:Threshold;                   // win threshold
		private var _resetTimeline:Boolean = false;
		private var _score:int = 0;
	}
}
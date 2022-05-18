package game.scene.template.ads
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.scanHardware;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.MovieClipHit;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.character.TopDownShooter;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.StarShooterSystem.EnemyAi;
	import game.scenes.custom.StarShooterSystem.EnemyPattern;
	import game.scenes.custom.StarShooterSystem.StarShooter;
	import game.scenes.custom.StarShooterSystem.StarShooterSystem;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.custom.questInterior.QuestInterior;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;

	/**
	 * Game template for vertical shooter game which uses bitmapped timelines
	 * There must be at least two background layers "background1" and "background2" at 960x641.
	 * The background tiles don't have to be identical but need to stitch together along the top and bottom edges.
	 * The camera limits and camera bounds should be 640 high.
	 * If not using choose player popup, then game defaults to "player" clip.
	 * Basing obstacles appearances based on time, instead of position to allow more effectively designed flying patterns
	 * Patterns will spawn duplicates of designated types of obstacles and control their movement while the obstacles will dtermine their own behaviours
	 * @author ugilimsc
	 */
	public class StarShooterGame extends AdGameTemplate
	{
		public var backEntity1:Entity;							
		public var backEntity2:Entity;
		public var foreEntity1:Entity;
		public var foreEntity2:Entity;
		public var playerEntity:Entity;
		public var progress:MovieClip;						// progress bar
		public var progressFactor:Number;					// scaling factor for progress bar
		public var progressAlignment:String = "vertical";	// alignment of progress bar
		public var gameTime:uint = 60;						// how long the game goes for before it ends
		public var shooters:Array;							// array of shooters
		public var tileHeight:Number;						// height of background tile
		public var speed:uint = 800;						// roadway speed
		public var playerY:uint = 540;						// Y location of player in scene
		public var starShooter:StarShooter;					// the enemies that can spawn from encounters, the name as the key, and its attributes as an object for the value
		
		private var _maxHits:uint = 5;						// maximum number of hits
		private var _animFrameRate:int = 8;					// default frame rate for animating objects (can override in movieClip labels)
		private var _leftEdgeBounds:int = 0;				// left edge bounds for player movement
		private var _rightEdgeBounds:uint = 960;			// right edge bounds for player movement
		private var _targetPrefix:String;
		private var _hud:MovieClip;							// hud
		private var _hudScoreDisplay:TextField;				// hud score display text
		private var _hudTimeline:Timeline;					// hud timeline
		private var _feedback:Timeline;						// player hit feedback
		private var _choosePopup:String;					// path to choose player popup
		private var _tileTime:Number
		
		public function StarShooterGame()
		{
			this.id = "StarShooterGame";
		}
		
		 /**
		 * Setup game based on xml 
		 * @param group
		 * @param xml
		 * @param hitContainer
		 */
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void
		{
			// remember scene
			super.setupGame(scene,xml,hitContainer);
			addSystems();
			// setup backgrounds and foregrounds
			backEntity1 = createBitmapEntity(_hitContainer["background1"]);
			backEntity2 = createBitmapEntity(_hitContainer["background2"]);
			Spatial(backEntity2.get(Spatial)).y = - tileHeight;
			if (_hitContainer["foreground1"] != null)
			{
				// foregrounds don't use scene bounds
				foreEntity1 = createBitmapEntity(_hitContainer["foreground1"], false);
				foreEntity2 = createBitmapEntity(_hitContainer["foreground2"], false);
				Spatial(foreEntity2.get(Spatial)).y = - tileHeight;
			}
			
			parseEncounterData(scene.getData("encounters.xml"));
			// get scene ui group
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID));
			
			// set up hud
			_hud = _hitContainer["hud"];
			if (_hud != null)
			{
				_hudScoreDisplay = _hud["score"];
				if (_hudScoreDisplay != null)
				{
					_hudScoreDisplay.text = "0";
				}
				// create into timeline and stop on first frame
				var hudEntity:Entity = TimelineUtils.convertClip(_hud, scene);
				_hudTimeline = hudEntity.get(Timeline);
				_hudTimeline.gotoAndStop(0);
				// add to scene ui group so hud won't move around
				sceneUIGroup.groupContainer.addChild(_hud);
				
				// if mobile then delete web text
				if (AppConfig.mobile)
				{
					if (_hud["web"] != null)
						_hud.removeChild(_hud["web"]);
				}
				else
				{
					// else delete mobile text
					if (_hud["mobile"] != null)
						_hud.removeChild(_hud["mobile"]);
				}
			}
			
			// set up progress bar display, if any
			if (_hitContainer["progressClip"] != null)
			{
				// add to scene ui group so progress bar won't move around
				var progressClip:MovieClip = MovieClip(sceneUIGroup.groupContainer.addChild(_hitContainer["progressClip"]));
				starShooter.hud = progressClip["bar"];
				starShooter.alignment = progressAlignment;
			}
			
			var notification:MovieClip = _hitContainer["notification"];
			if(notification)
			{
				if(PlatformUtils.isMobileOS)//remove reminder to hit space bar on mobile
					_hitContainer.removeChild(notification);
				else
					TimelineUtils.convertClip(notification, _scene);
			}
			
			// if choose popup, then load it
			if (_choosePopup != null)
			{
				var selectionPopup:AdChoosePopup = QuestGame(scene).loadChoosePopup() as AdChoosePopup;
				selectionPopup.ready.addOnce(gameSetUp.dispatch);
				selectionPopup.selectionMade.addOnce(QuestGame(scene).playerSelection);
			}
				// else start race right away
			else
			{
				gameSetUp.dispatch(this);
				playerSelection();
			}
		}
		
		private function addSystems():void
		{
			_scene.addSystem(new ThresholdSystem());
			_scene.addSystem(new FollowClipInTimelineSystem());
			_scene.addSystem(new TimelineClipSystem());
			_scene.addSystem(new TimelineControlSystem());
			_scene.addSystem(new BitmapSequenceSystem());
		}
		
		private function parseEncounterData(xml:XML):void
		{
			starShooter = new StarShooter(gameTime);
			var children:XMLList = xml.children();
			for (var i:int = 0; i < children.length(); i++)
			{
				var child:XML = children[i];
				var nodes:XMLList = child.children();
				for(var n:int = 0; n < nodes.length(); n++)
				{
					var node:XML = nodes[n];
					var id:String = DataUtils.getString(node.attribute("id")[0]);
					var clip:MovieClip;
					var time:Number;
					var entity:Entity;
					
					switch(String(child.name()))
					{
						case "enemies":
						{
							var enemyAi:EnemyAi = new EnemyAi(node);
							starShooter.poolObject(id+"ai", enemyAi);
							break;
						}
							
						case "patterns":
						{
							time = DataUtils.getNumber(node.attribute("time")[0]);
							entity = _scene.getEntityById(id);
							if(entity)
							{
								starShooter.encounters[time] = entity;
								continue;
							}
							
							clip = _hitContainer[id];
							entity = EntityUtils.createSpatialEntity(_scene, clip);
							TimelineUtils.convertClip(clip, _scene, entity, null, false);
							var pattern:EnemyPattern = new EnemyPattern();
							pattern.cleared.add(updateScore);
							entity.add(pattern).add(new Id(id)).add(new Children());
							var timeline:Timeline = entity.get(Timeline);
							timeline.handleLabel("reverse", Command.create(reverseTimeline, timeline), false);
							timeline.handleLabel("reverseCheck", Command.create(reverseCheck, timeline), false);
							starShooter.encounters[time] = entity;
							break;
						}
							
						case "messages":
						{
							time = DataUtils.getNumber(node.attribute("time")[0]);
							entity = _scene.getEntityById(id);
							if(entity)
							{
								starShooter.encounters[time] = entity;
								continue;
							}
							clip = _hitContainer[id];
							entity = EntityUtils.createSpatialEntity(_scene, clip);
							TimelineUtils.convertClip(clip, _scene, entity);
							entity.remove(Sleep);
							starShooter.encounters[time] = entity;
							break;
						}
					}
				}
			}
		}
		
		public function updateScore(points:Number):void
		{
			starShooter.score += points;
			_hudScoreDisplay.text = "" + starShooter.score;
		}
		
		private function reverseCheck(timeline:Timeline):void
		{
			if(timeline.reverse)
			{
				timeline.gotoAndStop(0);
				timeline.reverse = false;
			}
		}
		
		private function reverseTimeline(timeline:Timeline):void
		{
			timeline.reverse = true;
		}
		
		private function tile(entity:Entity):void
		{
			var spatial:Spatial = entity.get(Spatial);
			var target:Spatial;
			switch(entity)
			{
				case backEntity1:
				{
					target = backEntity2.get(Spatial);
					break;
				}
				case backEntity2:
				{
					target = backEntity1.get(Spatial);
					break;
				}
				case foreEntity1:
				{
					target = foreEntity2.get(Spatial);
					break;
				}
				case foreEntity2:
				{
					target = foreEntity1.get(Spatial);
					break;
				}
			}
			// unfortunately tiliing is too unpredictable to handle dynamically
			// apparently a lot of gap can be generated so we need intentional overlap
			spatial.y = target.y - target.height + 20;
		}
		
		// create bitmap of background or foreground layers
		private function createBitmapEntity(layer:DisplayObject, useSceneBounds:Boolean = true):Entity
		{
			var bounds:Rectangle;
			if (useSceneBounds)
				bounds = new Rectangle(0, 0, _scene.sceneData.cameraLimits.width, layer.height);
			var sprite:Sprite = createBitmapSprite(layer, 1, bounds);
			var entity:Entity = EntityUtils.createMovingEntity(_scene, sprite);
			var motion:Motion = entity.get(Motion);
			motion.velocity = new Point(0, speed);
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = tileHeight;
			threshold.entered.add(Command.create(tile, entity));
			entity.add(threshold);
			return entity;
		}
		
		override protected function parseXML(xml:XML):void
		{
			// note: returnX and returnY are pulled from QuestGame.as
			
			// set tile height (usually one less then actual height)
			tileHeight = uint(xml.tileHeight);
			
			// get choose screen
			if (String(xml.choosePopup) != "")
				_choosePopup = String(xml.choosePopup);
			
			// get roadway speed
			if (String(xml.speed) != "")
				speed = uint(xml.speed);
			
			_tileTime = tileHeight / speed;
			
			// get target distance
			if (String(xml.gameTime) != "")
				gameTime = uint(xml.gameTime);
			
			// progress bar alignment ("vertical" - default or "horizontal")
			if (String(xml.progressAlignment) != "")
				progressAlignment = String(xml.progressAlignment);
			
			// number of obstacle hits before you lose
			if (String(xml.maxHits) != "")
				_maxHits = uint(xml.maxHits);
			
			// get frame rate for animating objects
			if (String(xml.animFrameRate) != "")
				_animFrameRate = uint(xml.animFrameRate);
			
			// get left bounds for player movement
			if (String(xml.leftEdgeBounds) != "")
				_leftEdgeBounds = int(xml.leftEdgeBounds);
			
			// get right bounds for player movement (added to left bounds to get final bounds)
			if (String(xml.rightEdgeBounds) != "")
				_rightEdgeBounds = uint(xml.rightEdgeBounds);
			
			if(xml.hasOwnProperty("shooters"))
			{
				_scene.addSystem(new SpecialAbilityControlSystem());
				
				shooters = [];
				
				var shooterXml:XML = xml.child("shooters")[0];
				
				for(var i:int = 0; i < shooterXml.children().length(); i++)
				{
					var shooterAbility:SpecialAbilityData = new SpecialAbilityData();
					shooterAbility.parse(shooterXml.children()[i]);
					//trace(shooterAbility.specialClass);
					_targetPrefix = shooterAbility.params.byId("targetPrefix");
					if(DataUtils.validString(_targetPrefix))
					{
						if(_scene.getSystem(MovieClipHitSystem) == null)
							_scene.addSystem(new MovieClipHitSystem());
						
						if(_scene.getSystem(HitTestSystem) == null)
							_scene.addSystem(new HitTestSystem());
					}
					
					shooters.push(shooterAbility);
				}
			}
		}
		
		override public function playerSelection(selection:int = 0):void
		{
			trace("select player " + selection);
			//if(_scene.shellApi.screenManager.appScale)
			//_scene.container.scaleX = _scene.container.scaleY = _scene.shellApi.screenManager.appScale;
			//if(!PlatformUtils.isMobileOS)
			//_scene.resize(_scene.shellApi.screenManager.deviceSize.width,_scene.shellApi.screenManager.deviceSize.height);
			if(selection == -1)
			{
				_scene.shellApi.loadScene(QuestInterior, _returnX, _returnY);
				return;
			}
			// get player clip, use "player" if no selection from choose popup
			var clip:MovieClip;
			if (selection == 0)
				clip = _hitContainer["player"];
			else
				clip = _hitContainer["player" + selection];
			
			// look for hit clip
			if (clip["hit"] == null)
				trace("player is missing hit clip: " + clip.name);
			else
			{
				// remember hit clip
				var playerHit:MovieClip = clip["hit"];
				clip.y = _scene.shellApi.viewportHeight - 50;
				///*
				if(PlatformUtils.isMobileOS)
				{
					trace("before: " + clip.y);
					var aspectRatio:Number = _scene.shellApi.screenManager.deviceSize.width / _scene.shellApi.screenManager.deviceSize.height;
					if(aspectRatio > 1.5)
					{
						clip.y = _scene.shellApi.viewportHeight / (aspectRatio/1.5) - 50;//(1.5) is aspect ratio for 960X640
					}
					
					trace("after: " + clip.y);
					trace("Device height: " + _scene.shellApi.screenManager.deviceSize.height + " viewport height: " + _scene.shellApi.viewportHeight);
					trace("Device width: " + _scene.shellApi.screenManager.deviceSize.width + " viewport width: " + _scene.shellApi.viewportWidth);
					trace("Device scale: " + _scene.shellApi.screenManager.appScale + " viewport scale: " + _scene.shellApi.viewportScale);
				}
				//*/
				playerY = clip.y;
				clip.x = 480;
				playerHit.visible = false;
				
				// create entity for player
				playerEntity = EntityUtils.createSpatialEntity(_scene, clip, _hitContainer);
				if(shooters != null)
				{
					var shooterAbility:SpecialAbilityData;
					if(selection <= 0 || selection > shooters.length)
						shooterAbility = shooters[0];
					else
						shooterAbility = shooters[selection-1];
					if(shooterAbility != null)
					{
						playerEntity.add(new Player());
						InteractionCreator.addToEntity(playerEntity, [InteractionCreator.KEY_DOWN, InteractionCreator.KEY_UP]);
						CharUtils.addSpecialAbility(playerEntity, shooterAbility,true);
					}
				}
				
				// convert clip and stop at first frame if timeline
				var animClip:MovieClip = clip["anim"];
				if (animClip != null)
				{
					// check for idle loop
					var isIdle:Boolean = checkForIdle(animClip);
					
					// create bitmap timeline and add to scene
					var bmEntity:Entity = BitmapTimelineCreator.createBitmapTimeline(animClip, true, true, null, PerformanceUtils.defaultBitmapQuality, _animFrameRate);
					_scene.addEntity(bmEntity);
					
					// get timeline and add to player
					var timeline:Timeline = bmEntity.get(Timeline);
					playerEntity.add(timeline);
					
					if (isIdle)
						timeline.gotoAndPlay("idle");
					else
						timeline.gotoAndStop(0);
					_feedback = timeline;
				}
				var hit:MovieClipHit = new MovieClipHit();
				hit.hitDisplay = playerHit;
				playerEntity.add(starShooter).add(hit).add(new Id("player"))
					.add(new EntityIdList()).add(new HitTest(playerHitCheck));
				
				starShooter.done.add(winGame);
				
				_scene.addSystem(new StarShooterSystem(playerEntity));
				// enable player control
				setPlayerControl(true);				
			}
			super.playerSelected();
		}
		
		private function playerHitCheck(bullet:Entity, hitId:String):void
		{
			if(!starShooter.playing)
				return;
			trace(hitId);
			starShooter.hits++;
			_hudTimeline.gotoAndStop(starShooter.hits);
			if(_feedback)
			{
				_feedback.gotoAndPlay("hit");
			}
			// only == so it doesn't spam the lose screen
			if(starShooter.hits == _maxHits)
			{
				loseGame();
			}
		}
		
		private function checkForIdle(clip:MovieClip):Boolean
		{
			for each (var label:FrameLabel in clip.currentLabels)
			{
				if (label.name == "idle")
				{
					trace(clip.parent.name + " is a looping animation");
					return true;
				}
			}
			return false;
		}
		
		public function winGame():void
		{
			if(starShooter.playing)
			{
				endGame();
				QuestGame(_scene).loadWinPopup(starShooter.score);
			}
		}
		
		public function loseGame():void
		{
			if(starShooter.playing)
			{
				starShooter.playing = false;
				SceneUtil.delay(_scene, 0.5, delayLoss);
			}
		}
		
		private function delayLoss():void
		{
			endGame();
			QuestGame(_scene).loadLosePopup( false,starShooter.score);
		}
		
		private function endGame():void
		{
			var specialControl:SpecialAbilityControl = playerEntity.get( SpecialAbilityControl ) as SpecialAbilityControl;
			
			if(specialControl != null)
			{
				CharUtils.removeSpecialAbilityByClass(playerEntity, TopDownShooter);
				playerEntity.remove(Interaction);
				playerEntity.remove(Player);
			}
			
			setPlayerControl(false);
			
			if (playerEntity)
				playerEntity.get(Spatial).y = 10000;
			
			starShooter.destroy();
			
			AdUtils.setScore(_scene.shellApi,starShooter.score,"starshooter");
		}
		
		public function setPlayerControl(state:Boolean = true):void
		{
			// if turning on
			if (state)
			{
				// setup player to follow input in horizontal direction
				var inputSpatial:Spatial = _scene.shellApi.inputEntity.get( Spatial );
				var followTarget:FollowTarget 		= new FollowTarget( inputSpatial, .05 );
				followTarget.properties			 	= new <String>["x"];
				followTarget.allowXFlip 			= true;
				playerEntity.add(followTarget);
				
				// set bounds for movement
				playerEntity.add(new MotionBounds(new Rectangle(_leftEdgeBounds, 0, _rightEdgeBounds, tileHeight)));
			}
				// if turning off
			else
			{
				playerEntity.remove(FollowTarget);
			}
			starShooter.playing = state;
		}
	}
}
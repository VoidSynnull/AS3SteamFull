package game.scene.template.ads
{
	import com.greensock.easing.Elastic;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.entity.collider.RaceCollider;
	import game.components.hit.MovieClipHit;
	import game.components.motion.FollowTarget;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.character.TopDownShooter;
	import game.scene.template.AudioGroup;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.TopDownBitmapGameSystem;
	import game.scenes.custom.StarShooterSystem.EnemyAi;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.custom.questInterior.QuestInterior;
	import game.systems.SystemPriorities;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.specialAbility.SpecialAbilityControlSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	// to do: also convert static objects such as finish line
	
	/**
	 * Game template for top down race game which uses bitmapped timelines
	 * There must be at least two background layers "background1" and "background2" at 960x641.
	 * The background tiles don't have to be identical but need to stitch together along the top and bottom edges.
	 * The camera limits and camera bounds should be 640 high.
	 * If not using choose player popup, then game defaults to "player" clip.
	 * Collision objects instance names need to end with an integer
	 * The collision object positions in obstacles.xml are based on movieClip centers.
	 * The zero position for collision objects is at the top of the screen, but when placed, they are shifted up beyond the top edge.
	 * Only one collision object can be on the screen at one time since we reuse the same object (make copies if need more)
	 * Only one powerup boost object can be on the screen at one time because the code only allows for one set of boost params at one time.
	 * @author uhockri
	 */
	public class TopDownBitmapGame extends AdGameTemplate
	{
		// backgrounds and foregrounds and roadway
		public var backEntity1:Entity;							
		public var backEntity2:Entity;
		public var foreEntity1:Entity;
		public var foreEntity2:Entity;
		public var roadEntity:Entity;
		
		public var playing:Boolean = false;					// playing flag
		public var playerEntity:Entity;						// player entity
		public var playerHit:MovieClip;						// player hit clip
		public var playerTopY:Number;						// top of player hit clip
		public var playerHalfWidth:Number;					// half width of player hit clip
		public var startTileY:Number;						// starting Y position of background
		public var progress:MovieClip;						// progress bar
		public var progressFactor:Number;					// scaling factor for progress bar
		public var holder:Sprite;							// obstacles holder
		public var boostTimeline:Timeline					// boost timeline
		public var obstacles:Dictionary;					// obstacles dict
		public var obstacleData:Array = [];					// array of obstacles in scene
		public var shooters:Array;							// array of shooters
		
		// private vars
		private var _hud:MovieClip;							// hud
		private var _hudScoreDisplay:TextField;				// hud score display text
		private var _hudTimeline:Timeline;					// hud timeline
		private var _hits:Number = 0;						// current number of hits
		private var _raceSystem:TopDownBitmapGameSystem;	// reference to TopDownBitmapGameSystem
		private var _multiples:Object = {};					// for multiple items
		private var _indexes:Object = {};					// index used for multiple items
		private var _points:Number = 0;						// game points
		
		// from xml (public vars are refernced by TopDownRaceGameSystem)
		public var tileHeight:Number;						// height of background tile
		private var _choosePopup:String;					// path to choose player popup
		public var speed:uint = 800;						// roadway speed
		public var targetDistance:uint = 20000;				// target distance for game (in pixels)
		private var _maxHits:uint = 5;						// maximum number of hits
		public var playerY:uint = 540;						// Y location of player in scene
		private var _animFrameRate:int = 8;					// default frame rate for animating objects (can override in movieClip labels)
		private var _boostFrameRate:int = 32;				// frame rate for car timeline
		public var sideSpeed:uint = 400;					// side speed for collision objects
		private var _hitRotation:int = 20;					// angle of rotation when crashing into obstacle
		private var _hitRotationTime:Number = 1.0;			// time of rotation tween when crashint into obstacle
		private var _leftEdgeBounds:int = 0;				// left edge bounds for player movement
		private var _rightEdgeBounds:uint = 960;			// right edge bounds for player movement
		private var _targetPrefix:String;
		public var progressAlignment:String = "vertical";	// alignment of progress bar
		private var _pointsForCrashing:Boolean = false;		// points for crashing into object
		
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		/**
		 * Constructor 
		 */
		public function TopDownBitmapGame()
		{
			this.id = "TopDownBitmapGame";
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
			
			_scene.addSystem(new TimelineControlSystem());
			_scene.addSystem(new TimelineClipSystem());
			_scene.addSystem(new TimelineVariableSystem());
			
			// setup backgrounds and foregrounds
			backEntity1 = createBitmapEntity(_hitContainer["background1"]);
			backEntity2 = createBitmapEntity(_hitContainer["background2"]);
			if (_hitContainer["foreground1"] != null)
			{
				// foregrounds don't use scene bounds
				foreEntity1 = createBitmapEntity(_hitContainer["foreground1"], false);
				foreEntity2 = createBitmapEntity(_hitContainer["foreground2"], false);
			}
			startTileY = backEntity1.get(Spatial).y;
			
			// create holder entity for obstacles (zero is at top of screen)
			holder = _hitContainer["holder"];
			holder.x = 0;
			holder.y = 0;
			roadEntity = EntityUtils.createSpatialEntity(scene, holder);
			
			// parse obstacles xml (get names and positions of obstacles from this file)
			parseObstaclesData(scene.getData("obstacles.xml"));
			
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
				progress = progressClip["bar"];
				if (progressAlignment == "vertical")
					progressFactor = progress.height / targetDistance;
				else
					progressFactor = progress.width / targetDistance;
			}
			
			var notification:MovieClip = _hitContainer["notification"];
			if(notification)
			{
				if(PlatformUtils.isMobileOS)//remove reminder to hit space bar on mobile
					_hitContainer.removeChild(notification);
				else
					TimelineUtils.convertClip(notification, _scene);
			}
			
			// initialize race system
			_raceSystem = TopDownBitmapGameSystem(scene.addSystem( new TopDownBitmapGameSystem(this), SystemPriorities.update ));				
			
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
		
		// create bitmap of background or foreground layers
		private function createBitmapEntity(layer:DisplayObject, useSceneBounds:Boolean = true):Entity
		{
			var bounds:Rectangle;
			if (useSceneBounds)
				bounds = new Rectangle(0, 0, _scene.sceneData.cameraLimits.width, layer.height);
			var sprite:Sprite = BitmapUtils.createBitmapSprite(layer, 1, bounds);
			sprite = Sprite(_hitContainer.addChildAt(sprite, 0));
			var entity:Entity = EntityUtils.createSpatialEntity(_scene, sprite);
			_hitContainer.removeChild(layer);
			return entity;
		}
		
		/**
		 * Parse game xml for game parameters
		 * @param xml
		 */
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
			
			// get target distance
			if (String(xml.targetDistance) != "")
				targetDistance = uint(xml.targetDistance);
			
			// progress bar alignment ("vertical" - default or "horizontal")
			if (String(xml.progressAlignment) != "")
				progressAlignment = String(xml.progressAlignment);
			
			// number of obstacle hits before you lose
			if (String(xml.maxHits) != "")
				_maxHits = uint(xml.maxHits);
			
			// get Y location of player in scene
			if (String(xml.playerY) != "")
				playerY = uint(xml.playerY);
			
			// get frame rate for animating objects
			if (String(xml.animFrameRate) != "")
				_animFrameRate = uint(xml.animFrameRate);
			
			// get frame rate for boost animation
			if (String(xml.boostFrameRate) != "")
				_boostFrameRate = uint(xml.boostFrameRate);
			
			// get points for crashing
			if (String(xml.pointsForCrashing) != "")
				_pointsForCrashing = DataUtils.getBoolean(xml.pointsForCrashing);
			
			// get side speed for obstacles
			if (String(xml.sideSpeed) != "")
				sideSpeed = uint(xml.sideSpeed);
			
			// get hit rotation for player
			if (String(xml.hitRotation) != "")
				_hitRotation = uint(xml.hitRotation);		
			
			// get hit rotation time for player
			if (String(xml.hitRotationTime) != "")
				_hitRotationTime = uint(xml.hitRotationTime);
			
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
		
		/**
		 * Parse obstacles xml for game obstacles and positions
		 * @param xml
		 */
		private function parseObstaclesData(xml:XML):void
		{
			// init obstacles dictionary
			obstacles = new Dictionary();
			
			// for each child in xml
			var children:XMLList = xml.children();
			for (var i:int = 0; i != children.length(); i++)
			{
				var child:XML = children[i];
				// get attributes of enclosing group node
				var groupDataObject:Object = getAttributesData(child);
				
				// if sub children, then iterate through grouped nodes
				// ALL obstacle entities are grouped in xml
				var subChildren:XMLList = child.children();
				var numChildren:int = subChildren.length();
				if (numChildren != 0)
				{
					// set multiples to number of children for obstacle
					_multiples[groupDataObject["baseName"]] = numChildren;
					// start index at zero
					_indexes[groupDataObject["baseName"]] = 0;
					
					// process sub children
					for (var j:int = 0; j!=numChildren; j++)
					{
						processNode(subChildren[j], groupDataObject);
					}
				}
					// if no children, process single node
					// ALL position nodes are NOT grouped
				else
				{
					processNode(child);
				}
			}
			// sort obstacleData by y
			obstacleData.sortOn(["y"], [Array.NUMERIC]);
		}
		
		/**
		 * Process node
		 * @param child
		 * @param groupDataObject
		 */
		private function processNode(child:XML, groupDataObject:Object = null):void
		{
			// get data object made from node attributes
			var dataObject:Object = getAttributesData(child, groupDataObject);
			
			// check node name: either item or position
			switch (String(child.name()))
			{
				// item node is for obstacle entity
				case "item":
					
					// if x provided, then create position data objects for length of roadway
					// assumes there are also startY and spacingY attributes
					if (dataObject["x"] != null)
					{
						// get values
						var x:int = int(dataObject["x"]);
						var startY:int = int(dataObject["startY"]);
						var spacingY:int = int(dataObject["spacingY"]);
						
						// loop until reach end of roadway
						while (true)
						{
							// create position object with name, x, and y
							var posObject:Object = {};
							posObject.name = dataObject["name"];
							posObject.x = x;
							posObject.y = startY;
							posObject.points = DataUtils.getNumber(dataObject["points"]);
							// add to obstacle data array
							obstacleData.push(posObject);
							// increment Y
							startY += spacingY;
							// break when reach target distance
							if (startY >= targetDistance)
								break;
						}
					}
					
					// create obstacle entity
					setupObstacleEntity(dataObject);
					break;
				
				// position node
				case "position":
					
					// get name of entity
					var name:String = dataObject["name"];
					
					// if name doesn't end with number, then add number using looping index
					if (isNaN(Number(name.substr(name.length - 1))))
					{
						var newName:String = name + (_indexes[name] + 1);
						_indexes[name] = (_indexes[name] + 1) % _multiples[name];
						dataObject["name"] = newName;
					}
					
					// add to obstacle data array
					obstacleData.push(dataObject);
					break;
			}
		}
		
		/**
		 * Convert XML attributes to data object
		 * @param child
		 * @param groupDataObject
		 * @return data object
		 */
		private function getAttributesData(child:XML, groupDataObject:Object = null):Object
		{
			// init empty object
			var	dataObject:Object = {};
			
			// if group data object is not null, then pull those properties into data object
			if (groupDataObject != null)
			{
				// copy group data object properties
				for (var prop:String in groupDataObject)
				{
					dataObject[prop] = groupDataObject[prop];
				}
			}
			
			// get attributes
			var attributes:XMLList = child.attributes();
			// for each attribute, add to data object
			for (var i:int = 0; i != attributes.length(); i++)
			{
				var attribute:XML = attributes[i];
				var nodeName:String = attribute.name();
				// if not number, then get string
				if (isNaN(Number(attribute)))
					dataObject[nodeName] = String(attribute);
				else
					dataObject[nodeName] = Number(attribute);
			}
			return dataObject;
		}
		
		/**
		 * Setup and create obstacle entity
		 * @param dataObject
		 */
		private function setupObstacleEntity(dataObject:Object):void
		{			
			// get obstacle name
			var name:String = dataObject["name"];
			
			// make sure name ends with number
			if (isNaN(Number(name.substr(name.length - 1))))
			{
				trace("----------------ERROR: obstacle name '" + name + "'` needs to end with an integer!");
				return;
			}
			
			// get clip in FLA that matches name
			var clip:MovieClip = holder[name];
			if (clip == null)
			{
				trace("----------------ERROR: obstacle name '" + name + "'` does not have clip in scene!");
				return;
			}
			
			// setup race collider component
			var collider:RaceCollider = new RaceCollider();
			
			// set hit clip if exists
			if (clip["hit"] != null)
			{
				var hitClip:MovieClip  = clip["hit"];
				hitClip.visible = false;
				collider.hitClip = hitClip;
				collider.halfHeight = hitClip.height/2;
				collider.halfWidth = hitClip.width/2;
			}
				// if no hit clip then use clip itself
			else
			{
				collider.halfHeight = clip.height/2;
				collider.halfWidth = clip.width/2;
			}
			
			// move clip offscreen
			clip.x = 10000;
			clip.y = 10000;
			
			// attach points
			collider.points = dataObject["points"];
						
			var type:String = dataObject["type"];
			
			collider.hp = dataObject["hp"];
			
			// move to back if static, powerup or slick
			switch(type)
			{
				case RaceCollider.STATIC:
				case RaceCollider.BOOST:
				case RaceCollider.SLICK:
					clip.parent.setChildIndex(clip, 0);
					break;
			}
			
			var frameRate:int = _animFrameRate;
			var overrideFrameRate:Number = Number(clip.currentLabel);
			if (overrideFrameRate != 0)
				frameRate = int(overrideFrameRate);
			
			trace(clip.name + " frame rate: " + frameRate);
			
			// create entity for obstacle
			var entity:Entity = EntityUtils.createMovingEntity(_scene, clip, holder);

			//var clipEntity:Entity = convertClipx(clip, _scene, entity, roadEntity, false, frameRate);
			if(_scene.getSystem(TimelineVariableSystem) == null)
				_scene.addSystem(new TimelineVariableSystem());
			
			// look for embedded anim clip and convert to bitmap
			var animClip:MovieClip = clip["anim"];
			if (animClip != null)
			{
				// check if idle loop and pass to collider
				var isIdle:Boolean = checkForIdle(animClip);
				collider.looping = isIdle;
				
				// create bitmap timeline and add to scene
				var bmEntity:Entity = BitmapTimelineCreator.createBitmapTimeline(animClip, true, true, null, PerformanceUtils.defaultBitmapQuality, frameRate);
				_scene.addEntity(bmEntity);
				
				// get timeline and add to entity
				var timeline:Timeline = bmEntity.get(Timeline);
				entity.add(timeline);
				
				// if idle loop
				if (isIdle)
					timeline.gotoAndPlay("idle");
				else
					timeline.gotoAndStop(0);
				timeline.labelReached.add(Command.create(checkAnimLabel, timeline));
			}
			
			// iterate through object properties
			for (var prop:String in dataObject)
			{
				// if collider has matching property, then set
				if (collider.hasOwnProperty(prop))
				{
					collider[prop] = dataObject[prop];
					//trace("setting property " + prop + " with value " + dataObject[prop]);
				}
			}
			if(collider.hp != 0)
			{
				var enemyAI:EnemyAi = new EnemyAi();
				enemyAI.health = collider.hp;
				entity.add(enemyAI);
			}
			entity.add(collider);
			
			if(DataUtils.validString(_targetPrefix))
			{
				entity.add(new MovieClipHit()).add(new Id(name));
			}
			entity.add(new Sleep(false, true));
			
			// hide entity until needed
			entity.get(Display).visible = false;
			
			// add hit audio from sounds.xml
			var audioGroup:AudioGroup = _scene.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			audioGroup.addAudioToEntity(entity, name + "Hit");
			
			// add entity to obstacles dictionary
			obstacles[name] = entity;
		}
		
		// check animation label (for idle loops)
		private function checkAnimLabel(label:String, timeline:Timeline):void
		{
			switch (label)
			{
				case "idleEnd":
				case "leftEndIdle":
				case "rightEndIdle":
					timeline.gotoAndPlay("idle");
					break;
				case "leftEnd":
				case "rightEnd":
				case "animEnd":
					timeline.gotoAndStop(0);
					break;
			}
		}
		
		/**
		 * Setup player based on selection from AdChoosePopup
		 * @param selection player selection (starts at 1, if zero, then use "player")
		 */
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
				playerHit = clip["hit"];
				
				// move player clip into place (center horizontally)
				clip.y = _scene.shellApi.viewportHeight - 100;
				if(PlatformUtils.isMobileOS)
				{
					clip.y = _scene.shellApi.screenManager.deviceSize.height - 640;
					trace("Device height: " + _scene.shellApi.screenManager.deviceSize.height + "viewport height: " + _scene.shellApi.viewportHeight);
				}
				playerY = clip.y;
				clip.x = 480;
				playerHit.visible = false;
				
				// hide powerup boost
				var boostClip:MovieClip = clip["boost"];
				if (boostClip != null)
				{
					trace("boost frame rate: " + _boostFrameRate);

					// create bitmap timeline and add to scene
					var bmEntity:Entity = BitmapTimelineCreator.createBitmapTimeline(boostClip, true, true, null, PerformanceUtils.defaultBitmapQuality, _boostFrameRate);
					_scene.addEntity(bmEntity);
					
					// save timeline and go to end frame where there is no art
					boostTimeline = bmEntity.get(Timeline);
					boostTimeline.gotoAndStop("boostEnd");
				}
				
				// get top of player and halfwidth of hit clip
				playerTopY = playerY - playerHit.height/2;
				playerHalfWidth = playerHit.width/2;
				
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
					bmEntity = BitmapTimelineCreator.createBitmapTimeline(animClip, true, true, null, PerformanceUtils.defaultBitmapQuality, _animFrameRate);
					_scene.addEntity(bmEntity);
					
					// get timeline and add to player
					var timeline:Timeline = bmEntity.get(Timeline);
					playerEntity.add(timeline);
					
					if (isIdle)
						timeline.gotoAndPlay("idle");
					else
						timeline.gotoAndStop(0);
					timeline.labelReached.add(Command.create(checkAnimLabel, timeline));
				}
				
				// enable player control
				setPlayerControl(true);
				
				// start game and race
				playing = true;
				_raceSystem.startRace();				
			}
			super.playerSelected();
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
		
		// GAME FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		/**
		 * Enable or disable player control
		 * @param state
		 */
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
		}
		
		/**
		 * When player hits obstacle
		 * @param playerAtRight
		 * @param colliderType
		 */
		public function gotHit(playerAtRight:Boolean, colliderType:String):void
		{
			if (playing)
			{
				// crash animation
				crashAnim(playerEntity, playerAtRight, true);
				
				//increment hits if not crashing collider
				if (colliderType == RaceCollider.CRASHING)
					return;
				
				_hits++;
				
				// load game if reach max hits
				if (_hits <= _maxHits)
				{
					// update to next frame in hud
					if (_hudTimeline)
						_hudTimeline.gotoAndStop(_hits);
					// if reach max, then lose (do this only once!)
					if (_hits == _maxHits)
						loseGame();
				}
			}
		}
		
		/**
		 * When player gets points
		 * @param newPoints
		 * @param colliderType
		 */
		public function gotPoints(newPoints:Number, colliderType:String = RaceCollider.OBSTACLE):void
		{
			if ((newPoints != 0) && (playing))
			{
				// suppress points if not allow points for crashing
				if ((!_pointsForCrashing) && (colliderType == RaceCollider.CRASHING))
					return;
				
				_points += newPoints;
				
				if (_hudScoreDisplay != null)
					_hudScoreDisplay.text = String(_points);
			}
		}
		
		/**
		 * Crash animation with an elastic tween and timeline animation (player or other cars)
		 * @param entity
		 * @param away direction of animation (left or right)
		 */
		public function crashAnim(entity:Entity, away:Boolean, rotate:Boolean = false):void
		{
			// if timeline, then play left or right animation
			if (entity.has(Timeline))
			{
				if (away)
				{
					entity.get(Timeline).gotoAndPlay("left");
				}
				else
				{
					entity.get(Timeline).gotoAndPlay("right");
				}
			}
			
			if (rotate)
			{
				// rotate also with elastic tween
				var rotation:int = _hitRotation;
				if (!away)
					rotation = -rotation;
				entity.get(Spatial).rotation = rotation;
				TweenUtils.entityTo(entity, Spatial, _hitRotationTime, {rotation:0, ease:Elastic.easeOut});
			}
		}
		
		/**
		 * When game ends 
		 */
		private function endGame():void
		{
			playing = false
				
			var specialControl:SpecialAbilityControl = playerEntity.get( SpecialAbilityControl ) as SpecialAbilityControl;
			
			if(specialControl != null)
			{
				CharUtils.removeSpecialAbilityByClass(playerEntity, TopDownShooter);
				playerEntity.remove(Interaction);
				playerEntity.remove(Player);
			}
			
			// remove system
			_scene.removeSystemByClass(TopDownBitmapGameSystem);
			
			// turn off control
			setPlayerControl(false);
			
			// move non-player entity off screen
			if (playerEntity)
				playerEntity.get(Spatial).y = 10000;
		}
		
		/**
		 * When lose game 
		 */
		private function loseGame():void
		{
			if (playing)
			{
				// add delay so can see last crash
				SceneUtil.delay(_scene, 0.5, finalLoseGame);
			}
		}
		
		/**
		 * When lose game after delay
		 */
		public function finalLoseGame():void
		{
			playing = false;
			endGame();
			// show lose popup
			QuestGame(_scene).loadLosePopup();
		}
		
		/**
		 * When win game 
		 */
		public function winGame():void
		{
			if (playing)
			{
				endGame();
				// load win popup
				QuestGame(_scene).loadWinPopup(_points);
			}
		}
	}
}
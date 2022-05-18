package game.scene.template.ads
{

	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Screen;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	
	import game.components.entity.character.Player;
	import game.components.motion.FollowTarget;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.specialAbility.character.TopDownShooter;
	import game.managers.ScreenManager;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.AdChoosePopup;
	import game.scenes.custom.TopDownBitmapGameSystem;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.custom.questInterior.QuestInterior;
	import game.scenes.examples.bounceMaster.BounceMasterGroup;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	
	public class BotBreakerGame extends AdGameTemplate
	{
		
		// private vars
		public var hud:MovieClip;							// hud
		private var _hudScoreDisplay:TextField;				// hud score display text
		private var _hudTimeline:Timeline;					// hud timeline
		private var _hits:Number = 0;						// current number of hits
		private var _choosePopup:String;					// path to choose player popup
		private var _bounds:Point;
		//sounds
		public var brickSound:String;
		public var bounceSound:String;
		public var loseSound:String;
		public var gameOverSound:String;
		
		public var playerHit:MovieClip;						// player hit clip
		public var playerEntity:Entity;						// player entity
		public var ball:MovieClip;
		public var _playerClip:MovieClip;
		
		public var speed:uint = 800;						// speed
		public var playing:Boolean = false;					// playing flag
		public var points:Number = 0;						// game points
		public var basicBrickPoints:Number = 10;
		public var bounceFactor:Number = 5;
		public var multiplierTime:Number = 10;               //how long the multipler lasts (seconds)
		public var multiplierPowerChance:Number = 25;		//% chance of power spawning
		public var movePlayerAmount:Number = 0;
		private var _playerSpeed:Number = 2;				//used for mobile moving
		public var _popupScene:Boolean;
		private var _clip:MovieClip;
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		/**
		 * Constructor 
		 */
		public function BotBreakerGame()
		{
			this.id = "BotBreaker";
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
			
			// get scene ui group
			var sceneUIGroup:SceneUIGroup = SceneUIGroup(scene.groupManager.getGroupById(SceneUIGroup.GROUP_ID));
			
			// set up hud
			hud = _hitContainer["hud"];
			if (hud != null)
			{
				_hudScoreDisplay = hud["score"];
				if (_hudScoreDisplay != null)
				{
					_hudScoreDisplay.text = "0";
				}
				// create into timeline and stop on first frame
				var hudEntity:Entity = TimelineUtils.convertClip(hud, scene);
				_hudTimeline = hudEntity.get(Timeline);
				_hudTimeline.gotoAndStop(0);
				// add to scene ui group so hud won't move around
				sceneUIGroup.groupContainer.addChild(hud);
				
				// if mobile then delete web text
				if (AppConfig.mobile)
				{
					if (hud["web"] != null)
						hud.removeChild(hud["web"]);
					
				}
				else
				{
					// else delete mobile text
					if (hud["mobile"] != null)
						hud.removeChild(hud["mobile"]);
					
				}
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
		private function movePlayer(button:Entity, dir:Number):void
		{
			movePlayerAmount = (_playerSpeed * dir);
		}
		private function stopPlayer(button:Entity):void
		{
			movePlayerAmount = 0;
		}
		protected function setupButton(button:MovieClip, action:Function, hide:Boolean = true, interactionType:String = InteractionCreator.CLICK):Entity
		{
			// if no button then error
			if (button == null)
				trace("null button");
			else
			{
				// if button found
				// force button to vanish (it flashes otherwise)
				if (hide)
					button.alpha = 0;
				
				//create button entity
				var buttonEntity:Entity = new Entity();
				buttonEntity.add(new Spatial(button.x, button.y));
				buttonEntity.add(new Display(button));
				buttonEntity.add(new Id(button.name));
				if (hide)
					buttonEntity.get(Display).alpha = 0;
				
				// add entity to group
				_scene.addEntity(buttonEntity);
				
				// add tooltip
				ToolTipCreator.addToEntity(buttonEntity);
				
				// add interaction
				var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [interactionType, InteractionCreator.UP, InteractionCreator.TOUCH], button);
				if (interactionType == InteractionCreator.CLICK)
					interaction.click.add(action);
				else if (interactionType == InteractionCreator.DOWN)
				{
					interaction.down.add(action);
					
				}
				
				interaction.up.add(stopPlayer);
				
				// if multiple frames
				if (button.totalFrames != 1)
				{
					button.gotoAndStop(1);
					TimelineUtils.convertClip(button, this, buttonEntity, null, false);
				}
			}
			return buttonEntity;
		}
		
		/**
		 * Parse game xml for game parameters
		 * @param xml
		 */
		override protected function parseXML(xml:XML):void
		{
			// note: returnX and returnY are pulled from QuestGame.as
			
			
			// get choose screen
			if (String(xml.choosePopup) != "")
				_choosePopup = String(xml.choosePopup);
			
			// get roadway speed
			if (String(xml.speed) != "")
				speed = uint(xml.speed);
			
			if (String(xml.brickSound) != "")
				brickSound = String(xml.brickSound);
			
			if (String(xml.bounceSound) != "")
				bounceSound = String(xml.bounceSound);
			
			if (String(xml.loseSound) != "")
				loseSound = String(xml.loseSound);
			
			if (String(xml.gameOverSound) != "")
				gameOverSound = String(xml.gameOverSound);
			
			if (String(xml.bounceFactor) != "")
				bounceFactor = Number(xml.bounceFactor);
			
			if (String(xml.playerSpeed) != "")
				_playerSpeed = Number(xml.playerSpeed);
			
			if (String(xml.multiplierTime) != "")
				multiplierTime = Number(xml.multiplierTime);
			
			if (String(xml.multiplierPowerChance) != "")
				multiplierPowerChance = Number(xml.multiplierPowerChance);
			
			if (String(xml.popupScene) != "")
				_popupScene = DataUtils.getBoolean(xml.popupScene);
			
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
				if (clip.name.substr(0,4) == "brick")
					{
						trace("brick found: " + clip.name);
					}
				
			}
		}
		
		/**
		 * Setup player based on selection from AdChoosePopup
		 * @param selection player selection (starts at 1, if zero, then use "player")
		 */
		override public function playerSelection(selection:int = 0):void
		{
			trace("select player " + selection);
			if(PlatformUtils.isMobileOS){
				if(_scene.shellApi.screenManager.appScale){
					_scene.container.scaleX = _scene.container.scaleY = _scene.shellApi.screenManager.appScale;
				}
			}
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
				//clip.y = _scene.shellApi.viewportHeight - 50;
				/*
				if(PlatformUtils.isMobileOS)
				{
					clip.y = _scene.shellApi.screenManager.deviceSize.height - (clip.height * 4);
					//trace("Device height: " + _scene.shellApi.screenManager.deviceSize.height + "viewport height: " + _scene.shellApi.viewportHeight);
				}
				*/
				_clip = clip;
				clip.x = 480;
				playerHit.visible = false;
				
				
				
				// create entity for player
				playerEntity = EntityUtils.createSpatialEntity(_scene, clip, _hitContainer);
				
				
				// enable player control
				setPlayerControl(true);
				
				ball = _hitContainer["ball"];
				// start game and race
				playing = true;
				
				var _bounceMasterGroup:BounceMasterGroup = new BounceMasterGroup();
				_scene.addChildGroup(_bounceMasterGroup);
				_bounceMasterGroup.setupGroup(this, _hitContainer, hud, _scene.sceneData.cameraLimits.width, _scene.sceneData.cameraLimits.height*1.5,_hitContainer["ball"],playerEntity,clip);
				//_bounceMasterGroup.gameOver.add(gameOver);
				//_bounceMasterGroup.makeCatcher(playerEntity, 1000, 100);
				_bounceMasterGroup.createCatcher(clip,playerEntity.get(Spatial));
				_bounceMasterGroup.setupStage(_hitContainer,"stage1");
				_bounceMasterGroup.startGame();			
			
				//_scene.addSystem(new BotBreakerGameSystem(this));
			}
			super.playerSelected();
		}
		
	
		
		// GAME FUNCTIONS /////////////////////////////////////////////////////////////////////
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
				playerEntity.add(new MotionBounds(new Rectangle(0, _clip.y, _scene.shellApi.viewportWidth, 100)));
			}
				// if turning off
			else
			{
				playerEntity.remove(FollowTarget);
			}
		}
		
		/**
		 * When player gets points
		 * @param newPoints
		 * @param colliderType
		 */
		public function gotPoints(newPoints:Number):void
		{
				points += newPoints;
				if (_hudScoreDisplay != null)
					_hudScoreDisplay.text = String(points);
			
		}
		public function setScoreColor(color:uint):void
		{
			
			if (_hudScoreDisplay != null)
				_hudScoreDisplay.textColor = color;
			
		}
		public function loseLife(currentLives:Number):void
		{
			var life:MovieClip = hud["life"+(currentLives+1)];
			if(life != null)
				hud.removeChild(life);
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
		public function loseGame():void
		{
		
			AdUtils.setScore(_scene.shellApi,points,"botbreaker");

			QuestGame(_scene).loadLosePopup(_popupScene, points);
		}
	
		/**
		 * When win game 
		 */
		public function winGame():void
		{
			// load win popup
			QuestGame(_scene).loadWinPopup(points, _popupScene);
		}
	}
}


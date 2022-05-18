package game.scenes.backlot.sunriseStreet
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.systems.AudioSystem;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Door;
	import game.components.hit.Platform;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Celebrate;
	import game.data.animation.entity.character.StandNinja;
	import game.data.game.GameEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.extSoundStage1.ExtSoundStage1;
	import game.scenes.backlot.shared.popups.BacklotBonusQuest;
	import game.scenes.backlot.shared.popups.CarsonPrints;
	import game.scenes.backlot.sunriseStreet.Systems.EarthquakeSystem;
	import game.scenes.backlot.sunriseStreet.Systems.SearchLightSystem;
	import game.scenes.backlot.sunriseStreet.Systems.SpringBoardSystem;
	import game.scenes.backlot.sunriseStreet.components.Earthquake;
	import game.scenes.backlot.sunriseStreet.components.SearchLight;
	import game.scenes.backlot.sunriseStreet.components.SpringBoard;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class SunriseStreet extends PlatformerGameScene
	{
		public function SunriseStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/sunriseStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_events = super.events as BacklotEvents;
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new EarthquakeSystem(), SystemPriorities.update );
			super.addSystem( new SearchLightSystem(), SystemPriorities.update );
			
			super.shellApi.camera.camera.area = new Rectangle(0,0,4500,1150);
			
			setOriginalBounds();
			setUpLedge();
			setUpFade();
			setUpGate()
			setUpSideWalk();
			setUpTheatre();
			setUpPages();
			setUpNpcs();
			setUpSpotLights();
			setUpSpringPlatforms();
			
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			super.loaded();
		}
		
		private function setUpNpcs():void
		{
			setUpWindowTeller();
			
			if(shellApi.checkEvent(_events.COMPLETE_MOVIE_EDITING))
			{
				Dialog(getEntityById("char3").get(Dialog)).setCurrentById("everyone");
			}
			if(shellApi.checkEvent(_events.SAW_MOVIE))
			{
				removeEntity(getEntityById("char1"));
				removeEntity(getEntityById("char2"));
				Dialog(getEntityById("char3").get(Dialog)).setCurrentById("saw_movie");
				if(!shellApi.checkEvent(_events.SUGGEST_BONUS))
				{
					SceneUtil.lockInput(this);
					Dialog(player.get(Dialog)).sayById("no sense");
				}
			}
			if(shellApi.checkEvent(_events.SUGGEST_BONUS))
			{
				for(var i:int = 7; i < 10; i++)
				{
					var critic:Entity = getEntityById("char"+i);
					removeEntity(critic);
				}
				Dialog(getEntityById("char6").get(Dialog)).setCurrentById("shoot");
			}
			if(shellApi.checkEvent(_events.DAY_2_STARTED))
			{
				Dialog(getEntityById("char6").get(Dialog)).setCurrentById("thanks");
			}
		}
		
		private function setUpWindowTeller():void
		{
			var tellerDisplay:Display = getEntityById("char3").get(Display);
			DisplayUtils.moveToOverUnder(tellerDisplay.displayObject, _hitContainer["window"],false);//move behind sheen so it looks like shes behind window
			tellerDisplay.displayObject.mask = _hitContainer["windowCover"];// mask her so she only shows where it looks appropriate
		}
		
		private function setUpSpringPlatforms():void
		{
			var spring1:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer["spring1"],this._hitContainer);
			spring1.add( new Platform());
			spring1.add( new SpringBoard(35, .1, spring1.get(Spatial).rotation ));
			spring1.add( new Motion());
			
			SpringBoard(spring1.get(SpringBoard)).spring.add(spring);
			
			var spring2:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer["spring2"],this._hitContainer);
			spring2.add( new Platform());
			spring2.add( new SpringBoard(35, .1, -spring1.get(Spatial).rotation ));
			spring2.add( new Motion());
			
			SpringBoard(spring2.get(SpringBoard)).spring.add(spring);
			
			super.addSystem( new SpringBoardSystem(), SystemPriorities.update);
		}
		
		private function spring():void
		{
			shellApi.triggerEvent(_events.SPRING);
		}
		
		private function setUpSpotLights():void
		{
			var light1:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer["searchLight1"],this._hitContainer);
			var light2:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer["searchLight2"],this._hitContainer);
			if(super.shellApi.checkEvent(_events.COMPLETED_ALL_STAGES))
			{
				super.addSystem(new SearchLightSystem(), SystemPriorities.update);
				
				light1.add(new SearchLight(.01,new Point(.39,Math.PI - .39), true, false));
				light1.add(new Id("sl1"));
				
				light2.add(new SearchLight(.01,new Point(.39,Math.PI - .39), false, true));
				light2.add(new Id("sl2"));
			}
			else
			{
				light1.get(Display).visible = false;
				light2.get(Display).visible = false;
			}
		}
		
		private function setUpPages():void
		{
			for(var i : int = 1; i < 3; i ++)
			{
				var pageName:String = "page" + i;
				var page:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer[pageName],this._hitContainer);
				TimelineUtils.convertClip(this._hitContainer[pageName],this,page);
				var eventName:String = "got_page_" + i;
				if(super.shellApi.checkEvent(_events.PAGES_BLEW_AWAY))
				{
					if(super.shellApi.checkEvent(eventName))
						super.removeEntity(page);// may need to make it invisible
					else
					{
						page.add(new Id(eventName));
						page.add(new SceneInteraction());
						var interaction:Interaction = InteractionCreator.addToEntity(page,[InteractionCreator.CLICK],this._hitContainer[pageName]);
						ToolTipCreator.addToEntity(page);
						var pageInteraction:SceneInteraction = page.get(SceneInteraction);
						pageInteraction.reached.add(collectPage);
						var audioRange:AudioRange = new AudioRange(1000, .01, 1, Quad.easeIn);
						page.add(new Audio()).add(audioRange);
						Audio(page.get(Audio)).play("effects/paper_flap_01.mp3",true, SoundModifier.POSITION);
					}
				}
				else
				{
					super.removeEntity(page);
				}
			}
		}
		
		private function collectPage(player:Entity, page:Entity):void
		{
			super.shellApi.triggerEvent(page.get(Id).id, true);
			super.shellApi.getItem(_events.SCREENPLAY_PAGES,null,true);
			super.removeEntity(page); 
		}
		
		private function setUpTheatre():void
		{
			var movieTitle:Entity = TimelineUtils.convertClip(this._hitContainer["movieTitle"],this,movieTitle);
			var title:Timeline = movieTitle.get(Timeline);
			if(!super.shellApi.checkEvent(_events.GO_SEE_MOVIE))
			{
				var door1:Entity = this.getEntityById("door1");
				var interactionTheatre:SceneInteraction = door1.get(SceneInteraction);
				interactionTheatre.reached.removeAll();
				interactionTheatre.reached.add(sayDialogTheatre);
				title.gotoAndStop(0);
			}
			else
				title.gotoAndStop(1);
		}
		
		private function setUpSideWalk():void
		{
			var sideWalk:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer["sidewalk"],this._hitContainer);
			sideWalk.add(new Id("sidewalk"));
			sideWalk.add(new SceneInteraction());
			var interaction:Interaction = InteractionCreator.addToEntity(sideWalk,[InteractionCreator.CLICK],this._hitContainer["sidewalk"]);
			ToolTipCreator.addToEntity(sideWalk);
			var interactionSideWalk:SceneInteraction = sideWalk.get(SceneInteraction);
			interactionSideWalk.reached.add(sayDialogSideWalk);
			if(!super.shellApi.checkEvent(_events.SAW_SIDEWALK))
			{
				var threshHold:Threshold = new Threshold("x",">");
				threshHold.threshold = sideWalk.get(Spatial).x + 50;
				threshHold.entered.add( Command.create( passSideWalk, super.player ));
				super.player.add(threshHold);
			}
		}
		
		private function passSideWalk(player:Entity):void
		{
			SceneUtil.lockInput(this, true, false);
			var position:Spatial = player.get(Spatial);
			CharUtils.moveToTarget( player, position.x - 50, position.y, false, lookAtSidewalk );
		}
		
		private function lookAtSidewalk(player:Entity):void
		{
			sayDialogSideWalk(player, super.getEntityById("sidewalk"));
		}
		
		private function sayDialogSideWalk(player:Entity, sidewalk:Entity):void
		{
			player.remove(Threshold);
			SceneUtil.lockInput(this);
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("sidewalk");
		}
		
		private function setUpGate():void
		{
			var gate:Entity = TimelineUtils.convertClip(this._hitContainer["gate"],this,gate);
			gate.add(new Id("gate"));
			var timeLine:Timeline = gate.get(Timeline);
			
			if(super.shellApi.checkEvent( _events.OPENED_BACKLOT_GATE))
				timeLine.gotoAndStop("open");
			else
			{
				timeLine.gotoAndStop("closed");
				var door:Entity = this.getEntityById("gateExit");
				var interactionGate:SceneInteraction = door.get(SceneInteraction);
				interactionGate.reached.removeAll();
				interactionGate.reached.add(sayDialogGate);
			}
		}
		
		private function sayDialogGate(player:Entity, door:Entity):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("looks closed");
		}
		
		private function setUpFade():void
		{
			var darkFade:Entity = EntityUtils.createSpatialEntity(this, new MovieClip(),this._hitContainer);
			darkFade.add(new Id("darkFade"));
			_darkFade = darkFade.get(Display);
		}
		
		private function setUpLedge():void
		{
			var ledge:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer["ledge"],this._hitContainer);
			ledge.add(new Id("ledge"));
			
			if(super.shellApi.checkEvent(_events.ENTERED_BACKLOT))
			{
				ledge.get(Display).visible = false;
				super.getEntityById("ledgeHit").remove(Platform);
			}
		}
		
		private function sayDialogTheatre(player:Entity, door:Entity):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("nothing good");
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			if( event == _events.GIVE_CAMERA)
			{
				if(!super.shellApi.checkHasItem(_events.CAMERA))
				{
					SceneUtil.lockInput(this, true, false);
					CharUtils.lockControls(player,true, true);
					SceneUtil.addTimedEvent( super, new TimedEvent( 6, 1, Command.create( finishDialog)));
				}
			}
			if( event ==_events.CAMERA )
			{
				Dialog( player.get(Dialog)).sayById("fix");
			}
			if(player.get(Spatial).x > 2500 && player.get(Spatial).y < 500)
			{
				if( event ==_events.TAKE_PICTURE )
				{
					if(!_dontTriggerTwice)
					{
						SceneUtil.lockInput(this, true, false);
						CharUtils.moveToTarget( player, 3200, 330, true, getIntoPosition );
						_dontTriggerTwice = true;
					}
				}
				if( event ==_events.TOOK_PICTURE )
				{
					Dialog( player.get(Dialog)).sayById("took picture");
				}
			}
			else
			{
				if( event ==_events.TAKE_PICTURE )
				{
					Dialog( player.get(Dialog)).sayById("better view");
				}
			}
			if( event == _events.LOOK_AT_SIDEWALK)
			{
				if(!nearSideWalk())
					return;
				SceneUtil.lockInput(this, false);
				_carsonPrints = super.addChildGroup( new CarsonPrints( super.overlayContainer )) as CarsonPrints;
			}
			if( event == _events.LOOK_AWAY_FROM_SIDEWALK)
			{
				SceneUtil.lockInput(this);
				Dialog( super.getEntityById("char1").get(Dialog)).sayById("carsons prints");
				shellApi.triggerEvent(_events.SAW_SIDEWALK, true);
			}
			if( event == _events.WELL_HE_WAS)
			{
				SceneUtil.lockInput(this, false, false);
			}
			if(event == _events.GO_SEE_MOVIE && ! shellApi.checkEvent(_events.SAW_MOVIE))
			{
				sendCharsToMovies();
			}
			if(event == _events.CRITICS_REVIEW)
			{
				SceneUtil.setCameraTarget(this, getEntityById("char8"));
			}
			if(event == _events.TALK_TO_SOPHIA)
			{
				SceneUtil.setCameraTarget(this, player);
				Dialog(getEntityById("char6").get(Dialog)).sayById("you see");
				for(var i:int = 7; i < 10; i++)
				{
					var critic:Entity = getEntityById("char"+i);
					CharUtils.moveToTarget(critic,2050, 1100,false,exit);
					CharacterMotionControl(critic.get(CharacterMotionControl)).maxVelocityX = 200;
				}
			}
			if( event == GameEvent.GOT_ITEM + _events.MEDALLION )
			{
				CharUtils.setAnim(player, Celebrate);
				
				var timeline:Timeline = CharUtils.getTimeline( super.player );
				timeline.labelReached.add( onLabelTrigger );
			}
			if(event == _events.SUGGEST_BONUS)
			{
				Dialog(getEntityById("char6").get(Dialog)).setCurrentById("shoot");
				SceneUtil.lockInput(this, false);
				bonusQuest = super.addChildGroup( new BacklotBonusQuest( super.overlayContainer )) as BacklotBonusQuest;
			}
			if(event == _events.DAY_2_STARTED)
			{
				Dialog(getEntityById("char6").get(Dialog)).setCurrentById("thanks");
			}
		}
		
		private function nearSideWalk():Boolean
		{
			var playerPos:Point = new Point(player.get(Spatial).x, player.get(Spatial).y);
			var sideWalk:Entity = getEntityById("sidewalk");
			var sideWalkPos:Point = new Point(sideWalk.get(Spatial).x, sideWalk.get(Spatial).y);
			if(Point.distance(playerPos, sideWalkPos) < 400)
				return true;
			return false;
		}
		
		private function onLabelTrigger( label:String ):void
		{
			var timeline:Timeline = CharUtils.getTimeline( super.player );
			if( label == "trigger" )
			{
				timeline.labelReached.removeAll( );
				Dialog(getEntityById("char6").get(Dialog)).sayById("shoot");
				
				shellApi.completedIsland(null, null);	// TODO: get a callback in here and manage the IslandEndingPopup business
				//SceneUtil.lockInput(this, false, false);
			}
		}
		
		private function exit(entity:Entity):void
		{
			removeEntity(entity);
		}
		
		private function sendCharsToMovies():void
		{
			SceneUtil.lockInput(this);
			var sophia:Entity = getEntityById("char6");
			var char1:Entity = getEntityById("char1");
			var char2:Entity = getEntityById("char2");
			
			var chars:Array = [sophia, char1, char2];
			
			var theatreDoor:Entity = getEntityById("door1");
			
			for(var i:int = 0; i < chars.length; i++)
			{
				var char:Entity = chars[i];
				CharUtils.moveToTarget(char, theatreDoor.get(Spatial).x, char.get(Spatial).y, false, goInTheatre);
				var motionControls:CharacterMotionControl = char.get(CharacterMotionControl);
				motionControls.maxVelocityX = 200;
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(5,1,enterTheatre));
		}
		
		private function enterTheatre():void
		{
			SceneUtil.lockInput(this, false);
			var door1:Entity = this.getEntityById("door1");
			var interactionTheatre:SceneInteraction = door1.get(SceneInteraction);
			interactionTheatre.reached.removeAll();
			Door(door1.get(Door)).open = true;
		}
		
		private function goInTheatre(char:Entity):void
		{
			removeEntity(char);
		}
		
		private function finishDialog():void
		{
			trace("should get camera by now");
			CharUtils.lockControls(super.player,false, false);
			SceneUtil.lockInput(this, false, false);
		}
		
		private function getIntoPosition(entity:Entity):void
		{
			loadCamera();
			SceneUtil.lockInput(this, false, false);
		}
		
		private function setOriginalBounds():void
		{
			_originalBounds = super.shellApi.camera.camera.area;
			super.shellApi.sceneManager.currentScene.sceneData.bounds.setTo(_originalBounds.x- 100,_originalBounds.y, _originalBounds.width + 200, _originalBounds.height - 50);
		}
		
		private function setEventBounds():void
		{
			super.shellApi.sceneManager.currentScene.sceneData.bounds.setTo(-100,PICTURE_AREA_Y, _originalBounds.width + PICTURE_AREA_WIDTH, _originalBounds.height - 50);
			super.shellApi.camera.camera.area = new Rectangle(PICTURE_AREA_X,PICTURE_AREA_Y, PICTURE_AREA_WIDTH, PICTURE_AREA_HEIGHT);
		}
		
		private function resetNormalBounds():void
		{
			super.shellApi.sceneManager.currentScene.sceneData.bounds.setTo(_originalBounds.x - 100,_originalBounds.y, _originalBounds.width + 200, _originalBounds.height - 50);
			super.shellApi.camera.camera.area = _originalBounds;
		}
		
		private function loadCamera():void
		{
			setEventBounds();
			
			if(_cameraOverlay == null)
			{
				_cameraOverlay = super.getAsset("telephotoOverlay.swf", true ) as MovieClip
				_cameraOverlay.x = -super.shellApi.viewportWidth / 2;
				_cameraOverlay.y = -super.shellApi.viewportHeight / 2;
				_cameraOverlay.width = super.shellApi.viewportWidth;
				_cameraOverlay.height = super.shellApi.viewportHeight;
			}
			
			if(_cameraLookTarget == null)
				_cameraLookTarget = EntityUtils.createSpatialEntity(this, new Sprite(),this._hitContainer);
			
			super.groupContainer.addChild(_cameraOverlay);
			
			setUpInteraction();
		}
		
		private function setUpInteraction():void
		{
			var inputEntity:Entity = shellApi.inputEntity;
			ToolTipCreator.addToEntity(inputEntity,"target");
			
			var inputSpatial:Spatial = inputEntity.get(Spatial);
			var followTarget:FollowTarget = new FollowTarget();
			followTarget.target = inputSpatial;
			followTarget.rate = .025;
			followTarget.applyCameraOffset = true;
			_cameraLookTarget.add(followTarget);
			
			var threshHoldY:Threshold = new Threshold("y",">");
			threshHoldY.threshold = 1000;
			threshHoldY.entered.add( Command.create( checkThreshHold, _cameraLookTarget ));
			_cameraLookTarget.add(threshHoldY);
			
			SceneUtil.setCameraTarget(this, _cameraLookTarget);
		}
		
		private function checkThreshHold(target:Entity):void
		{
			var carson:Entity = super.getEntityById("char5");
			_cameraLookTarget.remove(Threshold);
			CharUtils.moveToTarget( carson, 5150, 1090, false, carsonAppears);
		}
		
		private function carsonAppears(carson:Entity):void
		{
			var followTarget:FollowTarget = _cameraLookTarget.get(FollowTarget);
			followTarget.target = carson.get(Spatial);
			followTarget.applyCameraOffset = false;
			SkinUtils.setEyeStates( carson, EyeSystem.OPEN, EyeSystem.CENTER ); 
			SceneUtil.addTimedEvent( super, new TimedEvent( 2, 1, Command.create( useEarthquake, carson)));
		}
		
		private function useEarthquake(carson:Entity):void
		{
			_cameraLookTarget.add(new Earthquake(carson.get(Spatial), new Point(25,10),30));
			/*var followTarget:FollowTarget = _cameraLookTarget.get(FollowTarget);
			followTarget.target = carson.get(Spatial);
			followTarget.rate = 0;*/
			SceneUtil.addTimedEvent( super, new TimedEvent( 2, 1, Command.create( returnToGame, carson)));
		}
		
		private function returnToGame(carson:Entity):void
		{
			resetNormalBounds();
			var quake:Earthquake = _cameraLookTarget.get(Earthquake);
			quake.origin = super.player.get(Spatial);
			super.groupContainer.removeChild(_cameraOverlay);
			super.player.get(Dialog).sayById("Earthquake");
			CharUtils.setAnim(super.player, StandNinja); // doing this for some reason prevents the player from being able to utilize the move to target function
			ToolTipCreator.addToEntity(shellApi.inputEntity , "wait");
			SceneUtil.addTimedEvent( super, new TimedEvent( 2, 1, Command.create( fall, super.player)));
		}
		
		private function fall(player:Entity):void
		{
			CharUtils.setState(super.player, CharacterState.HURT);
			super.player.get(Motion).acceleration.y = -100;
			super.player.get(Motion).acceleration.x = 5000;
			
			super.getEntityById("ledgeHit").remove(Platform);
			
			SceneUtil.addTimedEvent( super, new TimedEvent( .8, 1, Command.create( disapear, super.player)));
			var motion:Motion = new Motion();
			motion.acceleration = new Point(0, 750);
			motion.rotationAcceleration = 100;
			super.getEntityById("ledge").add(motion);
		}
		
		private function disapear(player:Entity):void
		{
			player.get(Display).visible = false;
			var m:Motion = player.get(Motion);
			m.acceleration.x = 0;
			SceneUtil.addTimedEvent( super, new TimedEvent( .5, 1, Command.create( fadeToBlack)));
		}
		
		private function fadeToBlack():void
		{
			var left:Number = -super.shellApi.camera.camera.viewport.width /2 - 100;
			var width:Number = super.shellApi.camera.camera.viewport.width + 200;
			var top:Number = -super.shellApi.camera.camera.viewport.height /2 - 100;
			var height:Number = super.shellApi.camera.camera.viewport.height + 200;
			var darkFadeDisplay:MovieClip = _darkFade.displayObject as MovieClip;
			darkFadeDisplay.graphics.beginFill(0);
			darkFadeDisplay.graphics.moveTo( left, top);
			darkFadeDisplay.graphics.lineTo(width, top);
			darkFadeDisplay.graphics.lineTo(width, height);
			darkFadeDisplay.graphics.lineTo( left, height);
			darkFadeDisplay.graphics.endFill();
			darkFadeDisplay.alpha =0;
			_darkFade.alpha = 0;
			var position:Spatial = super.getEntityById("darkFade").get(Spatial);
			position.x = -super.shellApi.camera.x;
			position.y = -super.shellApi.camera.y;
			SceneUtil.addTimedEvent(super, new TimedEvent(.1,21,Command.create(fade)));
		}
		
		private function fade():void
		{
			if(_darkFade.alpha >= 1)
				super.shellApi.loadScene( ExtSoundStage1 );
			_darkFade.alpha += .05;
		}
		
		private var bonusQuest:BacklotBonusQuest;
		
		private var _carsonPrints:CarsonPrints;
		private var _darkFade:Display;
		private var _dontTriggerTwice:Boolean =false;
		private var _cameraLookTarget:Entity;
		private var _originalBounds:Rectangle;
		private const PICTURE_AREA_X :Number = 4700;
		private const PICTURE_AREA_WIDTH :Number = 1500;
		private const PICTURE_AREA_Y :Number = 0;
		private const PICTURE_AREA_HEIGHT :Number = 1400;
		private var _events : BacklotEvents;
		private var _cameraOverlay:MovieClip;
	}
}
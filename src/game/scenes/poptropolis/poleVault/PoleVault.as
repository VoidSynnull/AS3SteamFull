package game.scenes.poptropolis.poleVault{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.entity.character.Skin;
	import game.components.hit.Zone;
	import game.components.input.MotionControlInputMap;
	import game.components.motion.FollowTarget;
	import game.components.motion.MotionControl;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookData;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scenes.poptropolis.common.PoptropolisScene;
	import game.scenes.poptropolis.poleVault.states.PoleVaultLandState;
	import game.scenes.poptropolis.poleVault.states.PoleVaultLaunchState;
	import game.scenes.poptropolis.poleVault.states.PoleVaultNoJumpState;
	import game.scenes.poptropolis.poleVault.states.PoleVaultRunState;
	import game.scenes.poptropolis.poleVault.states.PoleVaultStandState;
	import game.scenes.poptropolis.poleVault.states.PoleVaultVaultState;
	import game.scenes.poptropolis.shared.Poptropolis;
	import game.scenes.poptropolis.shared.data.Matches;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TribeUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class PoleVault extends PoptropolisScene
	{
		private var barTimeline:Timeline;
		private var curRound:Number;
		private var practicing:Boolean = true;
		private var bestScore:Number;
		private var powerEntity:Entity;
		private var heatEntity:Entity;
		private var eventEntity:Entity;
		private var poleEntity:Entity;
		private var barEntity:Entity;
		private var fouled:Boolean = false;
		private var landed:Boolean = false;
		private var noJump:Boolean = false;
		private var fsmControl:FSMControl;
		private var playerDummy:Entity;
		private var _hud:PoleVaultHud;
		
		public function PoleVault()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/poptropolis/poleVault/";
			//super.showHits = true;
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
			super.loaded();

			var pole_mc:MovieClip = MovieClip(super._hitContainer['pole']);
			var power_mc:MovieClip = MovieClip(super._hitContainer['releaseMeter']);
			var eventTXT:MovieClip = MovieClip(super._hitContainer['eventTXT']);
			var fgVector:MovieClip  = MovieClip(super._hitContainer['fgVector']);
			var bar_mc:MovieClip = MovieClip(super._hitContainer['barMC']);
				
			super._hitContainer.setChildIndex (pole_mc, (super._hitContainer.numChildren - 1));				
			super._hitContainer.setChildIndex (fgVector, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex (bar_mc, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex (eventTXT, (super._hitContainer.numChildren - 1));	
			
			var entity:Entity = super.getEntityById("zone1");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			zone.entered.add(handleZoneEntered);
			
			playerDummy = super.getEntityById( "playerDummy" );
			var playerLook:LookData = SkinUtils.getLook( super.player ); 
			super.applyTribalLook( playerLook ); // apply tribal jersey to look
			playerDummy.get(Skin).applyLook( playerLook );
			playerDummy.add(new HitAudio());
			playerDummy.add(new Audio());
			
			super.removeEntity(super.getEntityById("player"), true);
			super.shellApi.defaultCursor = ToolTipType.TARGET;
						
			SceneUtil.setCameraTarget( this, playerDummy );
			SkinUtils.setSkinPart( playerDummy, SkinUtils.ITEM, 'vaultpole' );				
			
			// Set up the two entities we need for later
			poleEntity = EntityUtils.createSpatialEntity(this, _hitContainer["pole"]);
			poleEntity = TimelineUtils.convertClip( MovieClip(super._hitContainer['pole']), this, poleEntity );
			Sleep(poleEntity.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(poleEntity.get(Sleep)).sleeping = false;
			
			powerEntity = EntityUtils.createSpatialEntity(this, _hitContainer["releaseMeter"]);
			powerEntity = TimelineUtils.convertClip(MovieClip(_hitContainer["releaseMeter"]), this, powerEntity);
			Sleep(powerEntity.get(Sleep)).ignoreOffscreenSleep = true;
			Sleep(powerEntity.get(Sleep)).sleeping = false;
			var powerTarget:FollowTarget = new FollowTarget(playerDummy.get(Spatial));
			powerTarget.offset = new Point(80, 0);
			powerEntity.add(powerTarget);
			
			var display:Display;
			var spatial:Spatial;
			
			var clip:MovieClip = MovieClip(super._hitContainer['heatTXT']);
			heatEntity = EntityUtils.createSpatialEntity(this, clip, super.overlayContainer);
			TimelineUtils.convertClip(clip, null, heatEntity, null, false);
			heatEntity.remove(Sleep);
			display = heatEntity.get(Display);
			display.alpha = 0;
			spatial = heatEntity.get(Spatial);
			spatial.x = shellApi.viewportWidth/2 - 100;
			spatial.y = shellApi.viewportHeight/2 + 100;
			spatial.scaleX = spatial.scaleY = .4;
			
			eventEntity = EntityUtils.createSpatialEntity(this, eventTXT, super.overlayContainer);
			display = eventEntity.get(Display);
			spatial = eventEntity.get(Spatial);
			display.alpha = 0;
			spatial.x = shellApi.viewportWidth/2;
			spatial.y = shellApi.viewportHeight/2 + 50;
			spatial.scaleX = spatial.scaleY = .4;			
			
			poleEntity.get(Display).alpha = 0;
			powerEntity.get(Display).alpha = 0;

			var barEntity:Entity = TimelineUtils.convertClip(bar_mc, this);
			barTimeline = barEntity.get(Timeline);
			
			_hud = super.addChildGroup(new PoleVaultHud(super.overlayContainer)) as PoleVaultHud;
			_hud.stopRaceClicked.add(onStopRaceClicked)
			_hud.exitClicked.add(onExitPracticeClicked)
			_hud.ready.addOnce(initHud);
			
			setupSpectators();
			SceneUtil.addTimedEvent(this, new TimedEvent(.5, 1, onSceneAnimateInComplete));
		}
		
		private function onSceneAnimateInComplete ():void 
		{
			openInstructionsPopup()
		}
		
		override protected function onStartClicked (): void 
		{
			_hud.setMode("game")
			startMatch(false);
		}
		
		override protected function onPracticeClicked (): void 
		{
			_hud.setMode("practice")
			startMatch(true);
		}
		
		private function startMatch( isPractice:Boolean ):void 
		{			
			practicing = isPractice;			
			curRound = 1;
			bestScore = 0;
			startGame();
		}
		
		private function startGame():void
		{
			// Reset these
			fouled = false;
			landed = false;
			noJump = false;
			barTimeline.gotoAndStop("start");
			
			playerDummy.add(new MotionControlInputMap()); // NPC needs to listen to input
			playerDummy.add(new Player());
			var charGroup:CharacterGroup = CharacterGroup(super.getGroupById("characterGroup"));
			fsmControl = charGroup.addFSM(playerDummy, true, new <Class>[PoleVaultStandState, PoleVaultRunState, PoleVaultLandState, PoleVaultVaultState, PoleVaultLaunchState, PoleVaultNoJumpState], CharacterState.STAND);
			fsmControl.stateChange = new Signal();
			fsmControl.stateChange.add(onStateChange);
			MotionControl(playerDummy.get(MotionControl)).lockInput = false;
			
			SkinUtils.setSkinPart(playerDummy, SkinUtils.ITEM, "vaultpole");
			showHeatText(curRound);
		}
		
		private function onStateChange(type:String, entity:Entity):void
		{
			switch(type)
			{
				case CharacterState.STAND:
					if(landed)
					{
						jumpComplete(PoleVaultLaunchState(fsmControl.getState("launch")).maxHeight);
						landed = false;
					}
					else if(noJump)
					{
						fouled = true;
						jumpComplete(0);
						noJump = false;
					}
					break;
				
				case CharacterState.RUN:
					PoleVaultRunState(fsmControl.getState(CharacterState.RUN)).threshold = 2040;
					PoleVaultRunState(fsmControl.getState(CharacterState.RUN)).endX = 2700;
					break;
					
				case "vault":
					// add the follow target to the pole before showing it
					var poleTarget:FollowTarget = new FollowTarget(playerDummy.get(Spatial));
					poleTarget.offset = new Point(0, 20);
					poleEntity.add(poleTarget);					
					
					PoleVaultLaunchState(fsmControl.getState("launch")).meterMax = 27;
					SkinUtils.setSkinPart(playerDummy, SkinUtils.ITEM, "empty");
					poleEntity.get(Display).alpha = 1;
					poleEntity.get(Timeline).gotoAndPlay(2);
					powerEntity.get(Display).alpha = 1;
					powerEntity.get(Timeline).gotoAndPlay(2);			
					TimelineUtils.onLabel(powerEntity, "reachedEnd", forceFoul);
					break;
				
				case "launch":
					poleEntity.remove(FollowTarget);
					var powerTimeline:Timeline = powerEntity.get(Timeline);
					powerTimeline.stop();
					powerEntity.get(Display).alpha = 0;
					PoleVaultLaunchState(fsmControl.getState("launch")).meter = powerTimeline.currentIndex;

					if(powerTimeline.currentIndex > 25 || powerTimeline.currentIndex < 9)
					{
						fouled = true;
						forceFoul();						
						shellApi.triggerEvent("pickOtherSFX");
					}
					else
					{
						shellApi.triggerEvent("pickGreenSFX");
					}
					
					break;
				
				case CharacterState.LAND:
					landed = true;
					break;
				
				case "noJump":
					noJump = true;
					break;
					
				default:
					break;
			}
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{
			fouled = true;
			barTimeline.gotoAndPlay("fall");
			super.shellApi.triggerEvent("hitBarSFX");
		}
	
		private function jumpComplete(maxHeight):void 
		{
			var myHeight:Number = 0;
			if (maxHeight < 814 && playerDummy.get(Spatial).x > 2800)  
				myHeight = Math.round(((1108-maxHeight) * .064) * 10)/10;
			
			var playerScore:Number = myHeight;
			if (playerScore < 0 || fouled == true) playerScore = 0;
			if (playerScore > bestScore)
			{
				bestScore = playerScore;
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, newBestScore));	
			}

			if(playerScore > 0 )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, doProud));
			}
			else
			{
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, doGrief));
			}
			
			showEventText(playerScore, curRound, bestScore);
		}
		
		private function newBestScore():void
		{
			super.shellApi.triggerEvent("beatScoreSFX");
		}
		
		private function forceFoul():void
		{			
			fouled = true;
			fsmControl.setState(CharacterState.STAND);
			CharUtils.setAnim(playerDummy, Dizzy)
			CharUtils.getTimeline(playerDummy).gotoAndPlay("dizzy");
			CharUtils.getTimeline(playerDummy).handleLabel("ending", Command.create(jumpComplete, 0));
			super.shellApi.triggerEvent("notPickedSFX");		
		}
		
		private function doProud():void
		{
			CharUtils.setAnim(playerDummy,game.data.animation.entity.character.Proud)
		}
	
		private function doGrief():void
		{
			CharUtils.setAnim(playerDummy,game.data.animation.entity.character.Grief)
		}
		
		private function showHeatText(curRound:int):void 
		{
			var clip:MovieClip = MovieClip(heatEntity.get(Display).displayObject);
			if(practicing != true)
			{
				switch(curRound) 
				{
					case 1:
						clip.attemptMC.attemptTXT.text = "First attempt";
						break;
					case 2:
						clip.attemptMC.attemptTXT.text = "Second attempt";
						break;
					case 3:
						clip.attemptMC.attemptTXT.text = "Final attempt";
						break;
				}
			}
			else 
			{
				clip.attemptMC.attemptTXT.text = "Practice attempt";
			}					
			
			var timeline:Timeline = heatEntity.get(Timeline);
			timeline.gotoAndPlay(1);
			TweenUtils.entityFromTo(heatEntity, Display, .5, {alpha:0}, {alpha:1});
			TweenUtils.entityFromTo(heatEntity, Spatial, .5, {scaleX:.4, scaleY:.4}, {scaleX:1, scaleY:1});
			
			TimelineUtils.onLabel(heatEntity, "ending", startRunning);
		}
		
		private function hideEventText():void
		{		
			// Delay 3 seconds
			TweenUtils.entityTo(eventEntity, Spatial, .3, {scaleX:.4, scaleY:.4}, "", 3);
			TweenUtils.entityTo(eventEntity, Display, .3, {alpha:0, onComplete:reset}, "", 3);	
		}
		
		private function startRunning():void
		{
			fsmControl.setState(CharacterState.RUN);
			Timeline(heatEntity.get(Timeline)).gotoAndStop(1);
			heatEntity.get(Display).alpha = 0;
			heatEntity.get(Spatial).scaleX = heatEntity.get(Spatial).scaleY = .4;
		}
		
		private function showEventText(score:Number, attempt:Number, bestScore:Number):void 
		{
			var eventTXT:MovieClip = MovieClip(eventEntity.get(Display).displayObject);
			// set text
			if(score > 0)
			{
				eventTXT.largeTXT.text = score + " Meters!";
			} 
			else 
			{
				eventTXT.largeTXT.text = "Fouled!";
			}
			if(practicing != true)
			{
				switch(attempt) 
				{
					case 1:
						eventTXT.attemptTXT.text = "First attempt:";
						break;
					case 2:
						eventTXT.attemptTXT.text = "Second attempt:";
						break;
					case 3:
						eventTXT.attemptTXT.text = "Final attempt:";
						break;
				}
			}
			else
			{
				eventTXT.attemptTXT.text = "Practice attempt:";
			}
			if (bestScore > 0) 
			{
				eventTXT.farthestTXT.text = "Your farthest distance: " + bestScore + " Meters";
			}
			else 
			{
				eventTXT.farthestTXT.text = "";
			}
			
			if (playerDummy.get(Spatial).x > 3175) eventTXT.x = 3175; else eventTXT.x = playerDummy.get(Spatial).x;
	
			TweenUtils.entityFromTo(eventEntity, Display, .5, {alpha:0}, {alpha:1});
			TweenUtils.entityFromTo(eventEntity, Spatial, .5, {scaleX:.4, scaleY:.4}, {scaleX:1, scaleY:1, onComplete:hideEventText});
		}		
		
		private function reset():void
		{
			poleEntity.get(Display).alpha = 0;
			powerEntity.get(Display).alpha = 0;
			heatEntity.get(Display).alpha = 0;
			eventEntity.get(Display).alpha = 0;
			heatEntity.get(Spatial).scaleX = heatEntity.get(Spatial).scaleY = .4;
			eventEntity.get(Spatial).scaleX = eventEntity.get(Spatial).scaleY = .4;
			
			playerDummy.get(Spatial).x = 135;
			playerDummy.get(Spatial).y = 1114;
			
			if (curRound < 3 && practicing != true)
			{				
				curRound++;
				startGame();
			}
			else
			{
				finishGame();
			}	
		}
		
		private function finishGame():void
		{
			CharUtils.setAnim(playerDummy,Stand,false);
			if (practicing != true)
			{
				var pop:Poptropolis = new Poptropolis( shellApi, dataLoaded );
				pop.setup();
			}
			else
			{
				openInstructionsPopup()
			}
		}
		
		private function dataLoaded( pop:Poptropolis ):void 
		{			
			pop.reportScore( Matches.POLE_VAULT, bestScore );			
		}
		
		private function initHud (hud:PoleVaultHud):void 
		{
			_hud.setMode("clear")
		}
		
		private function onExitPracticeClicked (): void 
		{
			abortRace()
		}
		
		private function onStopRaceClicked (): void 
		{
			abortRace()
		}
		
		private function abortRace ():void 
		{			
			super.shellApi.loadScene(game.scenes.poptropolis.poleVault.PoleVault);
		}		
	}
}
package game.scenes.deepDive2.alienDoor
{
	import com.greensock.easing.Back;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.hit.MovieClipHit;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineMasterVariable;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.comm.PopResponse;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitDataComponent;
	import game.data.scene.hit.HitType;
	import game.scene.template.ItemGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive2.predatorArea.particles.GlassParticles;
	import game.scenes.deepDive2.shared.components.Breakable;
	import game.scenes.deepDive2.shared.popups.PuzzleKey2Popup;
	import game.scenes.deepDive2.shared.systems.BreakableSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class AlienDoor extends SubScene
	{
		private var completionsUpdated:Boolean;
		private var endingPopupWaiting:Boolean;

		public function AlienDoor()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive2/alienDoor/";			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private function removeIslandParts():void
		{
			
		}	
		
		override public function destroy():void
		{
			for each(var bitmap:Bitmap in this._bitmaps)
			{
				if(bitmap.bitmapData)
				{
					bitmap.bitmapData.dispose();
					bitmap.bitmapData = null;
				}
			}
			this._bitmaps = null;
			
			if(_predatorSection)
			{
				Bitmap(_predatorSection.getChildAt(0)).bitmapData.dispose();
				_predatorSection = null;
			}
			
			if(_pipeSection)
			{
				Bitmap(_pipeSection.getChildAt(0)).bitmapData.dispose();
				_pipeSection = null;
			}
			
			if(_medusaSection)
			{
				Bitmap(_medusaSection.getChildAt(0)).bitmapData.dispose();
				_medusaSection = null;
			}
			
			highlight.dispose();
			highlight = null;
			
			power.dispose();
			power = null;
			
			hose.dispose();
			hose = null;
			
			Bitmap(pipeHose.getChildAt(0)).bitmapData.dispose();
			pipeHose = null;
			
			Bitmap(predatorHose.getChildAt(0)).bitmapData.dispose();
			predatorHose = null;
			
			Bitmap(medusaHose.getChildAt(0)).bitmapData.dispose();
			medusaHose = null;			
			
			super.destroy();
		}		
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_alienDoorEvents = super.events as DeepDive2Events;
			shellApi.eventTriggered.add(handleEventTrigger);
			
			super.addLight(super.shellApi.player, 400, .4, true, false, 0x000033, 0x000033);
			
			setupDoor();
			setupGlass();
			setupGlyph();
			

		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _alienDoorEvents.SOLVED_PUZZLE)
			{
				AudioUtils.getAudio(this, "sceneSound").stop(SoundManager.MUSIC_PATH + "atlantis_2_main_theme.mp3", "music");
				AudioUtils.play(this, SoundManager.MUSIC_PATH + "atlantis_2_ending_cutscene.mp3", .75, true);
				shellApi.removeItem(_alienDoorEvents.PUZZLE_KEY);
				if( _podiumGlow ) 
				{ 
					removeEntity(_podiumGlow);
					EntityUtils.removeInteraction(_podiumGlow); 
				}

				CharUtils.setDirection(shellApi.player, true);
				SceneUtil.lockInput(this, true);
				MotionUtils.moveToTarget(shellApi.player, 1500, 590, true, playerAtSpot, new Point(10, 10));
				SceneUtil.setCameraTarget(this, _shipDoor);
				shellApi.camera.camera.scaleTarget = .75;
			}
		}
		
		private function playGlyphSequence():void
		{
			SceneUtil.lockInput(this, true);
			MotionUtils.moveToTarget(shellApi.player, 1090, 490, true);
			playMessage("film_this", glyphMessagePlayed);
		}
		
		private function glyphMessagePlayed():void
		{
			SceneUtil.lockInput(this, false);
			var threshold:Threshold = new Threshold("x", ">");
			threshold.threshold = 1700;
			threshold.entered.addOnce(playOpeningSequence);
			shellApi.player.add(threshold);
			
			this.addSystem(new ThresholdSystem());
		}
		
		private function playOpeningSequence():void
		{
			SceneUtil.lockInput(this, true);
			MotionUtils.moveToTarget(shellApi.player, 2000, 630, true);
			playMessage("what", playMessage2);
		}
		
		private function playMessage2():void
		{
			playerSay("city", playMessage3);
		}
		
		private function playMessage3(dialogData:DialogData):void
		{
			CharUtils.setDirection(shellApi.player, false);
			playMessage("doorway", Command.create(SceneUtil.lockInput, this, false));
		}
		
		private function showVictoryPopup():void
		{
			SceneUtil.lockInput(this, false);
			if (completionsUpdated) {
				addChildGroup(new IslandEndingPopup(this.overlayContainer));
			} else {
				endingPopupWaiting = true;
			}
		}
		
		private function wallHit(entity:Entity):void
		{
			_shardsEmitter.spark();
			wallHits++;
			
			if(wallHits >= WALL_STRENGTH)
			{
				shellApi.triggerEvent("glassBreak");
				playGlyphSequence();
				shellApi.triggerEvent(_alienDoorEvents.ALIEN_WALL_BROKEN, true);
				this.removeSystemByClass(BreakableSystem);
			}
			else
			{
				shellApi.triggerEvent("glassHit");
			}
			
			// rebound player	
			var motion:Motion = super.shellApi.player.get(Motion);
			motion.velocity.x *= -3;
		}
		
		private function setupGlass():void
		{
			var glassEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["glassWall"], _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline(glassEntity);
			
			if(!shellApi.checkEvent(_alienDoorEvents.ALIEN_WALL_BROKEN))
			{
				var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
				introPopup.updateText("you've discovered something amazing at the bottom of the ocean! try to find a way inside.", "start");
				introPopup.configData("introPopup.swf", "scenes/deepDive2/alienDoor/introPopup/");
				addChildGroup(introPopup);
				
				var breakable:Breakable = new Breakable(WALL_STRENGTH);
				breakable.wallHit.add(wallHit);
				glassEntity.add(breakable);
				glassEntity.add(new MovieClipHit("glassWall", "ship"));
				
				_shardsEmitter = new GlassParticles();
				_shardsEmitter.init(BitmapUtils.createBitmapData(_hitContainer["shard2"]));
				EmitterCreator.create(this, _hitContainer["glassWall"], _shardsEmitter, 0, 0);
				
				this.addSystem(new BreakableSystem(), SystemPriorities.resolveCollisions);
			}
			else
			{
				glassEntity.get(Timeline).gotoAndStop(WALL_STRENGTH);
			}
		}
		
		private function setupGlyph():void
		{
			
			var glyph:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["glyphHit"]);
			var isCaptured:Boolean = shellApi.checkEvent(_alienDoorEvents.GLYPH_ + 1);
			makeFilmable(glyph, handleFilmed, 300, 3, true, true, isCaptured);
			
			var subCamera:SubCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 500;
			subCamera.distanceMin = 0;
		}
		
		private function setupDoor():void
		{
			// The Door
			this.convertContainer(_hitContainer["shipDoor"]);
			_shipDoor = EntityUtils.createSpatialEntity(this, _hitContainer["shipDoor"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["shipDoor"], this, _shipDoor, null, false, 60);
			
			_shipDoorGlow = EntityUtils.createSpatialEntity(this, _hitContainer["shipDoorGlow"]);
			if(!PlatformUtils.isDesktop) DisplayUtils.bitmapDisplayComponent(_shipDoorGlow, true, 1);
			_shipDoorGlow.get(Display).alpha = 0;
			
			// Door highlights
			highlight = BitmapUtils.createBitmapData(_hitContainer["highlight"], 1, null, true);
			
			// Power
			power = BitmapUtils.createBitmapData(_hitContainer["orangePower"], 1, null, true);
			hose = BitmapUtils.createBitmapData(_hitContainer["hose"], 1, null, true);
			
			if(shellApi.checkEvent(_alienDoorEvents.COMPLETED_PIPES))
			{
				_pipeSection = BitmapUtils.createBitmapSprite(_hitContainer["highlight"], 1, null, true, 0, highlight);
				_pipeSection.x = 2145;
				_pipeSection.y = 773;
				_pipeSection.rotation = 120;
				_hitContainer.addChild(_pipeSection);
				
				var pipeDisplay:Display = new Display();
				pipeDisplay.displayObject = BitmapUtils.createBitmapSprite(_hitContainer["orangePower"], 1, null, true, 0, power);
				_hitContainer.addChild(pipeDisplay.displayObject);
				
				var pipeEntity:Entity = new Entity();
				pipeEntity.add(pipeDisplay);				
				pipeEntity.add(new Spatial(1756, 926));
				this.addEntity(pipeEntity);
				
				if(PlatformUtils.isDesktop)
					TweenUtils.globalTo(this, pipeDisplay, 1, {alpha:.5, onComplete:halfGlow, onCompleteParams:[pipeDisplay]});
			}			
			if(shellApi.checkEvent(_alienDoorEvents.TRAPPED_SHARK))
			{
				_predatorSection = BitmapUtils.createBitmapSprite(_hitContainer["highlight"], 1, null, true, 0, highlight);
				_predatorSection.x = 1840;
				_predatorSection.y = 692;
				_predatorSection.rotation = -120;
				_hitContainer.addChild(_predatorSection);
				
				var predatorDisplay:Display = new Display();
				predatorDisplay.displayObject = BitmapUtils.createBitmapSprite(_hitContainer["orangePower"], 1, null, true, 0, power);
				_hitContainer.addChild(predatorDisplay.displayObject);
				
				var predatorEntity:Entity = new Entity();
				predatorEntity.add(predatorDisplay);
				var predatorSpatial:Spatial = new Spatial(1744, 332);
				predatorSpatial.rotation = 180;
				predatorSpatial.scaleX = -1;
				predatorEntity.add(predatorSpatial);
				this.addEntity(predatorEntity);
				
				if(PlatformUtils.isDesktop)
					TweenUtils.globalTo(this, predatorDisplay, 1, {alpha:.5, onComplete:halfGlow, onCompleteParams:[predatorDisplay]});
			}
			if(shellApi.checkEvent(_alienDoorEvents.TRAPPED_MEDUSA))
			{
				_medusaSection = BitmapUtils.createBitmapSprite(_hitContainer["highlight"], 1, null, true, 0, highlight);
				_medusaSection.x = 2063;
				_medusaSection.y = 468;
				_hitContainer.addChild(_medusaSection);
				
				var medusaDisplay:Display = new Display();
				medusaDisplay.displayObject = BitmapUtils.createBitmapSprite(_hitContainer["orangePower"], 1, null, true, 0, power);
				_hitContainer.addChild(medusaDisplay.displayObject);
				
				var medusaEntity:Entity = new Entity();
				medusaEntity.add(medusaDisplay);
				var medusaSpatial:Spatial = new Spatial(2328, 918);
				medusaSpatial.rotation = -90;
				medusaEntity.add(medusaSpatial);
				this.addEntity(medusaEntity);
				
				if(PlatformUtils.isDesktop)
					TweenUtils.globalTo(this, medusaDisplay, 1, {alpha:.5, onComplete:halfGlow, onCompleteParams:[medusaDisplay]});
			}			
			_hitContainer.removeChild(_hitContainer["highlight"]);
			_hitContainer.removeChild(_hitContainer["orangePower"]);
			_hitContainer.removeChild(_hitContainer["hose"]);
			
			// setup hoses
			pipeHose = BitmapUtils.createBitmapSprite(_hitContainer["hose"], 1, null, true, 0, hose);
			_hitContainer.addChild(pipeHose);
			
			predatorHose = BitmapUtils.createBitmapSprite(_hitContainer["hose"], 1, null, true, 0, hose);
			predatorHose.x = 1871;
			predatorHose.y = 361;
			predatorHose.rotation = 180;
			predatorHose.scaleX = -1;
			_hitContainer.addChild(predatorHose);
			
			medusaHose = BitmapUtils.createBitmapSprite(_hitContainer["hose"], 1, null, true, 0, hose);
			medusaHose.x = 2303;
			medusaHose.y = 791;
			medusaHose.rotation = -90;
			_hitContainer.addChild(medusaHose);
			
			_currents = new Vector.<Entity>();
			var currentSequence:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer["current"]);
			for(var i:int = 0; i < DOOR_CURRENTS; i++)
			{
				var newCurrent:Entity = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["current"], true, false, currentSequence);
				addBitmappedEntity(newCurrent, _currentSpots[i].x, _currentSpots[i].y, _currentAngles[i], "empty");
				_currents.push(newCurrent);
			}
			_hitContainer.removeChild(_hitContainer["current"]);
			
			_doorGlow = EntityUtils.createMovingEntity(this, _hitContainer["doorGlow"]);
			if(!PlatformUtils.isDesktop) DisplayUtils.bitmapDisplayComponent(_doorGlow, true);
			_doorGlow.get(Display).alpha = 0;
			
			// Check if the puzzle isn't solved make the podium clickable
			if(!shellApi.checkEvent(_alienDoorEvents.SOLVED_PUZZLE))
			{
				_podiumGlow = EntityUtils.createSpatialEntity(this, _hitContainer["podiumGlow"]);
				BitmapTimelineCreator.convertToBitmapTimeline(_podiumGlow);		
				_podiumGlow.get(Timeline).play();
				InteractionCreator.addToEntity(_podiumGlow, [InteractionCreator.CLICK]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add(podiumClicked);
				_podiumGlow.add(sceneInteraction);
				ToolTipCreator.addToEntity(_podiumGlow);				
			}
			else
			{
				_hitContainer.removeChild(_hitContainer["podiumGlow"]);
			}
			
			_hitContainer.addChild(shellApi.player.get(Display).displayObject);
		}
		
		private function handleFilmed(glyph:Entity):void
		{
			handleFilmStates(glyph.get(Filmable), _alienDoorEvents.GLYPH_ + 1);
		}
		
		private function handleFilmStates( filmable:Filmable, sucessEvent:String):void
		{
			var camMessage:String = "alreadyFilmed";
			if(!shellApi.checkEvent(sucessEvent))
			{
				switch( filmable.state )
				{
					case filmable.FILMING_OUT_OF_RANGE:
					{
						camMessage = "filmTooFar";
						break;
					}
					case filmable.FILMING_BLOCK:
					{
						camMessage = "failedFilm";
						break;
					}
					case filmable.FILMING_START:
					{
						camMessage = "startFilm";
						break;
					}
					case filmable.FILMING_STOP:
					{
						camMessage = "failedFilm";
						break;
					}
					case filmable.FILMING_COMPLETE:
					{
						camMessage = "sucessFilm";;
						logFish( sucessEvent );
						break;
					}
					default:
					{
						trace( "invalid state: " + filmable.state );
						break;
					}
				}
			}
			
			playMessage(camMessage);
		}
		
		private function halfGlow(display:Display):void
		{
			TweenUtils.globalTo(this, display, 1, {alpha:1, onComplete:fullGlow, onCompleteParams:[display]});
		}
		
		private function fullGlow(display:Display):void
		{
			TweenUtils.globalTo(this, display, 1, {alpha:.5, onComplete:halfGlow, onCompleteParams:[display]});
		}
		
		private function podiumClicked(player:Entity, podium:Entity):void
		{
			CharUtils.setDirection(shellApi.player, true);
			var spatial:Spatial = shellApi.player.get(Spatial);
			spatial.x = 1525;
			spatial.y = 785;
			
			this.addChildGroup(new PuzzleKey2Popup(this.overlayContainer));
		}
		
		private function playerAtSpot(entity:Entity):void
		{
			SceneUtil.lockInput(this, true);
			entity.get(Motion).velocity = new Point(0,0);
			TweenUtils.globalTo(this, _doorGlow.get(Display), 1, {alpha:1});
			_doorGlow.get(Motion).rotationAcceleration = -60;
			SceneUtil.addTimedEvent(this, new TimedEvent(7, 1, openDoor));
			CharUtils.setDirection(entity, true);
		}
		
		private function openDoor():void
		{
			this.addSystem(new TimelineVariableSystem());
			
			var glowMotion:Motion = _doorGlow.get(Motion);
			glowMotion.rotationAcceleration = 75;
			
			var camera:Entity = this.getEntityById("camera");			
			this.addSystem(new ShakeMotionSystem());
			camera.add(new ShakeMotion(new RectangleZone(-3, -3, 3, 3))).add(new SpatialAddition());
			
			TweenUtils.globalFromTo(this, _shipDoorGlow.get(Display), 2, {alpha:0}, {alpha:1});			
			var timeline:Timeline = _shipDoor.get(Timeline);
			_shipDoor.get(TimelineMasterVariable).frameRate = 15;
			timeline.handleLabel("opened", moveToDoor);
			
			if( _medusaSection ) { _hitContainer.removeChild(_medusaSection); }
			if( _pipeSection ) { _hitContainer.removeChild(_pipeSection); }
			if( _predatorSection ) { _hitContainer.removeChild(_predatorSection); }
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heavy_gritty_drag_01_L.mp3", 4, true);
			timeline.gotoAndPlay("open");
		}
		
		private function moveToDoor():void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "heavy_gritty_drag_01_L.mp3.mp3");
			TweenUtils.globalTo(this, _doorGlow.get(Display), 2, {alpha:0});	
			this.getEntityById("camera").remove(ShakeMotion);			
			MotionUtils.moveToTarget(shellApi.player, 1630, 640, true);
			SceneUtil.delay(this, 4, playerAtDoor );
		}
		
		private function playerAtDoor():void
		{
			playMessage("found", playCurrents);
		}
		
		private function playCurrents():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_suction_01_loop.mp3", 2, true);
			for(var i:int = 0; i < _currents.length; i++)
			{
				var current:Entity = _currents[i];
				current.get(Timeline).gotoAndPlay("playCurrent");
			}
			
			SkinUtils.setSkinPart(this._playerDummy, SkinUtils.MOUTH, "angry" , false);
			CharUtils.setDirection(shellApi.player, false);
			DisplayUtils.moveToTop(_shipDoor.get(Display).displayObject);
			var spatial:Spatial = shellApi.player.get(Spatial);
			TweenUtils.globalTo(this, spatial, 5, {rotation:spatial.rotation + 120, x:2000, y:660, ease:Back.easeIn, onComplete:playerThroughDoor});
		}
		
		private function playerThroughDoor():void
		{
			_shipDoor.get(TimelineMasterVariable).frameRate = 180;
			
			var timeline:Timeline = _shipDoor.get(Timeline);
			timeline.reverse = true;
			timeline.play();
			timeline.handleLabel("closed", doorClosed);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heavy_gritty_drag_04.mp3");
		}
		
		private function doorClosed():void
		{
			this.getEntityById("camera").add(new ShakeMotion(new RectangleZone(-1, -1, 1, 1)));
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "snow_large_impact_01.mp3", 3);
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "water_suction_01_loop.mp3");
			for each(var current:Entity in _currents)
			{
				current.get(Timeline).gotoAndStop("empty");
			}
			
			if( !shellApi.checkHasItem( _alienDoorEvents.MEDAL))
			{
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
				itemGroup.showAndGetItem( _alienDoorEvents.MEDAL, null);
			}			
			shellApi.completedIsland('', onCompletions);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.5, 1, playWhereAreYou));
		}

		private function onCompletions(response:PopResponse):void
		{
			completionsUpdated = true;
			if (endingPopupWaiting) {
				showVictoryPopup();
			}
		}
		
		private function playWhereAreYou():void
		{
			this.removeSystemByClass(ShakeMotionSystem);
			playMessage("come_in", showStaticMessage);
		}
		
		private function showStaticMessage():void
		{
			playStaticMessage("glyphs", playConfusedMessage);
		}
		
		private function playConfusedMessage():void
		{
			playMessage("who", showVictoryPopup);
		}
		
		private function addBitmappedEntity(entity:Entity, x:Number, y:Number, rotation:Number = 0, timelineStart:String = "", scaleX:Number = 1, scaleY:Number = 1, index:DisplayObject = null):void
		{
			this.addEntity(entity);
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = x;
			spatial.y = y;
			spatial.rotation = rotation;
			spatial.scaleX = scaleX;
			spatial.scaleY = scaleY;
			
			if(timelineStart != "")
			{
				entity.get(Timeline).gotoAndStop(timelineStart);
			}
			
			if(index == null) DisplayUtils.moveToBack(entity.get(Display).displayObject);
			else DisplayUtils.moveToOverUnder(entity.get(Display).displayObject, index, true);
		}
		
		private var _alienDoorEvents:DeepDive2Events;
		
		private static var DOOR_CURRENTS:int = 6;
		private static var WALL_STRENGTH:int = 2;
		private var wallHits:int = 0;
		
		private var _shardsEmitter:GlassParticles;
		private var _shipDoor:Entity;
		private var _shipDoorGlow:Entity;
		private var _podiumGlow:Entity;
		private var _doorGlow:Entity;
		
		private var _medusaSection:Sprite;
		private var _predatorSection:Sprite;
		private var _pipeSection:Sprite;
		
		private var highlight:BitmapData;
		private var power:BitmapData;
		private var hose:BitmapData;
		
		private var pipeHose:Sprite;
		private var predatorHose:Sprite;
		private var medusaHose:Sprite;
		
		private var _currentSpots:Array = new Array(new Point(1717, 427), new Point(1682, 650), new Point(1724, 859), new Point(2309, 447), new Point(2350, 656), new Point(2297, 866));
		private var _currentAngles:Array = new Array(0, -30, -60, 120, 150, 180);
		private var _currents:Vector.<Entity>;
		private var _bitmaps:Vector.<Bitmap> = new Vector.<Bitmap>();
	}
}
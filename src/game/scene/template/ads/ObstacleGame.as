package game.scene.template.ads {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Hazard;
	import game.components.hit.Zone;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.data.WaveMotionData;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.questGame.QuestGame;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class ObstacleGame extends AdGameTemplate {

		// from XML
		public var _timeout:Number = 0; // when left as zero, then timer is disabled
		public var _winNPC:String = null; // NPC who speaks when win game
		public var _hazards:Array = null; // list of hazards with hit animations
		public var _movingHazards:Array = null; // list of hazards that move up and down
		public var _toggleHazards:Array = null; // list of hazards that turn on and off
		public var _waveMotionMagnitude:Number = 5.0;
		public var _waveMotionRate:Number = 0.075;
		public var _hitScaleTarget:Number = 1.5;
		public var _hitScaleTimer:Number = 0.4;
		
		// HUD
		private var _HUD:MovieClip;
		
		// end game
		private var _wonGame:Boolean = false;
		
		// timer
		private var _textField:TextField;
		private var _time:Number = 0;
		private var _secs:Number = 0;
		private var _triggeredLose:Boolean = false;
		
		public function ObstacleGame(container:DisplayObjectContainer = null) {
			super(container);
			id = "ObstacleGame";
		}
	
		override public function destroy():void {
			groupContainer = null;
			stopTimer();
			super.destroy();
		}
	
		// initialization /////////////////////////////////////////////////////
	
		override protected function parseXML(xml:XML):void {
			parseGameXML(xml);
			// this sets up looks and needs to follow parseGameXML or else _looks gets overwritten
			super.parseXML(xml);
		}
	
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void {
			super.setupGame(scene, xml, hitContainer);
	
			// catch events that may get triggered
			_scene.shellApi.eventTriggered.add(handleEventTriggered);
			// get hud
			_HUD = _scene.getEntityById("hud").get(Display).displayObject;
			// for some reason, the hud gets shrunk, so force scaling to 100%
			var hudSpatial:Spatial = _scene.getEntityById("hud").get(Spatial);
			hudSpatial.scaleX = hudSpatial.scaleY = 1.0;
			/**
			 * Loop through hazards 
			 * These are hazards with hit animations that trigger when passed and also hit
			 */
			if (_hazards != null) {
				for each (var hazard:String in _hazards) {
					// get movieClip
					var clip:MovieClip = _scene.hitContainer[hazard];
					// convert to timeline entity
					var entity:Entity = TimelineUtils.convertClip(clip, _scene);
					// turn off sleep
					entity.get(Sleep).ignoreOffscreenSleep = true;
					// add and get spatial
					var spatial:Spatial = entity.add(new Spatial(clip.x, clip.y)).get(Spatial);
					// add threshold component (didn't add value to vivoQuest, but we can re-enable if desired)
					// Threshold doesn't trigger when jumping over an obstacle. It triggers after you land.
					/*
					var threshold:Threshold = new Threshold("x", "<", _scene.player);
					// if movieClip is flipped then offset by width of entity (assuming x is at left edge)
					var offset:Float = 0;
					if (clip.scaleX == -1) {
						offset -= clip.width;
					}
					threshold.threshold = spatial.x + offset;
					entity.add(threshold);
					// add hit function for when enter zone
					threshold.entered.add(Command.create(doHit, entity));
					*/
					// get hazard hit entity associated with timeline entity
					var hazardEntity:Entity = _scene.getEntityById(clip.name + "Hazard");
					// add hit function for when hit hazard
					hazardEntity.get(Hazard).hitFunction = Command.create(doHit, entity);
					// listen for scale label
					TimelineUtils.onLabel(entity, "scale", Command.create(doScale, hazardEntity), false);
				}
				// Add threshold system
				_scene.addSystem(new ThresholdSystem());
			}
			/**
			 * Loop through moving hazards 
			 * These are hazards that move up and down
			 */
			if(_movingHazards != null) {
				for each (hazard in _movingHazards) {
					var bugs:Entity = _scene.getEntityById(hazard);
					var wm:WaveMotion = new WaveMotion();
					var waveMotionData:WaveMotionData = new WaveMotionData("y", _waveMotionMagnitude, _waveMotionRate);
					wm.data.push(waveMotionData);
					bugs.add(wm);
				}
				// Add WaveMotionSystem system
				_scene.addSystem(new WaveMotionSystem());
			}
			/**
			 * Loop through toggle hazards 
			 * These are hazards that turn on and off
			 */
			if(_toggleHazards != null) {
				for each (hazard in _toggleHazards) {
					var tl:Timeline = TimelineUtils.convertClip(_scene.hitContainer[hazard], _scene).get(Timeline);
					tl.labelReached.add(Command.create(labelReached, hazard));
				}
			}
			// setup timer
			_textField = _HUD["twrap"]["timer"];
			_textField = TextUtils.refreshText(_textField, "CreativeBlock BB");
			// setup end zone
			var endentity:Entity = _scene.getEntityById("endZone");
			var endzone:Zone = endentity.get(Zone);
			endzone.pointHit = true;
			endzone.inside.add(triggerEnd);
			// notify game is setup
			gameSetUp.dispatch(this);
			// setup look if passed
			if (_looks != null) {
				SkinUtils.applyLook(_scene.shellApi.player, _looks[0],false,playerSelected);
			} else {
				playerSelected();
			}
		}
	
		// scale hazard hit when scale frame is reached
		private function doScale(entity:Entity):void {
			TweenUtils.entityTo(entity, Spatial, _hitScaleTimer, {scaleY:_hitScaleTarget, onComplete:Command.create(doneScale, entity)});
		}
	
		// unscale hazard hit when tween is done
		private function doneScale(entity:Entity):void {
			TweenUtils.entityTo(entity, Spatial, _hitScaleTimer, {scaleY:1.0});
		}
	
		// this doesn't work if avatar is in air
		private function doHit(crocEnt:Entity):void {
			crocEnt.get(Timeline).gotoAndPlay("hit");
		}
	
		private function labelReached(label:String, id:String):void {
			// ignore labels that don't start with hit_
			if (label.indexOf("hit_") != 0) {
				return;
			}
			// look for hit that is name of entity with "hit" appended
			var entity:Entity = _scene.getEntityById(id + "Hit");
			if (entity != null) {
				entity.get(Hazard).active = (label == "hit_on");
			}
		}
	
		override protected virtual function playerSelected(...args):void {
			// start timer
			if (_timeout != 0) {
				startTimer();
			}
		}
	
		private function startTimer():void {
			_time = getTimer()/1000;
			_secs = _timeout;
			_textField.addEventListener(Event.ENTER_FRAME, fnTimer);
		}
	
		// game play ////////////////////////////////////////////////////////////
	
		/**
		 * To capture any game triggers
		 * @param event
		 * @param makeCurrent
		 * @param init
		 * @param removeEvent
		 */
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false,
			removeEvent:String = null):void {
			trace("ObstacleGame: handleEvent: " + event);
			switch (event) {
				case "winGame":
					winGame();
			}
		}
	
		// timer enterFrame event
		private function fnTimer(e:Event):void {
			var vSecs:Number = Math.floor(_timeout - (getTimer()/1000 - _time));
			if (vSecs != _secs) {
				// don't allow negative times
				if (vSecs < 0) {
					vSecs = 0;
				}
				_secs = vSecs;
				fnShowTime();
				if ((vSecs == 0) && (!_triggeredLose)) {
					removeHUD();
					triggerLose();
				}
			}
		}
	
		// update timer display
		private function fnShowTime():void {
			var vMins:Number = Math.floor(_secs / 60);
			var vLeft:Number = _secs - vMins * 60;
			var vDigits:String = "0";
			if (vLeft < 10) {
				vDigits += String(vLeft);
			} else {
				vDigits = String(vLeft);
			}
			_textField.text = String(vMins) + ":" + vDigits;
		}
	
		// end game functions //////////////////////////////////////////////
	
		// when lose
		private function triggerLose():void {
			// stop timer
			stopTimer();
			QuestGame(_scene).loadLosePopup();
			_triggeredLose = true;
		}
	
		// when enter end zone
		private function triggerEnd(zoneId:String, characterId:String):void {
			// remove end zone listener
			var endentity:Entity = _scene.getEntityById("endZone");
			var endzone:Zone = endentity.get(Zone);
			endzone.inside.removeAll();
			// stop timer
			stopTimer();
			// make avatar stop
			CharUtils.lockControls(_scene.shellApi.player);
			// make NPC speak
			if (_winNPC != null) {
				npcSpeak();
			} else {
				winGame();
			}
		}
	
		private function stopTimer():void {
			if (_textField != null) {
				_textField.removeEventListener(Event.ENTER_FRAME, fnTimer);
				_textField = null;
			}
		}
	
		private function npcSpeak():void {
			// say win dialog (will trigger WinGame event when complete)
			_scene.getEntityById(_winNPC).get(Dialog).sayById("winGame");
		}
	
		// win game
		private function winGame():void {
			if (!_wonGame) {
				_wonGame = true;
				// remove hud
				removeHUD();
				// load win game popup
				QuestGame(_scene).loadWinPopup();
			}
		}
	
		private function removeHUD():void {
			if (_HUD != null) {
				_HUD.visible = false;
			}
		}
	}
}

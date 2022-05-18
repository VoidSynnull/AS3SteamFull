package game.scene.template.ads
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.MotionMaster;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.questGame.QuestGame;
	import game.util.AudioUtils;
	import game.util.ColorUtil;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MovieClipUtils;
	import game.util.SceneUtil;
	import game.util.StringUtil;
	import game.util.TimelineUtils;
	
	

	/**
	 * Game template for sequential based game - DisneyBakeOffQuest is the first using this
	 * @author Justin
	 */
	public class AdSimonGame extends AdGameTemplate {
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		public var _maxNumWrong:Number = 3; // when left as zero, then timer is disabled
		public var _numSteps:Number = 5; //number of rounds
		public var _wrongSound:String = ""; //number of rounds
		public var _rightSound:String = ""; //number of rounds
		private var _currentStep:Number = 0;
		private var _buttons:Array;
		private var _sequence:Array;
		private var _showingSequence:Boolean = true;
		private var _correctClick:Boolean = false;
		private var _healthTimeline:Timeline;
		private var _currentNumWrong:Number = 0;
		private var _mainTimeline:Timeline;
		private var _waitTimeline:Timeline;
		private var _wrongChoiceEntity:Entity;
		private var _playing:Boolean = false;
		private var _wrongClicked:Boolean = false;
		private var _HUD:MovieClip;
		//timer vars
		private var  _timerText:TextField;
		private var  _timeout:Number = 0; // when left as zero, then timer is disabled
		private var _time:Number;
		/**
		 * Constructor
		 */
		public function AdSimonGame(container:DisplayObjectContainer = null) {
			super(container);
			this.id = "AdSimonGame";
			_buttons = new Array();
			_sequence = new Array();
		}
		
		/**
		 * Setup game based on xml
		 * @param group
		 * @param xml
		 * @param hitContainer
		 */
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void {
			super.setupGame(scene, xml, hitContainer);
			_scene.ready.addOnce(setupPlayer);
			if(_scene.getEntityById("hud") != null) {
				_HUD = _scene.getEntityById("hud").get(Display).displayObject;
				// for some reason, the hud gets shrunk, so force scaling to 100%
				var hudSpatial:Spatial = _scene.getEntityById("hud").get(Spatial);
				hudSpatial.scaleX = hudSpatial.scaleY = 1.0;
				_timerText = TextField(_HUD.getChildByName( "twrap.timer"));
				//_timerText = TextUtils.refreshText(_timerText, "CreativeBlock BB".font());
			}
			setupClickables();
			//init sequence
			_sequence.push(int(Math.floor(Math.random() * 4) + 1));
			_playing = true;
			startCountDown();
			// get hud
			
			gameSetUp.dispatch(this);
		}
		
		private function startCountDown():void {
			var count:TextField = TextField(_hitContainer.getChildByName("countdown"));
			
			count.text = Std.string(int(count.text) - 1);
			if (count.text == "0") {
				count.visible = false;
				_scene.shellApi.defaultCursor = ToolTipType.TARGET;
				showSequence();
			} else {
				SceneUtil.addTimedEvent(_scene, new TimedEvent(1, 1, startCountDown));
			}
			
		}
		
		private function getButtonById(id:String):Entity {
			for (var ent:Entity in _buttons) {
				if (ent.get(Id).id == id) {
					return ent;
				}
			}
			return null;
		}
		
		private function showSequence():void {
			_showingSequence = true;
			changeGameMessage(_showingSequence);
			trace("showing sequence: " + _sequence[_currentStep]);
			// _buttons[_sequence[_currentStep]].getTimeline().gotoAndPlay("clickCorrect");
			_mainTimeline.gotoAndPlay("button" + _sequence[_currentStep]);
			_scene.getEntityById("button" + _sequence[_currentStep]).get(Timeline).gotoAndStop("on");
			trace("currentstep++");
			_currentStep++;
		}
		
		private function setupClickables():void {
			if (_hitContainer != null) {
				
				var mainEntity:Entity = TimelineUtils.convertClip(MovieClip(_hitContainer.getChildByName("main_timeline")), _scene);
				_mainTimeline = mainEntity.get(Timeline);
				_mainTimeline.gotoAndStop(0);
				
				var clip:MovieClip;
				var buttonCount:Number = 0;
				var i:Number = _hitContainer.numChildren - 1;
				while (i != -1) {
					if (_hitContainer.getChildAt(i) is MovieClip) {
						clip = MovieClip(_hitContainer.getChildAt(i));
						if (clip.name.indexOf("button") != -1) {
							buttonCount++;
							var buttonEntity:Entity = ButtonCreator.createNewStandardButton(clip, _scene, buttonClicked, null, null, clip.name);
							//_buttons[Std.parseInt(clip.name.substr(clip.name.length-1,1))] = TimelineUtils.convertClip(clip,_scene,buttonEntity,null,false);
							_buttons.push(TimelineUtils.convertClip(clip, _scene, buttonEntity, null, false));
							_mainTimeline.handleLabel("button" + buttonCount + "End", animDone, false);
						}
					}
					i--;
				}
				
				// create into timeline and stop on first frame
				var hudEntity:Entity = TimelineUtils.convertClip(MovieClip(_HUD.getChildByName("health")), _scene);
				_healthTimeline = hudEntity.get(Timeline);
				_healthTimeline.gotoAndStop(0);
				
				if (_HUD.getChildByName("wait_message") != null) {
					hudEntity = TimelineUtils.convertClip(MovieClip(_HUD.getChildByName("wait_message")), _scene);
					_waitTimeline = hudEntity.get(Timeline);
					_waitTimeline.gotoAndStop(0);
				}
				
				_wrongChoiceEntity = EntityUtils.createSpatialEntity(_scene, _hitContainer.getChildByName("wrong_choice"));
				_wrongChoiceEntity.get(Display).visible = false;
				
				
			}
		}
		
		private function changeGameMessage(waiting:Boolean):void {
			if (_waitTimeline != null) {
				if (waiting == true) {
					_waitTimeline.gotoAndStop("wait");
				} else {
					_waitTimeline.gotoAndStop("no_wait");
				}
			}
		}
		
		private function animDone():void {
			_mainTimeline.gotoAndStop(0);
			_wrongClicked = false;
			var ent:Entity = _scene.getEntityById("button" + _sequence[_currentStep - 1]); 
			if(ent != null){
			_scene.getEntityById("button" + _sequence[_currentStep - 1]).get(Timeline).gotoAndStop("off");
			} 
			if (_showingSequence == true) {
				if (_currentStep == _sequence.length) {
					_showingSequence = false;
					changeGameMessage(_showingSequence);
					_currentStep = 0;
					trace("sequence done, set step to 0");
				} else {
					SceneUtil.addTimedEvent(_scene, new TimedEvent(.5, 1, showSequence));
					//showSequence();
				}
			} else {
				if (_currentStep == _sequence.length) {
					if (_sequence.length == _numSteps) {
						winGame();
					} else {
						_sequence.push(int(Math.floor(Math.random() * 4) + 1));
						_currentStep = 0;
						SceneUtil.addTimedEvent(_scene, new TimedEvent(.5, 1, showSequence));
						//showSequence();
					}
				}
			}
		}
		
		private function resetButtonStates():void {
			for(var i:Number = 0; i < _buttons.length; i++){
				_buttons[i].get(Timeline).gotoAndStop("off");
			}
		}
		
		private function checkGameOver():void {
			_currentNumWrong++;
			_healthTimeline.gotoAndStop(_currentNumWrong);
			if (_currentNumWrong == _maxNumWrong) {
				triggerLose();
			}
		}
		
		private function getButton(id:String):Entity {
			for (var ent:Entity in _buttons) {
				if (ent.get(Id).id == id) {
					return ent;
				}
			}
			return null;
		}
		
		private function buttonClicked(entity:Entity):void {
			if (_showingSequence == false && _currentStep != _sequence.length && _wrongClicked == false) {
				var entid:String = entity.get(Id).id.substr(entity.get(Id).id.length - 1, 1);
				if (Number(entid) == _sequence[_currentStep]) {
					resetButtonStates();
					
					trace("correct");
					if (_rightSound != "") {
						AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + _rightSound);
					}
					
					_mainTimeline.gotoAndPlay("button" + _sequence[_currentStep]);
					_scene.getEntityById("button" + _sequence[_currentStep]).get(Timeline).gotoAndStop("on");
					_currentStep++;
					
					
					/*
					if (_currentStep == _sequence.length) {
					changeGameMessage(true);
					}
					*/
					
				}
				else {
					trace("incorrect");
					_wrongClicked = true;
					resetButtonStates();
					if (_wrongSound != "") {
						AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + _wrongSound);
					}
					_currentNumWrong++;
					_healthTimeline.gotoAndStop(_currentNumWrong);
					if (_currentNumWrong == _maxNumWrong) {
						triggerLose();
					} else {
						_currentStep = 0;
						_wrongChoiceEntity.get(Spatial).x = entity.get(Spatial).x;
						_wrongChoiceEntity.get(Spatial).y = entity.get(Spatial).y;
						_wrongChoiceEntity.get(Display).visible = true;
						changeGameMessage(true);
						SceneUtil.addTimedEvent(_scene, new TimedEvent(1, 1, wrongChoiceClear));
					}
				}
			}
		}
		
		private function wrongChoiceClear():void {
			_wrongChoiceEntity.get(Display).visible = false;
			showSequence();
		}
		
		private function setupPlayer(...args):void {
			_scene.removeEntity(_scene.shellApi.player);
		}
		
		override protected function parseXML(xml:XML):void {
			parseGameXML(xml);
			_numSteps = Number(xml.numSteps);
			_maxNumWrong = Number(xml.maxNumWrong);
			super.parseXML(xml);
		}
		
		
		/**
		 * When game ends
		 */
		private function endGame():void {
			_playing = false;
		}
		
		/**
		 * When lose game
		 */
		private function triggerLose():void {
			if (_playing) {
				endGame();
				AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + "mini_game_loss.mp3");
				// show lose popup
				QuestGame(_scene).loadLosePopup();
			}
		}
		
		/**
		 * When win game
		 */
		private function winGame():void {
			endGame();
			AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + "mini_game_win.mp3");
			// load win popup
			QuestGame(_scene).loadWinPopup();
		}
		
	}
}
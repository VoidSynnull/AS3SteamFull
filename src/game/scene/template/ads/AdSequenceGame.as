package game.scene.template.ads
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.managers.ScreenManager;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.questGame.QuestGame;
	import game.ui.hud.Hud;
	import game.util.AudioUtils;
	import game.util.ColorUtil;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	
	
	/**
	 * Game template for sequential based game - DisneyBakeOffQuest is the first using this
	 * @author Justin
	 */
	public class AdSequenceGame extends AdGameTemplate
	{
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		public var _timeout:Number = 0; // when left as zero, then timer is disabled
		public var _timePenalty:Number = 10; //subtracts time for wrong choice
		public var _numRounds:Number = 1; //number of rounds
		// timer
		private var _textField:TextField;
		private var _time:Number = 0;
		private var _secs:Number = 0;
		private var _triggeredLose:Boolean = false;
		private var _currentSequence:Array; //current sequence in array
		private var _sequences:Array; //all sequences
		private var _currentStep:Number = 0;
		private var _mainEntities:Array; //main clip to house animations per round
		private var _clickableItems:Array;
		private var _popupEntity:Entity; //shows round/ingredients
		private var _wrongChoiceEntity:Entity; //small popup when wrong choice is selected
		private var _wrongChoiceMessageEntity:Entity; //message indicating lost time
		private var _init:Boolean = false;
		private var _currentRound:Number = 1;
		private var _roundWinAnimations:Array;
		private var _canPlayNextAnimation:Boolean = true;
		private var _closeRecipeButton:Entity;
		/**
		 * Constructor
		 */
		public function AdSequenceGame(container:DisplayObjectContainer = null)
		{
			super(container);
			id = "AdSequenceGame";
			_currentSequence = new Array();
			_sequences = new Array();
			_clickableItems = new Array();
			_roundWinAnimations = new Array();
			_mainEntities = new Array();
		}
		
		/**
		 * Setup game based on xml
		 * @param group
		 * @param xml
		 * @param hitContainer
		 */
		override public function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void {
			super.setupGame(scene, xml, hitContainer);
			setupClickables();
			_scene.ready.addOnce(setupPlayer);
			//gameSetUp.dispatch([this]);
			playerSelected();
			/*
			if(PlatformUtils.isMobileOS){
				trace("centering mobile");
				centerPopupToDeviceContent();
				
			}
			*/
		}
		public function centerPopupToDeviceContent():void
		{
			if(_scene.shellApi.screenManager.appScale){
				_scene.container.scaleX = _scene.container.scaleY = _scene.shellApi.screenManager.appScale;
			}
		}
		private function setupClickables():void {
			for(var i:int = 1; i <= _numRounds; i++){
				var rclip:MovieClip = MovieClip(_hitContainer.getChildByName("round"+i+"_base_mc"));
				var main:Entity = EntityUtils.createSpatialEntity(_scene,rclip);
				_mainEntities.push(TimelineUtils.convertClip(rclip, _scene, main));
			}
			
			_closeRecipeButton = ButtonCreator.createNewStandardButton(MovieClip(_hitContainer.getChildByName("closeRecipe")), _scene, recipeClickedClose);
			_closeRecipeButton.remove(ToolTipActive);
			_closeRecipeButton.remove(ToolTip);
			_popupEntity = TimelineUtils.convertClip(MovieClip(_hitContainer.getChildByName("popup")), _scene, _popupEntity);
			for(var p:int = 1; p <= _numRounds+1; p++){
				if(_hitContainer.getChildByName("round"+p+"Win") != null) {
					var win:Entity = EntityUtils.createSpatialEntity(_scene,_hitContainer.getChildByName("round"+p+"Win"));
					TimelineUtils.convertClip(MovieClip(_hitContainer.getChildByName("round"+p+"Win")), _scene, win);
					win.add(new Id("round"+p+"Win"));
					win.get(Timeline).gotoAndStop(0);
					win.get(Timeline).handleLabel("animComplete",winAnimationDone);
					win.get(Display).visible = false;
					_roundWinAnimations.push(win);
				}
			}
			_popupEntity.get(Timeline).gotoAndStop(0);
			for(var k:int = 1; k <= _numRounds+1; k++){
				_popupEntity.get(Timeline).handleLabel("recipe"+k+"CloseFull",Command.create(stopOnFrameTimeline,_popupEntity,"recipe"+k+"CloseFull"),false);
				_popupEntity.get(Timeline).handleLabel("recipe"+k+"OpenFull",Command.create(pauseOnFrameTimeline,_popupEntity,"recipe"+k+"OpenFull",3),false);
			} 
			for(var j:int = 0; j < _mainEntities.length; j++){
				_mainEntities[j].get(Timeline).gotoAndStop(0);
				if(j > 0) {
					_mainEntities[j].get(Display).visible = false;
				}
			}
			for each(var clip:String in _currentSequence){
				_clickableItems.push(ButtonCreator.createNewStandardButton(MovieClip(_hitContainer.getChildByName(clip)), _scene, objectClicked,objectOver,objectOut, clip));
				_mainEntities[_currentRound-1].get(Timeline).handleLabel(clip+"Stop",stopTimeline,false);
			}
			ButtonCreator.createNewStandardButton(MovieClip(_hitContainer.getChildByName("recipeClick")), _scene, recipeClicked);
			_wrongChoiceEntity = EntityUtils.createSpatialEntity(_scene,_hitContainer.getChildByName("wrongChoice"));
			_wrongChoiceEntity.get(Display).visible = false;
			_wrongChoiceMessageEntity = EntityUtils.createSpatialEntity(_scene,_hitContainer.getChildByName("wrongChoiceMsg"));
			_wrongChoiceMessageEntity.get(Display).alpha = 0;
			_popupEntity.get(Timeline).gotoAndPlay("round"+_currentRound+"Start");
			gameSetUp.dispatch(this);
			//SceneUtil.addTimedEvent(_scene,new TimedEvent(3, 1,playerSelected));
			
		}
		private function recipeClicked(entity:Entity):void {
			if(_popupEntity.get(Timeline).currentFrameData.label == "recipe"+_currentRound+"CloseFull") {
				_popupEntity.get(Timeline).gotoAndPlay("recipe"+_currentRound+"Open");
			}
		}
		private function winAnimationDone():void {
			if(_roundWinAnimations[_currentRound-1] != null) {
				_roundWinAnimations[_currentRound-1].get(Timeline).gotoAndStop(0);
				_roundWinAnimations[_currentRound-1].get(Display).visible = false;
			}
			if(_currentRound < _numRounds){
				_currentRound++;
				startNextRound();
			} else {
				winGame();
			}
		}
		private function pauseOnFrameTimeline(entity:Entity, frame:String, time:Number):void {
			entity.get(Timeline).gotoAndStop(frame);
			SceneUtil.addTimedEvent(_scene,new TimedEvent(time, 1,resumePlayingPopup));
			
		}
		private function resumePlayingPopup():void {
			if(_popupEntity.get(Timeline).currentFrameData.label == "recipe"+_currentRound+"OpenFull") {
				_popupEntity.get(Timeline).play();
			}
		}
		private function stopOnFrameTimeline(entity:Entity, frame:String):void {
			entity.get(Timeline).gotoAndStop(frame);
			if(frame == "recipe"+_currentRound+"CloseFull" && _init == false) {
				_playing = true;
				_init = true;
				if(_currentRound == 1) {
					if (_timeout != 0) {
						startTimer();
					}
					// start game
					startGame();
				}
			}
		}
		private function playOverSound():void {
			var randSound:Number = Math.floor(Math.random() * 5) + 1;
			AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + "metal_ball_tap_0" + Std.string(randSound) + ".mp3");
		}
		private function recipeClickedClose(entity:Entity):void {
			if(_popupEntity.get(Timeline).currentFrameData.label == "recipe"+_currentRound+"OpenFull") {
				_popupEntity.get(Timeline).gotoAndPlay("recipe"+_currentRound+"Close");
			}
		}
		private function stopTimeline():void {
			_mainEntities[_currentRound-1].get(Timeline).stop();
			_canPlayNextAnimation = true;
			if(_currentStep == _currentSequence.length) {
				AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + "achievement_01.mp3");
				_playing = false;
				stopTimer();
				var win:Entity = _roundWinAnimations[_currentRound-1];
				if(win != null) {
					win.get(Display).visible = true;
					win.get(Timeline).gotoAndPlay(1);
				} else {
					winAnimationDone();
				}
				
				
			}
			
		}
		private function getClickableEntity(id:String):Entity {
			for each(var entity:Entity in _clickableItems){
				if(entity.get(Id).id == id) {
					return entity; 
				}
			}
			return null;
		}
		
		private function objectClicked(entity:Entity):void {
			if(_canPlayNextAnimation == true && _playing == true && _popupEntity.get(Timeline).currentFrameData.label == "recipe"+_currentRound+"CloseFull") {
				var id:String = entity.get(Id).id;
				trace(id + " clicked");
				if(_currentSequence[_currentStep] == id){
					trace("correct sequence");
					AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + "points_ping_01a.mp3");
					getClickableEntity(id).get(Display).visible = false;
					var timeline:Timeline = _mainEntities[_currentRound-1].get(Timeline);
					timeline.gotoAndPlay(id);
					_canPlayNextAnimation = false;
					// _hitContainer.getChildClip("base_mc").gotoAndPlay(id);
					_currentStep++;
					
				} else {
					
					_wrongChoiceEntity.get(Spatial).x =  -DisplayUtils.mouseXY( getClickableEntity(id).get(Display).displayObject).x + getClickableEntity(id).get(Spatial).x;
					_wrongChoiceEntity.get(Spatial).y =  -DisplayUtils.mouseXY( getClickableEntity(id).get(Display).displayObject).y + getClickableEntity(id).get(Spatial).y;
					_wrongChoiceMessageEntity.get(Display).alpha = 1;
					
					var tween:Tween = new Tween();
					tween.to(_wrongChoiceMessageEntity.get(Display), 2, {
						alpha : 0
					});
					
					_wrongChoiceMessageEntity.add(tween);
					if(  _wrongChoiceEntity.get(Display).visible == false) {
						_wrongChoiceEntity.get(Display).visible = true;
						//ColorUtil.tint(DisplayObjectContainer(MovieClip(_hitContainer.getChildByName("hud")).getChildByName("timer")), 0xFF0000, 66);
						SceneUtil.addTimedEvent(_scene,new TimedEvent(1.5, 1,resetTimerColor));
						
					}
					AudioUtils.play(_scene, SoundManager.EFFECTS_PATH + "miss_points_01.mp3");
					_timeout -= _timePenalty;
				}
			}
		}
		private function startNextRound():void {
			_mainEntities[_currentRound-2].get(Display).visible = false;
			_mainEntities[_currentRound-1].get(Display).visible = true;
			_init = false;
			_popupEntity.get(Timeline).gotoAndPlay("round"+_currentRound+"Start");
			startTimer();
			_currentStep = 0;
			_currentSequence = _sequences[_currentRound-1].split(",");
			_clickableItems = new Array();
			for each(var clip:String in _currentSequence){
				_hitContainer.getChildByName(clip).visible = true;
				_clickableItems.push(ButtonCreator.createNewStandardButton(MovieClip(_hitContainer.getChildByName(clip)), _scene, objectClicked,objectOver,objectOut, clip));
				_mainEntities[_currentRound-1].get(Timeline).handleLabel(clip+"Stop",stopTimeline,false);
			}
			// _playing = true;
			
		}
		private function resetTimerColor():void {
			if(_secs > (_timeout * .2)){
				MovieClip(_hitContainer.getChildByName("hud")).getChildByName("timer").transform.colorTransform = new ColorTransform();
			}
			_wrongChoiceEntity.get(Display).visible = false;
		}
		private function objectOver(entity:Entity):void {
			playOverSound();
		}
		private function objectOut(entity:Entity):void {
			if (entity.get(Display).displayObject.transform.colorTransform != null) {
				entity.get(Display).displayObject.transform.colorTransform = new ColorTransform();
			}
		}
		override public function playerSelection(selection:int = 0):void{
			//_popupEntity.getTimeline().gotoAndPlay("round"+_currentRound+"Start");
			if (_timeout != 0) {
				startTimer();
			}
			// start game
			startGame();
			
		}
		private function setupPlayer(...args):void {
			_scene.removeEntity(_scene.shellApi.player);
			_scene.shellApi.defaultCursor = ToolTipType.CLICK;
			var hud:Hud = _scene.getGroupById(Hud.GROUP_ID) as Hud;
			if(hud._actionBtn){
				hud._actionBtn.get(Display).visible = false;
			}
		}
		private function startTimer():void {
			_time = getTimer();
			_secs = _timeout;
			_textField = TextField(MovieClip(_hitContainer.getChildByName("hud")).getChildByName("timer"));
			_textField.addEventListener(Event.ENTER_FRAME, fnTimer);
			
		}
		public function stopTimer():void {
			if (_textField != null) {
				_textField.removeEventListener(Event.ENTER_FRAME, fnTimer);
			}
		}
		// timer enterFrame event
		private function fnTimer(e:Event):void {
			if(_playing == true) {
				var vSecs:Number = Math.floor(_timeout - (getTimer() - _time) / 1000);
				if (vSecs != _secs) {
					// don't allow negative times
					
					if (vSecs < 0) {
						vSecs = 0;
					}
					
					_secs = vSecs;
					fnShowTime();
					if ((vSecs == 0) && (!_triggeredLose)) {
						//removeHUD();
						//removeEndMessage();
						loseGame();
					}
				}
			}
		}
		// update timer display
		private function fnShowTime():void {
			var vMins:Number = Math.floor(_secs / 60);
			var vLeft:Number = _secs - vMins * 60;
			var vDigits:String = "0";
			if (vLeft < 10) {
				vDigits += Std.string(vLeft);
			} else {
				vDigits = Std.string(vLeft);
			}
			_textField.text = String(vMins) + ":" + vDigits;
			if(_secs < (_timeout * .2)){
				//ColorUtil.tint(DisplayObjectContainer(MovieClip(_hitContainer.getChildByName("hud")).getChildByName("timer")), 0xFF0000, 66);
			}
		}
		
		/**
		 * Parse game xml for game parameters
		 * @param xml
		 */
		override protected function parseXML(xml:XML):void {
			parseGameXML(xml);
			_timeout = Number(xml.timeout);
			_numRounds = Number(xml.numRounds);
			_currentSequence = xml.sequence1.split(',');

			var items:XMLList = xml.children();
			// for each group in xml
			for (var i:int = items.length() - 1; i != -1; i--)
			{
				var value:String = items[i].valueOf();
				var propID:String = items[i].name();
				if(propID.indexOf("sequence") != -1) {
					trace(value);
					_sequences.push(value);
				}
			}
			_sequences.reverse();
			
			_timePenalty = Number(xml.timePenalty);
			// this sets up looks and needs to follow parseGameXML or else _looks gets overwritten
			super.parseXML(xml);
		}
		
		
		
		/**
		 * Start game w
		 */
		private function startGame():void {
			
		}
		
		
		/**
		 * When game ends
		 */
		private function endGame():void {
			_playing = false;
			stopTimer();
		}
		
		/**
		 * When lose game
		 */
		private function loseGame():void {
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
		
		
		override public function destroy():void {
			stopTimer();
			super.destroy();
		}
		
		private var _hudTimeline:Timeline;
		private var _playing:Boolean = false;
		
	}
}
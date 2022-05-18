package game.scene.template.ads
{
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ads.shared.AdGameTemplate;
	import game.scenes.custom.questGame.QuestGame;
	import game.ui.elements.BasicButton;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class AdMemoryGame extends AdGameTemplate
	{
		
		// private vars
		public var _victory:Signal = new Signal();
		public var _lost:Signal = new Signal();
		
		private var tiles:Array;								//tiles <entity>
		private var buttons:Array;								//tile interaction		
		private var _numSwaps:int = 42;							//how many times tiles are swapped
		private var _numTiles:int = 20;							//number of tiles
		private var _waitTime:Number = 7;						//wait time to show player cards before shuffling
		private var _tweenSpeed:Number = .1;					//speed for shuffle anim
		private var _firstTileClicked:Boolean = false;			// flag for first tile clicked
		private var _firstTile:Entity;							//first clicked tile to compare against
		private var _timer:TextField;							//timer textfield
		private var _timeOut:Number = 0;						//timeout
		private var _time:Number;								//timer display
		private var _secs:Number;								//timer display
		private var _playing:Boolean = false;					// flag after done shuffling and player can play
		private var _comparing:Boolean = false;					//dont allow other tiles ot be clicked while comparing
		private var _matchesLeft:Number = 10;					//matches left to get
		private var _matchesLeftTF:TextField;					//matches left textfield
		private var _correctSFX:String ="";						//correct match sound
		private var _incorrectSFX:String="";					//incorrect match sound
		private var _correctAnimation:Entity = null;			//animation to play on successful math
		private var _locked:Boolean =  false;
		
		// INITIALIZATION FUNCTIONS /////////////////////////////////////////////////////////////////////
		
		/**
		 * Constructor 
		 */
		public function AdMemoryGame()
		{
			this.id = "AdMemoryGame";
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
			/*
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
			*/
			
			var _correctAnimationMC:MovieClip = _hitContainer["correctAnimation"];
			if(_correctAnimationMC != null) {
				_correctAnimation = TimelineUtils.convertClip(_correctAnimationMC, _scene);
				var timeline:Timeline = _correctAnimation.get(Timeline);
				timeline.gotoAndStop(0);
				timeline.handleLabel("stopAnimation", Command.create(stopAnimation, timeline), false);
				
			}
			gameSetUp.dispatch(this);
			playerSelection();
		}
		
		
		/**
		 * Parse game xml for game parameters
		 * @param xml
		 */
		override protected function parseXML(xml:XML):void
		{
			// note: returnX and returnY are pulled from QuestGame.as
			
			if (String(xml.tweenSpeed) != "")
				_tweenSpeed = Number(xml.tweenSpeed);
			
			if (String(xml.numShuffles) != "")
				_numSwaps = Number(xml.numShuffles);
			
			if (String(xml.waitTime) != "")
				_waitTime = Number(xml.waitTime);
			
			if (String(xml.numTiles) != ""){
				_numTiles = Number(xml.numTiles);
				_matchesLeft = (_numTiles/2);
			}
			
			if (String(xml.timeOut) != "")
				_timeOut = Number(xml.timeOut);
			
			if(String(xml.correctSFX) != "")
				_correctSFX = xml.correctSFX;
			
			if(String(xml.incorrectSFX) != "")
				_incorrectSFX = xml.incorrectSFX;
			
			_timer = _hitContainer["timer"];
			if(_timer != null)
				_timer.addEventListener(Event.ENTER_FRAME,fnTimer);
			
			_matchesLeftTF = _hitContainer["matchesLeft"];
			if(_matchesLeftTF != null)
				_matchesLeftTF.text = _matchesLeft.toString();
			
			
		}
		private function startTimer():void
		{
			_time = getTimer();
			_secs = _timeOut / 1000;
		}
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
			_timer.text = String(vMins) + ":" + vDigits;
		}
		// timer enterFrame event
		private function fnTimer(e:Event):void
		{
			if(_playing == true) {
				var vSecs:Number = Math.floor(_timeOut - (getTimer() - _time) / 1000);
				if (vSecs != _secs)
				{
					// don't allow negative times
					if (vSecs < 0)
						vSecs = 0;
					
					_secs = vSecs;
					fnShowTime();
					if ((vSecs == 0) && (_playing == true))
					{
						QuestGame(_scene).loadLosePopup();
						_playing = false;
						//removeHUD();
						//removeEndMessage();
						//triggerLose();
						
					}
				}
			}
		}
		public function centerPopupToDeviceContent():void
		{
			
				if(_scene.shellApi.screenManager.appScale){
					//
					//_scene.container.y = 0;
					//_scene.resize(_scene.shellApi.viewportWidth, _scene.shellApi.viewportHeight);
					_scene.container.scaleX = _scene.container.scaleY = _scene.shellApi.screenManager.appScale;
					//_scene.container.x = _scene.shellApi.viewportWidth/2;
					//_scene.container.y = _scene.shellApi.viewportHeight/2;
					
				}
			
			
		}
		private function setupPlayer(...p):void {
			_scene.removeEntity(_scene.shellApi.player);
			//_scene.shellApi.defaultCursor = ToolTipType.CLICK;
		}
		private function setupStart():void
		{
			//_scene.shellApi.defaultCursor = ToolTipType.TARGET;
			//EntityUtils.getDisplay(_scene.shellApi.player).visible = false;
			//CharUtils.lockControls(_scene.shellApi.player);
			//_scene.removeEntity(_scene.shellApi.player);
			_scene.ready.addOnce(setupPlayer);
			
			// Array of tile entites
			tiles = new Array();
			var pairedTiles:Array =  new Array();
			var paired:Boolean = false;
			var pairCounter:Number = 10;
			var frame:Number = 1;
			for(var j:int = 1; j <= _numTiles; j++)
			{
				pairedTiles.push(j);
			}
			for(var i:int = 1; i <= _numTiles; i++)
			{
				var figure:MovieClip = MovieClip(_hitContainer["t" + i]["flip"]["figure"]);
				
					var rand:Number = randomMinMax(pairedTiles.length);
					frame = pairedTiles[rand] + 1;
					trace("frame: " + frame);
					pairedTiles.removeAt(rand);
				
				
				figure.gotoAndStop(frame);
				
				var tile:MovieClip = MovieClip(_hitContainer["t" + i]);
				var tileEntity:Entity = TimelineUtils.convertClip(tile, _scene);
				tileEntity.add(new Display(tile));
				tileEntity.add(new Spatial(tile.x, tile.y));
				
				var timeline:Timeline = tileEntity.get(Timeline);
				timeline.gotoAndStop("flipOver");
				tiles.push(tileEntity);
			}
			
			
			
			SceneUtil.addTimedEvent(_scene, new TimedEvent(_waitTime, 1, flipTiles));
			
		}
		
		
		private function flipTiles():void
		{
			_scene.shellApi.triggerEvent("majong_all_flip");
			for each(var tile:Entity in tiles)
			{
				// flip the tiles over and listen for when they are done
				var timeline:Timeline = tile.get(Timeline);
				timeline.gotoAndPlay("flipOver");
				timeline.handleLabel("overDone", Command.create(flippedOver, timeline), false);
				timeline.handleLabel("flipped", Command.create(onFlipped, tile), false);
				timeline.handleLabel("unflipped", Command.create(onFlipped, tile), false);
			}
		}
		
		private function stopAnimation(timeline:Timeline):void
		{
			timeline.gotoAndStop("stopAnimation");
		}
		// When its halfway done flipping change its visibility
		private function onFlipped(entity:Entity):void
		{
			var mc:MovieClip = MovieClip(Display(entity.get(Display)).displayObject);
			MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("figure")).visible = !MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("figure")).visible;
			MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("logo")).visible = !MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("logo")).visible;

		}
		
		private var counter:int = 0;
		private function flippedOver(timeline:Timeline):void
		{
			counter++;
			timeline.stop();
			if(_playing == false)
			{
				if(_locked == false)
				{
					//SceneUtil.lockInput(_scene,true);
					//CharUtils.lockControls(_scene.shellApi.player,true);
					_locked = true;
				}
				if(counter >= _numTiles)
				{
					swapTiles(tiles[Math.floor(Math.random() * _numTiles)], tiles[Math.floor(Math.random() * _numTiles)]);
				}
			}
			else
			{
				//SceneUtil.lockInput(_scene,false);
				//CharUtils.lockControls(_scene.shellApi.player,false);
			}
		}
		
		private function swapTiles(tile1:Entity, tile2:Entity):void
		{
			_scene.shellApi.triggerEvent("majong_swap");
			var tile1MC:MovieClip = MovieClip(Display(tile1.get(Display)).displayObject);
			var tile2MC:DisplayObject = tile2.get(Display).displayObject
			var tile1Spatial:Spatial = tile1.get(Spatial);
			var tile2Spatial:Spatial = tile2.get(Spatial);
			
			var tile1Pos:Point = new Point(tile1Spatial.x, tile1Spatial.y);
			var tile2Pos:Point = new Point(tile2Spatial.x, tile2Spatial.y);
			
			tile1MC.parent.setChildIndex(tile1MC, tile1MC.parent.numChildren-1);
			tile2MC.parent.setChildIndex(tile2MC, tile2MC.parent.numChildren-1);
						
			TweenUtils.entityTo(tile1, Spatial, _tweenSpeed, {x: tile2Pos.x, y:tile2Pos.y});
			TweenUtils.entityTo(tile2, Spatial, _tweenSpeed, {x: tile1Pos.x, y: tile1Pos.y, onComplete: tweensCompleted});
		}
		
		private function tweensCompleted():void
		{
			_numSwaps--;
			if(_numSwaps > 0)
			{
				swapTiles(tiles[Math.floor(Math.random() * _numTiles)], tiles[Math.floor(Math.random() * _numTiles)]);
			}
			else
			{
				
				
				buttons = new Array();
				for each(var tile:Entity in tiles)
				{
					ToolTipCreator.addToEntity(tile,ToolTipType.CLICK);
					var basicBtn:BasicButton = ButtonCreator.createBasicButton(tile.get(Display).displayObject, [InteractionCreator.CLICK], _scene);
					basicBtn.click.add(Command.create(tileClicked, tile));
					buttons.push(basicBtn);
				}
				_scene.shellApi.defaultCursor = ToolTipType.CLICK;
				_playing = true;
			}
		}
		
		private function tileClicked(e:Event, tile:Entity):void
		{
			if(_comparing == false)
			{
				_scene.shellApi.triggerEvent("majong_single_flip");
				//for each(var button:BasicButton in buttons)
				//button.removeSignals();
				var tileMC:MovieClip = MovieClip(Display(tile.get(Display)).displayObject);
				var figure:MovieClip = MovieClip(tileMC.flip.figure);
				
				if(figure.visible == false){
				if(_firstTileClicked == true && _firstTile.get(Id).id != tile.get(Id).id)
				{
					_comparing = true;
					var timeline:Timeline = tile.get(Timeline);
					timeline.gotoAndPlay("flipUp");
					timeline.handleLabel("upDone", Command.create(flippedBack, timeline), false);
					
				
					
					//compare frames
					var firstTileMC:MovieClip = MovieClip(Display(_firstTile.get(Display)).displayObject);
					var firstFigure:MovieClip = MovieClip(firstTileMC.flip.figure);
					
					trace("comparing " + figure.currentFrame + " and "+ firstFigure.currentFrame);
					
					if(figure.currentFrame + (_numTiles/2) == firstFigure.currentFrame || figure.currentFrame == firstFigure.currentFrame + (_numTiles/2))
					{
						if(_correctSFX != "")
						{
							AudioUtils.play(_scene,_correctSFX);
						}
						if(_correctAnimation != null) {
							//make sure it is on top of game
							DisplayUtils.moveToTop(TimelineClip(_correctAnimation.get(TimelineClip)).mc);
							_correctAnimation.get(Timeline).gotoAndPlay("playAnimation");
						}
						_matchesLeft--;
						if(_matchesLeftTF != null) {
							_matchesLeftTF.text = _matchesLeft.toString();
						}
						if(_matchesLeft == 0)
						{
							QuestGame(_scene).loadWinPopup();
						}
						_comparing = false;
					}
					else
					{
						if(_incorrectSFX != "")
						{
							AudioUtils.play(_scene,_incorrectSFX);
						}
						SceneUtil.addTimedEvent(_scene, new TimedEvent(2, 1, Command.create(wrongChoice,tile)));
						
	
					}
					_firstTileClicked = false;
					//_firstTile = null;
					
				}
				else
				{
					if(_firstTile != null) {
						if(_firstTile.get(Id).id != tile.get(Id).id) {
							var timeline3:Timeline = tile.get(Timeline);
							timeline3.gotoAndPlay("flipUp");
							timeline3.handleLabel("upDone", Command.create(flippedBack, timeline3), false);
							
							var tileMC2:MovieClip = MovieClip(Display(tile.get(Display)).displayObject);
							var figure3:MovieClip = MovieClip(tileMC2.flip.figure);
							_firstTile = tile;
							_firstTileClicked = true;
						}
					} else {
						var timeline2:Timeline = tile.get(Timeline);
						timeline2.gotoAndPlay("flipUp");
						timeline2.handleLabel("upDone", Command.create(flippedBack, timeline2), false);
						
						var tileMC3:MovieClip = MovieClip(Display(tile.get(Display)).displayObject);
						var figure2:MovieClip = MovieClip(tileMC3.flip.figure);
						_firstTile = tile;
						_firstTileClicked = true;
					}
					
				}
				
				}
			}
		}
		private function wrongChoice(tile:Entity):void
		{
			Timeline(tile.get(Timeline)).gotoAndPlay("flipOver");
			Timeline(_firstTile.get(Timeline)).gotoAndPlay("flipOver");
			_comparing = false;
			_firstTile = null;
			//Timeline(_firstTile.get(Timeline)).handleLabel("overDone", Command.create(flippedBackOver, _firstTile), true);
			//Timeline(tile.get(Timeline)).handleLabel("overDone", Command.create(flippedBackOver, tile), true);
		
		}
		private function flippedBackOver(tile:Entity):void
		{
			var mc:MovieClip = MovieClip(Display(tile.get(Display)).displayObject);
			MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("figure")).visible = !MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("figure")).visible;
			MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("logo")).visible = !MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("logo")).visible;
			
			var mc2:MovieClip = MovieClip(Display(_firstTile.get(Display)).displayObject);
			MovieClip(MovieClip(mc2.getChildByName("flip")).getChildByName("figure")).visible = !MovieClip(MovieClip(mc2.getChildByName("flip")).getChildByName("figure")).visible;
			MovieClip(MovieClip(mc2.getChildByName("flip")).getChildByName("logo")).visible = !MovieClip(MovieClip(mc2.getChildByName("flip")).getChildByName("logo")).visible;
			
			Timeline(tile.get(Timeline)).stop();
			Timeline(_firstTile.get(Timeline)).stop();
		
		}
		private function flippedBack(timeline:Timeline):void
		{
			timeline.stop();
		}
		private function gameOver(evt:TimerEvent, win:Boolean):void {
			if(win == true) {
				QuestGame(_scene).loadWinPopup();
			} else {
				QuestGame(_scene).loadLosePopup();
			}
		}
		/**
		 * Setup player based on selection from AdChoosePopup
		 * @param selection player selection (starts at 1, if zero, then use "player")
		 */
		override public function playerSelection(selection:int = 0):void
		{
			trace("select player " + selection);

			//centerPopupToDeviceContent();
			if(PlatformUtils.isMobileOS){
				trace("centering mobile");
				centerPopupToDeviceContent();
				
			}
				// start game and race
				//playing = true;
			
			//setupStart();
			super.playerSelected();
			setupStart();
			if(_timeOut != 0)
			{
				startTimer();
			}
		}
		
		
		private function randomMinMax(maxNum:Number ):Number
		{
			var num:Number = Math.floor(Math.random() * maxNum);
			trace(num);
			return num;
		}
		
		/**
		 * When game ends 
		 */
		private function endGame():void
		{
			//playing = false
			
			// remove system
			//_scene.removeSystemByClass(TopDownBitmapGameSystem);
			
		}
		
		/**
		 * When lose game 
		 */
		public function loseGame():void
		{			
			QuestGame(_scene).loadLosePopup();
		}
		
		/**
		 * When win game 
		 */
		public function winGame():void
		{
			// load win popup
			QuestGame(_scene).loadWinPopup();
		}
	}
}


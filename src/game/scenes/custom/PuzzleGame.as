package game.scenes.custom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.motion.Draggable;
	import game.components.ui.ToolTip;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManager;
	import game.scenes.custom.puzzleSystems.PuzzleSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.DraggableSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class PuzzleGame extends AdGamePopup
	{
		private var xmlPath:String; // path to puzzle xml
		private var puzzleSystem:PuzzleSystem;
		
		// these are accessed by PuzzleSystem
		public var count:int = 0; // piece counter
		public var currentTimeout:Number; // current timeout value
		public var currentNumPieces:int; // current number of pieces
		public var doWait:Boolean = false; // wait for end dialog flag
		
		private var currentPuzzle:int = 0; // current puzzle number
		private var bubbleEntity:Entity; // reference to bubble text entity
		private var currentID:String = ""; // id of current puzzle piece
		private var currentEntity:Entity; // referenct to current puzzle entity
		private var startX:Number; // starting pos of puzzle piece
		private var startY:Number; // starting pos of puzzle piece
		private var currentShadow:int = -1; // current silhouette hilited

		// params from xml file
		public var _numPuzzles:Number; // number of puzzles
		public var _numPieces:Array; // number of puzzle pieces
		public var _timeouts:Array; // timeouts in seconds
		public var _snapThreshold:Number = 80; // threshold for snapping
		public var _waitTime:Number = 1.5; // wait time before next puzzle or win popup
		public var _startColor:uint = 1; // start color for silhouettes
		public var _hiliteColor:uint = 1; // hilight color for rollovers
		public var _returnPosX:Number = 0;		
		public var _returnPosY:Number = 0;
		public var _popSound:String; // sound effect for snapping piece in place

		// bubble params from xml file
		public var _hasBubble:Boolean = false; // has bubble
		public var _segmentTime:Number = 5; // time for each segment of speech bubble
		public var _messageTime:Number = 4; // time that speech bubble is up
		public var _fadeTime:Number = 2; // time for speech bubble to fade
		public var _startText:Array; // start bubble text
		public var _encouragementText:Array; // encouragement text
		public var _struggleText:Array; // struggle text
		public var _endText:Array; // end text
			
		/**
		 * When swf loaded
		 */
		override protected virtual function loadedSwf(clip:MovieClip):void
		{
			super.loadedSwf(clip);
			// setup background to make it clickable and force arrow cursor
			var buttonEntity:Entity = setupButton( clip.back, swallowClicks, false);
			var toolTipEntity:Entity = EntityUtils.getChildById(buttonEntity, "tooltip", false);
			toolTipEntity.get(ToolTip).type = ToolTipType.ARROW;
		}
		
		/**
		 * Setup specific popup buttons 
		 */
		override protected function setupPopup():void
		{
			// stop on first puzzle
			super.screen.gotoAndStop(1);
			
			// move avatar in scene
			if (_returnPosX != 0)
			{
				super.shellApi.player.get(Spatial).x = _returnPosX;
				super.shellApi.player.get(Spatial).y = _returnPosY;
			}
			
			// setup bubble text entity
			if (_hasBubble)
			{
				bubbleEntity = EntityUtils.createSpatialEntity(this, super.screen.bubble);
			}
			
			// add system
			this.addSystem( new DraggableSystem() );

			// setup first puzzle
			setupPuzzle();
		}
		
		/**
		 * Setup individual puzzle 
		 */
		private function setupPuzzle():void
		{
			// reset variables
			count = 0;
			doWait = false;
			currentTimeout = _timeouts[currentPuzzle];
			currentShadow = -1;
			
			// show start message
			showMessage(_startText[currentPuzzle]);
			
			// for each piece
			currentNumPieces = _numPieces[currentPuzzle];
			for (var i:int = 0; i != currentNumPieces; i++)		
			{
				var id:String = "p" + (currentPuzzle + 1) + (i + 1);
				trace("piece " + id + this.screen[id]);
				var entity:Entity = EntityUtils.createSpatialEntity(this, this.screen[id]);
				entity.add( new Id(id));
				
				// remember starting index
				var clip:MovieClip = MovieClip(this.screen[id]);
				clip.startIndex = clip.parent.getChildIndex(clip);
				
				// if more than one frame, then stop at frame 1
				if (clip.totalFrames != 1)
					clip.gotoAndStop(1);
				
				// interations
				InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
				ToolTipCreator.addToEntity(entity);
				entity.add(new Draggable());
				
				var draggable:Draggable = entity.get( Draggable );	
				draggable.drag.add( pieceDown );
				draggable.drop.add( pieceUp );
			}
			
			// init puzzle system
			puzzleSystem = PuzzleSystem(this.addSystem( new PuzzleSystem(this), SystemPriorities.update ));
		}
		
		/**
		 * Mousedown on piece
		 */
		private function pieceDown(entity:Entity):void
		{
			// set current piece
			currentEntity = entity;
			currentID = entity.get(Id).id;
			
			// get starting position
			startX = entity.get(Spatial).x;
			startY = entity.get(Spatial).y;
		}
		
		/**
		 * Mouseup on piece (when done dragging)
		 */
		private function pieceUp(entity:Entity):void
		{
			// check match to shadow piece
			var shadowPiece:MovieClip = this.screen["s" + currentID.substr(1)];
			
			if (currentEntity == null)
				return;
			
			// calculate distance to shadow piece
			var distX:Number = shadowPiece.x - currentEntity.get(Spatial).x;
			var distY:Number = shadowPiece.y - currentEntity.get(Spatial).y;
			var dist:Number = Math.sqrt(distX*distX + distY*distY);
			
			// if within threshold
			if (dist <= _snapThreshold)
			{
				// snap to shadow piece
				currentEntity.get(Spatial).x = shadowPiece.x;
				currentEntity.get(Spatial).y = shadowPiece.y;
				currentEntity.get(Spatial).rotation = 0;
				
				if (_popSound != null)
					AudioUtils.play(super.shellApi.sceneManager.currentScene, SoundManager.EFFECTS_PATH + _popSound);
				
				// restore original index
				var clip:MovieClip = MovieClip(currentEntity.get(Display).displayObject);
				clip.parent.setChildIndex(clip, clip.startIndex);
				
				// go to frame two if there is one
				if (clip.totalFrames != 1)
					clip.gotoAndStop(2);
				
				// prevent further dragging
				currentEntity.remove(Draggable);
				
				// remove tooltip
				ToolTipCreator.removeFromEntity(currentEntity);
				
				// increment counter
				count++;
				// if have all pieces
				if (count == _numPieces[currentPuzzle])
				{
					// show end message
					showMessage(_endText[currentPuzzle]);
					// wait for end message
					doWait = true;
					SceneUtil.delay(this, _waitTime, endPuzzle);
				}
			}
			// if no match, then put back into starting position
			else
			{
				currentEntity.get(Spatial).x = startX;
				currentEntity.get(Spatial).y = startY;
			}
			// clear current piece
			currentEntity = null;
			currentID = "";
		}
		
		/**
		 * Show bubble text message
		 */
		public function showMessage(messageText:String):void
		{
			if (_hasBubble)
			{
				// remove tween if already tweening
				bubbleEntity.remove( Tween );
				// force visible
				bubbleEntity.get(Display).alpha = 1.0;
				// update message
				var message:TextField = bubbleEntity.get(Display).displayObject.message;
				message.text = messageText;
				bubbleEntity.get(Display).displayObject.box.width = message.textWidth + 14;
				// fade bubble after message time
				TweenUtils.entityTo(bubbleEntity, Display, _fadeTime, {alpha:0, onComplete:endFade}, "fadeBubble", _messageTime);
			}
		}
		
		/**
		 * When text message is done fading
		 */
		private function endFade():void
		{
			bubbleEntity.remove( Tween );
			bubbleEntity.get(Display).alpha = 0;
		}
		
		/**
		 * Check rollover on silhouettes
		 */
		public function checkRollovers():void
		{
			if (_startColor == 1)
				return;
			
			var puzzleNum:int = currentPuzzle + 1;
			var over:int = -1;
			var overClip:MovieClip;

			// for each piece
			for (var i:int = 0; i != currentNumPieces; i++)				
			{
				var id:String = "s" + puzzleNum + (i + 1);
				var clip:MovieClip = this.screen[id];
				if (clip == null)
				{
					trace("shadow clip " + id + " is not found!");
				}
				// if mouse if over, then remember (pieces with higher values will override)
				else if (clip.hitTestPoint(this.screen.stage.mouseX, this.screen.stage.mouseY, true))
				{
					over = i + 1;
					overClip = clip;
				}
			}
			// if new piece
			if (currentShadow != over)
			{
				// colorize new piece
				if (over != -1)
				{
					var color:ColorTransform = new ColorTransform();
					color.color = _hiliteColor;
					overClip.transform.colorTransform = color;
				}

				// restore old piece
				if (currentShadow != -1)
				{
					id = "s" + puzzleNum + currentShadow;
					clip = this.screen[id];
					color = new ColorTransform();
					color.color = _startColor;
					clip.transform.colorTransform = color;
				}
				
				// remember piece
				currentShadow = over;
			}
		}

		/**
		 * swallow mouse clicks on background
		 */
		private function swallowClicks(entity:Entity):void
		{
		}
		
		// END FUNCTIONS //////////////////////////////////////////////////////////////////
		
		/**
		 * End puzzle 
		 */
		public function endPuzzle():void
		{
			// clear puzzle system
			this.removeSystem(puzzleSystem);
			
			// remove previous puzzle pieces
			var pieces:int = _numPieces[currentPuzzle];
			for (var i:int = 0; i!=pieces; i++)
			{
				var id:String = "p" + (currentPuzzle + 1) + (i + 1);
				this.removeEntity(this.getEntityById(id));
			}
			
			// increment to next puzzle
			currentPuzzle++;
			
			// end game if done all puzzles
			if (currentPuzzle == _numPuzzles)
			{
				endGame(true);
			}
			else
			{
				// else start next puzzle
				this.screen.nextFrame();
				setupPuzzle();
			}
		}
		
		/**
		 * End game 
		 */
		public function endGame(win:Boolean = false):void
		{
			// if win false, then remove puzzle system
			if (!win)
				this.removeSystem(puzzleSystem);
			
			if (win)
				winGame();
			else
				gameOver();
		}
		
		/**
		 * Close popup
		 * @param button
		 */
		override protected function closePopup(button:Entity):void
		{
			AdManager(super.shellApi.adManager).track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLOSE_GAME_POPUP, _trackingChoice);
			endGame();
		}
	}
}
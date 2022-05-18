package game.scenes.time.china
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.ui.elements.BasicButton;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class MemoryGame extends Popup
	{
		public function MemoryGame(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
			
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{			
			super.pauseParent = true;
			super.darkenBackground = true;
			super.groupPrefix = "scenes/time/china/";
			super.init(container);
			load();
		}
		
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			// Load in swf
			super.loadFiles(new Array("memoryGame.swf"));
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset("memoryGame.swf", true) as MovieClip;	
			super.layout.centerUI(super.screen.content);
			var content:MovieClip = MovieClip(super.screen.content);
			content.scaleX = content.scaleY = 1.35;
			super.loadCloseButton();
			super.loaded();			
			setupStart();
		}
		
		private function setupStart():void
		{
			// The bubble starts of not visible and grows onto the screen
			var bubble:MovieClip = MovieClip(super.screen.content.instructions.bubble);
			bubbleEntity = EntityUtils.createSpatialEntity(this, bubble, super.screen.content.instructions);
			var spatial:Spatial = bubbleEntity.get(Spatial);
			spatial.scaleX = spatial.scaleY = .01;
			
			targetNum = Math.ceil(Math.random() * NUM_TILES);
			
			var target:MovieClip = MovieClip(super.screen.content.instructions.tile.flip.figure);
			target.gotoAndStop(targetNum);
			var intructionTile:MovieClip = MovieClip(super.screen.content.instructions.tile);
			intructionTile.gotoAndStop(1);
			
			// Array of tile entites
			tiles = new Array();
			for(var i:int = 1; i <= NUM_TILES; i++)
			{
				var figure:MovieClip = MovieClip(super.screen["content"]["t" + i]["flip"]["figure"]);
				figure.gotoAndStop(i);
				
				var tile:MovieClip = MovieClip(super.screen["content"]["t" + i]);
				var tileEntity:Entity = TimelineUtils.convertClip(tile, this);
				tileEntity.add(new Display(tile));
				tileEntity.add(new Spatial(tile.x, tile.y));
				
				var timeline:Timeline = tileEntity.get(Timeline);
				timeline.gotoAndStop("flipOver");
				tiles.push(tileEntity);
			}
			
			growBubble(.4);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(WAIT_TIME, 1, flipTiles));
		}
		
		private function flipTiles():void
		{
			shellApi.triggerEvent("majong_all_flip");
			for each(var tile:Entity in tiles)
			{
				// flip the tiles over and listen for when they are done
				var timeline:Timeline = tile.get(Timeline);
				timeline.gotoAndPlay("flipOver");
				timeline.handleLabel("overDone", Command.create(flippedOver, timeline), true);
				timeline.handleLabel("flipped", Command.create(onFlipped, tile), true);
				timeline.handleLabel("unflipped", Command.create(onFlipped, tile), true);
			}
			shrinkBubble(.3);
		}
		
		// When its halfway done flipping change its visibility
		private function onFlipped(entity:Entity):void
		{
			var mc:MovieClip = MovieClip(Display(entity.get(Display)).displayObject);
			MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("figure")).visible = !MovieClip(MovieClip(mc.getChildByName("flip")).getChildByName("figure")).visible;
		}
		
		private var counter:int = 0;
		private function flippedOver(timeline:Timeline):void
		{
			counter++;
			timeline.stop();
			if(counter >= NUM_TILES)
			{
				swapTiles(tiles[Math.floor(Math.random() * NUM_TILES)], tiles[Math.floor(Math.random() * NUM_TILES)]);
			}
		}
		
		private function swapTiles(tile1:Entity, tile2:Entity):void
		{
			shellApi.triggerEvent("majong_swap");
			var tile1MC:MovieClip = MovieClip(Display(tile1.get(Display)).displayObject);
			var tile2MC:DisplayObject = tile2.get(Display).displayObject
			var tile1Spatial:Spatial = tile1.get(Spatial);
			var tile2Spatial:Spatial = tile2.get(Spatial);
			
			var tile1Pos:Point = new Point(tile1Spatial.x, tile1Spatial.y);
			var tile2Pos:Point = new Point(tile2Spatial.x, tile2Spatial.y);
			
			tile1MC.parent.setChildIndex(tile1MC, tile1MC.parent.numChildren-1);
			tile2MC.parent.setChildIndex(tile2MC, tile2MC.parent.numChildren-1);
			
			var speed:Number = Math.random() * .4 + .5;
			
			TweenUtils.entityTo(tile1, Spatial, speed, {x: tile2Pos.x, y:tile2Pos.y});
			TweenUtils.entityTo(tile2, Spatial, speed, {x: tile1Pos.x, y: tile1Pos.y, onComplete: tweensCompleted});
		}
		
		private function tweensCompleted():void
		{
			numSwaps++;
			if(numSwaps < NUM_SWAPS)
			{
				swapTiles(tiles[Math.floor(Math.random() * NUM_TILES)], tiles[Math.floor(Math.random() * NUM_TILES)]);
			}
			else
			{
				var textfield:TextField = TextUtils.refreshText(this.screen.content.instructions.bubble.fldBubble);
				textfield.text = "Now show me where the tile is.";
				growBubble(.3);
				
				buttons = new Array();
				for each(var tile:Entity in tiles)
				{
					var basicBtn:BasicButton = ButtonCreator.createBasicButton(tile.get(Display).displayObject, [InteractionCreator.CLICK], this);
					basicBtn.click.addOnce(Command.create(tileClicked, tile));
					buttons.push(basicBtn);
				}
			}
		}
		
		private function tileClicked(e:Event, tile:Entity):void
		{
			shellApi.triggerEvent("majong_single_flip");
			for each(var button:BasicButton in buttons)
				button.removeSignals();
			
			var timeline:Timeline = tile.get(Timeline);
			timeline.gotoAndPlay("flipUp");
			timeline.handleLabel("upDone", Command.create(flippedBack, timeline), true);
			
			var tileMC:MovieClip = MovieClip(Display(tile.get(Display)).displayObject);
			var figure:MovieClip = MovieClip(tileMC.flip.figure);
			
			var win:Boolean = false;
			if(figure.currentFrame == targetNum)
				win = true;
			
			var timer:Timer = new Timer(1000, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, Command.create(gameOver, win));
			timer.start();
		}
		
		private function flippedBack(timeline:Timeline):void
		{
			timeline.stop();
		}
		
		private function gameOver(evt:TimerEvent, win:Boolean):void
		{
			// only have to do this once
			var timer:Timer = evt.target as Timer;
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, flipTiles);
			
			if(win)
				_victory.dispatch();
			else
				_lost.dispatch();
		}
		
		private function shrinkBubble(time:Number):void
		{
			TweenUtils.entityTo(bubbleEntity, Spatial, time, {scaleX: .01, scaleY:.01, ease:Quad.easeOut});
		}
		
		private function growBubble(time:Number):void
		{
			TweenUtils.entityTo(bubbleEntity, Spatial, time, {scaleX: 1, scaleY:1, ease:Quad.easeOut});
		}
		
		public var _victory:Signal = new Signal();
		public var _lost:Signal = new Signal();
		
		private var numSwaps:int = 0;
		private var tiles:Array;
		private var targetNum:int;
		private var buttons:Array;
		private var bubbleEntity:Entity;
		private static var NUM_SWAPS:int = 20;
		private static var NUM_TILES:int = 8;
		private static var WAIT_TIME:Number = 7;
	}
}

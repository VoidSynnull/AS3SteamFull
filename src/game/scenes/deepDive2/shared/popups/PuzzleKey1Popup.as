package game.scenes.deepDive2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.Draggable;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTip;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.Animation;
	import game.data.ui.TransitionData;
	import game.scenes.backlot.shared.components.Dragable;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive2.shared.components.PieceData;
	import game.systems.motion.DraggableSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class PuzzleKey1Popup extends Popup
	{
		private var pieceShufflePoints:Array;
		private var pieces:Vector.<Entity>;
		private var _outlineEntity:Entity;
		private var _events:DeepDive2Events;
		private var linkedPieces:int = 0;
		private const PIECE_COUNT:int = 6;
		private var foundPieces:int = 0;
		private var allPieces:Boolean;
		
		
		public function PuzzleKey1Popup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/deepDive2/shared/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.loadFiles(["puzzleKey1Popup.swf"],false,true,loaded);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("puzzleKey1Popup.swf", true) as MovieClip;
			
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640), false);
			
			_events = new DeepDive2Events();
			
			pieceShufflePoints = [new Point(745,442), new Point(868,166), new Point(111,111), new Point(112,297), new Point(694,100), new Point(163,509)];
			
			setupPuzzle();
			
			AudioUtils.play(this, SoundManager.AMBIENT_PATH + "futuristic_drone_01_loop.mp3", 0.65, true);
			
			super.loaded();		
		}
		
		// make dragable pieces
		private function setupPuzzle():void
		{
			DraggableSystem(addSystem(new DraggableSystem()));
			allPieces = shellApi.checkEvent(_events.GOT_ALL_PUZZLE_PIECES);
			pieces = new Vector.<Entity>();
			var clip:MovieClip;

			for (var i:int = 1; i <= PIECE_COUNT; i++) 
			{
				clip = screen.content["piece"+i];
				if( shellApi.checkEvent(_events.GOT_PUZZLE_PIECE_+i))
				{
					foundPieces++;
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
						BitmapUtils.convertContainer(clip, 1.25);
					}
					var piece:Entity = EntityUtils.createSpatialEntity(this, clip);
					// add dragging
					InteractionCreator.addToEntity(piece,[InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
					var dragable:Draggable = new Draggable();
					dragable.drag.add(pieceGrabbed);
					dragable.drop.add(pieceDropped);
					piece.add(dragable);
					ToolTipCreator.addUIRollover(piece);
					
					var spat:Spatial = piece.get(Spatial);
					var pieceData:PieceData = new PieceData(spat.x,spat.y,20);
					piece.add(pieceData);
					pieces.push(piece);
				}
				else
				{
					clip.parent.removeChild( clip );
				}
			}
			
			clip = screen.content["outline"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
				_outlineEntity = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null,1.25);
				this.addEntity(_outlineEntity);
			}else{
				_outlineEntity = EntityUtils.createMovingTimelineEntity(this,clip);
			}
			EntityUtils.visible(_outlineEntity, false, true);
			DisplayUtils.moveToBack(clip);
			
			scatterPieces(350,150);		
			
			super.loadCloseButton();
		}
		
		private function pieceGrabbed(piece:Entity):void
		{
			// SOUND HERE
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "single_stone_impact_03.mp3", 1.5, false);
		}
		
		private function pieceDropped(piece:Entity):void
		{
			var pieceData:PieceData = piece.get(PieceData);
			var pos:Point = EntityUtils.getPosition(piece);
			var range:Number = GeomUtils.distSquaredPt(pos, pieceData.startingPos);
			// check drop position, if in range of right spot, snap to right spot, disable dragging
			if(pieceData.snapRadius * pieceData.snapRadius >= range){
				EntityUtils.position(piece,pieceData.startingPos.x,pieceData.startingPos.y);
				linkedPieces++;
				piece.remove(Dragable);
				piece.remove(Interaction);
				piece.remove(ToolTip);
				Display(piece.get(Display)).disableMouse();
				// SOUND HERE
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "stone_impact_04.mp3", 1.5, false);
			}
			else{
				// SOUND HERE
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "single_stone_impact_04.mp3", 1.5, false);
			}
			if(linkedPieces >= 6){
				puzzleWin();
			}
			DisplayUtils.moveToTop( EntityUtils.getDisplayObject(super.closeButton));
		}
		
		private function puzzleWin():void
		{
			SceneUtil.timedLockInput(this,true,false,3);
			animateLines();
			shellApi.triggerEvent(_events.PUZZLE_ASSEMBLED,true);
		}
		
		private function animateLines():void
		{
			// SOUND HERE
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "electric_zap_06.mp3", 1, false);
			
			for (var i:int = 0; i < pieces.length; i++) 
			{
				Display(pieces[i].get(Display)).displayObject["outline"].visible = false;
			}
			
			Display(_outlineEntity.get(Display)).moveToFront();
			EntityUtils.visible( _outlineEntity, true );
			var tl:Timeline = Timeline(_outlineEntity.get(Timeline));
			tl.gotoAndPlay("start");
			tl.handleLabel("noLines",morphSound);
			tl.handleLabel(Animation.LABEL_ENDING,onMorphComplete);
		}
		
		private function morphSound(...p):void
		{
			// SOUND HERE
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "electric_zap_05.mp3", 1, false);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.1,1,Command.create(AudioUtils.play, this, SoundManager.EFFECTS_PATH + "points_ping_01d.mp3", 1, false)));
		}
		
		private function onMorphComplete(...p):void
		{
			SceneUtil.delay(this, 2, close);
		}
		
		// scatter pieces within a range
		private function scatterPieces(rangeX:Number,rangeY:Number):void
		{
			var pieceSpat:Spatial;
			for (var i:int = 0; i < pieces.length; i++) 
			{
				pieceSpat = pieces[i].get(Spatial);
				pieceSpat.x = pieceShufflePoints[i].x;
				pieceSpat.y = pieceShufflePoints[i].y;
			}
		}
		
		override public function close(removeOnClose:Boolean=true, onCloseHandler:Function=null):void
		{
			if( super.isOpened )
			{
				if(!allPieces)
				{
					// tell player piece(s) is missing
					var missingCount:int = PIECE_COUNT - foundPieces;
					var words:String = null;
					if(missingCount == 1){
						words = "missingPieces1";
					}else if(missingCount > 1){
						words = "missingPieces2";
					}
					if(words != null){
						SceneUtil.addTimedEvent( parent, new TimedEvent( 0.8,1,Command.create( SubScene(parent).playMessage,words)));
					}
				}
				super.close(removeOnClose,onCloseHandler);
			}
		}
		
		
	}
}
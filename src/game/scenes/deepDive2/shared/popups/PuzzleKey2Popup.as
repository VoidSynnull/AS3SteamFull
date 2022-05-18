package game.scenes.deepDive2.shared.popups
{
	import com.greensock.TweenMax;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.custom.questGame.QuestGame;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class PuzzleKey2Popup extends Popup
	{
		public function PuzzleKey2Popup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{			
			super.pauseParent		= true;
			super.darkenBackground 	= true;
			super.groupPrefix = "scenes/deepDive2/shared/popups/";
			super.screenAsset = "puzzleKey2Popup.swf";

			super.init(container);
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();			
			
			_container = this.screen.content;
			
			this.letterbox(screen.content, new Rectangle(0, 0, 960, 640));
			
			setupPower();
			setupPieces();
			setupGlyphs();
			setupFolder();
			
			AudioUtils.play(this, SoundManager.AMBIENT_PATH + "futuristic_drone_01_loop.mp3", 1, true);
			
			super.loadCloseButton();		
		}
		
		private function setupPower():void
		{
			var mc:MovieClip = _container["powerlines"];
			
			var powerlines:Entity = EntityUtils.createSpatialEntity(this, mc);
			TimelineUtils.convertClip(mc, this, powerlines);
			
			if(shellApi.checkEvent(_events.COMPLETED_PIPES) && shellApi.checkEvent(_events.TRAPPED_MEDUSA) && shellApi.checkEvent(_events.TRAPPED_SHARK))
			{
				_powerOn = true;
				powerlines.get(Timeline).gotoAndStop("on");
				
				if(PlatformUtils.isDesktop)
				{
					var orange:Entity = EntityUtils.createSpatialEntity(this, mc["orange"]);
					powerFull(orange);
				}
			}
			else
			{
				_powerOn = false;
				powerlines.get(Timeline).gotoAndStop("off");
			}
		}
		
		private function powerHalf(orange:Entity):void
		{
			TweenUtils.globalTo(this, orange.get(Display), 1, {alpha:1, onComplete:powerFull, onCompleteParams:[orange]});
		}
		
		private function powerFull(orange:Entity):void
		{
			TweenUtils.globalTo(this, orange.get(Display), 1, {alpha:.5, onComplete:powerHalf, onCompleteParams:[orange]});
		}
		
		private function setupPieces():void
		{
			if(shellApi.checkEvent(_events.PUZZLE_ASSEMBLED) || parent is QuestGame)
			{
				_pieces = new Vector.<Entity>();
				var clip:MovieClip;
				for(var i:int = 1; i <= 5; i++)
				{
					clip = _container["piece" + i];
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
						BitmapUtils.convertContainer(clip, 1.25);
					}
					var piece:Entity =  EntityUtils.createSpatialEntity(this, clip, _container);
					var spatial:Spatial = piece.get(Spatial);
					spatial.rotation = Math.round(Math.random() * 8) * 45;
					if(spatial.rotation == 360){
						spatial.rotation = 0;
					}
					InteractionCreator.addToEntity(piece, [InteractionCreator.CLICK]);
					Interaction(piece.get(Interaction)).click.add(pieceClicked);
					_pieces.push(piece);
				}
			}
			else
			{
				_container.removeChild(_container["whole"]);
				for(var j:int = 1; j <= 5; j++)
				{
					_container.removeChild(_container["piece" + j]);
				}
				
				SceneUtil.lockInput(this, true);
				SceneUtil.addTimedEvent(parent, new TimedEvent(1, 1, Command.create(SubScene(parent).playerSay, "no_piece")));
				SceneUtil.addTimedEvent(this, new TimedEvent(1.7, 1, close));
			}
		}
		
		private function setupGlyphs():void
		{
			_glyphs = new Vector.<Entity>();
			
			// There are 6 glyphs
			for(var i:int = 1; i <= 6; i++)
			{
				_container["glyph" + i]["glyph"].gotoAndStop(i.toString());
				var glyphButton:Entity = ButtonCreator.createButtonEntity(_container["glyph"+i], this, glyphClicked, _container);
				var button:Button = glyphButton.get(Button);
				button.value = i;				
				button.isDisabled = true;
				
				_glyphs.push(glyphButton);
			}
		}
		
		private function glyphClicked(entity:Entity):void
		{
			if(_glyphsGlowing)
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ping_04.mp3", 1, false);
				// Show Selected state
				var button:Button = entity.get(Button);
				button.isSelected = true;
				
				if(button.value == _glyphsCorrect)
				{
					if(_glyphsCorrect == 6)
					{
						shellApi.triggerEvent(_events.SOLVED_PUZZLE, true);
						SceneUtil.lockInput(this, true);
						SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, close));
					}
					_glyphsCorrect++;
				}
				else if(button.value > _glyphsCorrect)
				{
					_glyphsCorrect = 1;
					
					for each(var glyph:Entity in _glyphs)
					{
						// Put buttons back to up state
						var glyphButton:Button = glyph.get(Button);
						glyphButton.isSelected = false;						
					}
				}
			}
		}
		
		private function pieceClicked(entity:Entity):void
		{
			SceneUtil.lockInput(this, true);
			if(_powerOn || parent is QuestGame)
			{
				var spatial:Spatial = entity.get(Spatial);
				TweenUtils.globalTo(this, spatial, .35, {rotation:spatial.rotation + 45, onComplete:pieceRotated, onCompleteParams:[spatial]});
			}
			else
			{
				SceneUtil.addTimedEvent(parent, new TimedEvent(.9, 1, Command.create(SubScene(parent).playerSay, "no_power")));
				SceneUtil.addTimedEvent(this, new TimedEvent(1.1, 1, close));
			}
		}
		
		private function pieceRotated(spatial:Spatial):void
		{
			SceneUtil.lockInput(this, false);
			
			if(spatial.rotation >= 360)
				spatial.rotation -= 360;
			
			checkPieces();
		}
		
		private function checkPieces():void
		{
			var angle:Number = -1;
			for(var i:int = 0; i < _pieces.length; i++)
			{
				var spatial:Spatial = _pieces[i].get(Spatial)
				
				if(angle == -1)
					angle = spatial.rotation;
				else if(spatial.rotation != angle)
					return;
			}
			
			_container["whole"].rotation = angle;
			
			// Make it to this point, all pieces rotation is 0
			// And show whole piece
			for each(var piece:Entity in _pieces)
			{
				EntityUtils.removeInteraction(piece);
				TweenUtils.globalTo(this, piece.get(Display), 1.5, {alpha:0, onComplete:solvedPiece, onCompleteParams:[piece]});
			}
		}
		
		private function solvedPiece(piece:Entity):void
		{
			_pieces.splice(_pieces.indexOf(piece), 1);			
			this.removeEntity(piece);
			
			if(_pieces.length <= 0)
			{
				_pieces = null;
				for each(var glyph:Entity in _glyphs)
				{
					var glyphDisplay:Display = glyph.get(Display);
					new TweenMax(glyphDisplay.displayObject["glyph"], 2, {alpha:1, onComplete:glyphLoaded, onCompleteParams:[glyph]});
					new TweenMax(glyphDisplay.displayObject["purpleBack"], 2, {alpha:1});
					
					_glyphsGlowing = true;
				}
			}
		}
		
		private function glyphLoaded(glyph:Entity):void
		{
			glyph.get(Button).isDisabled = false;
		}
		
		private function setupFolder():void
		{
			if(shellApi.checkItemEvent(_events.GLYPH_FILES))
			{
				var folder:Entity = EntityUtils.createSpatialEntity(this, _container["folder"], _container);
				InteractionCreator.addToEntity(folder, [InteractionCreator.CLICK]);
				ToolTipCreator.addToEntity(folder);
				
				Interaction(folder.get(Interaction)).click.add(clickedFolder);
			}
			else
			{
				_container.removeChild(_container["folder"]);
			}
		}
		
		private function clickedFolder(folder:Entity):void
		{
			// Open popup
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "paper_flap_01.mp3");
			addChildGroup(new GlyphsPopup(this.groupContainer));
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			SceneUtil.lockInput(this, false, false);
			super.close(removeOnClose, onClosedHandler);
		}
		
		private var _events:DeepDive2Events = new DeepDive2Events();
		private var _container:MovieClip;
		private var _pieces:Vector.<Entity>;
		private var _glyphs:Vector.<Entity>;
		private var _glyphsGlowing:Boolean = false;
		private var _powerOn:Boolean = false;
		private var _glyphsCorrect:Number = 1;
	}
}
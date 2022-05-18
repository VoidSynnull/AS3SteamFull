package game.scenes.backlot.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.scenes.backlot.shared.components.PieceGrid;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class TrainConstruction extends Popup
	{
		public function TrainConstruction(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/shared/";
			super.screenAsset = "PropAssemblyPopup.swf";
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		private var backlot:BacklotEvents;
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content as MovieClip;
			
			super.layout.centerUI(content);
			
			for (var i:int=0; i!=vHeight; i++)
			{
				for (var j:int=0; j!=vWidth; j++)
					vTrainMatch[i].push(0);
			}
			
			setUp();
			
			super.loadCloseButton();
		}
		
		private var content:MovieClip;
		private var vNumPieces:Number = 23;
		private var vSpacing:Number = 27;
		private var vWidth:Number = 12;
		private var vHeight:Number = 6;
		private var vTotal:Number = vWidth * vHeight;
		private var vInit:Boolean = false;
		private var vFilter:DropShadowFilter = new DropShadowFilter(5, 135, 0x000000, 0.25, 0, 0);
		private var vTrainMatch:Array = [[],[],[],[],[],[]];
		private var vTrainGrid1:Array = 
			[[0,0,1,1,1,1,0,0,1,1,1,1],
			[0,0,0,1,1,0,0,0,1,1,1,1],
			[0,0,1,1,1,1,1,1,1,1,1,1],
			[0,0,1,1,1,1,1,1,1,1,1,1],
			[0,1,1,1,1,1,1,1,1,1,1,1],
			[1,1,0,1,1,0,0,0,1,1,1,0]];
		private var vTrainGrid2:Array = 
			[[1,1,1,1,1,1,1,1,1],
			[1,1,1,1,1,1,1,1,1],
			[1,1,1,1,1,1,1,1,1],
			[1,1,1,1,1,1,1,1,1],
			[0,1,1,0,0,0,1,1,0]];
		private var vCurrentGrid:Array = vTrainGrid1;
		private var vCurrPrint:Entity;
		private var vNextPrint:MovieClip;
		private var printSize:MovieClip;
		private var print:int = 0;
		
		private var bag:Entity;
		private var reset:Entity;
		
		private function setUp():void
		{
			// set up parts
			for (var i:int=0; i!= vNumPieces; i++)
			{
				var vPart:MovieClip = content["part" + i];
				var part:Entity;
				var partGrid:PieceGrid;
				// set up events if first init
				if (!vInit)
				{
					part = EntityUtils.createMovingEntity(this, vPart, content);
					part.add( new PieceGrid(vPart.getChildAt(0).name));
					part.add(new Id("part" + i));
					part.add(new Audio());
					
					partGrid = part.get(PieceGrid);
					var interaction:Interaction = InteractionCreator.addToEntity(part, [InteractionCreator.DOWN, InteractionCreator.UP],vPart); 
					
					interaction.down.add(fnClick);
					interaction.up.add(fnRelease);
					
					ToolTipCreator.addToEntity(part);
					partGrid.startX = part.get(Spatial).x;
					partGrid.startY = part.get(Spatial).y;
					partGrid.depth = content.getChildIndex(content.bagtop);// + vNumPieces;
					content.setChildIndex(vPart, partGrid.depth);
				}
				else
				{
					part = getEntityById("part" + i);
					partGrid = part.get(PieceGrid);
					
					var tween:Tween = new Tween();
					tween.to(part.get(Spatial),2,{x:partGrid.startX, y:partGrid.startY});
					//part.get(Spatial).x = partGrid.startX;
					//part.get(Spatial).y = partGrid.startY;
					part.add(tween);
					content.setChildIndex(vPart, partGrid.depth);
				}
				partGrid.onGrid = false;
				vPart.filters = [vFilter];
			}
			
			print++;
			
			if(print == 1)
				vCurrentGrid = vTrainGrid1;
			else
				vCurrentGrid = vTrainGrid2;
			
			for(var prints:int = 1; prints <= 3; prints++)
			{
				var printLayouts:Entity;
				var thisPrint:MovieClip = content["print"+prints];
				if(!vInit)
				{
					printLayouts = EntityUtils.createSpatialEntity(this, thisPrint, content);
					printLayouts.add(new Id("print"+prints));
				}
				else
				{
					printLayouts = getEntityById("print"+prints);
				}
				if(prints == print)
				{
					vCurrPrint = printLayouts;
					printSize = thisPrint.trainSize;
				}
				else
				{
					printLayouts.get(Display).visible = false;
					//printLayouts.get(Spatial).y = -480;// this doesnt work out anymore because the popup is smaller than the window and no longer looks like it is coming from off screen
				}
			}
			
			vCurrPrint.get(Display).visible = true;
			
			if(!vInit)
			{
				bag = EntityUtils.createSpatialEntity(this, content.bagtop, content);
				reset = EntityUtils.createSpatialEntity(this, content.resetButton, content);
				TimelineUtils.convertClip(content.resetButton, this, reset, null, false);
				var timeline:Timeline = reset.get(Timeline);

				trace("set up reset button");
				var resetInteraction:Interaction = InteractionCreator.addToEntity(reset, [InteractionCreator.DOWN, InteractionCreator.OVER, InteractionCreator.UP, InteractionCreator.OUT],content.resetButton);
				resetInteraction.down.add(Command.create(down, timeline));
				resetInteraction.up.add(Command.create(up, timeline));
				resetInteraction.over.add(Command.create(over, timeline));
				resetInteraction.out.add(Command.create(out, timeline));
				
				ToolTipCreator.addToEntity(reset);
			}
			
			Display(bag.get(Display)).moveToFront();
			
			vWidth = vCurrentGrid[0].length;
			vHeight = vCurrentGrid.length;
			
			if (vInit)
			{
				for (i=0; i!=vHeight; i++)
				{
					for (var j:int=0; j!=vWidth; j++)
						vTrainMatch[i][j] = 0;
				}	
			}
			vInit = true;
		}
		
		private function out(button:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("up");
		}
		
		private function over(button:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("over");
		}
		
		private function up(button:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("up");
		}
		
		private function down(button:Entity, timeline:Timeline):void
		{
			timeline.gotoAndStop("down");
			print--;
			setUp();
		}
		
		private function fnRelease(piece:Entity):void
		{		
			Audio(piece.get(Audio)).play("effects/hammering_on_wood_02.mp3");
			var piecePosition:Point = new Point(piece.get(Spatial).x - vCurrPrint.get(Spatial).x - printSize.x, piece.get(Spatial).y - vCurrPrint.get(Spatial).y- printSize.y);
			
			var pieceX:int = int(Math.round(piecePosition.x / vSpacing));
			var pieceY:int = int(Math.round(piecePosition.y / vSpacing));
			
			var pieceGrid:PieceGrid = piece.get(PieceGrid);
			var width:int = pieceGrid.grid[0].length;
			var height:int = pieceGrid.grid.length;
			var pieceCoordinates:Rectangle = new Rectangle(pieceX, pieceY, width, height);
			
			if( onGrid(pieceCoordinates) )
			{
				if(canSetPieceOnGrid(pieceCoordinates, pieceGrid))
				{
					piece.get(Spatial).x = vCurrPrint.get(Spatial).x + printSize.x + (pieceX * vSpacing);
					piece.get(Spatial).y = vCurrPrint.get(Spatial).y + printSize.y + (pieceY * vSpacing);
					piece.remove(FollowTarget);
					setOrRemovePiece(pieceCoordinates, pieceGrid, true);
					pieceGrid.pointX = pieceX;
					pieceGrid.pointY = pieceY;
					pieceGrid.onGrid = true;
					Display(piece.get(Display)).displayObject.filters = [];
				}
			}
			else
			{
				piece.remove(FollowTarget);
			}
			
			if(trainsMatch())
			{
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, addDelay));
				trace("trains match");
				// need to add some sort of animation for completing a print
			}
		}
		
		private function addDelay():void
		{
			if(print < 3)
				setUp();
			else
			{
				shellApi.triggerEvent(backlot.MADE_TRAIN_PROP, true);
				super.close();
			}
		}
		
		private function onGrid(pieceCoordinates:Rectangle):Boolean
		{
			if( pieceCoordinates.x >= 0 && pieceCoordinates.x  <= vWidth - pieceCoordinates.width && pieceCoordinates.y >= 0 && pieceCoordinates.y <= vHeight - pieceCoordinates.height)
				return true;
			return false;
		}
		
		private function canSetPieceOnGrid(pieceCoordinates:Rectangle, pieceGrid:PieceGrid):Boolean
		{
			for(var row:int = pieceCoordinates.y; row < pieceCoordinates.y + pieceCoordinates.height; row++)
			{
				for( var col:int = pieceCoordinates.x; col < pieceCoordinates.x + pieceCoordinates.width; col++)
				{
					if(vTrainMatch[row][col] == 1 && pieceGrid.grid[row - pieceCoordinates.y][col - pieceCoordinates.x] == 1)
						return false;
				}
			}
			return true;
		}
		
		private function setOrRemovePiece(pieceCoordinates:Rectangle, pieceGrid:PieceGrid, setPiece:Boolean):void
		{
			for(var row:int = pieceCoordinates.y; row < pieceCoordinates.y + pieceCoordinates.height; row++)
			{
				for( var col:int = pieceCoordinates.x; col < pieceCoordinates.x + pieceCoordinates.width; col++)
				{
					if(pieceGrid.grid[row - pieceCoordinates.y][col - pieceCoordinates.x] == 1)
					{
						if(setPiece)
							vTrainMatch[row][col] = 1;
						else
							vTrainMatch[row][col] = 0;
					}
				}
			}
		}
		
		private function trainsMatch():Boolean
		{
			for(var row:int = 0; row < vCurrentGrid.length; row++)
			{
				for( var col:int = 0; col < vCurrentGrid[0].length; col++)
				{
					trace("row: " + row + " col: " + col);
					trace(vTrainMatch[row][col] + " " + vCurrentGrid[row][col]);
					if(vTrainMatch[row][col] != vCurrentGrid[row][col])
						return false;
				}
			}
			return true;
		}
		
		private function fnClick(piece:Entity):void
		{
			Audio(piece.get(Audio)).play("effects/hammering_on_wood_01.mp3");
			
			var mousePosition:Point = new Point(shellApi.inputEntity.get(Spatial).x,shellApi.inputEntity.get(Spatial).y);
			var piecePosition:Point = new Point(piece.get(Spatial).x, piece.get(Spatial).y);
			var difference:Point = new Point(mousePosition.x - piecePosition.x, mousePosition.y - piecePosition.y);
			
			var pieceGrid:PieceGrid = piece.get(PieceGrid);
			var width:int = pieceGrid.grid[0].length;
			var height:int = pieceGrid.grid.length;
			var pieceCoordinates:Rectangle = new Rectangle(pieceGrid.pointX, pieceGrid.pointY, width, height);
			
			if(onGrid(pieceCoordinates))
			{
				if(!piece.get(FollowTarget) && pieceGrid.onGrid)
				{
					setOrRemovePiece(pieceCoordinates, pieceGrid, false);
					pieceGrid.onGrid = false;
				}
			}
			
			var follow:FollowTarget = new FollowTarget(shellApi.inputEntity.get(Spatial), .5);
			follow.offset = new Point(-difference.x, -difference.y);
			piece.add(follow);
			
			Display(piece.get(Display)).moveToFront();
			
			Display(piece.get(Display)).displayObject.filters = [vFilter];
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			super.close();
		}
	}
}
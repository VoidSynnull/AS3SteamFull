package game.scenes.examples.dynamicBoatScene
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	public class EntityGrid extends Component
	{
		public function EntityGrid()
		{
			this.grid = new Dictionary();
		}
		
		public function addElement(element:EntityGridElement):void
		{
			var x:int = element.x / elementSize;
			var y:int = element.y / elementSize;
			
			if(this.grid[x] == null)
			{
				this.grid[x] = new Dictionary();
			}
			
			var current:* = this.grid[x][y];
			
			if(current == null)
			{
				this.grid[x][y] = element;
			}
			else
			{
				if(current is EntityGridElement)
				{
					this.grid[x][y] = new Vector.<EntityGridElement>();
					this.grid[x][y].push(current);
				}
				
				this.grid[x][y].push(element);
			}
		}
		
		public function removeElement(element:EntityGridElement):void
		{
			var x:int = element.x / elementSize;
			var y:int = element.y / elementSize;
			
			if(this.grid[x] == null)
			{
				trace("Error :: removeElement : Element not in grid.");
				return;
			}
			
			var current:* = this.grid[x][y];
			
			if(current == null)
			{
				trace("Error :: removeElement : Element not in grid.");
				return;
			}
			
			if(current is EntityGridElement)
			{
				this.grid[x][y] = null;
			}
			else
			{
				current.splice(current.indexOf(element), 1);
				
				if(current.length == 0)
				{
					this.grid[x][y] = null;
				}
			}
		}
		
		public function getElement(x:Number, y:Number, useGridPosition:Boolean = false):*
		{
			if(!useGridPosition)
			{
				x /= elementSize;
				y /= elementSize;
			}
			
			return(this.grid[x][y]);
		}
		
		public var drawDistanceX:Number;
		public var drawDistanceY:Number;
		public var width:Number;
		public var height:Number;
		public var grid:Dictionary;
		public var elementSize:int = 100;
	}
}
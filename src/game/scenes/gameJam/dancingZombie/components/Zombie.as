package game.scenes.gameJam.dancingZombie.components
{
	import com.smartfoxserver.v2.requests.PublicMessageRequest;
	
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Zombie extends Component
	{
		public var active:Boolean = false;
		
		public var health:uint;
		
		public var coordinates:Point;//col, row
		
		public var direction:Point;
		
		public var tileSize:Number;
		
		public var beatMovements:Array;
		
		public var stateChanged:Signal;
		
		public function Zombie(tileSize:Number, health:uint = 0)
		{
			this.tileSize = tileSize;
			this.health = health;
			coordinates = new Point();
			direction = new Point(0,1);
			beatMovements = [4];//which beats they move on
			// signal when zombie dies or hits bottom of screen
			stateChanged = new Signal();
		}
		
		public function inRow(row:int):Boolean
		{
			return row == coordinates.y;
		}
		
		public function inCol(col:int):Boolean
		{
			return col == coordinates.x;
		}
		
		public function atCoordinate(col:uint, row:uint):Boolean
		{
			return inRow(row) && inCol(col);
		}
		
		public function inPath(path:Vector.<Point>):Boolean
		{
			for each (var i:Point in path) 
			{
				if( atCoordinate(i.x,i.y) ){	
					return true;
				}
			}
			return false;
		}
		
		override public function destroy():void
		{
			stateChanged.removeAll();
			stateChanged = null;
		}
		
		
		
		
		
		
		
		
		
	}
}
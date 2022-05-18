package game.systems.dragAndDrop
{
	import ash.core.Component;
	
	public class Capacity extends Component
	{
		public var capacity:Number;
		public var count:Number;
		public var allowOverflow:Boolean;
		public function Capacity(capacity:Number = 1, startFull:Boolean = false, allowOverflow:Boolean = false)
		{
			this.capacity = capacity;
			if(startFull)
				count = capacity;
			else
				count = 0;
			this.allowOverflow = allowOverflow;
		}
		
		public function add(quantity:Number):Number
		{
			var valid:Number = quantity;
			if(count + quantity > capacity && !infinte || count + capacity < 0 && !infinte)
			{
				if(allowOverflow)
				{
					if(count + quantity > capacity)
					{
						valid = capacity - count;
						count = capacity;
					}
					else
					{
						valid = count;
						count = 0;
					}
				}
				else
					valid = 0;
			}
			else
				count += quantity;
			
			return valid;
		}
		
		public function remove(quantity:Number):Number
		{
			return add(-quantity);
		}
		
		public function get full():Boolean{return (count == capacity && capacity > 0);}
		
		public function get empty():Boolean{return (count == 0 && capacity > 0);}
		
		public function get infinte():Boolean{return capacity <= 0;}
	}
}
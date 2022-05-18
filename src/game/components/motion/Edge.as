package game.components.motion
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class Edge extends Component
	{
		/**
		 * A Rectangle representing the "bounding box" of your Entity's Edge. These values are the unscaled
		 * values of your Edge when scaleX and scaleY both equal 1. The Entity's Spatial is considered to
		 * be the Edge's center at (0, 0), and as a result this "bounding box" can have both positive and negative
		 * values for its sides.
		 */
		public var unscaled:Rectangle = new Rectangle();
		
		/**
		 * A Rectangle representing the values of the unscaled Rectangle that are multiplied by the scaleX and
		 * scaleY of the Edge. This Rectangle is automatically updated in the EdgeSystem using an Entity's
		 * Display scaleX and scaleY and should not be altered directly. If an Entity does not have a Display,
		 * but you still want to scale this Rectangle, simply change the Edge's scaleX and scaleY values.
		 */
		public var rectangle:Rectangle = new Rectangle();
		
		private var _scaleX:Number = 1;
		private var _scaleY:Number = 1;
			
		public function Edge(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0) 
		{
			this.unscaled.setTo(x, y, width, height);
			this.scaleX = 1;
			this.scaleY = 1;
		}
		
		public function set scale(scale:Number):void
		{
			this.scaleX = scale;
			this.scaleY = scale;
		}
		
		public function get scaleX():Number { return this._scaleX; }
		public function set scaleX(scaleX:Number):void
		{
			if(isFinite(scaleX))
			{
				this._scaleX = scaleX;
				if(this._scaleX >= 0)
				{
					this.rectangle.x = this.unscaled.x * this._scaleX;
					this.rectangle.width = this.unscaled.width * this._scaleX;
				}
				else
				{
					this.rectangle.x = -this.unscaled.right * -this._scaleX;
					this.rectangle.width = this.unscaled.width * -this._scaleX;
				}
			}
		}
		
		public function get scaleY():Number { return this._scaleY; }
		public function set scaleY(scaleY:Number):void
		{
			if(isFinite(scaleY))
			{
				this._scaleY = scaleY;
				if(this._scaleY >= 0)
				{
					this.rectangle.y = this.unscaled.y * this._scaleY;
					this.rectangle.height = this.unscaled.height * this._scaleY;
				}
				else
				{
					this.rectangle.y = -this.unscaled.bottom * -this._scaleY;
					this.rectangle.height = this.unscaled.height * -this._scaleY;
				}
			}
		}
	}
}

package game.components
{
	import ash.core.Component;
	import org.osflash.signals.Signal;

	public class Viewport extends Component
	{
		public function Viewport( width:Number = 0, height:Number = 0 )
		{
			_width = width;
			_height = height;

			changed = new Signal( Viewport );
		}
		
		public var changed:Signal;

		private var _width:Number;
		public function get width():Number	{ return _width; }
		public function set width( value:Number ):void
		{ 
			if ( !isNaN( value ) )
			{
				_width = value 
				changed.dispatch( this ); 
			}
		}
		
		private var _height:Number;
		public function get height():Number	{ return _height; }
		public function set height( value:Number ):void	
		{ 
			if ( !isNaN( value ) )
			{
				_height = value 
				changed.dispatch( this ); 
			}
		}
		
		public function setDimensions( viewWidth:Number = NaN, viewHeight:Number = NaN ):void 
		{ 
			var hasChanged:Boolean = false;
			
			if ( !isNaN( viewWidth ) )
			{
				_width = viewWidth;
				hasChanged = true;
			}
			
			if ( !isNaN( viewHeight ) )
			{
				_height = viewHeight;
				hasChanged = true;
			}
			
			if ( hasChanged )
			{
				changed.dispatch( this );
			}
		}
	}
}

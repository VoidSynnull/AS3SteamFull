package game.util
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import engine.util.Command;

	public class ScreenEffects
	{						
		public function ScreenEffects(container:DisplayObjectContainer = null, width:Number = 0, height:Number = 0, darkenAlpha:Number = 1, color:Number = 0x000000, offset:Point = null )
		{
			if(container)
			{
				if( offset != null )	{ this.offset = offset; }
				_box = createBox(width, height, color);
				this.darkenAlpha = darkenAlpha;
				_box.alpha = this.darkenAlpha;
				container.addChild(_box);
			}
		}
		
		/**
		 * Remove black screen hiding the viewport.
		 * @param   [fade] : Use a smooth transition rather than instant change.
		 * @param   [complete] : function to trigger on fade completion
		 */
		public function fadeFromBlack(fadeTime:Number = 0, complete:Function = null):void
		{			
			if (fadeTime > 0)
			{
				_box.visible = true;
				_box.alpha = darkenAlpha;
				TweenLite.to(_box, fadeTime, { alpha : 0, ease:Linear.easeNone, onComplete : Command.create(fadeInComplete,complete) } );
			}
			else
			{
				fadeInComplete(complete);
			}
		}
		public function fadeInComplete(complete:Function):void
		{	
			if(complete != null){
				complete();
			}
			hide();
		}
		
		/**
		 * Add a black screen to hide the viewport.
		 * @param   [fade] : Use a smooth transition rather than instant change.
		 */
		public function fadeToBlack(fadeTime:Number = 0, onComplete:Function = null, onCompleteParams:Array = null):void
		{			
			if (fadeTime > 0)
			{				
				_box.visible = true;
				_box.alpha = 0;
				TweenLite.to(_box, fadeTime, { alpha : darkenAlpha, ease:Linear.easeNone, onComplete : onComplete, onCompleteParams : onCompleteParams } );
			}
			else
			{
				if(onComplete)
				{
					onComplete.apply(onCompleteParams);
				}
				else
				{
					show();
				}
			}
		}
		
		public function screenFlash(container:DisplayObjectContainer, width:Number, height:Number, color:uint = 0xffffff, fadeTime:Number = 1):void
		{
			var box:Sprite = createBox(width, height, color);
			container.addChild(box);
			TweenLite.to(box, fadeTime, { delay : .1, alpha : 0, ease:Linear.easeNone, onComplete : deleteBox, onCompleteParams : [box] } );
		}
		
		public function deleteBox(box:Sprite):void
		{
			box.parent.removeChild(box);
		}
		
		public function createBox(width:Number, height:Number, color:uint = 0):Sprite
		{
			var box:Sprite = new Sprite();
			box.graphics.beginFill(color);
			box.graphics.drawRect(offset.x, offset.y, width, height);
			box.graphics.endFill();

			//DisplayUtils.cacheAsBitmap(box);
			
			return(box);
		}
		
		public function hide():void
		{
			_box.visible = false;
		}	
		
		public function show():void
		{
			_box.visible = true;
		}
		
		private var _box:Sprite;
		public function get box():Sprite	{ return _box; }
		
		public var offset:Point = new Point();
		
		public var darkenAlpha:Number;
		private var _loadingDisplay:MovieClip;
	}
}
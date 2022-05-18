package game.scenes.mocktropica.server
{
	import com.greensock.TweenMax;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	public class AmbientLight extends EventDispatcher
	{
		private var _asset:MovieClip;
		private var _animating:Boolean = false
		
		public function AmbientLight(__asset:MovieClip)
		{
			_asset = __asset
			_asset.addEventListener(Event.ENTER_FRAME,onEnterFrame)
			_animating = true
		}
		
		protected function onEnterFrame(event:Event):void
		{
			if (_animating) {
				if (_asset.currentFrameLabel!= null){
					_asset.stop()
					_animating = false
					TweenMax.delayedCall( + Math.random()*1,playNextAnim)
				}
			}
			
		}	
		
		private function playNextAnim ():void {
			var r:int = Math.random()*_asset.currentLabels.length
			_asset.gotoAndPlay(_asset.currentLabels[r].frame+1)
			_animating = true
		}
		
	}
}
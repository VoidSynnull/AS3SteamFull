package game.ui.elements {

	public class SliderControl extends UIElement {

		import flash.display.*;
		import flash.events.MouseEvent;
		import flash.geom.*;
		
		import org.osflash.signals.Signal;
		import org.osflash.signals.natives.NativeSignal;

		public var changed:Signal;
		public var complete:Signal;
		public var isReversed:Boolean = false;

		private var trackRect:Rectangle;
		private var thumbsOwnBounds:Rectangle;
		private var minX:Number, maxX:Number;
		private var clickOffset:Point;
		private var thumb:MovieClip, track:InteractiveObject;

		public function SliderControl(trackAsset:InteractiveObject, thumbAsset:MovieClip) {
			if (!trackAsset) {
				trackAsset = makeSliderTrack();
			}
			if (!thumbAsset) {
				thumbAsset = makeSliderThumb();
			}
			track = trackAsset;
			thumb = thumbAsset;
			thumb.stop();
			thumb.mouseChildren = false;
			thumbsOwnBounds = thumb.getBounds(thumb);
			sliderRect = track.getBounds(track.parent);

			changed = new Signal(Number, SliderControl);
			complete = new Signal(Number, SliderControl);

			new NativeSignal(track,	'mouseDown', MouseEvent).add(onTrackPress);
			over = new NativeSignal(thumb, 'mouseOver', MouseEvent);
			over.add(onThumbRolled);
			out = new NativeSignal(thumb, 'mouseOut', MouseEvent);
			out.add(onThumbRolledOut);
			down = new NativeSignal(thumb, 'mouseDown', MouseEvent);
			down.add(onThumbPress);
			new NativeSignal(track.stage, 'mouseMove', MouseEvent).add(onThumbMove);
			up = new NativeSignal(track.stage, 'mouseUp'  , MouseEvent);
			up.add(onThumbRelease);
		}

		public function set sliderRect(newRect:Rectangle):void {
			trackRect = newRect;
			minX = (trackRect.left  + thumbsOwnBounds.width/2) - (thumbsOwnBounds.left + thumbsOwnBounds.width/2);
			maxX = (trackRect.right - thumbsOwnBounds.width/2) - (thumbsOwnBounds.left + thumbsOwnBounds.width/2);
		}

		public function get thumbRange():Number {
			return trackRect.width - thumb.width;
		}

		public function get percentValue():Number {
			var sliderValue:Number = ((thumb.x + thumbsOwnBounds.left) - trackRect.left) / thumbRange;
			// damn these tiny fractions, just jog it into place for now
			// TODO: get the math truly precise
			if (sliderValue <= 0.001) sliderValue = 0.0;
			if (sliderValue >= 0.998) sliderValue = 1.0;
			return isReversed ? 1.0 - sliderValue : sliderValue;
		}
		public function set percentValue(newPercent:Number):void {
			if (isReversed) {
				thumb.x = minX + ((1.0 - newPercent) * thumbRange);
			} else {
				thumb.x = minX + (newPercent * thumbRange);
			}
		}
		
		public function get enabled():Boolean {
			return track.mouseEnabled;
		}
		public function set enabled(flag:Boolean):void {
			thumb.mouseEnabled = track.mouseEnabled = flag;
			thumb.alpha = track.alpha = flag ? 1.0 : 0.5;
		}

		public override function destroy():void {
			changed.removeAll();
			complete.removeAll();
			super.destroy();
		}

		//// EVENT HANDLERS ////

		public function onTrackPress(e:MouseEvent):void {
			var newX:Number = track.x + e.localX - thumb.width / 2+thumbsOwnBounds.right;
			thumb.x = Math.max(trackRect.left-thumbsOwnBounds.left, Math.min(trackRect.right - thumb.width, newX));
			changed.dispatch(percentValue, this);
			clickOffset = new Point(thumb.width/2+thumbsOwnBounds.left, 0);
		}

		public function onThumbRolled(e:MouseEvent):void {
			thumb.gotoAndStop('over');
		}
		public function onThumbRolledOut(e:MouseEvent):void {
			thumb.gotoAndStop('up');
		}
		public function onThumbPress(e:MouseEvent):void {
			thumb.gotoAndStop('down');
			clickOffset = new Point(thumb.mouseX, thumb.mouseY);
		}

		public function onThumbMove(e:MouseEvent):void {
			if (!clickOffset) {
				return;
			}
			var newX:Number = track.parent.mouseX - clickOffset.x;
			thumb.x = Math.max(minX, Math.min(maxX, newX));
			changed.dispatch(percentValue, this);
		}

		public function onThumbRelease(e:MouseEvent):void {
			if (!clickOffset) {
				return;
			}
			thumb.gotoAndStop(thumb.getBounds(thumb).contains(thumb.mouseX, thumb.mouseY) ? 'over' : 'up');
			clickOffset = null;
			complete.dispatch(percentValue, this);
		}

		private function makeSliderTrack():Sprite {
			var blackTrack:Sprite = new Sprite();
			blackTrack.name = 'blackTrack';
			with (blackTrack.graphics) {
				lineStyle();
				beginFill(0x0);
				drawRoundRect(0, 0, 500, 10, 10);
			}
			return blackTrack;
		}

		private function makeSliderThumb(itsTrack:Sprite=null):MovieClip {
			var redThumb:MovieClip = new MovieClip();
			redThumb.name = 'redThumb';
			with (redThumb.graphics) {
				beginFill(0xcc3333);
				drawRoundRect(0, 0, 100, 10, 10);
			}
			return redThumb;
		}

	}

}

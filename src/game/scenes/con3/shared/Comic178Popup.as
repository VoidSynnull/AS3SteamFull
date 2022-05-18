package game.scenes.con3.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class Comic178Popup extends Popup
	{
		public function Comic178Popup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			this.pauseParent 		= true;
			this.autoOpen 			= true;
			super.groupPrefix = "scenes/con3/shared/";
			this.screenAsset = "comic178.swf";
			super.init(container);
			load();
		}		
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();	
			
			this.letterbox(screen.content, new Rectangle(0, 0, 831, 597), false);
			//this.layout.fitUI( super.screen );
			
			super.loadCloseButton();
			
			//			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			//			var qual:Number = PerformanceUtils.defaultBitmapQuality;
			//			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
			//				var clip:MovieClip = screen["bg"];
			//				var bitmap:SharedBitmap = BitmapUtils.createBitmap(clip, PerformanceUtils.defaultBitmapQuality);
			//				DisplayUtils.swap(bitmap, clip);
			//				//BitmapUtils.convertContainer(clip,qual);
			//			}
		}
	}
}
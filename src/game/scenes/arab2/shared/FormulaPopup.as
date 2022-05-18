package game.scenes.arab2.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.PerformanceUtils;
	
	public class FormulaPopup extends Popup
	{
		public function FormulaPopup(container:DisplayObjectContainer=null)
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
			super.groupPrefix = "scenes/arab2/shared/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["formula_popup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{				
			super.screen = super.getAsset("formula_popup.swf", true) as MovieClip;
			
			this.layout.fitUI( super.screen );
			
			super.loadCloseButton();
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			var qual:Number = PerformanceUtils.defaultBitmapQuality;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				var clip:MovieClip = screen.content["BG"];
				BitmapUtils.convertContainer(clip,qual);
			}

			super.loaded();	
		}
	}
}
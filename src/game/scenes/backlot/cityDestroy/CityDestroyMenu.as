package game.scenes.backlot.cityDestroy
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import game.data.ui.ButtonSpec;
	import game.scene.template.SceneUIGroup;
	import game.ui.elements.MultiStateButton;
	import game.ui.popup.Popup;
	
	import org.osflash.signals.Signal;
	
	public class CityDestroyMenu extends Popup
	{
		private var assetUrl:String;
		private var content:MovieClip;
		
		public var clickedOk:Signal;
		
		public function CityDestroyMenu(assetUrl:String = "GameStart.swf", container:DisplayObjectContainer=null)
		{
			clickedOk = new Signal();
			this.assetUrl = assetUrl;
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/backlot/cityDestroy/";
			super.screenAsset = assetUrl;
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content as MovieClip;
			
			content.x = shellApi.camera.camera.viewportWidth/2;
			content.y = shellApi.camera.camera.viewportHeight/2;
			
			setUp();
		}
		
		private function setUp():void
		{
			var okButton:MultiStateButton = MultiStateButton.instanceFromButtonSpec
			(
				ButtonSpec.instanceFromInitializer
				(
					{
						displayObjectContainer:content.btnOk,
						pressAction:super.playClick,
						clickHandler:clickOk
					}
				)
			)
		}
		
		private function clickOk(e:MouseEvent):void
		{
			clickedOk.dispatch();
			super.close();
		}
	}
}
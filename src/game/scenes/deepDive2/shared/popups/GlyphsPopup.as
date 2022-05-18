package game.scenes.deepDive2.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.creators.ui.ToolTipCreator;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.ui.popup.Popup;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	
	public class GlyphsPopup extends Popup
	{
		public function GlyphsPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent = true;
			this.darkenBackground = true;
			this.autoOpen = true;
			this.groupPrefix = "scenes/deepDive2/shared/popups/";
			this.screenAsset = "glyphsPopup.swf";
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			_container = this.screen.content;
			
			this.letterbox(_container, new Rectangle(0, 0, 864, 548), false);
			
			setupGlyphImages();
			
			super.loadCloseButton();
		}
		
		private function setupGlyphImages():void
		{
			for(var i:int = 1; i <= 6; i++)
			{
				if(shellApi.checkEvent(_events.GLYPH_ + i))
				{
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						BitmapUtils.convertContainer(_container["page" + i], 1.0);
					}
					var page:Entity = EntityUtils.createSpatialEntity(this, _container["page" + i], _container);
					InteractionCreator.addToEntity(page, [InteractionCreator.CLICK]);
					ToolTipCreator.addToEntity(page);
					
					page.get(Interaction).click.add(pageClicked);
				}
				else
				{
					_container.removeChild(_container["page" + i]);
				}
			}
		}
		
		private function pageClicked(page:Entity):void
		{
			DisplayUtils.moveToTop(page.get(Display).displayObject);
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			super.close(removeOnClose, onClosedHandler);
		}
		
		private var _events:DeepDive2Events = new DeepDive2Events();
		private var _container:DisplayObjectContainer;
	}
}
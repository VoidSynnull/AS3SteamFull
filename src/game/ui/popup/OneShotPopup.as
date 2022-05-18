package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.util.DisplayUtils;
	
	public class OneShotPopup extends Popup
	{
		public function OneShotPopup(container:DisplayObjectContainer=null, asset:String = null,  prefix:String = null, fill:Boolean = true)
		{
			this.fill = fill;
			super(container);
			configData(asset, prefix);
		}
		
		public function configData(asset:String = null, prefix:String = null):void
		{
			if(asset != null)
				screenAsset = asset;
			if(prefix != null)
				groupPrefix = prefix;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			if(data != null)
			{
				if(data.hasOwnProperty("screenAsset"))
					screenAsset = data["screenAsset"];
				if(data.hasOwnProperty("groupPrefix"))
					groupPrefix = data["groupPrefix"];
			}
			super.darkenBackground = true;
			super.darkenAlpha = .66;
			super.init(container);
			load();
		}
		
		public var content:MovieClip;
		public var fill:Boolean;
		
		override public function loaded():void
		{
			super.screen = super.getAsset(screenAsset) as MovieClip;
			content = screen.content as MovieClip;
			if(fill)
				DisplayUtils.fitDisplayToScreen(this, content);
			else
				layout.centerUI(content);
			super.loaded();
			super.loadCloseButton();
		}
	}
}